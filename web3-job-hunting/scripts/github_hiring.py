"""GitHub Issue 招聘频道 fetcher。

目前支持仓库：
  - rebase-network/who-is-hiring  → Web3 中文招聘信息聚合（每个 issue = 一个岗位）

数据质量极高：每个 issue 都有结构化 markdown，包括：
  - 标题：`[地点] 公司/业务 招聘 岗位 薪水 X-Y USD`
  - body 包含：## 公司/团队介绍 / ## 薪资福利待遇 / ## 地点 / ## 工作性质 / ## 岗位要求

为不污染主公司池，所有 issue 归到虚拟公司：
  - company_slug = "_gh_<owner>_<repo>"
  - team       = body 中解析到的真实公司名 / 业务方向
  - referral_id = "gh_<owner>/<repo>#<issue_num>"

API 限额：未鉴权 60 req/h，每仓 1 page 包 100 条 → 通常一次跑只用 1-3 次调用。
"""

from __future__ import annotations

import os
import re
import time
from dataclasses import dataclass
from pathlib import Path
from typing import Iterable

import requests

from extract_languages import extract_for_job
from filters import apply_job_flags, is_remote, matches_target
from storage import get_conn, init_db, upsert_company, upsert_job


# ============== 配置 ==============

REPOS: list[dict] = [
    dict(
        owner="rebase-network",
        repo="who-is-hiring",
        display_name="Rebase 招聘频道（中文 Web3）",
        notes="Web3 中文招聘聚合，结构化 markdown，每个 issue=一个岗位",
    ),
]

PAGE_LIMIT_PER_REPO = 3      # 100 * 3 = 300 条最近更新 issue → 覆盖 ~30-60 天
PER_PAGE = 100
TIMEOUT = 30
USER_AGENT = "web3-job-hunting/1.0 (+github-issue-scraper)"

# 可选：~/.config/web3-job-hunting/github_token 或 env GITHUB_TOKEN
GITHUB_TOKEN = os.environ.get("GITHUB_TOKEN", "")

RAW_DIR = Path("raw_html/github_hiring")
RAW_DIR.mkdir(parents=True, exist_ok=True)


# ============== HTTP ==============

def make_session() -> requests.Session:
    s = requests.Session()
    s.headers.update({
        "User-Agent": USER_AGENT,
        "Accept": "application/vnd.github+json",
        "X-GitHub-Api-Version": "2022-11-28",
    })
    if GITHUB_TOKEN:
        s.headers["Authorization"] = f"Bearer {GITHUB_TOKEN}"
    return s


# ============== body 解析 ==============

# title 格式举例：
#   [成都] 诚聘高级后端工程师(P6)/后端技术专家(P7) - Golang 薪水 3000-8000 USD
#   [远程办公] Crypto 交易所诚聘 用户增长实习生  薪水 1000 USDT
#   远程 区块链 Go/PHP 架构师golang 100-300w
LOC_RE = re.compile(r"^\s*\[([^\]]+)\]\s*(.*)$")

# body 字段
COMPANY_INTRO_RE = re.compile(
    r"##\s*公司/团队介绍\s*(.*?)(?:##|\Z)", re.DOTALL
)
SALARY_RE = re.compile(
    r"##\s*薪资福利待遇\s*(.*?)(?:##|\Z)", re.DOTALL
)
LOCATION_RE = re.compile(
    r"##\s*地点\s*(.*?)(?:##|\Z)", re.DOTALL
)
WORKTYPE_RE = re.compile(
    r"##\s*工作性质\s*(.*?)(?:##|\Z)", re.DOTALL
)

CONTACT_RE = re.compile(r"联系方式[：:](.+?)(?:\n|$)")


def _first_line(s: str) -> str:
    for line in s.split("\n"):
        line = line.strip().lstrip("-").strip()
        if line:
            return line
    return ""


def parse_issue_body(title: str, body: str) -> dict:
    """从 markdown body 提取结构化字段。"""
    body = body or ""

    # ----- title 拆解 -----
    location_in_title = ""
    pure_title = title
    m = LOC_RE.match(title)
    if m:
        location_in_title = m.group(1).strip()
        pure_title = m.group(2).strip()

    # ----- 公司 -----
    company = ""
    m = COMPANY_INTRO_RE.search(body)
    if m:
        intro = m.group(1).strip()
        company = _first_line(intro)[:80]
    if not company and pure_title:
        # 从 title 启发性提取公司（如「Crypto 交易所诚聘 X」）
        # 难，先留空
        pass

    # ----- 地点 -----
    location = location_in_title
    if not location:
        m = LOCATION_RE.search(body)
        if m:
            location = _first_line(m.group(1))[:80]

    # ----- 薪资 -----
    salary = ""
    m = SALARY_RE.search(body)
    if m:
        salary = _first_line(m.group(1))[:120]

    # ----- 工作性质 → remote 提示 -----
    work_type_text = ""
    m = WORKTYPE_RE.search(body)
    if m:
        work_type_text = m.group(1).strip()

    # ----- 联系方式 -----
    contact = ""
    m = CONTACT_RE.search(body)
    if m:
        contact = m.group(1).strip()[:80]

    return dict(
        company=company,
        title=pure_title or title,
        location=location,
        salary=salary,
        work_type_text=work_type_text,
        contact=contact,
    )


