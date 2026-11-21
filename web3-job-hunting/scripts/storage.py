"""SQLite 存储模块：负责 jobs 表的 schema 与 CRUD。

表结构：
- companies: 公司元数据
- jobs:      职位主表（含原文与中文翻译字段）
"""

from __future__ import annotations

import sqlite3
from contextlib import contextmanager
from pathlib import Path
from typing import Iterable

DB_PATH = Path(__file__).resolve().parent.parent / "data" / "jobs.db"

SCHEMA = """
CREATE TABLE IF NOT EXISTS companies (
    slug              TEXT PRIMARY KEY,
    display_name      TEXT NOT NULL,
    main_line         TEXT NOT NULL,        -- 'A' 公链 SDK / 'B' CEX-Wallet 业务合约
    ats_platform      TEXT NOT NULL,        -- greenhouse / lever / ashby / web3career
    ats_handle        TEXT NOT NULL,
    careers_url       TEXT,
    notes             TEXT
);

CREATE TABLE IF NOT EXISTS jobs (
    id                INTEGER PRIMARY KEY AUTOINCREMENT,
    company_slug      TEXT NOT NULL,
    external_id       TEXT NOT NULL,        -- ATS 自带的 id
    title             TEXT NOT NULL,
    title_zh          TEXT,                 -- 中文翻译
    location          TEXT,
    team              TEXT,
    employment_type   TEXT,
    workplace_type    TEXT,                 -- Remote / Hybrid / Onsite
    apply_url         TEXT,
    description       TEXT,                 -- 原始 JD（可能含 HTML 标签）
    description_text  TEXT,                 -- 纯文本 JD（清洗后）
    description_zh    TEXT,                 -- 中文翻译
    compensation      TEXT,
    posted_at         TEXT,
    fetched_at        TEXT DEFAULT (datetime('now')),
    is_remote         INTEGER DEFAULT 0,
    matches_target    INTEGER DEFAULT 0,    -- 是否匹配「后端/合约」目标方向
    role_tier         TEXT DEFAULT 'skip',  -- primary / secondary / skip（职级分层，用于报告排序）
    work_languages    TEXT,                 -- 命中的编程语言 CSV，如 "Java,Solidity"
    source            TEXT DEFAULT 'ats',   -- 数据来源：ats / feishu_referral / linkedin
    referral_id       TEXT,                 -- 内推渠道里的编号（飞书行号 / 群号等）
    UNIQUE(company_slug, external_id),
    FOREIGN KEY(company_slug) REFERENCES companies(slug)
);

CREATE INDEX IF NOT EXISTS idx_jobs_company  ON jobs(company_slug);
CREATE INDEX IF NOT EXISTS idx_jobs_target   ON jobs(matches_target);
CREATE INDEX IF NOT EXISTS idx_jobs_remote   ON jobs(is_remote);
"""


@contextmanager
def get_conn():
    DB_PATH.parent.mkdir(parents=True, exist_ok=True)
    conn = sqlite3.connect(DB_PATH)
    conn.row_factory = sqlite3.Row
    try:
        yield conn
        conn.commit()
    finally:
        conn.close()


def init_db() -> None:
    with get_conn() as conn:
        conn.executescript(SCHEMA)
        _migrate(conn)


def _migrate(conn: sqlite3.Connection) -> None:
    """给已有 jobs 表补充新列（兼容旧 DB）。"""
    cur = conn.execute("PRAGMA table_info(jobs)")
    existing = {row[1] for row in cur.fetchall()}
    if "source" not in existing:
        conn.execute("ALTER TABLE jobs ADD COLUMN source TEXT DEFAULT 'ats'")
    if "referral_id" not in existing:
        conn.execute("ALTER TABLE jobs ADD COLUMN referral_id TEXT")
    if "role_tier" not in existing:
        conn.execute("ALTER TABLE jobs ADD COLUMN role_tier TEXT DEFAULT 'skip'")


