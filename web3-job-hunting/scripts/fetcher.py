"""6 家公司 JD 抓取主程序

数据源：
- Scroll   : web3.career HTML 抓取（原 Lever 已下线）
- Mantle   : Ashby GraphQL（windranger）
- Manta    : Lever Public API（MantaNetwork）
- OKX      : Greenhouse Public API（okx）
- Binance  : Lever Public API（binance）
- Bitget   : web3.career HTML 抓取（自建系统未公开 API）

每个抓取器返回标准化字典：
    {
        company_slug, external_id, title, location, team,
        employment_type, workplace_type, apply_url,
        description, description_text, compensation, posted_at
    }

主程序执行：
1. 调用每个抓取器
2. 应用 filters.matches_target / is_remote
3. 写入 SQLite（matches_target=1 的才会被翻译/报告）
"""

from __future__ import annotations

import json
import re
import sys
import time
from html import unescape
from pathlib import Path
from typing import Iterable

import requests
from bs4 import BeautifulSoup

sys.path.insert(0, str(Path(__file__).resolve().parent))
from extract_languages import extract_for_job  # noqa: E402
from filters import apply_job_flags  # noqa: E402
from storage import init_db, stats, upsert_company, upsert_job  # noqa: E402

UA = (
    "Mozilla/5.0 (Macintosh; Intel Mac OS X 14_0) "
    "AppleWebKit/537.36 (KHTML, like Gecko) Chrome/130.0 Safari/537.36"
)
HEADERS = {"User-Agent": UA, "Accept-Language": "en-US,en;q=0.9,zh-CN;q=0.8,zh;q=0.7"}
RAW_DIR = Path(__file__).resolve().parent.parent / "raw"
RAW_DIR.mkdir(parents=True, exist_ok=True)


# ---------------- 公司元数据 ---------------- #

