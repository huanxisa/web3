"""飞书表格数据提取脚本（Phase 2）

策略：
- 直接在浏览器里 evaluate JS，从 window.spread / window.Spread / window.spreadApp
  这些飞书内部对象上挖 cell 数据
- 多种 fallback：
    1. 优先调用 spread 的标准 API（getActiveSheet → getRange → getValues）
    2. fallback 用反射枚举所有可调用方法
    3. 最后回退到「Ctrl+A 全选 + 复制」抓剪贴板

使用：
    python scripts/feishu_extract.py             # 普通模式
    python scripts/feishu_extract.py --headed    # 有头模式（看着浏览器干活）
"""

from __future__ import annotations

import argparse
import json
import os
import sys
import time
from datetime import datetime
from pathlib import Path

# 必须在 import playwright 之前设置浏览器缓存路径。
# Cursor 沙箱默认把 PLAYWRIGHT_BROWSERS_PATH 指向一次性临时目录（重启即丢失），
# 这里强制覆盖到用户主目录下的持久缓存。
_DEFAULT_BROWSER_CACHE = Path.home() / ".cache" / "ms-playwright"
if _DEFAULT_BROWSER_CACHE.exists():
    os.environ["PLAYWRIGHT_BROWSERS_PATH"] = str(_DEFAULT_BROWSER_CACHE)

from playwright.sync_api import sync_playwright  # noqa: E402

SHEET_URL = "https://my.feishu.cn/sheets/ScdYsiuRMhTjzFt0rdXcCyshnom"
PROJECT_ROOT = Path(__file__).resolve().parent.parent
PROFILE_DIR = PROJECT_ROOT / ".playwright_profile"
RAW_BASE = PROJECT_ROOT / "data" / "raw" / "feishu"
WAIT_AFTER_LOAD_SEC = 25


# ============== 浏览器里执行的 JS 代码 ==============

