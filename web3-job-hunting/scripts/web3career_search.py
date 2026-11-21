"""web3.career 关键词全站搜抓取器（不绑定公司，按 keyword 批量抓）。

设计：
- 入口 URL 形如 https://web3.career/backend%2Bremote-jobs
- 翻页参数 ?page=N
- 每个 job 链接 /<job-slug>/<id>，从 URL 末段反推真实公司名
- 所有岗位统一存到 company_slug='_w3c_search'（虚拟公司），
  source='web3career_search'，真实公司名放 team 字段，
  避免污染 companies 表

数据复用：
- 详情页解析复用 fetcher.html_to_text + 同样的 schema.org datePosted 正则
- 字段产出与 fetch_web3career 一致，可直接走 upsert_job
"""

from __future__ import annotations

import re
import sys
import time
from pathlib import Path
from typing import Iterable

import requests
from bs4 import BeautifulSoup

sys.path.insert(0, str(Path(__file__).resolve().parent))
from extract_languages import extract_for_job  # noqa: E402
from fetcher import HEADERS, RAW_DIR, html_to_text, make_session  # noqa: E402
from filters import apply_job_flags  # noqa: E402
from storage import get_conn, init_db, upsert_company, upsert_job  # noqa: E402

# ============== 关键词配置 ==============

# 每个 keyword URL 都会被抓 + 自动翻页（直到无新岗位或 page=PAGE_LIMIT）
KEYWORDS = [
    ("https://web3.career/backend%2Bremote-jobs", "backend + remote"),
    ("https://web3.career/solidity%2Bremote-jobs", "solidity + remote"),
    ("https://web3.career/golang%2Bweb3-jobs", "golang + web3"),
    ("https://web3.career/rust%2Bweb3-jobs", "rust + web3"),
    ("https://web3.career/blockchain%2Bremote-jobs", "blockchain + remote"),
    ("https://web3.career/smart-contract%2Bremote-jobs", "smart contract + remote"),
    ("https://web3.career/java%2Bweb3-jobs", "java + web3"),
]
PAGE_LIMIT = 5  # 每个关键词最多抓 5 页（每页 ~15 条 → 75 条）

VIRTUAL_SLUG = "_w3c_search"
VIRTUAL_COMPANY_META = dict(
    display_name="🔍 web3.career 关键词搜",
    main_line="X",  # X 表示「跨公司聚合」
    ats_platform="web3career_search",
    ats_handle="multi-keyword",
    careers_url="https://web3.career/",
    notes="不绑定单家公司的全站关键词搜结果聚合",
)


# ============== 抓取实现 ==============

JOB_LINK_RE = re.compile(r'href="(/[a-z0-9-]+/(\d+))"')


def _extract_company_from_slug(job_slug: str) -> str:
    """从 web3.career 的 job-slug 反推公司名。

    web3.career 的 slug 模板：
        /<role-words>-<company-slug>/<id>

    公司名通常是 slug 末段（slug 末段已是公司名 slug，可能带数字后缀）。
    没有 100% 可靠的 split，启发式：取 slug 最后 1-3 个 token 拼起来。
    """
    parts = job_slug.strip("/").split("-")
    if not parts:
        return "unknown"
    # 末段大概率是 company slug，去掉数字尾缀
    last = parts[-1]
    if last.isdigit():
        last = parts[-2] if len(parts) >= 2 else last
    return last


def _parse_detail(html: str, detail_url: str, ext_id: str, search_keyword: str) -> dict:
    """复用 fetcher.fetch_web3career 的详情页解析逻辑（轻量版）。"""
    soup = BeautifulSoup(html, "lxml")

    h1 = soup.find("h1")
    raw_title = h1.get_text(strip=True) if h1 else ""
    # web3.career 标题前缀常见格式：「<Company> is hiring a <Role>」
    title = re.sub(r"^[A-Za-z0-9.\- ]+is hiring an?\s*", "", raw_title).strip()
    title = re.sub(r"^a([A-Z])", r"\1", title)
    if not title:
        title = raw_title

    full_text = soup.get_text("\n", strip=True)
    salary_m = re.search(r"\$[\d,]+k?\s*-\s*\$[\d,]+k?", full_text)
    salary = salary_m.group(0) if salary_m else ""
    loc_m = re.search(r"\b(Remote|APAC|EMEA|AMER|Asia|Worldwide|Global)\b", full_text, re.I)
    loc = loc_m.group(0) if loc_m else ""

    desc_container = soup.select_one("div.col-12.col-md-8.pe-0")
    if desc_container:
        for noise in desc_container.select("nav, header, footer, .navbar, .footer"):
            noise.decompose()
        desc_html = str(desc_container)
        desc_text = html_to_text(desc_html)
    else:
        article = soup.find("article")
        desc_html = str(article) if article else ""
        desc_text = html_to_text(desc_html) if desc_html else full_text[:5000]

    posted_at = None
    m = re.search(r'"datePosted"\s*:\s*"([^"]+)"', html)
    if m:
        posted_at = m.group(1).strip()

    # 从 schema.org JSON-LD 拿真实 company 名
    real_company = ""
    cm = re.search(r'"hiringOrganization"\s*:\s*\{[^}]*"name"\s*:\s*"([^"]+)"', html)
    if cm:
        real_company = cm.group(1).strip()

    if not real_company:
        # fallback：从 H1 拆「X is hiring a」前缀
        cm2 = re.match(r"^([A-Za-z0-9.\- ]+?)\s+is hiring", raw_title)
        if cm2:
            real_company = cm2.group(1).strip()

    if not real_company:
        # 最后退路：从 URL slug 末段
        path = re.search(r"web3\.career(/[a-z0-9-]+/\d+)", detail_url)
        if path:
            real_company = _extract_company_from_slug(path.group(1).rsplit("/", 1)[0])

    return dict(
        company_slug=VIRTUAL_SLUG,
        external_id=f"w3csearch_{ext_id}",
        title=title,
        location=loc,
        team=real_company,            # 真实公司名放 team
        employment_type=None,
        workplace_type=loc,
        apply_url=detail_url,
        description=desc_html,
        description_text=desc_text,
        compensation=salary,
        posted_at=posted_at,
        # 自定义元数据通过额外字段透出（reporter 可读）
        _search_keyword=search_keyword,
    )