def _is_remote_from_body(text_blob: str, location: str = "", title: str = "") -> bool | None:
    """rebase-network 的 body 一般写"是否远程：是 / 否"。

    返回 True/False 表示能确定，None 表示无法判定（让上游 fallback 到 filters.is_remote）。
    """
    if re.search(r"是否远程[：:]\s*否|不支持远程|不远程", text_blob):
        return False
    if re.search(r"是否远程[：:]\s*是", text_blob):
        return True
    # title / location 明确含[远程]
    if re.search(r"\[(?:远程|远程办公|远程优先|完全远程)\]", title):
        return True
    if re.search(r"^(?:远程|Remote)\b", (location or "").strip(), re.I):
        return True
    if re.search(r"\b(?:fully\s+remote|完全远程)\b", text_blob, re.I):
        return True
    return None


# ============== 抓取 ==============

def fetch_repo(repo_cfg: dict, sess: requests.Session) -> Iterable[dict]:
    owner = repo_cfg["owner"]
    repo = repo_cfg["repo"]
    print(f"\n=== GitHub {owner}/{repo} ===")

    for page in range(1, PAGE_LIMIT_PER_REPO + 1):
        url = (
            f"https://api.github.com/repos/{owner}/{repo}/issues"
            f"?state=open&sort=updated&direction=desc"
            f"&per_page={PER_PAGE}&page={page}"
        )
        try:
            r = sess.get(url, timeout=TIMEOUT)
            r.raise_for_status()
        except Exception as e:
            print(f"  [warn] page {page} 失败: {e}")
            break
        items = r.json()
        if not items:
            print(f"  page {page}: 0 条，停止")
            break

        # 落盘备份
        (RAW_DIR / f"{owner}_{repo}_p{page}.json").write_text(r.text)

        print(f"  page {page}: 拿到 {len(items)} 条 issue")

        for it in items:
            # PR 也会出现，过滤
            if "pull_request" in it:
                continue
            num = it["number"]
            title = it["title"] or ""
            body = it["body"] or ""
            updated = it["updated_at"]
            created = it["created_at"]
            html_url = it["html_url"]

            parsed = parse_issue_body(title, body)
            ext_id = f"gh_{owner}_{repo}_{num}"

            # description_text：title + 全 body（用于 keyword 过滤）
            desc_blob = f"{title}\n\n{body}"

            remote_flag = _is_remote_from_body(desc_blob, parsed["location"], title)
            yield dict(
                company_slug=f"_gh_{owner}_{repo}",
                external_id=ext_id,
                title=parsed["title"],
                location=parsed["location"],
                team=parsed["company"],
                employment_type="",
                workplace_type="Remote" if remote_flag else ("Onsite" if remote_flag is False else ""),
                apply_url=html_url,
                description=body,
                description_text=desc_blob,
                compensation=parsed["salary"],
                posted_at=updated,
                referral_id=f"gh_{owner}/{repo}#{num}",
                _remote_explicit=remote_flag,
            )

        time.sleep(0.6)


# ============== 主流程 ==============

def run() -> dict:
    init_db()
    sess = make_session()

    total = 0
    target = 0
    new_added = 0
    updated = 0
    per_repo: dict[str, dict] = {}

    for cfg in REPOS:
        slug = f"_gh_{cfg['owner']}_{cfg['repo']}"
        upsert_company(
            slug=slug,
            display_name=f"📥 GitHub: {cfg['display_name']}",
            main_line="G",  # G = GitHub issue 招聘
            ats_platform="github_issues",
            ats_handle=f"{cfg['owner']}/{cfg['repo']}",
            careers_url=f"https://github.com/{cfg['owner']}/{cfg['repo']}/issues",
            notes=cfg.get("notes", ""),
        )

        with get_conn() as conn:
            cur = conn.execute(
                "SELECT external_id FROM jobs WHERE company_slug=?", (slug,)
            )
            existing = {row["external_id"] for row in cur.fetchall()}

        r_total = r_target = r_new = r_upd = 0
        for raw in fetch_repo(cfg, sess):
            r_total += 1

            apply_job_flags(raw, matched=bool(matches_target(
                raw.get("title", ""),
                raw.get("description_text", ""),
            )))

            # GitHub issue 的 body 通常显式写了"是否远程：是/否"
            # → 优先用显式字段；不明确再 fallback 到 filters.is_remote
            explicit = raw.pop("_remote_explicit", None)
            if explicit is True:
                raw["is_remote"] = 1
            elif explicit is False:
                raw["is_remote"] = 0

            raw["work_languages"] = extract_for_job(
                raw.get("title", ""), raw.get("description_text", "")
            )
            raw["source"] = "github_issues"

            if raw["external_id"] in existing:
                r_upd += 1
            else:
                r_new += 1
                existing.add(raw["external_id"])

            if raw["matches_target"]:
                r_target += 1
            upsert_job(raw)

        per_repo[f"{cfg['owner']}/{cfg['repo']}"] = dict(
            total=r_total, target=r_target, new=r_new, updated=r_upd
        )
        total += r_total
        target += r_target
        new_added += r_new
        updated += r_upd
        print(
            f"\n  → {cfg['owner']}/{cfg['repo']}: 抓到 {r_total} 个 issue，"
            f"目标方向 {r_target} 个 (新增 {r_new}, 更新 {r_upd})"
        )

    print(f"\n=== GitHub 完成 ===")
    print(f"  总 issue：{total} | 命中目标：{target}")
    print(f"  新增：{new_added} | 更新：{updated}")
    return {
        "total": total, "target": target,
        "new_added": new_added, "updated": updated,
        "per_repo": per_repo,
    }


if __name__ == "__main__":
    run()
