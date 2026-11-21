"""一键增量更新：

1. 在抓取前记录现有岗位 (company_slug, external_id) 快照
2. 调用 fetcher 重新抓取 15 家公司的最新岗位（自动跟随 fetcher.COMPANIES 的变更）
3. 对比快照，输出 diff：
   - 新增岗位（NEW）
   - 已下架岗位（CLOSED，本次抓取没出现的）
   - 标题被改的（CHANGED）
4. 标记已下架岗位（在 DB 里把 matches_target 设为 0，避免出现在报告里）
5. 调用 translator 翻译新增的目标岗位
6. 调用 reporter 重新生成中文报告
7. 输出本次更新摘要

用法：
    python scripts/update.py
"""

from __future__ import annotations

import sys
import time
from datetime import datetime
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))
from storage import get_conn, init_db  # noqa: E402

# 防止循环导入：fetcher / translator / reporter 在用到时再 import
import fetcher as fetcher_mod  # noqa: E402
import reporter as reporter_mod  # noqa: E402
import translator as translator_mod  # noqa: E402
import feishu_sync as feishu_sync_mod  # noqa: E402
import telegram_fetcher as tg_mod  # noqa: E402
import web3career_search as w3c_search_mod  # noqa: E402
import github_hiring as gh_mod  # noqa: E402
import new_jobs_digest as digest_mod  # noqa: E402

REPORTS_DIR = Path(__file__).resolve().parent.parent / "reports"
FEISHU_RAW = Path(__file__).resolve().parent.parent / "data" / "raw" / "feishu"


def snapshot_jobs() -> dict[tuple[str, str], dict]:
    """快照当前所有岗位：key=(company_slug, external_id)，value={title, matches_target, work_languages}"""
    with get_conn() as conn:
        rows = conn.execute(
            "SELECT company_slug, external_id, title, matches_target, work_languages, role_tier FROM jobs"
        ).fetchall()
    return {
        (r["company_slug"], r["external_id"]): dict(
            title=r["title"],
            matches_target=r["matches_target"],
            work_languages=r["work_languages"],
            role_tier=r["role_tier"],
        )
        for r in rows
    }


def mark_closed(closed_keys: set[tuple[str, str]]) -> None:
    """对已下架的岗位：matches_target 置 0（这样报告里不会出现，但数据保留）。

    注意：跳过虚拟数据源（telegram / web3.career 关键词搜 / 飞书内推），
    因为这些数据源每次抓取窗口有限，"老消息"不是真的"下架"。
    """
    if not closed_keys:
        return
    with get_conn() as conn:
        for slug, ext_id in closed_keys:
            # 虚拟数据源：抓取窗口有限，不视为下架
            if slug.startswith(("_tg_", "_w3c_", "_gh_")) or slug == "feishu":
                continue
            conn.execute(
                "UPDATE jobs SET matches_target=0 WHERE company_slug=? AND external_id=?",
                (slug, ext_id),
            )


def _norm_title(t: str | None) -> str:
    """归一化 title：去除首尾空白与连续空格，避免误判为变更。"""
    if not t:
        return ""
    return " ".join(t.split())


def compute_diff(before: dict, after: dict) -> dict:
    """对比快照，返回 diff dict。"""
    before_keys = set(before.keys())
    after_keys = set(after.keys())
    new_keys = after_keys - before_keys
    closed_keys = before_keys - after_keys
    common_keys = before_keys & after_keys
    changed_keys = {
        k for k in common_keys
        if _norm_title(before[k]["title"]) != _norm_title(after[k]["title"])
    }
    return dict(new=new_keys, closed=closed_keys, changed=changed_keys)


def _format_diff_line(slug: str, info: dict, conn) -> str:
    company = conn.execute(
        "SELECT display_name FROM companies WHERE slug=?", (slug,)
    ).fetchone()
    company_name = company["display_name"] if company else slug
    target_mark = " 🎯" if info.get("matches_target") else ""
    tier = info.get("role_tier") or ""
    tier_part = f" [{tier}]" if tier and tier != "skip" else ""
    lang = info.get("work_languages") or ""
    lang_part = f"  [{lang}]" if lang else ""
    return f"{company_name:15s} | {info['title']}{target_mark}{tier_part}{lang_part}"


