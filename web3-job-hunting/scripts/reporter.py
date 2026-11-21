"""生成中文 JD 汇总报告（Markdown）。

输出文件：reports/jd_summary.md

格式：
- 顶部：抓取统计 + 工作语言分布 + 时效性分布
- 「立即可投」TOP 清单：按发布时间倒序，只列 ≤90 天的近期岗位
- 主线 A / B / C / D 分组，每组内按发布时间倒序
- 每个岗位卡片：发布时间 + 多久前发布 + 新鲜度标记 + 完整字段 + 中文 JD 摘要

设计要点：
- main_lines 不再 hard-code "A,B"，自动遍历 DB 中所有 main_line
- 解析 posted_at 支持多种格式（毫秒时间戳 / ISO8601 / 带时区）
- 新鲜度分级：≤30天 = 🟢 新发布；30-90天 = 🟡 较新；90-365天 = 🟠 偏旧；>365 天 = 🔴 1+年（不投）
- 列表顺序：先 🟢/🟡，再 🟠/🔴；同级内按发布时间倒序
"""

from __future__ import annotations

import sys
from collections import defaultdict
from datetime import datetime, timezone
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))
from storage import fetch_target_jobs, get_conn, stats  # noqa: E402

REPORT_PATH = Path(__file__).resolve().parent.parent / "reports" / "jd_summary.md"
# 完整 JD 展示长度上限（3000 字符约等于 600-800 字中文，足够看清业务全貌）
MAX_DESC_PREVIEW = 3000
USER_KNOWN = {"Java", "Python", "Golang", "Solidity"}

# 报告主列表只优先展示 primary；secondary 沉到附录
ROLE_TIER_LABEL = {
    "primary": "⭐ 主投（后端/高级后端/智能合约）",
    "secondary": "📎 其他相关（Staff/全栈/协议等，靠后）",
}

# 中文字符判定：用于在 description_zh 缺失时判断 description_text 是否已经是中文
_CJK_RE = __import__("re").compile(r"[\u4e00-\u9fff]")


def _is_chinese_text(text: str | None, threshold: float = 0.15) -> bool:
    """中文字符占比 > threshold 视为中文（飞书/TG/GitHub 的中文 JD 检测）。"""
    if not text:
        return False
    cn = len(_CJK_RE.findall(text))
    return cn / max(len(text), 1) > threshold


def _get_chinese_jd(j: dict, max_len: int = MAX_DESC_PREVIEW) -> tuple[str, str]:
    """统一获取中文 JD，返回 (jd_text, source_label)。

    优先级：
      1. description_zh (已翻译/已是中文)
      2. description_text 且本身是中文（飞书/TG/GitHub 原生中文）
      3. description_text（英文原文，标注"未翻译"提示）
      4. description（裸字段兜底）

    source_label 用于让读者知道这段 JD 是中文还是英文未翻译。
    """
    zh = (j.get("description_zh") or "").strip()
    if zh and _is_chinese_text(zh):
        jd, label = zh, "中文翻译"
    else:
        dt = (j.get("description_text") or "").strip()
        if dt and _is_chinese_text(dt):
            jd, label = dt, "原文（中文）"
        elif dt:
            jd, label = dt, "⚠️ 英文原文（未翻译 — 运行 `python scripts/translator.py` 可补中文）"
        else:
            d = (j.get("description") or "").strip()
            jd = d
            label = "原文（中文）" if _is_chinese_text(d) else "⚠️ 英文原文（未翻译）" if d else "（无 JD 内容）"
    if jd and len(jd) > max_len:
        jd = jd[:max_len] + "\n\n…（内容截断，全文见申请链接）"
    return jd, label

# 飞书内推时效性窗口：超过这个天数的岗位不渲染（但仍入库）
# 内推岗位"需求更新时间"= 分享人最近一次维护该岗位的时间
# 超过 30 天通常意味着分享人已不再 push 这个岗位
FEISHU_FRESH_DAYS = 30

MAIN_TITLES = {
    "A": "公链 / Layer2 SDK & DevTool 后端",
    "B": "大型 CEX Web3 部门 + Launchpad 业务合约",
    "C": "强业务（DeFi 协议方 + 钱包托管 + NFT）",
    "D": "中文友好 CEX（华人创始 + 全中文）",
    "E": "L1 / L2 公链（华人贡献者活跃）",
    "T": "📨 Telegram 公开频道（实时招聘流）",
    "X": "🔍 web3.career 关键词全站搜（不绑公司）",
    "G": "📥 GitHub 招聘 issue 仓库（中文 Web3 聚合）",
}

# Telegram + 关键词搜 + GitHub issue 的新鲜度阈值（用户选 14 天）
TG_FRESH_DAYS = 14
W3C_SEARCH_FRESH_DAYS = 14
GH_FRESH_DAYS = 14


# ---------------- 时间解析 + 新鲜度分级 ---------------- #

def parse_posted_at(p) -> datetime | None:
    """支持 5 种格式，统一返回 tz-aware datetime（缺省视为 UTC）：
       1) None / 空串 → None
       2) 毫秒时间戳整数 / 字符串数字（Lever 的 createdAt）
       3) ISO8601 含时区（Greenhouse/Ashby/web3.career schema.org）
       4) 'YYYY-MM-DD HH:MM:SS +0100'（web3.career schema.org 的另一种）
       5) 'YYYY-MM-DD'（飞书 Excel 序号转换出来的格式，无时区）
    """
    if not p:
        return None
    s = str(p).strip()
    # 毫秒时间戳
    if s.isdigit():
        try:
            ts = int(s)
            return datetime.fromtimestamp(ts / 1000, tz=timezone.utc)
        except (ValueError, OSError):
            return None
    dt = None
    try:
        dt = datetime.fromisoformat(s.replace("Z", "+00:00"))
    except ValueError:
        try:
            dt = datetime.strptime(s, "%Y-%m-%d %H:%M:%S %z")
        except ValueError:
            return None
    # 兜底：naive → 补 UTC tz（避免后续比较报错）
    if dt and dt.tzinfo is None:
        dt = dt.replace(tzinfo=timezone.utc)
    return dt


NOW = datetime.now(timezone.utc)


def freshness(dt: datetime | None) -> tuple[str, str]:
    """返回 (emoji 标签, 中文描述)；未知时间也归为偏旧不优先。"""
    if not dt:
        return "⚪", "未知发布时间"
    days = (NOW - dt).days
    if days <= 30:
        return "🟢", f"近 30 天（{days} 天前）"
    if days <= 90:
        return "🟡", f"3 个月内（{days} 天前）"
    if days <= 365:
        return "🟠", f"1 年内（{days} 天前）"
    return "🔴", f"⚠️ 超 1 年（{days} 天前，可能已不在招）"


def role_tier_rank(tier: str | None) -> int:
    return {"primary": 0, "secondary": 1}.get(tier or "secondary", 2)


def sort_jobs_for_user(jobs: list[dict]) -> list[dict]:
    jobs.sort(key=lambda j: (
        role_tier_rank(j.get("role_tier")),
        freshness_rank(parse_posted_at(j.get("posted_at"))),
        -(parse_posted_at(j.get("posted_at")) or datetime.min.replace(tzinfo=timezone.utc)).timestamp(),
    ))
    return jobs