def upsert_company(
    slug: str,
    display_name: str,
    main_line: str,
    ats_platform: str,
    ats_handle: str,
    careers_url: str = "",
    notes: str = "",
) -> None:
    with get_conn() as conn:
        conn.execute(
            """
            INSERT INTO companies(slug, display_name, main_line, ats_platform, ats_handle, careers_url, notes)
            VALUES(?,?,?,?,?,?,?)
            ON CONFLICT(slug) DO UPDATE SET
                display_name=excluded.display_name,
                main_line=excluded.main_line,
                ats_platform=excluded.ats_platform,
                ats_handle=excluded.ats_handle,
                careers_url=excluded.careers_url,
                notes=excluded.notes
            """,
            (slug, display_name, main_line, ats_platform, ats_handle, careers_url, notes),
        )


def upsert_job(job: dict) -> None:
    """job 字典必填字段：company_slug, external_id, title, apply_url
    其余可选字段会自动填充 None / 默认值。
    """
    fields = [
        "company_slug",
        "external_id",
        "title",
        "title_zh",
        "location",
        "team",
        "employment_type",
        "workplace_type",
        "apply_url",
        "description",
        "description_text",
        "description_zh",
        "compensation",
        "posted_at",
        "is_remote",
        "matches_target",
        "role_tier",
        "work_languages",
        "source",
        "referral_id",
    ]
    values = [job.get(k) for k in fields]
    placeholders = ",".join(["?"] * len(fields))
    update_clause = ",".join([f"{k}=excluded.{k}" for k in fields if k not in ("company_slug", "external_id")])
    sql = f"""
        INSERT INTO jobs({','.join(fields)}) VALUES({placeholders})
        ON CONFLICT(company_slug, external_id) DO UPDATE SET {update_clause},
            fetched_at = datetime('now')
    """
    with get_conn() as conn:
        conn.execute(sql, values)


def list_jobs_needing_translation() -> list[sqlite3.Row]:
    """返回需要翻译的岗位：英文 JD 但中文字段为空。"""
    with get_conn() as conn:
        cur = conn.execute(
            """
            SELECT id, title, description_text
            FROM jobs
            WHERE matches_target = 1
              AND (
                description_zh IS NULL OR description_zh = ''
                OR title_zh IS NULL OR title_zh = ''
              )
            """
        )
        return list(cur.fetchall())


def update_translation(job_id: int, title_zh: str, description_zh: str) -> None:
    with get_conn() as conn:
        conn.execute(
            "UPDATE jobs SET title_zh=?, description_zh=? WHERE id=?",
            (title_zh, description_zh, job_id),
        )


def fetch_target_jobs(role_tier: str | None = None) -> list[sqlite3.Row]:
    """获取匹配目标岗位；role_tier=primary 时仅主投方向。"""
    with get_conn() as conn:
        sql = """
            SELECT j.*, c.display_name AS company_name, c.main_line, c.careers_url
            FROM jobs j
            JOIN companies c ON c.slug = j.company_slug
            WHERE j.matches_target = 1
        """
        params: tuple = ()
        if role_tier:
            sql += " AND j.role_tier = ?"
            params = (role_tier,)
        sql += " ORDER BY CASE j.role_tier WHEN 'primary' THEN 0 WHEN 'secondary' THEN 1 ELSE 2 END, c.main_line, c.display_name, j.title"
        cur = conn.execute(sql, params)
        return list(cur.fetchall())


def stats() -> dict:
    with get_conn() as conn:
        out = {}
        out["total_companies"] = conn.execute("SELECT COUNT(*) FROM companies").fetchone()[0]
        out["total_jobs"] = conn.execute("SELECT COUNT(*) FROM jobs").fetchone()[0]
        out["target_jobs"] = conn.execute("SELECT COUNT(*) FROM jobs WHERE matches_target = 1").fetchone()[0]
        out["remote_jobs"] = conn.execute("SELECT COUNT(*) FROM jobs WHERE is_remote = 1").fetchone()[0]
        out["per_company"] = {
            row["display_name"]: {"total": row["total"], "target": row["target"]}
            for row in conn.execute(
                """
                SELECT c.display_name,
                       COUNT(j.id) AS total,
                       SUM(CASE WHEN j.matches_target=1 THEN 1 ELSE 0 END) AS target
                FROM companies c
                LEFT JOIN jobs j ON j.company_slug = c.slug
                GROUP BY c.slug
                ORDER BY c.main_line, c.display_name
                """
            ).fetchall()
        }
        return out


if __name__ == "__main__":
    init_db()
    print(f"DB initialized at {DB_PATH}")