COMPANIES = {
    # 主线 A：公链 / L2 SDK 后端
    "scroll": dict(
        display_name="Scroll",
        main_line="A",
        ats_platform="web3career",
        ats_handle="scrollfoundation",
        careers_url="https://web3.career/web3-companies/scrollfoundation",
        notes="ZK Layer 2，华人创始团队，远程优先",
    ),
    "mantle": dict(
        display_name="Mantle",
        main_line="A",
        ats_platform="ashby",
        ats_handle="windranger",
        careers_url="https://group.mantle.xyz/jobs",
        notes="L2，BitDAO 系国库 30+ 亿美金",
    ),
    "manta": dict(
        display_name="Manta Network",
        main_line="A",
        ats_platform="lever",
        ats_handle="MantaNetwork",
        careers_url="https://jobs.lever.co/MantaNetwork",
        notes="ZK L2，华人创始团队",
    ),
    # 主线 B：CEX Web3 / Launchpad 业务合约
    "okx": dict(
        display_name="OKX",
        main_line="B",
        ats_platform="greenhouse",
        ats_handle="okx",
        careers_url="https://job-boards.greenhouse.io/okx",
        notes="Web3 Wallet / DEX 合约 + 后端",
    ),
    "binance": dict(
        display_name="Binance",
        main_line="B",
        ats_platform="lever",
        ats_handle="binance",
        careers_url="https://jobs.lever.co/binance",
        notes="Web3 Wallet + 业务合约 + 后端",
    ),
    "bitget": dict(
        display_name="Bitget",
        main_line="B",
        ats_platform="web3career",
        ats_handle="bitget",
        careers_url="https://web3.career/web3-companies/bitget",
        notes="Bitget Wallet + 交易所合约",
    ),
    # 主线 C：Web3 强业务公司（DeFi 协议方 / 钱包托管 / 稳定币 / NFT）
    # 全部走 web3.career 聚合，不依赖各家自建 ATS，便于统一抓取
    "coinbase": dict(
        display_name="Coinbase",
        main_line="C",
        ats_platform="web3career",
        ats_handle="coinbase",
        careers_url="https://web3.career/web3-companies/coinbase",
        notes="美股上市 CEX + 钱包 + Base L2，Go + Java 大户",
    ),
    "circle": dict(
        display_name="Circle",
        main_line="C",
        ats_platform="web3career",
        ats_handle="circle",
        careers_url="https://web3.career/web3-companies/circle",
        notes="USDC 发行方，稳定币业务标杆，Go + Java",
    ),
    "aave": dict(
        display_name="Aave Companies",
        main_line="C",
        ats_platform="web3career",
        ats_handle="aave",
        careers_url="https://web3.career/web3-companies/aave",
        notes="DeFi 借贷协议龙头，TVL 300 亿",
    ),
    "lido": dict(
        display_name="Lido Finance",
        main_line="C",
        ats_platform="web3career",
        ats_handle="lido",
        careers_url="https://web3.career/web3-companies/lido",
        notes="ETH 流动性质押龙头，TVL 300 亿，Go + Python",
    ),
    "pendle": dict(
        display_name="Pendle Finance",
        main_line="C",
        ats_platform="web3career",
        ats_handle="pendle",
        careers_url="https://web3.career/web3-companies/pendle",
        notes="DeFi 收益衍生品（PT/YT），2024 涨 50x",
    ),
    "fireblocks": dict(
        display_name="Fireblocks",
        main_line="C",
        ats_platform="web3career",
        ats_handle="fireblocks",
        careers_url="https://web3.career/web3-companies/fireblocks",
        notes="MPC 钱包托管业务，机构级，Go + Java",
    ),
    "magic-eden": dict(
        display_name="Magic Eden",
        main_line="C",
        ats_platform="web3career",
        ats_handle="magic-eden",
        careers_url="https://web3.career/web3-companies/magic-eden",
        notes="多链 NFT 市场龙头，业务故事好讲",
    ),
    "ondo": dict(
        display_name="Ondo Finance",
        main_line="C",
        ats_platform="web3career",
        ats_handle="ondo",
        careers_url="https://web3.career/web3-companies/ondo",
        notes="RWA 稳定币龙头（USDY），TradFi × DeFi",
    ),
    "uniswap": dict(
        display_name="Uniswap Labs",
        main_line="C",
        ats_platform="ashby",
        ats_handle="uniswap",
        careers_url="https://jobs.ashbyhq.com/uniswap",
        notes="DEX 之神，TS + Go，业务标杆",
    ),
    # 主线 D：中文友好 CEX（华人创始 + 全中文办公）
    "bybit": dict(
        display_name="Bybit",
        main_line="D",
        ats_platform="greenhouse",
        ats_handle="bybit",
        careers_url="https://job-boards.greenhouse.io/bybit",
        notes="全球第二大衍生品交易所，Ben Zhou 创立，新加坡，Java/Rust 多",
    ),
    "gate": dict(
        display_name="Gate.io",
        main_line="D",
        ats_platform="lever",
        ats_handle="gate",
        careers_url="https://jobs.lever.co/gate",
        notes="韩林创立，杭州办公室，币种最多，Go/Java，部分岗位中文标题",
    ),
    # 主线 E：L1 / L2 公链（华人贡献者活跃，业务匹配后端 + 协议）
    "polygon-labs": dict(
        display_name="Polygon Labs",
        main_line="E",
        ats_platform="ashby",
        ats_handle="polygon-labs",
        careers_url="https://jobs.ashbyhq.com/polygon-labs",
        notes="L2 + zkEVM，远程优先，华人贡献者多，13+ 岗位活跃",
    ),
    "ava-labs": dict(
        display_name="Ava Labs",
        main_line="E",
        ats_platform="ashby",
        ats_handle="ava-labs",
        careers_url="https://jobs.ashbyhq.com/ava-labs",
        notes="Avalanche L1 + 机构托管，Ashby 公开 4 个岗，工程岗在 GH avalabs（无开放 API）",
    ),
    "pagoda": dict(
        display_name="Pagoda (NEAR)",
        main_line="E",
        ats_platform="web3career",
        ats_handle="pagoda",
        careers_url="https://web3.career/web3-companies/pagoda",
        notes="NEAR 生态实际雇主，Rust 协议工程师 + Blockchain Node，远程",
    ),
}


