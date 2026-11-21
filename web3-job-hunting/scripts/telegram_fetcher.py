"""Telegram 公开频道抓取器（基于 t.me/s/<channel> 网页镜像）。

设计：
- 用 HTTP GET 抓 https://t.me/s/<channel>，无需登录、无需 telethon
- 翻页：?before=<msg_id>，越往前 id 越小
- 解析每条消息的 text + datetime + 链接
- 一条消息可能含多个岗位（如 abetterweb3jobs 频道：「submit - 岗位A」「submit - 岗位B」）
  → 拆成多个 jobs 入库

支持的频道（先支持「abetterweb3jobs 类」格式，后续扩展）：
- abetterweb3jobs：abetterweb3 的纯招聘筛选频道，结构最规范

存储：
- company_slug = "_tg_<channel>"
- external_id = "tg_<channel>_<msg_id>_<job_idx>"
- source = "telegram"
- referral_id = "tg_<channel>/<msg_id>"  (便于在频道里回查原帖)
"""

from __future__ import annotations

import re
import sys
import time
from datetime import datetime, timezone
from html import unescape
from pathlib import Path
from typing import Iterable

import requests

sys.path.insert(0, str(Path(__file__).resolve().parent))
from extract_languages import extract_for_job  # noqa: E402
from fetcher import HEADERS, RAW_DIR, make_session  # noqa: E402
from filters import HARD_EXCLUDE_RE, apply_job_flags, is_remote, matches_target  # noqa: E402
from storage import get_conn, init_db, upsert_company, upsert_job  # noqa: E402


# ============== Telegram 专用过滤 ==============
# 消息体很短（30-200 字符），用频道帖子里的 #标签 + title 做轻量判断
# 因为已经知道是「招聘」频道，不需要 ATS 那种"必须含 web3 关键词"的硬性要求

# 标签级匹配：消息里出现这些 #tag 之一 → 认为是技术岗
TG_TECH_TAGS = {
    # 中文方向
    "后端", "开发", "区块链", "智能合约", "合约", "wallet", "钱包",
    "工程师", "架构师", "全栈",
    # 语言
    "java", "javascript", "python", "rust", "golang", "go", "solidity",
    "typescript", "node", "nodejs",
    # 业务
    "web3", "defi", "dapp", "evm", "trading", "交易", "撮合",
}

# 排除性 tag：消息里只出现这些 tag → 直接排除（哪怕在招聘频道里）
TG_EXCLUDE_TAGS = {
    "运营", "市场", "增长", "bd", "销售", "客服", "招聘",  # 注意 #招聘 是这频道每条都有的元 tag
    "hr", "财务", "合规", "法务", "产品", "pm",
    "设计", "ui", "ux", "ux/ui",
    "前端", "frontend",  # 用户方向是后端
    "移动端", "mobile", "android", "ios",
}


# Title 级技术关键词（含中英文）：title 命中即通过
TG_TECH_TITLE_RE = re.compile(
    r"\b(?:backend|back[- ]end|server|engineer|developer|architect|"
    r"java|golang|rust|solidity|node\.?js|typescript|"
    r"smart\s*contract|blockchain|web3|defi|protocol|wallet|sdet|"
    r"infrastructure|"
    r"trading|matching|derivatives|crypto|"
    r"full[- ]stack)\b"
    r"|后端|开发(?:工程师|者)?|工程师|架构师|区块链|智能合约|合约|"
    r"钱包|链上|交易引擎|撮合|协议",
    re.IGNORECASE,
)

