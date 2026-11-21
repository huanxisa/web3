"""飞书内推岗位池同步脚本。

数据流：
  scripts/feishu_extract.py 已经把飞书表格 dump 到 data/raw/feishu/extract_*/cells.csv
  本脚本：
  1. 找最新的 cells.csv
  2. 解析 9 列：行号 / 企业类型 / 岗位 / JD / 办公模式 / base / 薪资 / 更新时间(Excel序号) / HC
  3. 跑 filters.matches_target() 判断是否目标岗位
  4. 跑 extract_languages 识别语言
  5. 入库（source='feishu_referral'，company_slug='feishu_referral'，
     external_id=f'feishu_<行号>'，referral_id=行号）
  6. 入库时 apply_url 填飞书表格 URL（HR 投递时回这个表找对应行号）

使用：
    python scripts/feishu_sync.py                    # 自动找最新 cells.csv
    python scripts/feishu_sync.py --csv path/to/csv  # 指定 csv
"""

from __future__ import annotations

import argparse
import csv
import re
import sys
from datetime import datetime, timedelta
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))
from storage import get_conn, init_db, upsert_company, upsert_job  # noqa: E402
from filters import apply_job_flags  # noqa: E402
from extract_languages import extract_languages  # noqa: E402

PROJECT_ROOT = Path(__file__).resolve().parent.parent
RAW_FEISHU_DIR = PROJECT_ROOT / "data" / "raw" / "feishu"

# 飞书表元数据
FEISHU_SHEET_URL = "https://my.feishu.cn/sheets/ScdYsiuRMhTjzFt0rdXcCyshnom"
COMPANY_SLUG = "feishu_referral"
COMPANY_NAME = "飞书内推岗位池"
MAIN_LINE = "F"   # F = Feishu，新增主线，渲染时归到「内推」section


# ============== 工具 ==============


def find_latest_csv() -> Path:
    """从 data/raw/feishu/extract_*/cells.csv 里挑最新的。"""
    candidates = sorted(RAW_FEISHU_DIR.glob("extract_*/cells.csv"))
    if not candidates:
        raise FileNotFoundError(
            f"找不到 cells.csv，请先跑 `python scripts/feishu_extract.py --headed`"
        )
    return candidates[-1]


def excel_serial_to_iso(s: str | None) -> str | None:
    """Excel 序号日期 → 'YYYY-MM-DD' 字符串。

    Excel 的日期 serial 起点：1899-12-30（不是 1900-01-01，因为 Lotus 兼容）。
    例：45553 → 2024-09-15
        45771 → 2025-04-21
    """
    if not s:
        return None
    s = str(s).strip()
    if not s.isdigit():
        # 也可能本来就是 ISO 格式
        return s if re.match(r"^\d{4}-\d{2}-\d{2}", s) else None
    try:
        days = int(s)
        # Excel/Lotus serial date: 1900-01-01 = 1, but with the famous
        # 1900-leap-year bug, Microsoft uses 1899-12-30 as effective epoch.
        epoch = datetime(1899, 12, 30)
        d = epoch + timedelta(days=days)
        return d.strftime("%Y-%m-%d")
    except (ValueError, OverflowError):
        return None


def detect_workplace(text: str | None) -> str:
    """飞书表的「办公模式」列：现场 / 远程 / 混合。归一为标准词。"""
    if not text:
        return ""
    t = text.strip()
    if "远程" in t or "remote" in t.lower():
        return "Remote"
    if "混合" in t or "hybrid" in t.lower():
        return "Hybrid"
    if "现场" in t or "onsite" in t.lower() or "on-site" in t.lower():
        return "Onsite"
    return t


def clean(s: str | None) -> str:
    if not s:
        return ""
    return s.strip()


# 企业类型规范化（合并大小写差异 + 同义词归一）
INDUSTRY_NORMALIZE = {
    "wallet": "Wallet",
    "Wallet": "Wallet",
    "Wallet ": "Wallet",
    "defi": "DeFi",
    "DeFi": "DeFi",
    "Defi": "DeFi",
    "Defi/DEX": "DeFi/DEX",
    "dex": "DEX",
    "DEX": "DEX",
    "cex": "CEX",
    "CEX": "CEX",
    "交易所": "CEX",
    "券商": "CEX",
    "layer1": "L1/L2 公链",
    "Layer1": "L1/L2 公链",
    "Layer1 ": "L1/L2 公链",
    "layer2": "L1/L2 公链",
    "L2": "L1/L2 公链",
    "ai": "AI / SocialFi",
    "AI": "AI / SocialFi",
    " AI": "AI / SocialFi",
    "AI+web3": "AI / SocialFi",
    "SocialFi": "AI / SocialFi",
    "项目方": "项目方",
    "数据": "数据 / DAO",
    "DAO": "数据 / DAO",
    "/": "未指定",
    "": "未指定",
}


