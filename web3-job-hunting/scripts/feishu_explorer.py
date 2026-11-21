"""飞书表格探查脚本（Phase 1）

功能：
- 持久化登录态：首次扫码后，cookie/localStorage 自动保存到 .playwright_profile/
- 多渠道 dump：XHR/Fetch 响应、DOM 快照、完整截图、localStorage
- 输出到 data/raw/feishu/<timestamp>/，方便后续分析

使用：
    # 首次跑：会弹出有头浏览器，请扫码登录
    python scripts/feishu_explorer.py

    # 之后跑：自动复用登录态，无需扫码
    python scripts/feishu_explorer.py

参数（可改顶部 SHEET_URL）：
    SHEET_URL = "https://my.feishu.cn/sheets/ScdYsiuRMhTjzFt0rdXcCyshnom"

后续：
    跑完后看 data/raw/feishu/<timestamp>/ 下生成的文件，挑出含数据的
    XHR 响应（一般是 .json 文件），告知正式解析脚本如何对应字段。
"""

from __future__ import annotations

import json
import re
import sys
import time
from datetime import datetime
from pathlib import Path
from urllib.parse import urlparse

from playwright.sync_api import Response, sync_playwright

# ============== 配置 ==============
SHEET_URL = "https://my.feishu.cn/sheets/ScdYsiuRMhTjzFt0rdXcCyshnom"

PROJECT_ROOT = Path(__file__).resolve().parent.parent
PROFILE_DIR = PROJECT_ROOT / ".playwright_profile"
RAW_BASE = PROJECT_ROOT / "data" / "raw" / "feishu"

# 飞书 sheet 数据相关接口的 URL 关键词（根据经验，会持续补充）
SHEET_API_PATTERNS = [
    r"/sheet/",
    r"/sheets-api/",
    r"/api/.*sheet",
    r"/api/.*spreadsheet",
    r"/space/api/",
    r"/suite/sheet/",
    r"/openapi/.*sheet",
]
SHEET_API_RE = re.compile("|".join(SHEET_API_PATTERNS), re.IGNORECASE)

# 抓取等待时长（飞书 sheet 加载较慢）
WAIT_AFTER_LOAD_SEC = 25

# ============== 工具 ==============


def now_tag() -> str:
    return datetime.now().strftime("%Y%m%d_%H%M%S")


def safe_filename(s: str, max_len: int = 80) -> str:
    s = re.sub(r"[^A-Za-z0-9_.-]", "_", s)
    return s[:max_len] or "_"


def is_sheet_api(url: str) -> bool:
    return bool(SHEET_API_RE.search(url))


# ============== 主流程 ==============