def html_to_text(html: str) -> str:
    if not html:
        return ""
    soup = BeautifulSoup(unescape(html), "lxml")
    for tag in soup(["script", "style"]):
        tag.decompose()
    text = soup.get_text(separator="\n")
    lines = [ln.strip() for ln in text.splitlines()]
    return "\n".join([ln for ln in lines if ln])


def make_session() -> requests.Session:
    s = requests.Session()
    s.headers.update(HEADERS)
    return s


# ---------------- Greenhouse: OKX ---------------- #

def fetch_greenhouse(slug: str, handle: str, sess: requests.Session) -> Iterable[dict]:
    """Greenhouse 公开 API: boards-api.greenhouse.io/v1/boards/{handle}/jobs?content=true"""
    url = f"https://boards-api.greenhouse.io/v1/boards/{handle}/jobs?content=true"
    print(f"  GET {url}")
    r = sess.get(url, timeout=30)
    r.raise_for_status()
    data = r.json()
    (RAW_DIR / f"{slug}_greenhouse.json").write_text(json.dumps(data, ensure_ascii=False, indent=2))
    for j in data.get("jobs", []):
        loc_name = (j.get("location") or {}).get("name", "")
        desc_html = j.get("content", "")
        yield dict(
            company_slug=slug,
            external_id=str(j.get("id")),
            title=j.get("title", ""),
            location=loc_name,
            team=", ".join([d.get("name", "") for d in (j.get("departments") or [])]),
            employment_type=None,
            workplace_type=None,
            apply_url=j.get("absolute_url", ""),
            description=desc_html,
            description_text=html_to_text(desc_html),
            compensation=None,
            posted_at=j.get("updated_at"),
        )


# ---------------- Lever: Manta, Binance ---------------- #

def fetch_lever(slug: str, handle: str, sess: requests.Session) -> Iterable[dict]:
    """Lever 公开 API: api.lever.co/v0/postings/{handle}?mode=json"""
    url = f"https://api.lever.co/v0/postings/{handle}?mode=json"
    print(f"  GET {url}")
    r = sess.get(url, timeout=30)
    r.raise_for_status()
    data = r.json()
    (RAW_DIR / f"{slug}_lever.json").write_text(json.dumps(data, ensure_ascii=False, indent=2))
    if not isinstance(data, list):
        return
    for j in data:
        cat = j.get("categories") or {}
        # Lever 的 description 在 description / descriptionPlain / lists 字段里
        desc_html = j.get("description", "") or ""
        if j.get("lists"):
            for lst in j["lists"]:
                desc_html += f"\n<h3>{lst.get('text','')}</h3>{lst.get('content','')}"
        if j.get("additional"):
            desc_html += "\n" + j["additional"]
        yield dict(
            company_slug=slug,
            external_id=str(j.get("id")),
            title=j.get("text", ""),
            location=cat.get("location", "") or ", ".join(cat.get("allLocations") or []),
            team=cat.get("team", ""),
            employment_type=cat.get("commitment", ""),
            workplace_type=j.get("workplaceType", ""),
            apply_url=j.get("hostedUrl", "") or j.get("applyUrl", ""),
            description=desc_html,
            description_text=html_to_text(desc_html),
            compensation=j.get("salaryRange") and json.dumps(j["salaryRange"], ensure_ascii=False),
            posted_at=str(j.get("createdAt", "") or ""),
        )


# ---------------- Ashby: Mantle ---------------- #

ASHBY_QUERY = """query ApiJobBoardWithTeams($organizationHostedJobsPageName: String!) {
  jobBoard: jobBoardWithTeams(organizationHostedJobsPageName: $organizationHostedJobsPageName) {
    teams { id name parentTeamId }
    jobPostings {
      id title teamId locationName workplaceType employmentType
      secondaryLocations { locationId locationName }
      compensationTierSummary
    }
  }
}"""

