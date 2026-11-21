"""不重新抓网络，只用最新的 filters 规则重新计算 matches_target / is_remote / role_tier。"""

from __future__ import annotations

import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))
from filters import apply_job_flags  # noqa: E402
from storage import get_conn, init_db  # noqa: E402


def run() -> None:
    init_db()
    with get_conn() as conn:
        rows = conn.execute(
            "SELECT id, title, description_text, location, workplace_type FROM jobs"
        ).fetchall()
        print(f"Recomputing flags for {len(rows)} jobs...")
        upd = 0
        for r in rows:
            job = {
                "title": r["title"] or "",
                "description_text": r["description_text"] or "",
                "location": r["location"],
                "workplace_type": r["workplace_type"],
            }
            apply_job_flags(job)
            conn.execute(
                "UPDATE jobs SET matches_target=?, is_remote=?, role_tier=? WHERE id=?",
                (job["matches_target"], job["is_remote"], job["role_tier"], r["id"]),
            )
            upd += 1
        print(f"Updated {upd} rows.")

        primary = conn.execute(
            "SELECT COUNT(*) FROM jobs WHERE matches_target=1 AND role_tier='primary'"
        ).fetchone()[0]
        print(f"  primary tier jobs: {primary}")

        for row in conn.execute(
            "SELECT c.display_name, "
            "  COUNT(j.id) AS total, "
            "  SUM(CASE WHEN j.matches_target=1 THEN 1 ELSE 0 END) AS target, "
            "  SUM(CASE WHEN j.role_tier='primary' THEN 1 ELSE 0 END) AS primary_n "
            "FROM companies c LEFT JOIN jobs j ON j.company_slug=c.slug "
            "GROUP BY c.slug ORDER BY c.main_line, c.display_name"
        ).fetchall():
            print(
                f"  {row['display_name']:20s} total={row['total']:>4} "
                f"target={row['target']:>3} primary={row['primary_n']:>3}"
            )


if __name__ == "__main__":
    run()