def fetch_keyword(keyword_url: str, label: str, sess: requests.Session) -> Iterable[dict]:
    """对单个关键词 URL 抓取，自动翻页直到无新岗位。"""
    print(f"\n=== [{label}] {keyword_url} ===")
    seen_ids: set[str] = set()

    for page in range(1, PAGE_LIMIT + 1):
        url = f"{keyword_url}?page={page}" if page > 1 else keyword_url
        try:
            r = sess.get(url, timeout=30)
            r.raise_for_status()
        except Exception as e:
            print(f"  [warn] page {page} 失败: {e}")
            break
        html = r.text

        page_links = set(JOB_LINK_RE.findall(html))
        new_links = [(p, eid) for p, eid in page_links if eid not in seen_ids]
        if not new_links:
            print(f"  page {page}: 无新岗位，停止")
            break
        print(f"  page {page}: 找到 {len(page_links)} 个 / 新增 {len(new_links)} 个")
        seen_ids.update(eid for _, eid in page_links)

        for path, ext_id in new_links:
            detail_url = f"https://web3.career{path}"
            try:
                dr = sess.get(detail_url, timeout=30)
                dr.raise_for_status()
            except Exception as e:
                print(f"    [warn] detail fail {detail_url}: {e}")
                continue
            time.sleep(0.4)

            try:
                yield _parse_detail(dr.text, detail_url, ext_id, label)
            except Exception as e:
                print(f"    [warn] parse fail {detail_url}: {e}")
                continue

        time.sleep(0.6)


def run() -> dict:
    init_db()
    upsert_company(
        slug=VIRTUAL_SLUG,
        display_name=VIRTUAL_COMPANY_META["display_name"],
        main_line=VIRTUAL_COMPANY_META["main_line"],
        ats_platform=VIRTUAL_COMPANY_META["ats_platform"],
        ats_handle=VIRTUAL_COMPANY_META["ats_handle"],
        careers_url=VIRTUAL_COMPANY_META["careers_url"],
        notes=VIRTUAL_COMPANY_META["notes"],
    )

    sess = make_session()
    raw_dir = RAW_DIR / "web3career_search"
    raw_dir.mkdir(parents=True, exist_ok=True)

    total = 0
    target = 0
    new_added = 0
    updated = 0

    # 先建立 ext_id 已有集合，便于统计 new vs updated
    with get_conn() as conn:
        cur = conn.execute(
            "SELECT external_id FROM jobs WHERE company_slug=?", (VIRTUAL_SLUG,)
        )
        existing_ids = {row["external_id"] for row in cur.fetchall()}

    for url, label in KEYWORDS:
        for raw in fetch_keyword(url, label, sess):
            total += 1
            apply_job_flags(raw)
            raw["work_languages"] = extract_for_job(
                raw.get("title", ""), raw.get("description_text", "")
            )
            raw["source"] = "web3career_search"
            raw["referral_id"] = raw.pop("_search_keyword", None)  # 借 referral_id 字段存关键词

            if raw["external_id"] in existing_ids:
                updated += 1
            else:
                new_added += 1
                existing_ids.add(raw["external_id"])

            if raw["matches_target"]:
                target += 1
            upsert_job(raw)

    print(f"\n=== web3career_search 完成 ===")
    print(f"  抓到岗位总数：{total}")
    print(f"  命中目标方向：{target}")
    print(f"  新增：{new_added} | 更新已有：{updated}")
    return {
        "total": total, "target": target,
        "new_added": new_added, "updated": updated,
    }


if __name__ == "__main__":
    run()