# Telegram 专属补充排除（这些 title 在 ATS 详情页一般会被 NON_WEB3_NOISE 过掉，
# 但 Telegram 短消息没足够 description，需要在 title 层面再加一层）
TG_EXTRA_EXCLUDE_RE = re.compile(
    "|".join([
        # 英文岗位（用 \b 边界）
        r"\bsupport\s+engineer\b",
        r"\bbusiness\s+engineer\b",
        r"\bvulnerability\s+(?:scanner|engineer)\b",
        r"\bsenior\s+pm\b",
        r"\bpm\b",
        r"\bresearcher\b",
        r"\bresearch\s+engineer\b",
        r"\bintern(?:ship)?\b",
        r"\baccelerator\b",
        r"\bspecialist\b",
        r"\bconsultant\b",
        r"\bdirector\b",
        r"\bhead\s+of\b",
        r"\bchief\b",
        r"\bc[eot]o\b",
        r"\bvp\b",
        # 移动端 / 运维：用 \b 或非 \b（汉字邻接情况）
        r"\bflutter\b",
        r"\breact\s*native\b",
        r"\bkotlin\b",
        r"\bswift\b",
        r"(?<![a-z])devops(?![a-z])",
        r"(?<![a-z])sre(?![a-z])",
        # 中文岗位（汉字之间不需要 \b）
        r"运维工程师",
        r"运维专家",
        r"产品(?:经理|急招|岗|策划|运营)",
        r"产品$",
        r"运维",
        r"客服",
        r"售前",
        r"销售",
        r"总监",
        r"主管",
        r"负责人",
        r"跟单",
        r"带货",
        r"商务",
        r"外宣",
        r"新媒体",
        r"社群",
    ]),
    re.IGNORECASE,
)


def _tg_matches_target(title: str, description: str, tags: list[str]) -> bool:
    """Telegram 消息专用过滤（title 主导）：

    1. title 命中 HARD_EXCLUDE（前端/移动/QA/PM/HR/BD/Marketing 等）→ 排除
    2. title 命中技术关键词 → 通过
    3. fallback：通用 matches_target（用 description + tags 拼成的 blob）
    """
    title_lower = (title or "").lower()
    if HARD_EXCLUDE_RE.search(title_lower):
        return False
    if TG_EXTRA_EXCLUDE_RE.search(title_lower):
        return False

    if TG_TECH_TITLE_RE.search(title_lower):
        return True

    # 还兜底 ATS 风格的 description 匹配（处理特殊格式频道）
    blob_desc = (description or "") + " " + " ".join(tags or [])
    return matches_target(title or "", blob_desc)


# ============== 频道配置 ==============

CHANNELS = [
    # ----- 结构化「公司+多 submit」格式 -----
    dict(
        username="abetterweb3jobs",
        display_name="abetterweb3 招聘频道（筛选）",
        notes="abetterweb3 的纯招聘筛选频道，每条消息 = 一家公司 + 多个 submit 岗位",
        format="abw_jobs",
    ),
    dict(
        username="abetterweb3_cn",
        display_name="abetterweb3 (主)",
        notes="abetterweb3 主频道（32.6K），招聘+求职混合，多岗位 submit 格式",
        format="abw_jobs",
    ),

    # ----- 结构化 emoji 字段格式 -----
    # @SmartDeerJobs 已停更 9 个月（最新 2025-08-07），暂时跳过抓取
    # dict(username="SmartDeerJobs", ...),
    dict(
        username="cryptojobslist",
        display_name="CryptoJobsList (国际)",
        notes="💼 岗位 / 🏛️ at 公司 / 🌍 地点 / ✅ Apply → URL 格式",
        format="emoji_kv",
    ),

    # ----- 自由文本（每条整体当一个岗位）-----
    dict(
        username="stablegram",
        display_name="Stablegram",
        notes="自由文本：公司描述 + Position: + 🌎 地点",
        format="freeform",
    ),
    dict(
        username="position999",
        display_name="@position999",
        notes="自由文本，岗位短描述 + 联系方式",
        format="freeform",
    ),
    dict(
        username="cryptojobhunter",
        display_name="Crypto Job Hunter",
        notes="自由文本，含中文岗位汇总（一条可能多岗位但格式不固定）",
        format="freeform",
    ),

    # ----- 用户提到但抓不到的（302/group）-----
    # @web3jobs - 302 (用户名可能错)
    # @DeJob_official_group - group 不是 channel，t.me/s 无法抓
    # @YSight_Talent_web3_cn - 302 (group 或私密)
]