ASHBY_DETAIL_QUERY = """query ApiJobPosting($organizationHostedJobsPageName: String!, $jobPostingId: String!) {
  jobPosting(organizationHostedJobsPageName: $organizationHostedJobsPageName, jobPostingId: $jobPostingId) {
    id title descriptionHtml
    locationName workplaceType employmentType
    compensationTierSummary
  }
}"""


def fetch_ashby(slug: str, handle: str, sess: requests.Session) -> Iterable[dict]:
    """Ashby REST API（推荐）：api.ashbyhq.com/posting-api/job-board/{handle}

    一次返回所有岗位 + 完整字段（含 publishedAt / descriptionHtml），无需逐个拉详情，
    比 GraphQL 流程快 100 倍。字段完整列表：
        id, title, department, team, employmentType, location, publishedAt,
        isListed, isRemote, workplaceType, jobUrl, applyUrl,
        descriptionHtml, descriptionPlain
    """
    url = f"https://api.ashbyhq.com/posting-api/job-board/{handle}"
    print(f"  GET {url}")
    r = sess.get(url, timeout=30)
    r.raise_for_status()
    data = r.json()
    (RAW_DIR / f"{slug}_ashby.json").write_text(json.dumps(data, ensure_ascii=False, indent=2))
    jobs = data.get("jobs", [])
    print(f"    found {len(jobs)} postings (REST 一次拉全)")

    for j in jobs:
        desc_html = j.get("descriptionHtml", "") or ""
        desc_text = j.get("descriptionPlain", "") or html_to_text(desc_html)
        loc = j.get("location") or ""
        # 兼容 location 既可能是字符串也可能是对象
        if isinstance(loc, dict):
            loc = loc.get("name", "")
        yield dict(
            company_slug=slug,
            external_id=j.get("id"),
            title=j.get("title", ""),
            location=loc,
            team=j.get("team") or j.get("department") or "",
            employment_type=j.get("employmentType", ""),
            workplace_type=j.get("workplaceType", ""),
            apply_url=j.get("jobUrl") or j.get("applyUrl") or f"https://jobs.ashbyhq.com/{handle}/{j.get('id')}",
            description=desc_html,
            description_text=desc_text,
            compensation=None,
            posted_at=j.get("publishedAt"),
        )


# ---------------- web3.career: Scroll, Bitget ---------------- #