def split_by_tier(jobs: list[dict]) -> tuple[list[dict], list[dict]]:
    primary = [j for j in jobs if j.get("role_tier") == "primary"]
    secondary = [j for j in jobs if j.get("role_tier") != "primary"]
    return primary, secondary


def freshness_rank(dt: datetime | None) -> int:
    """0=最新，4=最旧。"""
    if not dt:
        return 3
    days = (NOW - dt).days
    if days <= 30: return 0
    if days <= 90: return 1
    if days <= 365: return 2
    return 4


# ---------------- 渲染 ---------------- #

def _format_languages(csv: str | None) -> tuple[str, str]:
    if not csv:
        return "（未明确）", "❓ 看 JD 详情判断"
    langs = [l for l in csv.split(",") if l]
    you_have = [l for l in langs if l in USER_KNOWN]
    others = [l for l in langs if l not in USER_KNOWN]
    parts = [f"**{l}**" for l in you_have] + others
    text = " / ".join(parts) if parts else "（未明确）"
    if you_have:
        verdict = f"✅ 可直接投（命中你掌握的 {','.join(you_have)}）"
    elif langs:
        verdict = f"❌ 需要补：{','.join(langs)}"
    else:
        verdict = "❓ 看 JD 详情判断"
    return text, verdict


def render_job_card(j: dict) -> str:
    title_zh = j.get("title_zh") or j.get("title")
    title = j.get("title")
    location = j.get("location") or "-"
    team = j.get("team") or "-"
    workplace = j.get("workplace_type") or "-"
    salary = j.get("compensation") or "-"
    apply_url = j.get("apply_url") or "-"
    lang_text, lang_verdict = _format_languages(j.get("work_languages"))

    dt = parse_posted_at(j.get("posted_at"))
    fresh_emoji, fresh_text = freshness(dt)
    posted_str = dt.strftime("%Y-%m-%d") if dt else "未知"

    jd_text, jd_label = _get_chinese_jd(j)

    return f"""
#### {fresh_emoji} {title_zh}

> 原标题：{title}

| 字段 | 值 |
|---|---|
| **新鲜度** | {fresh_emoji} {fresh_text} |
| 发布时间 | {posted_str} |
| 地点 | {location} |
| 团队 | {team} |
| 办公方式 | {workplace} |
| 薪酬披露 | {salary} |
| 工作语言 | {lang_text} |
| 投递判断 | {lang_verdict} |
| 申请链接 | <{apply_url}> |

<details>
<summary>📄 JD 全文（{jd_label}，点击展开）</summary>

{jd_text}

</details>
"""