PAGE_LIMIT_PER_CHANNEL = 20  # 每个频道最多翻 20 页（每页 20 条 → 400 条消息）
RAW_TG = RAW_DIR / "telegram"
RAW_TG.mkdir(parents=True, exist_ok=True)


# ============== HTML 解析 ==============

# 单条消息块（用 data-post 锚点切分）
POST_BLOCK_RE = re.compile(
    r'<div class="tgme_widget_message [^"]*"[^>]*data-post="([^"]+)"[^>]*>'
    r'(.*?)(?=<div class="tgme_widget_message [^"]*"[^>]*data-post=|$)',
    re.DOTALL,
)
TEXT_RE = re.compile(
    r'<div class="tgme_widget_message_text[^"]*"[^>]*>(.*?)</div>\s*'
    r'(?:<div class="tgme_widget_message_(?:footer|reply|preview))',
    re.DOTALL,
)
TEXT_RE_FALLBACK = re.compile(
    r'<div class="tgme_widget_message_text[^"]*"[^>]*>(.*?)</div>',
    re.DOTALL,
)
DATETIME_RE = re.compile(r'<time[^>]*datetime="([^"]+)"')


def _html_to_text(html_fragment: str) -> str:
    """把消息 HTML 片段转为纯文本，保留换行。"""
    s = re.sub(r"<br\s*/?>", "\n", html_fragment)
    s = re.sub(r"</p>", "\n", s)
    s = re.sub(r"<[^>]+>", "", s)
    s = unescape(s)
    # 压缩多余空行
    s = re.sub(r"\n{3,}", "\n\n", s)
    return s.strip()


def _extract_external_links(html_fragment: str) -> list[str]:
    """提取消息中真正的外部链接（不要 telegram 内部 #tag 搜索链接）。"""
    links = re.findall(r'href="([^"]+)"', html_fragment)
    return [
        l for l in links
        if l.startswith(("http://", "https://"))
        and "t.me" not in l  # 排除 telegram 自身链接
    ]


def parse_emoji_kv_message(text: str) -> list[dict]:
    """解析 emoji 字段格式（SmartDeerJobs / cryptojobslist 等）。

    SmartDeerJobs 格式：
        🚨 #Recruit
        🦄 公司: MEXC
        👨‍💻 职位: 商务分析总监
        💰 薪资: 10,000 - 20,000 美元/月
        🌍 工作地: 全球
        ⏳ 工作性质: 全职
        🤝 更多信息: <url>

    cryptojobslist 格式：
        💼 Marketing Lead
        🏛️ at Immunefi
        🌍 Remote
        💰 $2k-3k/month
        ✅ Apply → https://...

    返回 list[dict]：每条消息可能是 1-N 个岗位（一般是 1 个）。
    """
    company = ""
    title = ""
    location = ""
    salary = ""
    emp_type = ""
    apply_url_in_msg = ""

    for line in text.split("\n"):
        line = line.strip()
        if not line:
            continue

        # SmartDeer 中文字段
        m = re.match(r"^[^\w]*公司\s*[:：]\s*(.+)$", line)
        if m and not company:
            company = m.group(1).strip()
            continue
        m = re.match(r"^[^\w]*职位\s*[:：]\s*(.+)$", line)
        if m and not title:
            title = m.group(1).strip()
            continue
        m = re.match(r"^[^\w]*薪资\s*[:：]\s*(.+)$", line)
        if m:
            salary = m.group(1).strip()
            continue
        m = re.match(r"^[^\w]*工作地\s*[:：]\s*(.+)$", line)
        if m:
            location = m.group(1).strip()
            continue
        m = re.match(r"^[^\w]*工作性质\s*[:：]\s*(.+)$", line)
        if m:
            emp_type = m.group(1).strip()
            continue

        # cryptojobslist 英文格式
        # 💼 <title>
        m = re.match(r"^💼\s*(.+)$", line)
        if m and not title:
            title = m.group(1).strip()
            continue
        # 🏛️ at <company>
        m = re.match(r"^🏛.*?\bat\s+(.+)$", line)
        if m and not company:
            company = m.group(1).strip()
            continue
        # 🌍 <location>
        m = re.match(r"^🌍\s*(.+)$", line)
        if m and not location:
            location = m.group(1).strip()
            continue
        # 💰 <salary>
        m = re.match(r"^💰\s*(.+)$", line)
        if m and not salary:
            salary = m.group(1).strip()
            continue
        # ✅ Apply → URL
        m = re.search(r"https?://\S+", line)
        if m and not apply_url_in_msg:
            apply_url_in_msg = m.group(0).rstrip(".,)")

    if not title and not company:
        return []

    return [dict(
        company=company,
        business_type="",
        title=title or "(no title)",
        location=location,
        salary=salary,
        emp_type=emp_type,
        apply_url=apply_url_in_msg,
    )]