def print_diff_section(title: str, keys: set, source: dict) -> None:
    print(f"\n  {title}: {len(keys)}")
    if not keys:
        return
    with get_conn() as conn:
        for k in sorted(keys):
            slug, _ = k
            info = source[k]
            print(f"    - {_format_diff_line(slug, info, conn)}")


def write_diff_log(diff: dict, before: dict, after: dict) -> Path:
    """把本次 diff 持久化到 reports/diff_YYYYMMDD_HHMM.md"""
    REPORTS_DIR.mkdir(parents=True, exist_ok=True)
    ts = datetime.now().strftime("%Y%m%d_%H%M")
    path = REPORTS_DIR / f"diff_{ts}.md"
    lines = []
    lines.append(f"# JD 增量更新 diff — {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}\n")
    lines.append(f"- 新增（NEW）：{len(diff['new'])}")
    new_target = sum(1 for k in diff['new'] if after[k].get('matches_target'))
    lines.append(f"  - 其中目标方向：**{new_target}**")
    lines.append(f"- 已下架（CLOSED）：{len(diff['closed'])}")
    lines.append(f"- 标题变更（CHANGED）：{len(diff['changed'])}\n")

    with get_conn() as conn:
        if diff["new"]:
            lines.append("## 🆕 新增岗位\n")
            for k in sorted(diff["new"]):
                slug, _ = k
                lines.append(f"- {_format_diff_line(slug, after[k], conn)}")
            lines.append("")
        if diff["closed"]:
            lines.append("## ❌ 已下架岗位（matches_target 已置 0）\n")
            for k in sorted(diff["closed"]):
                slug, _ = k
                lines.append(f"- {_format_diff_line(slug, before[k], conn)}")
            lines.append("")
        if diff["changed"]:
            lines.append("## 📝 标题变更\n")
            for k in sorted(diff["changed"]):
                slug, _ = k
                lines.append(
                    f"- {_format_diff_line(slug, after[k], conn)}\n"
                    f"  - 旧标题：{before[k]['title']}"
                )
            lines.append("")

    path.write_text("\n".join(lines), encoding="utf-8")
    return path