def fetch_web3career(slug: str, handle: str, sess: requests.Session) -> Iterable[dict]:
    """web3.career 聚合站抓取（Scroll/Bitget 用作备选源）。

    步骤：
    1. 拉公司主页 HTML，从中找出 <a href="/{job-slug}/{id}"> 的链接
    2. 对每个 job 链接拉详情页，提取 title / location / salary / description
    """
    list_url = f"https://web3.career/web3-companies/{handle}"
    print(f"  GET {list_url}")
    r = sess.get(list_url, timeout=30)
    r.raise_for_status()
    html = r.text
    (RAW_DIR / f"{slug}_w3c_list.html").write_text(html)

    # 提取 /xxx/12345 形式的链接
    job_links = set()
    for m in re.finditer(r'href="(/[a-z0-9-]+-' + re.escape(handle) + r'/(\d+))"', html):
        job_links.add((m.group(1), m.group(2)))
    print(f"    found {len(job_links)} job links")

    for path, ext_id in sorted(job_links, key=lambda x: -int(x[1])):
        detail_url = f"https://web3.career{path}"
        try:
            dr = sess.get(detail_url, timeout=30)
            dr.raise_for_status()
        except Exception as e:
            print(f"    [warn] failed: {e}")
            continue
        time.sleep(0.4)

        soup = BeautifulSoup(dr.text, "lxml")

        # 标题：<h1> 第一个，去掉 web3.career 自带前缀（如 "Scroll.io is hiring a"）
        h1 = soup.find("h1")
        raw_title = h1.get_text(strip=True) if h1 else ""
        title = re.sub(r"^[A-Za-z0-9.\- ]+is hiring an?\s*", "", raw_title).strip()
        # 处理粘连情况："aBlockchain" / "aWeb3" 等
        title = re.sub(r"^a([A-Z])", r"\1", title)
        if not title:
            title = raw_title

        # 薪资 / 地点 / tag 在 article 里
        # web3.career 详情页结构变化大，用启发式
        full_text = soup.get_text("\n", strip=True)

        # 薪资正则
        salary = ""
        salary_m = re.search(r"\$[\d,]+k?\s*-\s*\$[\d,]+k?", full_text)
        if salary_m:
            salary = salary_m.group(0)

        # 地点
        loc = ""
        loc_m = re.search(r"\b(Remote|APAC|EMEA|AMER|Asia|Worldwide|Global)\b", full_text, re.I)
        if loc_m:
            loc = loc_m.group(0)

        # description：web3.career 把 JD 正文放在 div.col-12.col-md-8.pe-0
        desc_container = soup.select_one("div.col-12.col-md-8.pe-0")
        if desc_container:
            # 移除导航/header 等噪声
            for noise in desc_container.select("nav, header, footer, .navbar, .footer"):
                noise.decompose()
            desc_html = str(desc_container)
            desc_text = html_to_text(desc_html)
        else:
            article = soup.find("article")
            desc_html = str(article) if article else ""
            desc_text = html_to_text(desc_html) if desc_html else full_text[:5000]

        # 提取发布时间：web3.career 详情页含 schema.org JSON-LD（"datePosted": "..."）
        # 例: "datePosted": "2026-04-28 19:21:01 +0100"  或 ISO8601
        posted_at = None
        m = re.search(r'"datePosted"\s*:\s*"([^"]+)"', dr.text)
        if m:
            posted_at = m.group(1).strip()

        yield dict(
            company_slug=slug,
            external_id=ext_id,
            title=title,
            location=loc,
            team=None,
            employment_type=None,
            workplace_type=loc,
            apply_url=detail_url,
            description=desc_html,
            description_text=desc_text,
            compensation=salary,
            posted_at=posted_at,
        )


# ---------------- 主流程 ---------------- #

DISPATCH = {
    "greenhouse": fetch_greenhouse,
    "lever": fetch_lever,
    "ashby": fetch_ashby,
    "web3career": fetch_web3career,
}


def run() -> None:
    init_db()
    sess = make_session()
    for slug, meta in COMPANIES.items():
        upsert_company(
            slug=slug,
            display_name=meta["display_name"],
            main_line=meta["main_line"],
            ats_platform=meta["ats_platform"],
            ats_handle=meta["ats_handle"],
            careers_url=meta["careers_url"],
            notes=meta["notes"],
        )

        print(f"\n=== {meta['display_name']} ({meta['ats_platform']}) ===")
        fetcher = DISPATCH[meta["ats_platform"]]
        try:
            count = 0
            target_count = 0
            for job in fetcher(slug, meta["ats_handle"], sess):
                # 标记
                apply_job_flags(job)
                job["work_languages"] = extract_for_job(job.get("title", ""), job.get("description_text", ""))
                upsert_job(job)
                count += 1
                if job["matches_target"]:
                    target_count += 1
            print(f"    total={count}, target_matched={target_count}")
        except Exception as e:
            print(f"  [ERROR] {meta['display_name']}: {e}")

    print("\n=== Stats ===")
    s = stats()
    print(f"companies={s['total_companies']} | total_jobs={s['total_jobs']} | target={s['target_jobs']} | remote={s['remote_jobs']}")
    for name, info in s["per_company"].items():
        print(f"  {name:20s} total={info['total']:>4}  target={info['target']:>3}")


if __name__ == "__main__":
    run()