def main():
    out_dir = RAW_BASE / now_tag()
    out_dir.mkdir(parents=True, exist_ok=True)
    xhr_dir = out_dir / "xhr"
    xhr_dir.mkdir(exist_ok=True)
    print(f"[*] dump 目录: {out_dir}")

    PROFILE_DIR.mkdir(parents=True, exist_ok=True)
    profile_first = not any(PROFILE_DIR.iterdir())
    if profile_first:
        print("[!] 检测到首次运行，将启动有头浏览器，请在弹出窗口里扫码登录飞书")
    else:
        print("[*] 检测到已有登录态，复用 profile")

    captured: list[dict] = []

    def on_response(resp: Response):
        url = resp.url
        if not is_sheet_api(url):
            return
        try:
            ctype = (resp.headers or {}).get("content-type", "")
            body_text = None
            body_json = None
            if "json" in ctype.lower():
                try:
                    body_json = resp.json()
                except Exception:
                    pass
            if body_json is None:
                try:
                    body_text = resp.text()
                except Exception:
                    body_text = None

            captured.append(
                {
                    "url": url,
                    "status": resp.status,
                    "content_type": ctype,
                    "method": resp.request.method,
                    "post_data": resp.request.post_data,
                    "has_json": body_json is not None,
                    "body_text_len": len(body_text) if body_text else 0,
                }
            )

            # 落盘
            path = urlparse(url).path
            fname = safe_filename(f"{resp.status}_{path.replace('/', '_')}_{len(captured):04d}")
            if body_json is not None:
                (xhr_dir / f"{fname}.json").write_text(
                    json.dumps(body_json, ensure_ascii=False, indent=2)
                )
            elif body_text:
                (xhr_dir / f"{fname}.txt").write_text(body_text)
            print(f"  [XHR] {resp.status} {url[:100]}")
        except Exception as e:
            print(f"  [warn] 抓 response 失败: {e}")

    with sync_playwright() as p:
        browser = p.chromium.launch_persistent_context(
            user_data_dir=str(PROFILE_DIR),
            headless=False,
            accept_downloads=True,
            viewport={"width": 1440, "height": 900},
            locale="zh-CN",
            timezone_id="Asia/Shanghai",
            # 一些 stealth 措施，避免被识别为爬虫
            args=[
                "--disable-blink-features=AutomationControlled",
                "--disable-features=IsolateOrigins,site-per-process",
            ],
        )

        page = browser.new_page() if not browser.pages else browser.pages[0]
        page.on("response", on_response)

        print(f"[*] 打开飞书表格: {SHEET_URL}")
        try:
            # 用 commit（只等导航命令发出，不等加载完成）
            # 飞书 SPA + 长连接，wait_until=load 永远不会触发
            page.goto(SHEET_URL, wait_until="commit", timeout=30_000)
        except Exception as e:
            print(f"[!] 打开页面有点慢（可忽略，请看浏览器窗口是否已打开）: {e}")
            print("[!] 如果浏览器空白，请手动在地址栏粘贴 URL 并按回车：")
            print(f"    {SHEET_URL}")

        # 不管首次还是二次，都让用户确认页面已经加载好（更稳）
        print("\n" + "=" * 60)
        if profile_first:
            print("⚠️  首次运行：请在浏览器里完成扫码登录")
        else:
            print("⚠️  请确认浏览器里已经看到表格内容（非空白页）")
        print("⚠️  如果浏览器卡在白屏 → 在地址栏按 ⌘+R 刷新一次")
        print("⚠️  确认表格内容已显示后，回这里按【回车】继续抓取...")
        print("=" * 60)
        input()

        print(f"[*] 等待 {WAIT_AFTER_LOAD_SEC}s 让表格充分加载（含虚拟滚动数据）...")
        time.sleep(5)

        # 滚动一遍触发懒加载
        try:
            for i in range(8):
                page.mouse.wheel(0, 1000)
                time.sleep(0.8)
                page.mouse.wheel(0, 800)
                time.sleep(0.8)
            # 滚回顶部
            page.keyboard.press("Control+Home")
            time.sleep(2)
        except Exception as e:
            print(f"[warn] 滚动出错（可能页面还没准备好）: {e}")

        # 再等一会让最后一波 XHR 完成
        time.sleep(WAIT_AFTER_LOAD_SEC - 5)

        # ===== Dump =====
        print("[*] 截图 + DOM + localStorage")
        try:
            page.screenshot(path=str(out_dir / "screenshot_full.png"), full_page=True)
        except Exception as e:
            print(f"  [warn] 截图失败: {e}")

        try:
            html = page.content()
            (out_dir / "dom.html").write_text(html)
        except Exception as e:
            print(f"  [warn] DOM dump 失败: {e}")

        try:
            local_storage = page.evaluate(
                """() => {
                    const out = {};
                    for (let i = 0; i < localStorage.length; i++) {
                        const k = localStorage.key(i);
                        out[k] = localStorage.getItem(k);
                    }
                    return out;
                }"""
            )
            (out_dir / "localStorage.json").write_text(
                json.dumps(local_storage, ensure_ascii=False, indent=2)
            )
        except Exception as e:
            print(f"  [warn] localStorage dump 失败: {e}")

        # 尝试抓页面里的全局 sheet 数据（有时候飞书把数据挂在 window 上）
        try:
            sniff = page.evaluate(
                """() => {
                    const out = {};
                    for (const k of Object.keys(window)) {
                        try {
                            const v = window[k];
                            if (typeof v === 'object' && v !== null) {
                                const keys = Object.keys(v).slice(0, 5);
                                out[k] = { type: typeof v, sample_keys: keys };
                            }
                        } catch (e) {}
                    }
                    return out;
                }"""
            )
            (out_dir / "window_sniff.json").write_text(
                json.dumps(sniff, ensure_ascii=False, indent=2)
            )
        except Exception as e:
            print(f"  [warn] window sniff 失败: {e}")

        # 抓表格可见区域的 textContent
        try:
            sheet_text = page.evaluate(
                """() => {
                    const candidates = [
                        document.querySelector('.sheet-container'),
                        document.querySelector('[class*="sheet"]'),
                        document.body
                    ];
                    for (const c of candidates) {
                        if (c) return c.innerText || c.textContent || '';
                    }
                    return '';
                }"""
            )
            (out_dir / "visible_text.txt").write_text(sheet_text)
        except Exception as e:
            print(f"  [warn] 可见文本 dump 失败: {e}")

        # XHR 汇总
        (out_dir / "xhr_summary.json").write_text(
            json.dumps(captured, ensure_ascii=False, indent=2)
        )

        print("\n" + "=" * 60)
        print(f"✅  抓取完成：")
        print(f"    XHR 数：{len(captured)}")
        print(f"    输出目录：{out_dir}")
        print(f"    关键文件：")
        print(f"      - xhr/*.json         ← 飞书后端 API 响应（找数据用这个）")
        print(f"      - screenshot_full.png ← 看页面长啥样")
        print(f"      - visible_text.txt   ← 表格可见文本")
        print(f"      - window_sniff.json  ← window 全局对象探查")
        print("=" * 60)

        print("\n[?] 浏览器保持打开 30 秒，方便你再操作（如手动滚动看更多）")
        try:
            time.sleep(30)
        except KeyboardInterrupt:
            print("[*] 收到 Ctrl+C，提前关闭浏览器")

        browser.close()


if __name__ == "__main__":
    try:
        main()
    except KeyboardInterrupt:
        print("\n[*] 用户中断")
        sys.exit(0)
