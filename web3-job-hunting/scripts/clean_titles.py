"""一次性清理 DB 中已有 title 的 web3.career 噪声前缀。"""

from __future__ import annotations

import re
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))
from filters import apply_job_flags  # noqa: E402
from storage import get_conn  # noqa: E402

PREFIX_RE = re.compile(r"^[A-Za-z0-9.\- ]+is hiring an?\s*")


def clean_title(t: str) -> str:
    if not t:
        return t
    out = PREFIX_RE.sub("", t).strip()
    # "aBlockchain" → "Blockchain"
    out = re.sub(r"^a([A-Z])", r"\1", out)
    return out or t


def run() -> None:
    with get_conn() as conn:
        rows = conn.execute(
            "SELECT id, title, description_text, location, workplace_type FROM jobs"
        ).fetchall()
        upd = 0
        for r in rows:
            new_title = clean_title(r["title"])
            if new_title != r["title"]:
                upd += 1
                conn.execute(
                    "UPDATE jobs SET title=? WHERE id=?",
                    (new_title, r["id"]),
                )
        print(f"Cleaned {upd} titles.")
        # 重跑 flag
        rows = conn.execute(
            "SELECT id, title, description_text, location, workplace_type FROM jobs"
        ).fetchall()
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
        print("Recomputed flags.")
        for row in conn.execute(
            "SELECT c.display_name, "
            "  COUNT(j.id) AS total, "
            "  SUM(CASE WHEN j.matches_target=1 THEN 1 ELSE 0 END) AS target "
            "FROM companies c LEFT JOIN jobs j ON j.company_slug=c.slug "
            "GROUP BY c.slug ORDER BY c.main_line, c.display_name"
        ).fetchall():
            print(f"  {row['display_name']:20s} total={row['total']:>4} target={row['target']:>3}")


if __name__ == "__main__":
    run()