def render_feishu_referral_section(referral_jobs: list[dict]) -> list[str]:
    """飞书内推池单独成段：按企业类型分组，列表化展示。

    这一段：
    - 仅渲染「需求更新时间 ≤ FEISHU_FRESH_DAYS（默认 30 天）」的岗位
    - 同时展示「时效性分布」让用户看到全量数据时效结构
    - 显示「行号」（referral_id），用户带行号去找分享人即可拿到公司+联系人
    - 按企业类型分桶（DEX / Wallet / 交易所 / 项目方 / Defi / 未分类 等）
    """
    lines = []
    lines.append("\n## ⭐ 飞书内推岗位池（按行号找分享人对接）\n")
    if not referral_jobs:
        lines.append("> 暂无飞书内推数据。先跑 `python scripts/feishu_extract.py --headed` 抓数据。\n")
        return lines

    matched_all = [j for j in referral_jobs if j.get("matches_target")]

    # ---- 时效性分布（基于「需求更新时间」/ posted_at） ----
    # 注意：飞书表里"需求更新时间"是分享人最近一次更新岗位的时间，超过 N 天 = 大概率已经不在 push
    age_buckets = {"≤30 天": 0, "30-90 天": 0, "90-365 天": 0, "超过 1 年": 0, "未知": 0}
    age_buckets_match = {"≤30 天": 0, "30-90 天": 0, "90-365 天": 0, "超过 1 年": 0, "未知": 0}
    fresh_jobs = []
    for j in referral_jobs:
        dt = parse_posted_at(j.get("posted_at"))
        if not dt:
            bucket = "未知"
        else:
            days = (NOW - dt).days
            if days <= FEISHU_FRESH_DAYS:
                bucket = "≤30 天"
                if j.get("matches_target"):
                    fresh_jobs.append(j)
            elif days <= 90:
                bucket = "30-90 天"
            elif days <= 365:
                bucket = "90-365 天"
            else:
                bucket = "超过 1 年"
        age_buckets[bucket] += 1
        if j.get("matches_target"):
            age_buckets_match[bucket] += 1

    fresh_remote = sum(1 for j in fresh_jobs if j.get("is_remote"))

    lines.append(
        f"> **数据源**：飞书《岗位资源管理对外版》（共 **{len(referral_jobs)}** 行 / 命中目标 **{len(matched_all)}** 个）\n"
        ">\n"
        f"> **本段只渲染「需求更新时间 ≤ {FEISHU_FRESH_DAYS} 天」的岗位**，因为内推岗位的更新时间反映"
        "分享人最近是否还在 push 该岗位 —— 超过 30 天大概率已被搁置。\n"
        ">\n"
        "> ⚠️ 内推表**没有公司名 / 联系人**。每条 `#行号` 是这个表里的编号，挑到喜欢的 → 把行号发给"
        "分享你飞书表的人 → ta 给你具体公司 + HR/内推人 contact"
    )

    # 时效分布表
    lines.append("\n### 全量时效性分布\n")
    lines.append("| 更新时间 | 全部岗位 | 命中目标方向 | 投递建议 |")
    lines.append("|---|---|---|---|")
    advices = {
        "≤30 天": "✅ **本段渲染** — 内推人最近 1 个月内还在维护",
        "30-90 天": "⚠️ 不渲染但保留 — 可主动问内推人是否还在招",
        "90-365 天": "🔴 不渲染 — 大概率已招满或撤岗",
        "超过 1 年": "❌ 不渲染 — 视同失效",
        "未知": "❓ 不渲染 — 数据本身缺失",
    }
    for bucket in ["≤30 天", "30-90 天", "90-365 天", "超过 1 年", "未知"]:
        lines.append(f"| {bucket} | {age_buckets[bucket]} | **{age_buckets_match[bucket]}** | {advices[bucket]} |")

    # 0 个新鲜岗位时给提示并 return
    if not fresh_jobs:
        lines.append(
            f"\n### ⚠️ 当前过去 {FEISHU_FRESH_DAYS} 天内没有命中目标方向的内推岗位\n"
            "\n可能原因 + 应对：\n"
            "\n"
            f"1. **飞书表本身已停更**：飞书表里最新的「需求更新时间」距今超过 {FEISHU_FRESH_DAYS} 天 → 可能分享人不再维护该表，建议直接联系 ta 确认\n"
            "2. **本地 CSV 已过期**：你上次抓飞书是几周前 → 重新跑：\n\n"
            "    ```bash\n"
            "    PLAYWRIGHT_BROWSERS_PATH=/Users/piliepeng/.cache/ms-playwright \\\n"
            "      python scripts/feishu_extract.py --headed\n"
            "    python scripts/feishu_sync.py\n"
            "    python scripts/reporter.py\n"
            "    ```\n"
            "\n"
            f"3. **临时放宽窗口**：改 `scripts/reporter.py` 顶部的 `FEISHU_FRESH_DAYS = {FEISHU_FRESH_DAYS}` 为 90 / 365，重生成报告\n"
        )
        return lines

    lines.append(
        f"\n> 本段显示 **{len(fresh_jobs)}** 个新鲜内推岗位（其中远程 **{fresh_remote}**），按业务类型分组\n"
    )

    matched = fresh_jobs  # 后续渲染只用新鲜的

    # 按企业类型分组 → 在每组内按 posted_at 倒序
    from collections import defaultdict as _dd
    by_industry: dict[str, list[dict]] = _dd(list)
    for j in matched:
        industry = (j.get("team") or "未分类").strip() or "未分类"
        by_industry[industry].append(j)

    # 优先级排序：业务相关排前（与 feishu_sync.normalize_industry 输出对齐）
    INDUSTRY_ORDER = [
        "Wallet", "DeFi", "DEX", "DeFi/DEX", "L1/L2 公链", "CEX",
        "项目方", "数据 / DAO", "AI / SocialFi", "未指定", "未分类",
    ]
    def _industry_key(name: str) -> int:
        try:
            return INDUSTRY_ORDER.index(name)
        except ValueError:
            return 999

    sorted_industries = sorted(by_industry.keys(), key=_industry_key)

    # 顶部统计表
    lines.append("\n### 各业务类型岗位数量\n")
    lines.append("| 业务类型 | 命中岗位数 | 远程数 |")
    lines.append("|---|---|---|")
    for ind in sorted_industries:
        ilist = by_industry[ind]
        ind_remote = sum(1 for j in ilist if j.get("is_remote"))
        lines.append(f"| {ind} | {len(ilist)} | {ind_remote} |")

    # 各业务类型详情
    for ind in sorted_industries:
        ilist = by_industry[ind]
        ilist.sort(
            key=lambda j: -(parse_posted_at(j.get("posted_at")) or datetime.min.replace(tzinfo=timezone.utc)).timestamp()
        )
        lines.append(f"\n### 业务类型：{ind}（{len(ilist)} 个）\n")
        lines.append("| 行号 | 岗位 | 远程? | Base | 薪资 | 语言 | 更新日期 |")
        lines.append("|---|---|---|---|---|---|---|")
        for j in ilist:
            rid = j.get("referral_id", "?")
            title = (j.get("title") or "").strip().replace("|", "/")[:40]
            remote_emoji = "🟢" if j.get("is_remote") else "🔴"
            base = (j.get("location") or "-").replace("|", "/")
            salary = (j.get("compensation") or "-").replace("|", "/")[:20]
            langs = (j.get("work_languages") or "-").replace(",", " / ")
            dt = parse_posted_at(j.get("posted_at"))
            date_s = dt.strftime("%Y-%m-%d") if dt else "未知"
            lines.append(f"| **#{rid}** | {title} | {remote_emoji} | {base} | {salary} | {langs} | {date_s} |")

    # 全部「新鲜」命中岗位都展开完整中文 JD（不限 top 20），按更新时间倒序
    lines.append(
        f"\n### 全部 {len(matched)} 个新鲜内推岗位 — 完整 JD 详情\n"
        "\n> 按更新时间倒序，含完整业务描述 + 联系入口。挑到目标岗位 → 把 `#行号` 发给分享人即可对接。\n"
    )
    matched_sorted = sorted(
        matched,
        key=lambda j: -(parse_posted_at(j.get("posted_at")) or datetime.min.replace(tzinfo=timezone.utc)).timestamp(),
    )
    for j in matched_sorted:
        rid = j.get("referral_id", "?")
        title = (j.get("title") or "").strip()
        ind = j.get("team", "未分类")
        base = j.get("location") or "-"
        salary = j.get("compensation") or "-"
        langs = (j.get("work_languages") or "-").replace(",", " / ")
        remote_emoji = "🟢 远程" if j.get("is_remote") else "🔴 现场"
        dt = parse_posted_at(j.get("posted_at"))
        date_s = dt.strftime("%Y-%m-%d") if dt else "未知"
        jd_text, jd_label = _get_chinese_jd(j)
        lines.append(
            f"\n#### #{rid} — {title}  ({ind})\n\n"
            f"| 字段 | 值 |\n|---|---|\n"
            f"| 业务类型 | {ind} |\n"
            f"| 远程 | {remote_emoji} |\n"
            f"| Base | {base} |\n"
            f"| 薪资 | {salary} |\n"
            f"| 语言 | {langs} |\n"
            f"| 更新日期 | {date_s} |\n"
            f"| 飞书表行 | <https://my.feishu.cn/sheets/ScdYsiuRMhTjzFt0rdXcCyshnom> （第 {rid} 行）|\n\n"
            f"<details><summary>📄 JD 全文（{jd_label}，点击展开）</summary>\n\n{jd_text}\n\n</details>\n"
        )

    return lines