def normalize_industry(s: str | None) -> str:
    if not s:
        return "未指定"
    raw = s.strip()
    return INDUSTRY_NORMALIZE.get(raw, raw)


# ============== 主流程 ==============


def parse_csv(csv_path: Path) -> list[dict]:
    """解析 cells.csv，返回标准化的 job dict 列表。"""
    with csv_path.open() as f:
        rows = list(csv.reader(f))

    if not rows or len(rows) < 2:
        return []

    header = rows[0]
    print(f"[*] 表头: {header[:9]}")

    # 列定义（对照实际数据）：
    #   0=行号, 1=企业类型, 2=岗位名称, 3=岗位JD, 4=办公模式, 5=base, 6=薪资, 7=更新时间, 8=HC
    COL_ROW = 0
    COL_INDUSTRY = 1
    COL_TITLE = 2
    COL_JD = 3
    COL_WORKPLACE = 4
    COL_BASE = 5
    COL_SALARY = 6
    COL_DATE = 7
    COL_HC = 8

    jobs = []
    misaligned_count = 0
    for row in rows[1:]:
        # 兜底防越界
        def get(idx):
            return row[idx] if idx < len(row) else ""

        row_num = clean(get(COL_ROW))
        if not row_num:
            continue

        raw_industry = clean(get(COL_INDUSTRY))
        raw_title = clean(get(COL_TITLE))
        raw_jd = clean(get(COL_JD))

        # 智能检测：飞书表里有些行填表人把"岗位名"填到了 [1] 企业类型列
        # 判定规则：industry 列含换行 / 超过 25 字 / 含"岗位"/"工程师"/"开发"等岗位词 → 大概率是误填的岗位名
        # 此时启用 fallback：[1]=title  [2]=JD  industry 置空
        is_misaligned = bool(raw_industry) and (
            len(raw_industry) > 25
            or "\n" in raw_industry
            or any(kw in raw_industry for kw in ["工程师", "开发", "Engineer", "engineer", "DeFi", "Backend", "Lead", "Senior", "Staff", "Principal", "QA", "测试"])
        )
        if is_misaligned:
            misaligned_count += 1
            title = raw_industry  # [1] 实际是岗位名
            jd = raw_title        # [2] 实际是 JD
            industry = "未指定"
        else:
            title = raw_title
            jd = raw_jd
            industry = normalize_industry(raw_industry)

        if not title:
            continue

        workplace_raw = clean(get(COL_WORKPLACE))
        workplace = detect_workplace(workplace_raw)
        base = clean(get(COL_BASE))
        salary = clean(get(COL_SALARY))
        if salary in ("/", "-", "n/a", "N/A"):
            salary = ""
        date_raw = clean(get(COL_DATE))
        posted_at = excel_serial_to_iso(date_raw)
        hc = clean(get(COL_HC))

        # 组合一段 description_text 方便检索
        desc_parts = []
        if industry:
            desc_parts.append(f"【企业类型】{industry}")
        if base and base != "/":
            desc_parts.append(f"【Base】{base}")
        if salary:
            desc_parts.append(f"【薪资】{salary}")
        if hc:
            desc_parts.append(f"【HC】{hc}")
        if workplace_raw:
            desc_parts.append(f"【办公模式】{workplace_raw}")
        if posted_at:
            desc_parts.append(f"【需求更新】{posted_at}")
        desc_parts.append("")
        desc_parts.append(jd)
        description_text = "\n".join(desc_parts)

        # filter / 语言识别
        languages = ",".join(extract_languages(f"{title}\n{jd}"))

        job_row = {
            "company_slug": COMPANY_SLUG,
            "external_id": f"feishu_{row_num}",
            "title": title,
            "title_zh": title,                  # 已是中文
            "location": base if base and base != "/" else "",
            "team": industry,                   # 用「企业类型」存到 team 字段
            "employment_type": "",
            "workplace_type": workplace,
            "apply_url": f"{FEISHU_SHEET_URL}#row={row_num}",  # 让用户回飞书查
            "description": jd,
            "description_text": description_text,
            "description_zh": description_text, # 已是中文
            "compensation": salary,
            "posted_at": posted_at,
            "work_languages": languages,
            "source": "feishu_referral",
            "referral_id": row_num,
        }
        apply_job_flags(job_row)
        jobs.append(job_row)
    if misaligned_count:
        print(f"[!] 检测到 {misaligned_count} 行被填表人填错了列（[1] 应填企业类型却填了岗位名），已自动纠正")
    return jobs