def run() -> None:
    init_db()
    print("=" * 70)
    print("Web3 求职 — 一键增量更新")
    print("=" * 70)

    # Step 1: 快照
    print("\n[1/6] 记录当前数据库快照...")
    before = snapshot_jobs()
    print(f"  当前库里有 {len(before)} 个岗位")

    # Step 2: 抓取（ATS + 飞书内推）
    print("\n[2/6] 抓取 ATS 平台最新岗位...")
    t0 = time.time()
    fetcher_mod.run()
    print(f"  抓取耗时 {time.time()-t0:.1f}s")

    # Step 2b: 同步飞书内推（增量模式：只插入新行，已存在的不动）
    latest_csvs = sorted(FEISHU_RAW.glob("extract_*/cells.csv"))
    if latest_csvs:
        print(f"\n[2b/6] 同步飞书内推岗位池 [增量模式]（最新 CSV: {latest_csvs[-1].parent.name}）...")
        try:
            feishu_stats = feishu_sync_mod.run(only_new=True)
            print(
                f"  飞书内推：CSV 解析 {feishu_stats['parsed']} 行，"
                f"新增 {feishu_stats['new_added']}（其中命中 {feishu_stats['new_matched']}），"
                f"跳过已有 {feishu_stats['skipped']}"
            )
        except Exception as e:
            print(f"  [warn] 飞书同步失败: {e}")
    else:
        print(
            "\n[2b/6] 没找到飞书 CSV，跳过\n"
            "  如要更新内推数据，先跑：\n"
            "    PLAYWRIGHT_BROWSERS_PATH=/Users/piliepeng/.cache/ms-playwright \\\n"
            "      python scripts/feishu_extract.py   # 默认 headless（profile 已就绪时）"
        )

    # Step 2c: Telegram 公开频道
    print("\n[2c/6] 抓取 Telegram 公开频道...")
    try:
        tg_stats = tg_mod.run()
        print(
            f"  Telegram：抓 {tg_stats['total']} 个，命中 {tg_stats['target']}，"
            f"新增 {tg_stats['new_added']}，更新 {tg_stats['updated']}"
        )
    except Exception as e:
        print(f"  [warn] Telegram 抓取失败: {e}")

    # Step 2d: web3.career 关键词搜
    print("\n[2d/6] 抓取 web3.career 关键词全站搜...")
    try:
        w3c_stats = w3c_search_mod.run()
        print(
            f"  关键词搜：抓 {w3c_stats['total']} 个，命中 {w3c_stats['target']}，"
            f"新增 {w3c_stats['new_added']}，更新 {w3c_stats['updated']}"
        )
    except Exception as e:
        print(f"  [warn] web3.career 关键词搜失败: {e}")

    # Step 2e: GitHub 招聘 issue 仓库
    print("\n[2e/6] 抓取 GitHub 招聘 issue 仓库...")
    try:
        gh_stats = gh_mod.run()
        print(
            f"  GitHub：抓 {gh_stats['total']} 个 issue，命中 {gh_stats['target']}，"
            f"新增 {gh_stats['new_added']}，更新 {gh_stats['updated']}"
        )
    except Exception as e:
        print(f"  [warn] GitHub 招聘抓取失败: {e}")

    # Step 3: diff
    print("\n[3/6] 对比新旧数据，计算 diff...")
    after = snapshot_jobs()
    diff = compute_diff(before, after)
    print_diff_section("🆕 新增岗位", diff["new"], after)
    print_diff_section("📝 标题变更", diff["changed"], after)
    print_diff_section("❌ 已下架岗位（matches_target 已置 0）", diff["closed"], before)

    # Step 4: 标记已下架（避免出现在报告里）+ 落档 diff
    if diff["closed"]:
        mark_closed(diff["closed"])
        print(f"\n  已把 {len(diff['closed'])} 个下架岗位的 matches_target 置 0")
    diff_path = write_diff_log(diff, before, after)
    print(f"\n  diff 已落档：{diff_path}")

    # Step 5: 翻译所有未翻译的目标岗位（不仅是新增）
    # 用户硬要求："没有提供给我完整的中文 jd，请修正这一点，后续的更新都需要这一点"
    # 之前的"无新增就跳过"会让历史失败的翻译永远留空 → 改成无条件跑
    print("\n[4/6] 翻译目标岗位（含历史未翻译的）...")
    new_target_count = sum(1 for k in diff["new"] if after[k].get("matches_target"))
    translated = translator_mod.run()
    if translated == 0:
        print("  全部目标岗位都已是中文，无需翻译")
    else:
        print(f"  翻译完成：{translated} 个岗位（其中本次新增 {new_target_count} 个）")

    # Step 6: 重新生成报告
    print("\n[5/6] 重新生成中文报告...")
    reporter_mod.run()

    # Step 7: 生成按日期的主投岗位摘要
    print("\n[6/6] 生成主投岗位日报 digest...")
    new_primary = sum(
        1 for k in diff["new"]
        if after[k].get("matches_target") and after[k].get("role_tier") == "primary"
    )
    digest_path = digest_mod.run(new_keys=diff["new"])

    # 摘要
    print("\n" + "=" * 70)
    print("✅ 更新完成")
    print("=" * 70)
    print(f"  新增： {len(diff['new']):>3}（其中目标岗位 {new_target_count} 个）")
    print(f"  下架： {len(diff['closed']):>3}")
    print(f"  改动： {len(diff['changed']):>3}")
    print(f"  当前总数： {len(after)} 个岗位")
    target_now = sum(1 for v in after.values() if v.get("matches_target"))
    # 注意 matches_target 在 mark_closed 后会变化，重新取
    with get_conn() as conn:
        target_now = conn.execute(
            "SELECT COUNT(*) FROM jobs WHERE matches_target=1"
        ).fetchone()[0]
    print(f"  当前目标岗位：{target_now} 个")
    with get_conn() as conn:
        primary_now = conn.execute(
            "SELECT COUNT(*) FROM jobs WHERE matches_target=1 AND role_tier='primary'"
        ).fetchone()[0]
    print(f"  其中主投 primary：{primary_now} 个（本次新增 primary {new_primary} 个）")
    print(f"\n  日常阅读：open reports/digest/LATEST.md")
    print(f"  完整归档：open reports/jd_summary.md")


if __name__ == "__main__":
    run()