def render_telegram_section(tg_jobs: list[dict]) -> list[str]:
    """Telegram 频道独立成段：按 TG_FRESH_DAYS（14 天）过滤 + 频道分组。"""
    lines = []
    lines.append("\n## 📨 Telegram 公开频道（实时招聘流）\n")
    lines.append(
        f"> 数据源：t.me/s/<channel> 网页镜像（无需登录），命中目标方向 **{len(tg_jobs)}** 个岗位\n"
        f"> 本段只渲染 ≤ **{TG_FRESH_DAYS} 天** 内更新的命中岗位\n"
        f"> 频道帖里 **submit - XXX** = 投递入口，点 apply_url 跳频道原帖按需点 submit 即可\n"
    )

    matched = [j for j in tg_jobs if j.get("matches_target")]
    fresh = []
    for j in matched:
        dt = parse_posted_at(j.get("posted_at"))
        if dt and (NOW - dt).days <= TG_FRESH_DAYS:
            fresh.append(j)

    # 按频道分组
    by_channel: dict[str, list[dict]] = defaultdict(list)
    for j in matched:
        by_channel[j.get("display_name") or j.get("company_slug")].append(j)

    lines.append("\n### 频道概览\n")
    lines.append("| 频道 | 抓到岗位 | 命中目标 | 命中且 ≤14 天 |")
    lines.append("|---|---|---|---|")
    for ch_name, jl in sorted(by_channel.items()):
        ch_fresh = sum(
            1 for j in jl
            if (dt := parse_posted_at(j.get("posted_at")))
            and (NOW - dt).days <= TG_FRESH_DAYS
        )
        ch_total = sum(
            1 for j in tg_jobs
            if (j.get("display_name") or j.get("company_slug")) == ch_name
        )
        lines.append(f"| {ch_name} | {ch_total} | {len(jl)} | **{ch_fresh}** |")

    if not fresh:
        lines.append(
            f"\n> ⚠️ 当前没有 ≤{TG_FRESH_DAYS} 天的命中岗位。"
            f"调宽窗口可改 `reporter.py` 顶部的 `TG_FRESH_DAYS`。\n"
        )
        return lines

    # 立即可投表
    fresh.sort(
        key=lambda j: parse_posted_at(j.get("posted_at")) or datetime.min.replace(tzinfo=timezone.utc),
        reverse=True,
    )
    lines.append(f"\n### ⭐ 近 {TG_FRESH_DAYS} 天内的命中岗位 — 速览表（{len(fresh)} 个）\n")
    lines.append("| 公司 | 业务 | 岗位 | 远程? | 语言 | 更新日期 | 频道原帖 |")
    lines.append("|---|---|---|---|---|---|---|")
    for j in fresh:
        dt = parse_posted_at(j.get("posted_at"))
        date_s = dt.strftime("%Y-%m-%d") if dt else "未知"
        emoji, _ = freshness(dt)
        company = (j.get("team") or "?").replace("|", "/")
        biz = (j.get("employment_type") or "-").replace("|", "/")
        title = (j.get("title") or "").replace("|", "/")[:60]
        langs = (j.get("work_languages") or "-").replace(",", " / ")
        remote = "🟢" if j.get("is_remote") else "❌"
        lines.append(
            f"| **{company}** | {biz} | {title} | {remote} | {langs} | {emoji} {date_s} | <{j.get('apply_url','-')}> |"
        )

    # 完整 JD 展开块（每个岗位含频道原帖的完整内容）
    lines.append(f"\n### 📄 完整 JD 详情（{len(fresh)} 个）\n")
    for j in fresh:
        dt = parse_posted_at(j.get("posted_at"))
        date_s = dt.strftime("%Y-%m-%d") if dt else "未知"
        company = j.get("team") or "?"
        title = (j.get("title") or "").strip()
        langs = (j.get("work_languages") or "-").replace(",", " / ")
        remote = "🟢 远程" if j.get("is_remote") else "❌ 非远程"
        jd_text, jd_label = _get_chinese_jd(j)
        lines.append(
            f"\n#### {company} — {title}\n\n"
            f"| 字段 | 值 |\n|---|---|\n"
            f"| 公司 | {company} |\n"
            f"| 远程 | {remote} |\n"
            f"| 语言 | {langs} |\n"
            f"| 更新日期 | {date_s} |\n"
            f"| 频道原帖 | <{j.get('apply_url','-')}> |\n\n"
            f"<details><summary>📄 频道原帖 / JD 全文（{jd_label}，点击展开）</summary>\n\n{jd_text}\n\n</details>\n"
        )
    return lines


def render_w3c_search_section(w3c_jobs: list[dict]) -> list[str]:
    """web3.career 关键词搜独立成段：按 W3C_SEARCH_FRESH_DAYS（14 天）过滤 + 关键词分组。

    这是最有价值的「发现新公司」数据源，不绑定既有公司池。
    """
    lines = []
    lines.append("\n## 🔍 web3.career 关键词全站搜（不绑公司，发现新雇主）\n")
    lines.append(
        f"> 数据源：web3.career 多关键词搜索聚合（backend / solidity / golang / rust / blockchain / smart contract / java + remote/web3）\n"
        f"> 命中目标方向 **{len(w3c_jobs)}** 个岗位，本段只渲染 ≤ **{W3C_SEARCH_FRESH_DAYS} 天** 内发布的命中岗位\n"
        f"> 这是**发现新雇主**最有价值的数据源 —— 不绑定既有公司池，会自动浮现 long-tail 雇主\n"
    )

    matched = [j for j in w3c_jobs if j.get("matches_target")]
    fresh = []
    for j in matched:
        dt = parse_posted_at(j.get("posted_at"))
        if dt and (NOW - dt).days <= W3C_SEARCH_FRESH_DAYS:
            fresh.append(j)

    # 按真实公司（team 字段）分组统计
    by_company: dict[str, list[dict]] = defaultdict(list)
    for j in matched:
        by_company[j.get("team") or "?"].append(j)

    lines.append(f"\n### 命中目标的公司 Top 15（共 {len(by_company)} 家）\n")
    lines.append("| 公司 | 命中岗位数 |")
    lines.append("|---|---|")
    for comp, jl in sorted(by_company.items(), key=lambda x: -len(x[1]))[:15]:
        lines.append(f"| **{comp}** | {len(jl)} |")

    if not fresh:
        lines.append(
            f"\n> ⚠️ 当前没有 ≤{W3C_SEARCH_FRESH_DAYS} 天的命中岗位。"
            f"web3.career 多数岗位发布日期较老，可调宽窗口（修改 `reporter.py` 顶部 `W3C_SEARCH_FRESH_DAYS`）。\n"
        )
        return lines

    fresh.sort(
        key=lambda j: parse_posted_at(j.get("posted_at")) or datetime.min.replace(tzinfo=timezone.utc),
        reverse=True,
    )
    lines.append(f"\n### ⭐ 近 {W3C_SEARCH_FRESH_DAYS} 天内的命中岗位 — 速览表（{len(fresh)} 个）\n")
    lines.append("| 公司 | 岗位 | 远程? | 薪资 | 语言 | 关键词 | 发布日期 | 链接 |")
    lines.append("|---|---|---|---|---|---|---|---|")
    for j in fresh:
        dt = parse_posted_at(j.get("posted_at"))
        date_s = dt.strftime("%Y-%m-%d") if dt else "未知"
        emoji, _ = freshness(dt)
        company = (j.get("team") or "?").replace("|", "/")
        title = (j.get("title") or "").replace("|", "/")[:55]
        langs = (j.get("work_languages") or "-").replace(",", " / ")
        salary = j.get("compensation") or "-"
        kw = j.get("referral_id") or "-"  # 我们把搜索关键词存在 referral_id
        remote = "🟢" if j.get("is_remote") else "❌"
        lines.append(
            f"| **{company}** | {title} | {remote} | {salary} | {langs} | {kw} | {emoji} {date_s} | <{j.get('apply_url','-')}> |"
        )

    # 完整 JD 展开块
    lines.append(f"\n### 📄 完整 JD 详情（{len(fresh)} 个）\n")
    for j in fresh:
        dt = parse_posted_at(j.get("posted_at"))
        date_s = dt.strftime("%Y-%m-%d") if dt else "未知"
        company = j.get("team") or "?"
        title = (j.get("title") or "").strip()
        langs = (j.get("work_languages") or "-").replace(",", " / ")
        salary = j.get("compensation") or "-"
        remote = "🟢 远程" if j.get("is_remote") else "❌ 非远程"
        jd_text, jd_label = _get_chinese_jd(j)
        lines.append(
            f"\n#### {company} — {title}\n\n"
            f"| 字段 | 值 |\n|---|---|\n"
            f"| 公司 | {company} |\n"
            f"| 远程 | {remote} |\n"
            f"| 薪资 | {salary} |\n"
            f"| 语言 | {langs} |\n"
            f"| 发布日期 | {date_s} |\n"
            f"| 申请链接 | <{j.get('apply_url','-')}> |\n\n"
            f"<details><summary>📄 JD 全文（{jd_label}，点击展开）</summary>\n\n{jd_text}\n\n</details>\n"
        )
    return lines