EXTRACT_JS = r"""
() => {
    // 通用工具：枚举对象上的方法名
    function listMethods(obj, depth = 1, prefix = '') {
        const out = [];
        if (!obj || depth <= 0) return out;
        const seen = new Set();
        let cur = obj;
        for (let d = 0; d < 3 && cur; d++) {
            try {
                const props = Object.getOwnPropertyNames(cur);
                for (const p of props) {
                    if (seen.has(p)) continue;
                    seen.add(p);
                    try {
                        const v = obj[p];
                        out.push({
                            name: prefix + p,
                            type: typeof v,
                            isFunc: typeof v === 'function',
                            sample: typeof v === 'function' ? null :
                                    (typeof v === 'object' ? '<obj>' : String(v).slice(0, 80))
                        });
                    } catch (e) {}
                }
                cur = Object.getPrototypeOf(cur);
            } catch (e) { break; }
        }
        return out;
    }

    const result = {
        _meta: {
            time: new Date().toISOString(),
            url: location.href,
        },
        candidates: {},
        cells: null,           // 提取到的 cell 数据（最终目标）
        attempts: [],          // 各种 fallback 的尝试日志
    };

    // === 1. 探查飞书核心对象 ===
    const targets = ['spread', 'Spread', 'spreadApp', 'sheetBlocksMagicShareService'];
    for (const k of targets) {
        const v = window[k];
        if (!v) { result.candidates[k] = '<missing>'; continue; }
        result.candidates[k] = {
            constructor: v.constructor && v.constructor.name,
            ownProps: Object.getOwnPropertyNames(v).slice(0, 50),
            methods: listMethods(v).filter(x => x.isFunc).slice(0, 80).map(x => x.name),
            scalar: listMethods(v).filter(x => !x.isFunc && x.type !== 'object').slice(0, 30),
        };
    }

    // === 2. 尝试调用 window.spread 的 SpreadJS 风格 API ===
    function tryExtractFromSpread() {
        const sp = window.spread;
        if (!sp) return { ok: false, reason: 'no window.spread' };

        // 候选方法名（SpreadJS / 飞书可能用到的）
        const sheetGetters = ['getActiveSheet', 'getSheet', 'sheet', 'getActiveSheetIndex'];
        let activeSheet = null;
        for (const m of sheetGetters) {
            try {
                if (typeof sp[m] === 'function') {
                    const r = sp[m]();
                    if (r) { activeSheet = r; break; }
                }
                // 也试试当属性
                if (sp[m] && typeof sp[m] === 'object') { activeSheet = sp[m]; break; }
            } catch (e) {}
        }

        // 兜底：sp.sheets[sp._activeSheetIndex]
        if (!activeSheet) {
            try {
                if (sp.sheets && Array.isArray(sp.sheets)) {
                    activeSheet = sp.sheets[sp._activeSheetIndex || 0];
                } else if (sp._sheets) {
                    activeSheet = Object.values(sp._sheets)[sp._activeSheetIndex || 0];
                }
            } catch (e) {}
        }

        if (!activeSheet) return { ok: false, reason: 'no active sheet found', spread_keys: Object.keys(sp) };

        // 提取 sheet 元数据
        const sheetInfo = {
            constructor: activeSheet.constructor && activeSheet.constructor.name,
            keys: Object.keys(activeSheet).slice(0, 50),
            methods: listMethods(activeSheet).filter(x => x.isFunc).slice(0, 80).map(x => x.name),
        };

        // 尝试各种方法获取行/列数
        const rowCountFns = ['getRowCount', 'rowCount', 'getRowsCount', 'getMaxRow'];
        const colCountFns = ['getColumnCount', 'columnCount', 'getColsCount', 'getMaxCol'];
        let rc = null, cc = null;
        for (const m of rowCountFns) {
            try {
                if (typeof activeSheet[m] === 'function') { rc = activeSheet[m](); break; }
                if (typeof activeSheet[m] === 'number') { rc = activeSheet[m]; break; }
            } catch (e) {}
        }
        for (const m of colCountFns) {
            try {
                if (typeof activeSheet[m] === 'function') { cc = activeSheet[m](); break; }
                if (typeof activeSheet[m] === 'number') { cc = activeSheet[m]; break; }
            } catch (e) {}
        }
        sheetInfo.detected_rows = rc;
        sheetInfo.detected_cols = cc;

        // 尝试获取 cell 数据
        const cellGetters = ['getValue', 'getCellValue', 'getCell', 'value'];
        const cells = [];
        // 限额：行 5000（飞书表 1401 行有余），列 100
        const ROW_HARD_LIMIT = 5000;
        const COL_HARD_LIMIT = 100;
        if (rc && cc && rc < 100000 && cc < 500) {
            const rmax = Math.min(rc, ROW_HARD_LIMIT);
            const cmax = Math.min(cc, COL_HARD_LIMIT);
            for (let r = 0; r < rmax; r++) {
                const row = [];
                for (let c = 0; c < cmax; c++) {
                    let val = null;
                    for (const m of cellGetters) {
                        try {
                            if (typeof activeSheet[m] === 'function') {
                                const v = activeSheet[m](r, c);
                                if (v !== undefined && v !== null && v !== '') { val = v; break; }
                            }
                        } catch (e) {}
                    }
                    row.push(val);
                }
                cells.push(row);
            }
            sheetInfo.extracted_rows = rmax;
            sheetInfo.extracted_cols = cmax;
        }

        return { ok: cells.length > 0, sheetInfo, cells: cells.length > 0 ? cells : null };
    }

    try {
        const r = tryExtractFromSpread();
        result.attempts.push({ method: 'spread_api', ...r });
        if (r.ok) result.cells = r.cells;
    } catch (e) {
        result.attempts.push({ method: 'spread_api', ok: false, error: String(e) });
    }

    // === 3. Fallback: 从 DOM 挖（如果飞书有 SEO/无障碍 fallback） ===
    if (!result.cells) {
        try {
            const cells = [];
            // 飞书 sheet 的可访问 DOM 通常用 role="gridcell" 或 .grid-cell
            const cellEls = document.querySelectorAll('[role="gridcell"], .sheet-cell, [class*="cell"]');
            const byRow = {};
            cellEls.forEach(el => {
                const r = el.getAttribute('aria-rowindex') || el.dataset.row || 0;
                const c = el.getAttribute('aria-colindex') || el.dataset.col || 0;
                const txt = (el.innerText || el.textContent || '').trim();
                if (!txt) return;
                if (!byRow[r]) byRow[r] = {};
                byRow[r][c] = txt;
            });
            const sortedRows = Object.keys(byRow).sort((a, b) => +a - +b);
            for (const r of sortedRows) {
                const row = byRow[r];
                const sortedCols = Object.keys(row).sort((a, b) => +a - +b);
                cells.push(sortedCols.map(c => row[c]));
            }
            if (cells.length > 0) {
                result.cells = cells;
                result.attempts.push({ method: 'dom_gridcell', ok: true, rows: cells.length });
            } else {
                result.attempts.push({ method: 'dom_gridcell', ok: false, reason: 'no gridcell found' });
            }
        } catch (e) {
            result.attempts.push({ method: 'dom_gridcell', ok: false, error: String(e) });
        }
    }

    return result;
}
"""