def parse_freeform_message(text: str) -> list[dict]:
    """自由文本：整条消息当一个岗位。

    适用：stablegram / position999 / cryptojobhunter 等格式不固定的频道。
    title 取启发式：
      - 含 "Position: XXX" → XXX
      - 否则取消息前 80 字符（去 emoji）作为 title
    """
    if not text or len(text) < 10:
        return []

    # Position: <title>
    title = ""
    m = re.search(r"Position[:：]\s*([^\n]+)", text)
    if m:
        title = m.group(1).strip()
    else:
        # 取首行作为 title（去掉 emoji 装饰）
        first_line = text.split("\n", 1)[0].strip()
        # 去前导 emoji / 装饰符
        first_line = re.sub(r"^[\W_]+", "", first_line).strip()
        title = first_line[:100]

    # 公司：取消息中第一段非 title 段的 1 行（启发式，可能不准）
    # → 不强求准，让 _tg_matches_target 去判断方向
    location = ""
    if re.search(r"\b(?:remote|远程|Remote|🌎|🌍)\b", text, re.I):
        location = "Remote"

    salary = ""
    sm = re.search(r"\$[\d,]+\s*-\s*\$?[\d,]+", text)
    if sm:
        salary = sm.group(0)
    elif (sm := re.search(r"[\d,]+\s*-\s*[\d,]+\s*(?:美元|usd|U)", text, re.I)):
        salary = sm.group(0)

    return [dict(
        company="",
        business_type="",
        title=title or "(unparsed)",
        location=location,
        salary=salary,
        emp_type="",
        apply_url="",
    )]


def parse_abw_jobs_message(text: str) -> dict:
    """解析 abetterweb3jobs 格式的消息。

    典型格式：
        #招聘
        Binance - CEX                    ← 第 2 行：公司 - 业务类型
        https://x.com/binance            ← 第 3 行：Twitter（可有可无）
        $BNB: $87.4B                     ← 市值（可有可无）

        #全职 #开发 #后端 #rust #java      ← 标签行
        — posted on May 7                 ← 发布日期
        submit - 岗位A, 地点A
        submit - 岗位B, 地点B
        ...
    """
    lines = [l for l in text.split("\n") if l.strip()]

    company = ""
    business_type = ""
    tags: list[str] = []
    posted_str = ""
    job_lines: list[str] = []

    for i, line in enumerate(lines):
        line_stripped = line.strip()

        # 第一行通常是 #招聘
        if i == 0 and line_stripped.startswith("#"):
            continue
        # 公司 - 业务类型（典型在第 2 行）
        if not company and " - " in line_stripped and not line_stripped.startswith(("#", "—", "submit")):
            parts = line_stripped.split(" - ", 1)
            company = parts[0].strip()
            business_type = parts[1].strip() if len(parts) > 1 else ""
            continue
        # 标签行
        if line_stripped.startswith("#") and "#" in line_stripped[1:]:
            tags.extend(re.findall(r"#([^\s#]+)", line_stripped))
            continue
        # 发布日期：— posted on May 7
        m = re.match(r"—?\s*posted on (.+)", line_stripped)
        if m:
            posted_str = m.group(1).strip()
            continue
        # 岗位行：submit - 岗位
        if line_stripped.startswith("submit - "):
            job_lines.append(line_stripped[len("submit - "):].strip())
            continue
        # 远程标记 ⚠️远程 #APAC 之类
        if "远程" in line_stripped or line_stripped.startswith("⚠️"):
            tags.extend(re.findall(r"#([^\s#]+)", line_stripped))

    return dict(
        company=company,
        business_type=business_type,
        tags=tags,
        posted_str=posted_str,
        jobs=job_lines,
    )


