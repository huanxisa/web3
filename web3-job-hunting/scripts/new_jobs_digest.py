"""生成按日期的「最新主投岗位」摘要。

输出：reports/digest/new_jobs_YYYYMMDD.md

每次 update.py 跑完后调用，只收录：
- role_tier = primary（后端/高级后端/智能合约/高级智能合约）
- 发布时间 ≤ NEW_JOB_DAYS（默认 30 天），或本次 diff 新增

这是日常协作的主阅读文档；完整 JD 仍见 reports/jd_summary.md。
"""

from __future__ import annotations

import sys
from datetime import datetime, timezone
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))
from reporter import freshness, parse_posted_at  # noqa: E402
from storage import get_conn, init_db  # noqa: E402

DIGEST_DIR = Path(__file__).resolve().parent.parent / "reports" / "digest"
NEW_JOB_DAYS = 30
LATEST_LINK = DIGEST_DIR / "LATEST.md"


def _job_row(j: dict, companies: dict, *, is_new: bool = False) -> str:
    dt = parse_posted_at(j.get("posted_at"))
    emoji, fresh_text = freshness(dt)
    date_s = dt.strftime("%Y-%m-%d") if dt else "未知"
    company = companies.get(j["company_slug"], {}).get("display_name", j["company_slug"])
    title = (j.get("title_zh") or j.get("title") or "").strip().replace("|", "/")
    langs = (j.get("work_languages") or "-").replace(",", " / ")
    src = j.get("source") or "ats"
    new_mark = "🆕 " if is_new else ""
    return (
        f"| {new_mark}{emoji} | {company} | {title} | {langs} | {date_s} | {src} | "
        f"<{j.get('apply_url', '-')}> |"
    )


def fetch_primary_recent(days: int = NEW_JOB_DAYS) -> list[dict]:
    with get_conn() as conn:
        rows = conn.execute(
            """
            SELECT j.*, c.display_name, c.main_line
            FROM jobs j
            JOIN companies c ON c.slug = j.company_slug
            WHERE j.matches_target = 1 AND j.role_tier = 'primary'
            ORDER BY j.posted_at DESC
            """
        ).fetchall()
    out = []
    now = datetime.now(timezone.utc)
    for r in rows:
        j = dict(r)
        dt = parse_posted_at(j.get("posted_at"))
        if dt and (now - dt).days <= days:
            out.append(j)
    out.sort(
        key=lambda x: parse_posted_at(x.get("posted_at"))
        or datetime.min.replace(tzinfo=timezone.utc),
        reverse=True,
    )
    return out


def fetch_jobs_by_keys(keys: set[tuple[str, str]]) -> list[dict]:
    if not keys:
        return []
    with get_conn() as conn:
        rows = conn.execute(
            """
            SELECT j.*, c.display_name, c.main_line
            FROM jobs j
            JOIN companies c ON c.slug = j.company_slug
            WHERE j.matches_target = 1 AND j.role_tier = 'primary'
            """
        ).fetchall()
    key_set = set(keys)
    return [dict(r) for r in rows if (r["company_slug"], r["external_id"]) in key_set]


def write_digest(
    *,
    new_keys: set[tuple[str, str]] | None = None,
    days: int = NEW_JOB_DAYS,
) -> Path:
    init_db()
    new_keys = new_keys or set()
    ts = datetime.now()
    path = DIGEST_DIR / f"new_jobs_{ts.strftime('%Y%m%d')}.md"

    with get_conn() as conn:
        companies = {
            r["slug"]: dict(r)
            for r in conn.execute("SELECT * FROM companies").fetchall()
        }

    recent = fetch_primary_recent(days)
    new_primary = fetch_jobs_by_keys(new_keys)
    new_ids = {(j["company_slug"], j["external_id"]) for j in new_primary}

    lines = [
        f"# Web3 主投岗位日报 — {ts.strftime('%Y-%m-%d')}\n",
        f"> 生成时间：{ts.strftime('%Y-%m-%d %H:%M:%S')}\n",
        "> **收录标准**：后端工程师 / 高级后端 / 智能合约 / 高级智能合约（`role_tier=primary`）\n",
        f"> **时间窗口**：近 **{days}** 天内发布；架构师 / 中间件 / Infra / Staff·Principal 等已排除\n",
        "> 完整 JD 归档见 [`reports/jd_summary.md`](../jd_summary.md)\n",
        "",
        "## 一、本次更新新增（主投方向）\n",
    ]

    if new_primary:
        lines.append(f"> 共 **{len(new_primary)}** 个\n")
        lines.append("| 新鲜度 | 公司 | 岗位 | 语言 | 发布日期 | 来源 | 链接 |")
        lines.append("|---|---|---|---|---|---|---|")
        new_primary.sort(
            key=lambda x: parse_posted_at(x.get("posted_at"))
            or datetime.min.replace(tzinfo=timezone.utc),
            reverse=True,
        )
        for j in new_primary:
            lines.append(_job_row(j, companies, is_new=True))
    else:
        lines.append("> 本次更新无新增主投方向岗位。\n")

    lines.append(f"\n## 二、近 {days} 天发布 — 主投方向全清单\n")
    lines.append(f"> 共 **{len(recent)}** 个（含本次新增）。按发布日期倒序。\n")
    if recent:
        lines.append("| 标记 | 公司 | 岗位 | 语言 | 发布日期 | 来源 | 链接 |")
        lines.append("|---|---|---|---|---|---|---|")
        for j in recent:
            is_new = (j["company_slug"], j["external_id"]) in new_ids
            lines.append(_job_row(j, companies, is_new=is_new))
    else:
        lines.append("> （当前窗口内无主投方向岗位，可调大 `NEW_JOB_DAYS` 或等下次抓取）\n")

    lines.append("\n---\n")
    lines.append("## 三、使用说明\n")
    lines.append("1. **日常只看本文件 + 第一节**；需要完整 JD 时再打开 `jd_summary.md`。")
    lines.append("2. 🆕 = 本次 `update.py` 新入库；🟢🟡 = 发布新鲜度。")
    lines.append("3. 飞书内推按 `#行号` 找分享人；Telegram 点链接看原帖联系方式。\n")

    content = "\n".join(lines)
    DIGEST_DIR.mkdir(parents=True, exist_ok=True)
    path.write_text(content, encoding="utf-8")
    LATEST_LINK.write_text(content, encoding="utf-8")
    return path


def run(new_keys: set[tuple[str, str]] | None = None) -> Path:
    path = write_digest(new_keys=new_keys)
    recent_n = len(fetch_primary_recent())
    new_n = len(fetch_jobs_by_keys(new_keys or set()))
    print(f"\nDigest written: {path}")
    print(f"  LATEST: {LATEST_LINK}")
    print(f"  primary recent ({NEW_JOB_DAYS}d): {recent_n} | new this run: {new_n}")
    return path


if __name__ == "__main__":
    run()