def _profile_has_session() -> bool:
    """检测 .playwright_profile/ 是否包含有效的浏览器会话数据。

    依据：persistent_context 跑过一次后，会写入 Default/Cookies、
    Default/Preferences 等文件。任何一个存在 → 视为已有 session。
    """
    if not PROFILE_DIR.exists():
        return False
    default_dir = PROFILE_DIR / "Default"
    if not default_dir.exists():
        return False
    # 检查至少一个会话相关文件
    for name in ("Cookies", "Preferences", "Network", "Local Storage"):
        if (default_dir / name).exists():
            return True
    # fallback：profile 里有任何文件即可
    return any(PROFILE_DIR.iterdir())


def main():
    ap = argparse.ArgumentParser()
    headed_group = ap.add_mutually_exclusive_group()
    headed_group.add_argument("--headed", action="store_true",
                              help="强制有头模式（默认智能：profile 已存在用 headless，否则用 headed）")
    headed_group.add_argument("--headless", action="store_true",
                              help="强制无头模式（profile 必须已存在，否则会抓不到数据）")
    ap.add_argument("--wait", type=int, default=WAIT_AFTER_LOAD_SEC, help="加载后等待秒数")
    args = ap.parse_args()

    # 智能选择 headless 模式
    profile_ready = _profile_has_session()
    if args.headed:
        headless = False
        print(f"[*] 模式：有头（用户强制 --headed）")
    elif args.headless:
        headless = True
        if not profile_ready:
            print("[!] profile 未初始化但你强制 --headless，可能会因风控/登录问题失败")
        print(f"[*] 模式：无头（用户强制 --headless）")
    else:
        headless = profile_ready
        if profile_ready:
            print(f"[*] 模式：无头（自动 — profile 已就绪 {PROFILE_DIR}）")
        else:
            print(f"[*] 模式：有头（自动 — profile 未初始化，需要可视化首次启动）")
            print(f"[*] 之后再跑会自动切到无头")

    out_dir = RAW_BASE / datetime.now().strftime("extract_%Y%m%d_%H%M%S")
    out_dir.mkdir(parents=True, exist_ok=True)
    print(f"[*] 输出目录: {out_dir}")

    PROFILE_DIR.mkdir(parents=True, exist_ok=True)

    with sync_playwright() as p:
        browser = p.chromium.launch_persistent_context(
            user_data_dir=str(PROFILE_DIR),
            headless=headless,
            viewport={"width": 1440, "height": 900},
            locale="zh-CN",
            timezone_id="Asia/Shanghai",
            # 无头模式下伪装 user-agent，避免飞书识别 HeadlessChrome 后返回不同内容
            user_agent=(
                "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) "
                "AppleWebKit/537.36 (KHTML, like Gecko) "
                "Chrome/147.0.0.0 Safari/537.36"
            ) if headless else None,
            args=[
                "--disable-blink-features=AutomationControlled",
            ],
        )

        page = browser.new_page() if not browser.pages else browser.pages[0]
        print(f"[*] 打开 {SHEET_URL}")
        try:
            page.goto(SHEET_URL, wait_until="commit", timeout=30_000)
        except Exception as e:
            print(f"[!] goto 异常（可忽略）: {e}")

        print(f"[*] 等待 {args.wait}s 让飞书表格充分加载...")
        time.sleep(args.wait)

        # 滚动到底触发懒加载：用 keyboard PageDown 反复按，直到 detected_rows 不再增长
        # 飞书表格内部用 SpreadJS，需要焦点在表格内才能触发 PageDown
        try:
            # 先点一下表格区域获取焦点
            try:
                page.mouse.click(720, 450)
                time.sleep(0.3)
            except Exception:
                pass

            last_rows = -1
            stable = 0
            for i in range(80):  # 最多滚 80 次（1401 行需要约 30 屏）
                page.keyboard.press("PageDown")
                time.sleep(0.25)
                # 每滚 10 次去问一次 spread 当前 rowCount
                if i % 10 == 9:
                    try:
                        cur_rows = page.evaluate("""
                            () => {
                                try {
                                    const sp = window.spread;
                                    if (!sp) return -1;
                                    let s = (sp.getActiveSheet && sp.getActiveSheet()) || (sp.sheets && sp.sheets[0]);
                                    if (!s) return -1;
                                    if (typeof s.getRowCount === 'function') return s.getRowCount();
                                    if (typeof s.rowCount === 'number') return s.rowCount;
                                    if (typeof s.getRowCount === 'number') return s.getRowCount;
                                    return -2;
                                } catch (e) { return -3; }
                            }
                        """)
                        print(f"  [scroll {i+1}] sheet rowCount = {cur_rows}")
                        if cur_rows > 0 and cur_rows == last_rows:
                            stable += 1
                            if stable >= 2:
                                print(f"  [scroll] rowCount 稳定在 {cur_rows}，停止滚动")
                                break
                        else:
                            stable = 0
                        if cur_rows > 0:
                            last_rows = cur_rows
                    except Exception as e:
                        print(f"  [scroll {i+1}] rowCount probe failed: {e}")

            # 滚回顶部以便后面提取
            page.keyboard.press("Control+Home")
            time.sleep(2)
        except Exception as e:
            print(f"[!] 滚动触发懒加载异常: {e}")

        # 截图 + DOM 备份
        try:
            page.screenshot(path=str(out_dir / "screenshot.png"), full_page=True)
        except Exception as e:
            print(f"[warn] 截图失败: {e}")
        try:
            (out_dir / "dom.html").write_text(page.content())
        except Exception as e:
            print(f"[warn] DOM dump 失败: {e}")

        print("[*] 在浏览器里执行提取 JS...")
        try:
            result = page.evaluate(EXTRACT_JS)
        except Exception as e:
            print(f"[!] evaluate 失败: {e}")
            result = {"error": str(e)}

        # 保存全部结果
        (out_dir / "extract_result.json").write_text(
            json.dumps(result, ensure_ascii=False, indent=2, default=str)
        )

        # 如果拿到 cells，单独输出 CSV 方便看
        cells = result.get("cells") if isinstance(result, dict) else None
        if cells:
            import csv
            with (out_dir / "cells.csv").open("w", newline="") as f:
                w = csv.writer(f)
                for row in cells:
                    w.writerow([str(c) if c is not None else "" for c in row])
            print(f"\n✅ 提取成功！cells: {len(cells)} 行 × {len(cells[0]) if cells else 0} 列")
            print(f"   CSV 文件: {out_dir / 'cells.csv'}")
            print(f"   前 3 行预览：")
            for row in cells[:3]:
                print("   ", row[:6], "...")
        else:
            print(f"\n⚠️  没拿到 cells，请看 {out_dir / 'extract_result.json'} 里的 attempts")
            attempts = result.get("attempts", []) if isinstance(result, dict) else []
            for a in attempts:
                print(f"   - {a.get('method')}: ok={a.get('ok')} reason={a.get('reason') or a.get('error') or ''}")

        # 有头模式时浏览器保留几秒方便观察
        if not headless:
            print("\n浏览器保留 15s 给你看一眼 ...")
            time.sleep(15)

        browser.close()


if __name__ == "__main__":
    try:
        main()
    except KeyboardInterrupt:
        sys.exit(0)