def _parse_posted(posted_str: str, fallback_dt: str) -> str:
    """把 'May 7' / 'May 7, 2024' 解析成 ISO 8601。

    fallback_dt 是消息 <time datetime="2026-05-07T..."> 里的精确值，更可靠。
    """
    if fallback_dt:
        return fallback_dt
    if not posted_str:
        return ""
    # 'May 7' 格式：补今年
    try:
        dt = datetime.strptime(f"{posted_str} {datetime.now().year}", "%b %d %Y")
        return dt.replace(tzinfo=timezone.utc).isoformat()
    except Exception:
        pass
    try:
        dt = datetime.strptime(posted_str, "%b %d, %Y")
        return dt.replace(tzinfo=timezone.utc).isoformat()
    except Exception:
        return ""


# ============== 抓取 ==============

def fetch_channel(channel_cfg: dict, sess: requests.Session) -> Iterable[dict]:
    username = channel_cfg["username"]
    fmt = channel_cfg.get("format", "abw_jobs")
    print(f"\n=== Telegram @{username} ({fmt}) ===")

    before_id = None
    for page in range(1, PAGE_LIMIT_PER_CHANNEL + 1):
        url = f"https://t.me/s/{username}"
        if before_id:
            url = f"{url}?before={before_id}"
        try:
            r = sess.get(url, timeout=30)
            r.raise_for_status()
        except Exception as e:
            print(f"  [warn] page {page} 失败: {e}")
            break
        html = r.text

        # 落盘备份
        (RAW_TG / f"{username}_p{page}.html").write_text(html)

        post_blocks = POST_BLOCK_RE.findall(html)
        if not post_blocks:
            print(f"  page {page}: 无消息块，停止")
            break

        # 先按 msg_id 升序排，最旧在前（用于翻页）
        post_blocks.sort(key=lambda x: int(x[0].rsplit("/", 1)[-1]))
        oldest_id = int(post_blocks[0][0].rsplit("/", 1)[-1])
        newest_id = int(post_blocks[-1][0].rsplit("/", 1)[-1])
        print(f"  page {page}: 拿到 {len(post_blocks)} 条消息 (id {oldest_id}-{newest_id})")

        for post_id, block in post_blocks:
            tm = TEXT_RE.search(block) or TEXT_RE_FALLBACK.search(block)
            if not tm:
                continue
            text_html = tm.group(1)
            text = _html_to_text(text_html)
            external_links = _extract_external_links(text_html)

            dtm = DATETIME_RE.search(block)
            dt_iso = dtm.group(1) if dtm else ""

            msg_id = post_id.rsplit("/", 1)[-1]
            channel_name = post_id.rsplit("/", 1)[0]

            if fmt == "abw_jobs":
                parsed = parse_abw_jobs_message(text)
                if not parsed["jobs"]:
                    continue
                posted = _parse_posted(parsed["posted_str"], dt_iso)
                tags_str = " ".join(f"#{t}" for t in parsed["tags"])
                for idx, job_title in enumerate(parsed["jobs"]):
                    yield dict(
                        company_slug=f"_tg_{channel_name}",
                        external_id=f"tg_{channel_name}_{msg_id}_{idx}",
                        title=job_title,
                        location="",
                        team=parsed["company"],
                        employment_type=parsed["business_type"],
                        workplace_type="",
                        apply_url=f"https://t.me/{channel_name}/{msg_id}",
                        description=text,
                        description_text=f"{text}\n\n[Tags] {tags_str}\n[External] {' '.join(external_links)}",
                        compensation="",
                        posted_at=posted,
                        referral_id=f"tg_{channel_name}/{msg_id}",
                    )

            elif fmt == "emoji_kv":
                jobs = parse_emoji_kv_message(text)
                for idx, jb in enumerate(jobs):
                    apply = jb["apply_url"] or f"https://t.me/{channel_name}/{msg_id}"
                    yield dict(
                        company_slug=f"_tg_{channel_name}",
                        external_id=f"tg_{channel_name}_{msg_id}_{idx}",
                        title=jb["title"],
                        location=jb["location"],
                        team=jb["company"],
                        employment_type=jb["emp_type"],
                        workplace_type="",
                        apply_url=apply,
                        description=text,
                        description_text=f"{text}\n\n[External] {' '.join(external_links)}",
                        compensation=jb["salary"],
                        posted_at=dt_iso,
                        referral_id=f"tg_{channel_name}/{msg_id}",
                    )

            elif fmt == "freeform":
                jobs = parse_freeform_message(text)
                for idx, jb in enumerate(jobs):
                    yield dict(
                        company_slug=f"_tg_{channel_name}",
                        external_id=f"tg_{channel_name}_{msg_id}_{idx}",
                        title=jb["title"],
                        location=jb["location"],
                        team=jb["company"],
                        employment_type=jb["emp_type"],
                        workplace_type="",
                        apply_url=f"https://t.me/{channel_name}/{msg_id}",
                        description=text,
                        description_text=f"{text}\n\n[External] {' '.join(external_links)}",
                        compensation=jb["salary"],
                        posted_at=dt_iso,
                        referral_id=f"tg_{channel_name}/{msg_id}",
                    )

        # 翻页：往更早走
        if oldest_id == before_id:
            print(f"  page {page}: oldest_id 未变化，到底，停止")
            break
        before_id = oldest_id
        time.sleep(0.6)