def render_github_section(gh_jobs: list[dict]) -> list[str]:
    """GitHub 招聘 issue 仓库独立成段：按 GH_FRESH_DAYS（14 天）过滤 + 仓库分组。

    数据特点：
      - 全中文岗位（rebase-network/who-is-hiring）
      - 结构化：标题含 [地点] + 公司业务 + 薪资
      - 含完整联系方式（TG / 微信）
      - issue updated_at = 招聘最近一次有效维护时间
    """
    lines = []
    lines.append("\n## 📥 GitHub 招聘 issue 仓库（中文 Web3 聚合）\n")
    matched = [j for j in gh_jobs if j.get("matches_target")]
    fresh = []
    for j in matched:
        dt = parse_posted_at(j.get("posted_at"))
        if dt and (NOW - dt).days <= GH_FRESH_DAYS:
            fresh.append(j)

    lines.append(
        f"> 数据源：rebase-network/who-is-hiring 等 issue 招聘聚合仓库\n"
        f"> 命中目标方向 **{len(matched)}** 个 issue，本段只渲染 ≤ **{GH_FRESH_DAYS} 天** 内更新的命中岗位\n"
        f"> 这是**中文 Web3 招聘聚合**质量最高的数据源 —— 大多直接附 TG/微信联系方式\n"
    )

    if not fresh:
        lines.append(
            f"\n> ⚠️ 当前没有 ≤{GH_FRESH_DAYS} 天的命中岗位（修改 `reporter.py` 顶部 `GH_FRESH_DAYS` 调宽窗口）。\n"
        )
        return lines

    fresh.sort(
        key=lambda j: parse_posted_at(j.get("posted_at")) or datetime.min.replace(tzinfo=timezone.utc),
        reverse=True,
    )
    lines.append(f"\n### ⭐ 近 {GH_FRESH_DAYS} 天内的命中岗位 — 速览表（{len(fresh)} 个）\n")
    lines.append("| 公司 / 业务 | 岗位 | 远程? | 地点 | 薪资 | 语言 | 更新日期 | 链接 |")
    lines.append("|---|---|---|---|---|---|---|---|")
    for j in fresh:
        dt = parse_posted_at(j.get("posted_at"))
        date_s = dt.strftime("%Y-%m-%d") if dt else "未知"
        emoji, _ = freshness(dt)
        team = (j.get("team") or "?").replace("|", "/")[:30]
        title = (j.get("title") or "").replace("|", "/")[:55]
        loc = (j.get("location") or "-").replace("|", "/")[:15]
        langs = (j.get("work_languages") or "-").replace(",", " / ")
        salary = (j.get("compensation") or "-").replace("|", "/")[:25]
        remote = "🟢" if j.get("is_remote") else "❌"
        lines.append(
            f"| **{team}** | {title} | {remote} | {loc} | {salary} | {langs} | {emoji} {date_s} | <{j.get('apply_url','-')}> |"
        )

    # 完整 JD 详情（含联系方式 / TG / 微信）
    lines.append(f"\n### 📄 完整 JD 详情（{len(fresh)} 个，含联系方式）\n")
    for j in fresh:
        dt = parse_posted_at(j.get("posted_at"))
        date_s = dt.strftime("%Y-%m-%d") if dt else "未知"
        team = j.get("team") or "?"
        title = (j.get("title") or "").strip()
        loc = j.get("location") or "-"
        langs = (j.get("work_languages") or "-").replace(",", " / ")
        salary = j.get("compensation") or "-"
        remote = "🟢 远程" if j.get("is_remote") else "❌ 非远程"
        jd_text, jd_label = _get_chinese_jd(j)
        lines.append(
            f"\n#### {team} — {title}\n\n"
            f"| 字段 | 值 |\n|---|---|\n"
            f"| 公司/业务 | {team} |\n"
            f"| 远程 | {remote} |\n"
            f"| 地点 | {loc} |\n"
            f"| 薪资 | {salary} |\n"
            f"| 语言 | {langs} |\n"
            f"| 更新日期 | {date_s} |\n"
            f"| Issue 链接 | <{j.get('apply_url','-')}> |\n\n"
            f"<details><summary>📄 JD 全文（{jd_label}，含联系方式，点击展开）</summary>\n\n{jd_text}\n\n</details>\n"
        )

    lines.append(
        f"\n> 💡 联系方式（TG / 微信 / 邮箱）在上面每个岗位的 JD 全文里，搜 `联系方式` / `TG` / `微信` 关键词即可定位。\n"
    )
    return lines


def render_quick_apply_table(jobs: list[dict], max_n: int = 30) -> list[str]:
    """🟢🟡：近 90 天内的 primary 主投岗位 → 一张大表。"""
    primary_jobs, _ = split_by_tier(jobs)
    fresh_jobs = [
        j for j in primary_jobs
        if freshness_rank(parse_posted_at(j.get("posted_at"))) <= 1
    ]
    fresh_jobs.sort(
        key=lambda j: parse_posted_at(j.get("posted_at")) or datetime.min.replace(tzinfo=timezone.utc),
        reverse=True,
    )
    lines = []
    lines.append("\n## ⭐⭐⭐ 立即可投：近 90 天内发布的主投岗位\n")
    lines.append(
        f"> 共 **{len(fresh_jobs)}** 个（仅 `primary`：后端/高级后端/智能合约；"
        f"🟢 = ≤30 天，🟡 = ≤90 天）。架构师/Infra/中间件等已排除。\n"
    )
    lines.append("> 📌 **日常协作请优先看** [`reports/digest/LATEST.md`](digest/LATEST.md)（按日期的最新岗位摘要）\n")
    if not fresh_jobs:
        lines.append("> （暂无近期发布岗位）\n")
        return lines
    lines.append("| 新鲜度 | 公司 | 岗位（中文）| 语言 | 发布日期 | 链接 |")
    lines.append("|---|---|---|---|---|---|")
    for j in fresh_jobs[:max_n]:
        dt = parse_posted_at(j.get("posted_at"))
        emoji, _ = freshness(dt)
        date_s = dt.strftime("%Y-%m-%d") if dt else "未知"
        title_zh = (j.get("title_zh") or j.get("title") or "").strip().replace("|", "/")
        company = j.get("display_name") or j.get("company_slug") or "-"
        langs = (j.get("work_languages") or "-").replace(",", " / ")
        # 不再截断标题：信息完整是用户的首要诉求
        lines.append(f"| {emoji} | {company} | {title_zh} | {langs} | {date_s} | <{j.get('apply_url','-')}> |")
    if len(fresh_jobs) > max_n:
        lines.append(f"\n> 还有 {len(fresh_jobs) - max_n} 个新鲜岗位，详见下方主线分组（每个岗位都附完整中文 JD）。\n")
    return lines