def _existing_referral_ids() -> set[str]:
    """查 DB 已存在的飞书行号（external_id like 'feishu_*'）"""
    with get_conn() as conn:
        cur = conn.execute(
            "SELECT external_id FROM jobs WHERE source='feishu_referral'"
        )
        return {row[0] for row in cur.fetchall()}


def run(csv_path: Path | None = None, only_new: bool = False) -> dict:
    """跑一次完整同步。返回统计 dict。

    :param csv_path: 可选，指定 CSV；不传则自动找最新。
    :param only_new: True 时只插入新行（基于 external_id 比对），跳过已存在的；
                     False 时全部 upsert（已存在的也会被刷新，覆盖手工修改）。
    :return: {'parsed': N, 'matched': N, 'remote': N, 'new_added': N, 'updated': N, 'skipped': N}
    """
    csv_path = csv_path or find_latest_csv()
    print(f"[*] 解析 CSV: {csv_path}")
    print(f"[*] 模式：{'增量（only_new=True）' if only_new else '全量 upsert'}")

    init_db()

    upsert_company(
        slug=COMPANY_SLUG,
        display_name=COMPANY_NAME,
        main_line=MAIN_LINE,
        ats_platform="feishu_sheet",
        ats_handle="ScdYsiuRMhTjzFt0rdXcCyshnom",
        careers_url=FEISHU_SHEET_URL,
        notes="飞书共享内推池。无公司名/联系人，按行号回飞书表对接分享人。每行 referral_id 即飞书行号。",
    )

    jobs = parse_csv(csv_path)
    print(f"[*] 解析到 {len(jobs)} 个有效岗位")

    matched = sum(1 for j in jobs if j["matches_target"])
    remote = sum(1 for j in jobs if j["is_remote"])
    print(f"    其中匹配目标方向（后端/合约）：{matched}")
    print(f"    其中远程：{remote}")

    # 入库（增量 vs 全量）
    existing = _existing_referral_ids() if only_new else set()
    new_added = 0
    updated = 0
    skipped = 0
    new_matched = 0  # 新增岗位中命中目标方向的数量
    new_match_samples: list[dict] = []
    for j in jobs:
        ext_id = j["external_id"]
        if only_new and ext_id in existing:
            skipped += 1
            continue
        upsert_job(j)
        if ext_id in existing:
            updated += 1
        else:
            new_added += 1
            if j["matches_target"]:
                new_matched += 1
                if len(new_match_samples) < 10:
                    new_match_samples.append(j)

    if only_new:
        print(
            f"[*] 增量入库完成：新增 {new_added}（命中目标 {new_matched}），"
            f"跳过已有 {skipped}"
        )
        if new_match_samples:
            print("    新增的命中目标岗位（最多 10 条）:")
            for j in new_match_samples:
                print(f"      #{j['referral_id']:<4} | {j['team']:<10} | {j['title']}")
    else:
        print(f"[*] 全量入库完成：upsert {len(jobs)} 行")

    # 按企业类型 + matches 统计
    from collections import Counter
    industry_match = Counter()
    industry_total = Counter()
    for j in jobs:
        industry_total[j["team"]] += 1
        if j["matches_target"]:
            industry_match[j["team"]] += 1
    print("\n=== 各企业类型 命中目标方向数 / 总数（基于全量 CSV）===")
    for industry, n in industry_total.most_common():
        m = industry_match.get(industry, 0)
        print(f"  {industry:<12}  {m:>3} / {n:>3}")

    return {
        "parsed": len(jobs),
        "matched": matched,
        "remote": remote,
        "new_added": new_added,
        "updated": updated,
        "skipped": skipped,
        "new_matched": new_matched,
    }


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--csv", type=Path, default=None, help="指定 cells.csv 路径")
    ap.add_argument("--only-new", action="store_true",
                    help="增量模式：只插入新行（基于 referral_id），跳过已存在的")
    args = ap.parse_args()
    run(args.csv, only_new=args.only_new)


if __name__ == "__main__":
    main()