# ============== 主流程 ==============

def run() -> dict:
    init_db()
    sess = make_session()

    total = 0
    target = 0
    new_added = 0
    updated = 0
    per_channel: dict[str, dict] = {}

    for cfg in CHANNELS:
        slug = f"_tg_{cfg['username']}"
        upsert_company(
            slug=slug,
            display_name=f"📨 Telegram: {cfg['display_name']}",
            main_line="T",  # T 表示 telegram
            ats_platform="telegram",
            ats_handle=cfg["username"],
            careers_url=f"https://t.me/{cfg['username']}",
            notes=cfg.get("notes", ""),
        )

        with get_conn() as conn:
            cur = conn.execute(
                "SELECT external_id FROM jobs WHERE company_slug=?", (slug,)
            )
            existing = {row["external_id"] for row in cur.fetchall()}

        ch_total = ch_target = ch_new = ch_upd = 0
        for raw in fetch_channel(cfg, sess):
            ch_total += 1
            # 用 telegram 专用过滤（title 主导，因消息体短）
            tags_in_desc = re.findall(r"#([^\s#]+)", raw.get("description_text", ""))
            mt = _tg_matches_target(
                raw.get("title", ""),
                raw.get("description_text", ""),
                tags_in_desc,
            )
            apply_job_flags(raw, matched=mt)
            raw["work_languages"] = extract_for_job(
                raw.get("title", ""), raw.get("description_text", "")
            )
            raw["source"] = "telegram"

            if raw["external_id"] in existing:
                ch_upd += 1
            else:
                ch_new += 1
                existing.add(raw["external_id"])

            if raw["matches_target"]:
                ch_target += 1
            upsert_job(raw)

        per_channel[cfg["username"]] = dict(
            total=ch_total, target=ch_target, new=ch_new, updated=ch_upd
        )
        total += ch_total
        target += ch_target
        new_added += ch_new
        updated += ch_upd
        print(f"\n  → @{cfg['username']}: 抓到 {ch_total} 个岗位，目标方向 {ch_target} 个 (新增 {ch_new}, 更新 {ch_upd})")

    print(f"\n=== Telegram 完成 ===")
    print(f"  总岗位：{total} | 命中目标：{target}")
    print(f"  新增：{new_added} | 更新：{updated}")
    return {
        "total": total, "target": target,
        "new_added": new_added, "updated": updated,
        "per_channel": per_channel,
    }


if __name__ == "__main__":
    run()
