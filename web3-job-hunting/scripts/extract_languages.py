"""从 JD 里抽取「工作语言」并写回 jobs 表。

逻辑：
1. 给 jobs 表加 work_languages 字段（CSV 字符串）
2. 用正则扫 title + description_text，识别命中的编程语言
3. 输出统计：每种语言命中的岗位数 + 你能投的 / 不能投的分类

用户掌握：Java / Python / Golang / Solidity → 这 4 种命中即可投
其他语言：Rust / C++ / TypeScript / Move 等 → 命中说明可能需要补
"""

from __future__ import annotations

import re
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))
from storage import get_conn  # noqa: E402

# 用户掌握的语言（命中即可投）
USER_KNOWN = {"Java", "Python", "Golang", "Solidity"}

# 语言识别正则。键是规范名，值是匹配模式（已加词边界，避免误判）
LANGUAGE_PATTERNS = {
    # 用户已掌握
    "Java": r"\bjava\b(?!\s*script)",      # 排除 JavaScript
    "Python": r"\bpython\b",
    "Golang": r"\bgo(?:lang)?\b|\bgolang\b",
    "Solidity": r"\bsolidity\b",
    # 用户暂未掌握（命中说明要补）
    "Rust": r"\brust\b",
    "C++": r"\bc\+\+\b|\bcpp\b",
    "TypeScript": r"\btypescript\b|\bts\b(?!\s*\w)",
    "JavaScript": r"\bjavascript\b|\bjs\b(?!\s*\w)|\bnode\.?js\b",
    "Move": r"\bmove\b\s+(?:language|lang|smart\s+contract|programming)|\b(?:sui|aptos)\s+move\b|\bmove\s+(?:on\s+sui|on\s+aptos)\b",
    "Vyper": r"\bvyper\b",
    "Cairo": r"\bcairo\b",
    "Kotlin": r"\bkotlin\b",
    "Scala": r"\bscala\b",
    "Swift": r"\bswift\b",
    "Ruby": r"\bruby\b",
    "Haskell": r"\bhaskell\b",
    "C#": r"\bc#\b|\bc\s+sharp\b",
}


def extract_languages(text: str) -> list[str]:
    """扫描文本，按 LANGUAGE_PATTERNS 顺序返回命中的语言（去重）。

    注意：必须使用 title + description_text 拼接的完整文本作为输入。
    """
    if not text:
        return []
    text_lower = text.lower()
    hits = []
    for lang, pat in LANGUAGE_PATTERNS.items():
        if re.search(pat, text_lower, re.IGNORECASE):
            hits.append(lang)
    return hits


def extract_for_job(title: str | None, description_text: str | None) -> str:
    """便捷函数：抽取后返回 CSV 字符串，供 fetcher 直接调用。"""
    blob = (title or "") + "\n" + (description_text or "")
    return ",".join(extract_languages(blob))


def ensure_column() -> None:
    """兼容老库：如果列不存在则补加。新库 schema 已默认包含。"""
    with get_conn() as conn:
        cols = {row["name"] for row in conn.execute("PRAGMA table_info(jobs)").fetchall()}
        if "work_languages" not in cols:
            conn.execute("ALTER TABLE jobs ADD COLUMN work_languages TEXT")
            print("Added column: work_languages")


def run(target_only: bool = False) -> None:
    """全量重算 work_languages。target_only=True 只处理目标岗位。"""
    ensure_column()
    with get_conn() as conn:
        sql = "SELECT id, title, description_text FROM jobs"
        if target_only:
            sql += " WHERE matches_target=1"
        rows = conn.execute(sql).fetchall()
        scope = "target" if target_only else "all"
        print(f"Scanning {len(rows)} {scope} jobs for languages...\n")
        updates = 0
        for r in rows:
            csv = extract_for_job(r["title"], r["description_text"])
            conn.execute(
                "UPDATE jobs SET work_languages=? WHERE id=?",
                (csv, r["id"]),
            )
            updates += 1
        print(f"Updated {updates} rows.\n")

        # 统计：每种语言命中数
        print("=== 语言命中分布（仅目标岗位）===")
        rows = conn.execute(
            "SELECT work_languages FROM jobs WHERE matches_target=1"
        ).fetchall()
        counter: dict[str, int] = {}
        for r in rows:
            for lang in (r["work_languages"] or "").split(","):
                if lang:
                    counter[lang] = counter.get(lang, 0) + 1
        for lang, cnt in sorted(counter.items(), key=lambda x: -x[1]):
            mark = "✅可投" if lang in USER_KNOWN else "  其他"
            print(f"  [{mark}] {lang:12s} {cnt:>3} 个岗位")

        # 统计：能投 / 不能投 / 通用工程师无明确语言要求
        print("\n=== 你能直接投的岗位（含至少一个 Java/Python/Golang/Solidity）===")
        rows = conn.execute(
            """
            SELECT c.display_name, j.title, j.work_languages, j.location
            FROM jobs j JOIN companies c ON c.slug=j.company_slug
            WHERE j.matches_target=1
            ORDER BY c.main_line, c.display_name, j.title
            """
        ).fetchall()
        you_can = []
        you_cannot = []
        unknown = []
        for r in rows:
            langs = set((r["work_languages"] or "").split(",")) - {""}
            if not langs:
                unknown.append(r)
            elif langs & USER_KNOWN:
                you_can.append(r)
            else:
                you_cannot.append(r)

        cur = ""
        for r in you_can:
            if r["display_name"] != cur:
                cur = r["display_name"]
                print(f"\n  --- {cur} ---")
            langs = r["work_languages"]
            highlights = ",".join([l for l in langs.split(",") if l in USER_KNOWN])
            print(f"  ✅ [{highlights:25s}] {r['title']}  | {r['location']}")

        print("\n=== 不能直接投（要求 Rust/C++/Move 等你不会的语言）===")
        cur = ""
        for r in you_cannot:
            if r["display_name"] != cur:
                cur = r["display_name"]
                print(f"\n  --- {cur} ---")
            print(f"  ❌ [{r['work_languages']:25s}] {r['title']}  | {r['location']}")

        print("\n=== 无明确语言要求（建议看 JD 详情判断）===")
        cur = ""
        for r in unknown:
            if r["display_name"] != cur:
                cur = r["display_name"]
                print(f"\n  --- {cur} ---")
            print(f"  ❓ {r['title']}  | {r['location']}")

        print(f"\n=== 汇总 ===")
        print(f"  你能直接投：    {len(you_can):>3} 个")
        print(f"  不能直接投：    {len(you_cannot):>3} 个（语言不会）")
        print(f"  无语言要求：    {len(unknown):>3} 个（看 JD 详情）")
        print(f"  合计：          {len(you_can)+len(you_cannot)+len(unknown):>3} 个目标岗位")


if __name__ == "__main__":
    run()