# ---------------- 主流程 ---------------- #

def run() -> None:
    REPORT_PATH.parent.mkdir(parents=True, exist_ok=True)
    s = stats()
    with get_conn() as conn:
        rows = conn.execute("SELECT * FROM companies").fetchall()
    companies = {r["slug"]: dict(r) for r in rows}
    all_jobs = [dict(j) for j in fetch_target_jobs()]

    # 给每个 job 注入 display_name（quick apply 表要用）
    for j in all_jobs:
        j["display_name"] = companies.get(j["company_slug"], {}).get("display_name", j["company_slug"])

    # 拆分多个数据源
    referral_jobs = [j for j in all_jobs if j.get("source") == "feishu_referral"]
    telegram_jobs = [j for j in all_jobs if j.get("source") == "telegram"]
    w3c_search_jobs = [j for j in all_jobs if j.get("source") == "web3career_search"]
    github_jobs = [j for j in all_jobs if j.get("source") == "github_issues"]
    # 主流 ATS 抓取（按公司分组的传统流程）
    jobs = [
        j for j in all_jobs
        if j.get("source") not in ("feishu_referral", "telegram", "web3career_search", "github_issues")
    ]

    # 时效性统计（仅 ATS，飞书内推不参与时效）
    fresh_count = {0: 0, 1: 0, 2: 0, 3: 0, 4: 0}
    for j in jobs:
        fresh_count[freshness_rank(parse_posted_at(j.get("posted_at")))] += 1

    # 按主线 → 公司分组（仅 ATS）
    grouped: dict[str, dict[str, list[dict]]] = defaultdict(lambda: defaultdict(list))
    for j in jobs:
        grouped[j["main_line"]][j["company_slug"]].append(j)

    lines = []
    lines.append(f"# Web3 后端 / 智能合约 — JD 汇总报告\n")
    lines.append(f"> 生成时间：{datetime.now().strftime('%Y-%m-%d %H:%M:%S')}\n")
    lines.append(
        f"> 📌 **日常主阅读**：[`reports/digest/LATEST.md`](digest/LATEST.md) — 仅近 30 天主投方向岗位\n"
    )
    lines.append(
        f"> 数据来源：\n"
        f"> - **ATS 抓取**：{s['total_companies'] - 1} 家公司官方 Greenhouse / Lever / Ashby + web3.career 聚合站\n"
        f"> - **飞书内推**：《岗位资源管理对外版》共 {len(referral_jobs)} 行匹配岗位（按行号回飞书表对接分享人）\n"
    )

    ats_target = len(jobs)
    ats_primary = sum(1 for j in jobs if j.get("role_tier") == "primary")
    ats_remote = sum(1 for j in jobs if j.get("is_remote"))
    referral_target = len(referral_jobs)
    referral_primary = sum(1 for j in referral_jobs if j.get("role_tier") == "primary")
    referral_remote = sum(1 for j in referral_jobs if j.get("is_remote"))
    tg_target = len(telegram_jobs)
    tg_primary = sum(1 for j in telegram_jobs if j.get("role_tier") == "primary")
    tg_remote = sum(1 for j in telegram_jobs if j.get("is_remote"))
    w3c_target = len(w3c_search_jobs)
    w3c_primary = sum(1 for j in w3c_search_jobs if j.get("role_tier") == "primary")
    w3c_remote = sum(1 for j in w3c_search_jobs if j.get("is_remote"))
    gh_target = len(github_jobs)
    gh_primary = sum(1 for j in github_jobs if j.get("role_tier") == "primary")
    gh_remote = sum(1 for j in github_jobs if j.get("is_remote"))

    # 动态算各数据源总数（不硬编码）
    with get_conn() as _c:
        def _src_total(src):
            return _c.execute(
                "SELECT COUNT(*) AS n FROM jobs WHERE source=?", (src,)
            ).fetchone()["n"]
        feishu_total = _src_total("feishu_referral")
        tg_total = _src_total("telegram")
        w3c_total = _src_total("web3career_search")
        gh_total = _src_total("github_issues")
    ats_total = s["total_jobs"] - feishu_total - tg_total - w3c_total - gh_total
    # 真实 ATS 公司数（剔除虚拟数据源公司：飞书池 + telegram 频道 + web3career 搜 + github 仓库）
    virtual_companies = sum(
        1 for slug in companies
        if slug.startswith(("_tg_", "_w3c_", "_gh_")) or slug == "feishu"
    )
    real_ats_companies = s["total_companies"] - virtual_companies

    # —— 一、抓取概览 ——
    lines.append("\n## 一、抓取概览\n")
    lines.append("| 数据源 | 公司数 | 总岗位 | 命中目标 | 主投 primary | 其中远程 |")
    lines.append("|---|---|---|---|---|---|")
    lines.append(f"| ATS 抓取 | {real_ats_companies} | {ats_total} | **{ats_target}** | **{ats_primary}** | {ats_remote} |")
    lines.append(f"| 飞书内推 | 1（共享池）| {feishu_total} | **{referral_target}** | **{referral_primary}** | {referral_remote} |")
    if tg_total:
        lines.append(f"| 📨 Telegram 频道 | {sum(1 for s_ in companies if s_.startswith('_tg_'))} | {tg_total} | **{tg_target}** | **{tg_primary}** | {tg_remote} |")
    if w3c_total:
        lines.append(f"| 🔍 web3.career 关键词搜 | 多公司聚合 | {w3c_total} | **{w3c_target}** | **{w3c_primary}** | {w3c_remote} |")
    if gh_total:
        lines.append(f"| 📥 GitHub 招聘 issue | {sum(1 for s_ in companies if s_.startswith('_gh_'))} | {gh_total} | **{gh_target}** | **{gh_primary}** | {gh_remote} |")
    grand_target = ats_target + referral_target + tg_target + w3c_target + gh_target
    grand_primary = ats_primary + referral_primary + tg_primary + w3c_primary + gh_primary
    grand_remote = ats_remote + referral_remote + tg_remote + w3c_remote + gh_remote
    lines.append(f"| **合计** | - | - | **{grand_target}** | **{grand_primary}** | {grand_remote} |\n")

    lines.append("\n### ATS 抓取 - 各公司分布\n")
    lines.append("| 公司 | 抓取岗位数 | 目标方向匹配 |")
    lines.append("|---|---|---|")
    for name, info in s["per_company"].items():
        if name == "飞书内推岗位池":
            continue  # 单独成段
        lines.append(f"| {name} | {info['total']} | {info['target']} |")

    # —— 二、时效性分布（新增！）——
    lines.append("\n## 二、时效性分布（按发布时间）\n")
    lines.append("> ⚠️ CEX 公司（如 Binance）经常把岗位长期挂着，1-4 年前的「在招」岗位可能 HR 已不再积极看简历。**优先投 🟢🟡**。\n")
    lines.append("| 新鲜度 | 含义 | 数量 | 投递建议 |")
    lines.append("|---|---|---|---|")
    lines.append(f"| 🟢 | 近 30 天发布 | **{fresh_count[0]}** | ⭐ 立即投，HR 正在积极看 |")
    lines.append(f"| 🟡 | 30-90 天发布 | **{fresh_count[1]}** | ✅ 可投，HR 还在筛 |")
    lines.append(f"| 🟠 | 90-365 天发布 | **{fresh_count[2]}** | ⚠️ 谨慎投，可能已挑到合适人选 |")
    lines.append(f"| 🔴 | 超 1 年 | **{fresh_count[4]}** | ❌ 不建议投，可能 HR 早就不维护 |")
    lines.append(f"| ⚪ | 未知发布时间 | **{fresh_count[3]}** | ❓ 主要是 web3.career 抓的，按 🟡 处理 |")

    # —— 三、工作语言分布（仅 primary 主投岗位）——
    lang_counter: dict[str, int] = {}
    you_can = you_cannot = unknown = 0
    primary_ats = [j for j in jobs if j.get("role_tier") == "primary"]
    for j in primary_ats:
        langs = [l for l in (j.get("work_languages") or "").split(",") if l]
        for l in langs:
            lang_counter[l] = lang_counter.get(l, 0) + 1
        if not langs:
            unknown += 1
        elif set(langs) & USER_KNOWN:
            you_can += 1
        else:
            you_cannot += 1
    lines.append("\n## 三、工作语言分布（仅 primary 主投岗位）\n")
    lines.append("> 用户掌握：**Java / Python / Golang / Solidity**\n")
    lines.append("| 语言 | 命中岗位数 | 是否你已掌握 |")
    lines.append("|---|---|---|")
    for lang, cnt in sorted(lang_counter.items(), key=lambda x: -x[1]):
        mark = "✅ 是" if lang in USER_KNOWN else "  否"
        lines.append(f"| {lang} | {cnt} | {mark} |")
    lines.append("")
    lines.append(f"- 🟢 你能直接投：**{you_can}** 个")
    lines.append(f"- 🔴 不能直接投（需要补 Rust/Move/C++ 等）：**{you_cannot}** 个")
    lines.append(f"- ⚪ 未明确语言要求：**{unknown}** 个")

    # —— 四、立即可投清单（仅 ATS 抓取的） ——
    lines.extend(render_quick_apply_table(jobs))

    # —— 飞书内推池（独立成段，不参与时效性筛选） ——
    lines.extend(render_feishu_referral_section(referral_jobs))

    # —— Telegram 频道（按 14 天阈值过滤）——
    if telegram_jobs:
        lines.extend(render_telegram_section(telegram_jobs))

    # —— web3.career 关键词搜（按 14 天阈值过滤）——
    if w3c_search_jobs:
        lines.extend(render_w3c_search_section(w3c_search_jobs))

    # —— GitHub 招聘 issue 仓库（按 14 天阈值过滤）——
    if github_jobs:
        lines.extend(render_github_section(github_jobs))

    # —— 五、按主线分组（先把"活跃公司"按主线渲染，"死火公司"独立成段）——
    # 活跃判断：公司至少有 1 个 ≤ 90 天的岗位（freshness_rank ≤ 1）
    def latest_dt(jlist: list[dict]) -> datetime | None:
        dts = [parse_posted_at(j.get("posted_at")) for j in jlist]
        dts = [d for d in dts if d]
        return max(dts) if dts else None

    def is_active(jlist: list[dict]) -> bool:
        return any(freshness_rank(parse_posted_at(j.get("posted_at"))) <= 1 for j in jlist)

    active_groups: dict[str, dict[str, list[dict]]] = defaultdict(dict)
    secondary_pool: list[dict] = []
    inactive_companies: list[tuple[str, str, list[dict]]] = []
    for main_line in sorted(grouped.keys()):
        for slug, jlist in grouped[main_line].items():
            primary_list, secondary_list = split_by_tier(jlist)
            secondary_pool.extend(secondary_list)
            if is_active(jlist):
                if primary_list:
                    active_groups[main_line][slug] = sort_jobs_for_user(primary_list)
            else:
                inactive_companies.append((main_line, slug, jlist))

    section_idx = 5
    for main_line in sorted(active_groups.keys()):
        title = MAIN_TITLES.get(main_line, f"未知主线 {main_line}")
        lines.append(f"\n## {_zh_num(section_idx)}、主线 {main_line}：{title}（活跃公司 · 仅 primary）\n")
        section_idx += 1
        if not active_groups[main_line]:
            lines.append("> 该主线下暂无 primary 主投岗位（Staff/架构师等已移至附录）。\n")
            continue
        # 公司按"最新发布时间"倒序（最近活跃的在前）
        company_items = sorted(
            active_groups[main_line].items(),
            key=lambda x: -(latest_dt(x[1]) or datetime.min.replace(tzinfo=timezone.utc)).timestamp(),
        )
        for slug, jlist in company_items:
            company = companies.get(slug, {})
            ldt = latest_dt(jlist)
            ldt_s = ldt.strftime("%Y-%m-%d") if ldt else "未知"
            ldays = (NOW - ldt).days if ldt else None
            lines.append(f"### {company.get('display_name', slug)} （{len(jlist)} 个目标岗位 · 最新发布 {ldt_s}{f' · {ldays} 天前' if ldays is not None else ''}）\n")
            lines.append(f"- ATS 平台：{company.get('ats_platform')}（句柄：`{company.get('ats_handle')}`）")
            lines.append(f"- 招聘主页：<{company.get('careers_url', '-')}>")
            lines.append(f"- 备注：{company.get('notes', '-')}\n")
            for j in jlist:
                lines.append(render_job_card(j))

    # —— secondary 附录：Staff/全栈/协议等，不作为主推送 ——
    if secondary_pool:
        lines.append(f"\n## {_zh_num(section_idx)}、📎 附录：其他相关岗位（非主投，靠后参考）\n")
        section_idx += 1
        lines.append(
            "> 以下岗位仍属后端/合约大类，但职级或方向为 Staff/Principal/全栈/协议等，"
            "**不在日常 digest 推送**，仅作备查。\n"
        )
        sort_jobs_for_user(secondary_pool)
        lines.append("| 公司 | 岗位 | 职级 | 发布日期 | 链接 |")
        lines.append("|---|---|---|---|---|")
        for j in secondary_pool[:80]:
            dt = parse_posted_at(j.get("posted_at"))
            date_s = dt.strftime("%Y-%m-%d") if dt else "未知"
            company = j.get("display_name") or j.get("company_slug")
            title = (j.get("title_zh") or j.get("title") or "").strip().replace("|", "/")
            lines.append(
                f"| {company} | {title} | {j.get('role_tier', '-')} | {date_s} | <{j.get('apply_url','-')}> |"
            )
        if len(secondary_pool) > 80:
            lines.append(f"\n> 还有 {len(secondary_pool) - 80} 个 secondary 岗位未列出。\n")

    # —— "⚠️ 仅参考"段：长期未更新 / 死火公司 ——
    if inactive_companies:
        lines.append(f"\n## {_zh_num(section_idx)}、⚠️ 仅参考：长期未更新 / 死火公司\n")
        section_idx += 1
        lines.append(
            "> 这些公司在 web3.career / Ashby / Lever 上的所有岗位都已发布超过 90 天，"
            "**HR 大概率不再积极看简历**。建议：\n"
            ">\n"
            "> 1. **不要直接投这里的岗位** —— 投了会石沉大海\n"
            "> 2. **去 LinkedIn 搜公司名 + 'Engineering Manager' / 'Backend Lead'**，找在职员工 DM 探虚实\n"
            "> 3. **去 Twitter/X 搜 `公司名 hiring`**，看团队近期是否在主动 push 招聘\n"
            "> 4. 同时在 [`backend_engineer_4weeks.md`](backend_engineer_4weeks.md) 的「业务学习」部分继续读他们的源码\n"
        )
        # 先按"主线 + 最新发布时间"排序
        inactive_companies.sort(
            key=lambda x: (x[0], -(latest_dt(x[2]) or datetime.min.replace(tzinfo=timezone.utc)).timestamp())
        )
        lines.append("| 公司 | 主线 | 抓到的岗位数 | 最新发布日期 | 距今天数 | 投递建议 | 替代行动 |")
        lines.append("|---|---|---|---|---|---|---|")
        for main_line, slug, jlist in inactive_companies:
            company = companies.get(slug, {})
            ldt = latest_dt(jlist)
            ldt_s = ldt.strftime("%Y-%m-%d") if ldt else "未知"
            ldays = (NOW - ldt).days if ldt else None
            ldays_s = f"{ldays} 天" if ldays is not None else "未知"
            verdict = "❌ 不投（明显死火）" if ldays and ldays > 365 else "⚠️ 谨慎"
            action = f"LinkedIn 搜「{company.get('display_name', slug)} engineering manager」"
            lines.append(
                f"| **{company.get('display_name', slug)}** | {main_line} | {len(jlist)} | {ldt_s} | {ldays_s} | {verdict} | {action} |"
            )
        lines.append("")
        # 折叠区列出每家死火公司具体岗位（不展开 JD 摘要，只列标题+链接）
        for main_line, slug, jlist in inactive_companies:
            company = companies.get(slug, {})
            lines.append(f"<details>\n<summary>{company.get('display_name', slug)} — {len(jlist)} 个老岗位（点击展开标题清单）</summary>\n")
            jlist.sort(key=lambda j: -(parse_posted_at(j.get("posted_at")) or datetime.min.replace(tzinfo=timezone.utc)).timestamp())
            for j in jlist:
                dt = parse_posted_at(j.get("posted_at"))
                emo, _ = freshness(dt)
                date_s = dt.strftime("%Y-%m-%d") if dt else "未知"
                title = (j.get("title_zh") or j.get("title") or "").strip()
                lines.append(f"- {emo} `{date_s}` — {title} — <{j.get('apply_url','-')}>")
            lines.append("\n</details>\n")

    # —— 手动跟踪清单（无 ATS / API 不通的强匹配公司）——
    lines.append(f"\n## {_zh_num(section_idx)}、🔖 手动跟踪清单（无 ATS，需要定期人工查）\n")
    section_idx += 1
    lines.append(
        "> 这些公司**业务方向极度匹配你（后端 / 合约 / 中文友好）**，但没有公开 ATS API，"
        "脚本抓不到。建议每周打开一次他们的招聘入口看新岗位。\n"
    )
    lines.append("| 公司 | 业务匹配度 | 投递入口 | 备注 |")
    lines.append("|---|---|---|---|")
    lines.append(
        "| **PancakeSwap** | ⭐⭐⭐ | hiring@pancakeswap.com<br>"
        "<https://docs.pancakeswap.finance/welcome-to-pancakeswap/about-us/team/become-a-chef> | "
        "越南/华人主导 DEX，目前明确在招 **Sr Backend (TS+Rust)** + **Sr Solidity** + **DevOps**，远程，邮件投 |"
    )
    lines.append(
        "| **KuCoin** | ⭐⭐ | <https://www.kucoin.com/join-us><br>"
        "<https://sc.linkedin.com/company/kucoin/jobs> | "
        "新加坡华人 CEX，自有招聘页 + LinkedIn，**LinkedIn 全球搜更准**（不要被默认香港地区限制） |"
    )
    lines.append(
        "| **Ava Labs**（工程岗）| ⭐⭐ | <https://job-boards.greenhouse.io/avalabs> | "
        "Ashby 句柄 `ava-labs` 只露了 4 个非工程岗；**真正的 Senior/Staff Backend Institutional Custody 在 Greenhouse `avalabs`**（无开放 API） |"
    )
    lines.append(
        "| **Pagoda（NEAR）实时岗** | ⭐⭐ | <https://careers.near.org/companies/pagoda> | "
        "我已通过 web3.career 抓到 7 个老岗位（2023 年），实时新岗位需去这里查 |"
    )
    lines.append(
        "| **SushiSwap** | ⭐ | <https://jobs.sequoiacap.com/jobs/sushiswap> | "
        "华人贡献者活跃但渠道不固定，主要靠 LinkedIn |"
    )
    lines.append(
        "| **Balancer** | ⭐ | <https://wellfound.com/company/balancer-labs-1/jobs> | "
        "目前 0 岗位，留意未来开放 |"
    )
    lines.append("\n> 💡 **建议节奏**：把这张表加到日历，每周一上午 10 分钟刷一遍。\n")

    # —— 末尾使用建议 ——
    lines.append("\n---\n")
    lines.append(f"## {_zh_num(section_idx)}、下一步使用建议\n")
    lines.append("1. **日常先看** [`reports/digest/LATEST.md`](digest/LATEST.md)：仅近 30 天主投方向；")
    lines.append("2. **再扫「⭐⭐⭐ 立即可投」**：那些是 HR 真在筛的 primary 岗；")
    lines.append("3. 同一家公司只投 1 个最匹配的岗位（CEX 重复投会被反感）；")
    lines.append("4. 针对每个 JD 写 Gap List：列出我现在的能力 vs JD 要求，差距用 1-2 周内补足；")
    lines.append("5. 简历针对每家做 1-2 处重写：把 Web2 项目用 JD 关键词重新包装；")
    lines.append("6. 内推：在 Telegram「Web3 中文招聘」群、X 上搜 `公司名 + Hiring + 中文`，找现役员工 DM。")
    lines.append("")

    REPORT_PATH.write_text("\n".join(lines), encoding="utf-8")
    primary_n = sum(1 for j in jobs if j.get("role_tier") == "primary")
    print(f"\nReport written to: {REPORT_PATH}")
    print(f"  total target jobs: {len(jobs)} (primary: {primary_n})")
    print(f"  freshness: 🟢{fresh_count[0]}  🟡{fresh_count[1]}  🟠{fresh_count[2]}  🔴{fresh_count[4]}  ⚪{fresh_count[3]}")
    print(f"Open with: open {REPORT_PATH}")


def _zh_num(n: int) -> str:
    """1→一，2→二 …"""
    m = ["零", "一", "二", "三", "四", "五", "六", "七", "八", "九", "十", "十一", "十二"]
    return m[n] if 0 <= n < len(m) else str(n)


if __name__ == "__main__":
    run()
