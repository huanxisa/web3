"""筛选规则：判断岗位是否匹配「后端 / 合约」目标，并按职级分层。

筛选逻辑：
1. ROLE_SKIP：架构师 / 中间件 / Infra / Staff·Principal 等 → 直接排除
2. STRONG_KEYWORDS：title 命中即视为目标岗位（明确的 Web3 / 合约 / 链上岗位）
3. SOFT_KEYWORDS：title + description 都命中（通用 backend/engineer + Web3 描述）

职级分层（role_tier，用于报告排序与每日摘要）：
- primary：后端工程师 / 高级后端 / 智能合约工程师 / 高级智能合约（用户主投方向）
- secondary：仍属后端/合约大类但职级或方向偏 Staff/全栈/协议等 → 报告靠后
- skip：不匹配或已排除
"""

from __future__ import annotations

import re

# 强匹配：title 命中即视为目标岗位（明确含 Web3 / 链上 / 合约 / 钱包 / 交易引擎）
STRONG_KEYWORDS = [
    # 智能合约
    r"\bsmart\s*contract\b",
    r"\bsolidity\b",
    r"\bcontract\s+(?:engineer|developer|auditor|security|architect)\b",
    r"区块链.*(?:工程师|开发|架构师)",
    r"智能合约",
    r"合约.*(?:工程师|开发|审计|架构师)",
    # 链上 / Web3 后端
    # 允许 "blockchain (development|core|...)? engineer" 这种中间夹词的表达
    r"\bblockchain\b.{0,30}\b(?:engineer|developer|architect|infrastructure|backend)\b",
    r"\bweb3\b.{0,30}\b(?:engineer|developer|backend|architect|infrastructure|protocol|wallet)\b",
    r"\b(?:engineer|developer|backend|architect)\b.{0,15}\bweb3\b",
    r"\bprotocol\s+engineer\b",
    r"\b(?:dapp|defi)\s+(?:engineer|developer|backend|architect)\b",
    r"\bwallet\s+(?:engineer|backend|developer|infrastructure|architect)\b",
    r"\b(?:engineer|developer|architect)\b.{0,15}\bwallet\b",
    r"\bwallet\b.{0,15}\b(?:engineer|developer|architect)\b",
    r"钱包.*(?:工程师|开发|架构师)",
    r"链上",
    # SDK / DevTool / Indexer / Sequencer
    r"\bsdk\s+engineer\b",
    r"\bdeveloper\s+experience\b",
    r"\bdevtool",
    r"\b(?:integrations?|indexer|sequencer)\s+(?:engineer|developer)\b",
    r"\bnode\s+(?:engineer|developer)\b",
    # ZK / 密码学
    r"\bzk[- ]?(?:engineer|developer|prover|circuit)\b",
    r"零知识",
    # Stablecoin / Bridge
    r"\bstablecoin\b.*\b(?:engineer|developer|backend|architect)\b",
    r"\bcross[- ]chain\b",
    r"\bbridge\s+engineer\b",
    # CEX 核心业务（撮合引擎、交易引擎等关键岗位）
    r"\btrading\s+(?:engine|system|core)\b",
    r"\bmatching\s+engine\b",
    r"\border\s+(?:matching|book)\b",
    r"\bderivatives?\s+(?:engineer|developer|backend|architect)\b",
    # 中文核心岗位
    r"交易(?:引擎|系统|平台).*?(?:负责人|架构师|工程师|开发|核心)",
    r"撮合.*?(?:引擎|工程师|开发)",
    r"核心(?:开发|架构|工程师)",
    r"后端(?:工程师|开发|架构师)",
]

# 软匹配（仅作辅助）：title 含通用 engineer/backend，但 description 必须含 Web3 / 链上字样
# 加入 architect、staff/principal/lead 资深前缀、"backend development engineer" 复合词
SOFT_TITLE_KEYWORDS = [
    # backend / server-side（允许中间夹 development/core 等词）
    r"\b(?:senior|staff|principal|lead)?\s*(?:backend|back[- ]end|server[- ]side)\b.{0,25}\b(?:engineer|developer|architect)\b",
    # 语言 + 工程师/开发（允许中间夹 development）
    r"\b(?:senior|staff|principal|lead)?\s*(?:go(?:lang)?|java|rust|node\.?js)\b.{0,25}\b(?:engineer|developer|backend|architect)\b",
    # 全栈
    r"\bfull[- ]stack\s+(?:engineer|developer)\b",
    # 通用 software engineer
    r"\b(?:senior|staff|principal|lead)?\s*software\s+engineer\b",
    # R&D engineer（CEX 常用）
    r"\br\s*&\s*d\s+(?:engineer|developer|architect)\b",
    r"\bdevelopment\s+engineer\b",
    # 中文
    r"后端.*(?:工程师|开发|架构师)",
    r"研发.*(?:工程师|架构师)",
]

SOFT_DESC_REQUIRE = [
    r"\bweb3\b",
    r"\bblockchain\b",
    r"\bsolidity\b",
    r"\bsmart\s*contract\b",
    r"\bdefi\b",
    r"\bdapp\b",
    r"\bevm\b",
    r"\bethereum\b",
    r"\bcrypto\b",
    r"\bonchain\b|\bon[- ]chain\b",
    r"\bwallet\b",
    r"\brollup\b",
    r"\bzk[- ]?proof\b",
    r"\bdigital\s+assets?\b",
    r"\bexchange\b",  # CEX 公司描述常用
    r"\btoken\b",
    r"区块链",
    r"链上",
    r"加密货币",
    r"加密资产",
    r"数字资产",
    r"智能合约",
    r"钱包",
    r"交易所",
    r"代币",
]

# 命中任何一个 → 排除（运营 / 市场 / 设计 / 移动 / 前端 等非「后端/合约」岗位）
EXCLUDE_KEYWORDS = [
    r"\bmarketing\b",
    r"\bdesigner?\b",
    r"\brecruiter\b",
    r"\bsales\b",
    r"\blegal\b",
    r"\bcompliance\b",
    r"\bhr\b",
    r"\boperations?\s+(?:manager|specialist)\b",
    r"\bevents?\s+(?:producer|manager)\b",
    r"\bcommunity\s+manager\b",
    r"\bbusiness\s+development\b",
    r"\bpartnerships?\s+manager\b",
    r"\bproduct\s+manager\b",
    r"\baccountant\b",
    r"\baccounting\b",
    r"\bcommunications?\b",
    r"\bcontent\s+(?:writer|creator|specialist|manager)\b",
    r"\bgrowth\s+manager\b",
    r"\bsocial\s+media\b",
    r"\bui[ /]?ux\b",
    r"\btechnical\s+writer\b",
    r"\bcustomer\s+(?:support|success)\b",
    r"\bproject\s+manager\b",
    r"\bgame\s+designer\b",
    r"\btreasury\b",
    r"\bfinance\b",
    r"\bdata\s+scientist\b",
    r"\banalyst\b",
    r"\bresearch(?:er)?\s+(?:lead|manager)?\b",  # 研究员超出 L1 范围
    r"\bsre\b",
    r"\bsite\s+reliability\b",
    # 前端 / 移动端：非用户目标方向（后端 / 合约）
    r"\bfrontend\b|\bfront[- ]end\b",
    r"\bmobile\b|\bandroid\b|\bios\b",
    r"\bui\s+engineer\b",
    # QA / DevOps 排除
    r"\bquality\b|\bqa\b|\btester\b",
    r"\bdevops\b",
    # 数据仓库 / 报表类
    r"\bdata\s+warehouse\b",
    # 中文
    r"招聘",
    r"客服",
    r"运营专员",
    r"分析师",
    r"前端",
    r"移动端",
    # 中文 QA / 纯测试（保留 SDET = "测试开发工程师"）
    # 用 negative lookbehind 避免误伤"测试开发工程师"
    r"(?<!开发)测试工程师",
]

# 远程关键词
REMOTE_KEYWORDS = [
    r"\bremote\b",
    r"\bworldwide\b",
    r"\bany(?:where)?\b",
    r"\bglobal\b",
    r"远程",
]

# 硬排除：title 命中即排除（即便同时含 wallet/web3 等强关键词也不要）
# 因为这些岗位不是「后端 / 合约」方向
HARD_EXCLUDE_KEYWORDS = [
    r"\bfrontend\b|\bfront[- ]end\b",
    r"\bmobile\b",
    r"\b(?:senior|staff)?\s*(?:android|ios)\b",
    r"\bui\s+engineer\b",
    r"\bqa\b|\bquality\s+assurance\b|\btester\b",
    r"\bdevops\b|\bsre\b|\bsite\s+reliability\b",
    r"\boperations?\s+(?:manager|specialist)\b",
    r"\bdata\s+warehouse\b",
    r"\b(?:big\s+)?data\s+(?:scientist|analyst|engineer)\b",
    r"\brecruiter\b",
    r"\bmarketing\b",
    r"\bdesigner?\b",
    r"\bsales\b",
    r"\bcommunity\s+manager\b",
    r"\bproduct\s+manager\b",
    r"\bcontent\s+(?:writer|creator|specialist|manager)\b",
    r"\bbusiness\s+development\b",
    r"\bpartnerships?\s+(?:manager|director|lead)\b",
    r"\bevents?\s+(?:producer|manager)\b",
    r"\baccountant\b|\baccounting\b",
    r"\bcommunications?\b",
    r"\bcustomer\s+(?:support|success)\b",
    r"\bproject\s+manager\b",
    r"\bgame\s+designer\b",
    r"\btreasury\b",
    r"\bfinance\b",
    r"\blegal\b|\bcompliance\b",
    r"\bhr\b",
    r"\bresearch(?:er)?\s+(?:lead|manager)?\b",
    r"\banalyst\b",
    r"\bsocial\s+media\b",
    r"\btechnical\s+writer\b",
    r"\bui[ /]?ux\b",
    r"前端|移动端|招聘|客服|分析师|运营专员",
    r"(?<!开发)测试工程师",   # 中文 QA（保留 SDET = 测试开发工程师）
]

STRONG_RE = re.compile("|".join(STRONG_KEYWORDS), re.IGNORECASE)
SOFT_TITLE_RE = re.compile("|".join(SOFT_TITLE_KEYWORDS), re.IGNORECASE)
SOFT_DESC_RE = re.compile("|".join(SOFT_DESC_REQUIRE), re.IGNORECASE)
HARD_EXCLUDE_RE = re.compile("|".join(HARD_EXCLUDE_KEYWORDS), re.IGNORECASE)
EXCLUDE_RE = re.compile("|".join(EXCLUDE_KEYWORDS), re.IGNORECASE)
REMOTE_RE = re.compile("|".join(REMOTE_KEYWORDS), re.IGNORECASE)

# Web3 无关业务领域，title 命中即直接排除（即便有 backend/engineer 字样）
NON_WEB3_NOISE = re.compile(
    r"\b(?:ai\s+agent|ai\s+chat|ai/llm|llm|customer\s+service|recommendation|"
    r"ad\s+tech|cms|crm|olap|big\s+data|search|treasury\s+management|kyc\s+tech|"
    r"trading\s+insights|growth\s+tech|cloud\s+native|cloud\s+tech|exchange\s+service|"
    r"flink|spark|cloud\s+services?|fraud\s+risk|anti[- ]fraud|vulnerability\s+scanner|"
    r"strategy\s+engine|risk(?:\s+engine)?|kyc|incident\s+response|productivity)\b",
    re.IGNORECASE,
)

# 职级/方向排除：架构师、中间件、Infra、Staff/Principal/Director 等（即便 title 含 backend/web3 也排除）
ROLE_SKIP_KEYWORDS = [
    r"\barchitect\b",
    r"架构师",
    r"\bmiddleware\b",
    r"中间件",
    r"\binfrastructure\b",
    r"\binfra\b",
    r"基础设施",
    r"\bplatform\s+engineer\b",
    r"\b(?:staff|principal)\b",
    r"\b(?:director|head\s+of|vp\b|chief)\b",
    r"\bsre\b",
    r"\bdevops\b",
    r"\bsite\s+reliability\b",
    r"\bprotocol\s+engineer\b",
    r"\bfull[- ]?stack\b",
    r"\bsecurity\s+(?:engineer|specialist|architect)\b",
    r"\b(?:application|solutions?|stability)\s+architect\b",
    r"\bdba\b",
    r"\bdatabase\s+administrator\b",
    r"负责人",
    r"\bquant(?:itative)?\s+(?:developer|engineer|researcher)\b",
    r"\bmatching\s+engine\b",
    r"\b(?:mobile|android|ios|frontend|front[- ]end)\b",
    r"\b(?:data|big\s+data)\s+(?:engineer|warehouse)\b",
    r"\bcryptography\s+engineer\b",
    r"\bcustody\s+(?:engineer|platform)\b",
    r"\b(?:r\s*&\s*d|research)\s+(?:engineer|architect)\b",
    r"研发架构",
    r"中间平台",
    r"稳定性架构",
]

# 用户主投方向：后端工程师 / 高级后端 / 智能合约 / 高级智能合约（及同义 Lead/Junior 后端/合约 IC 岗）
ROLE_PRIMARY_KEYWORDS = [
    r"\b(?:junior|senior|lead)?\s*(?:backend|back[- ]end)\b.{0,20}\b(?:engineer|developer)\b",
    r"\b(?:junior|senior|lead)?\s*(?:smart\s+contract|solidity)\s+(?:engineer|developer)\b",
    r"\b(?:senior|lead)?\s*(?:java|golang|go|rust|node\.?js)\s+(?:backend\s+)?(?:engineer|developer)\b",
    r"\b(?:senior|lead)?\s*blockchain\s+(?:engineer|developer)\b",
    r"\b(?:senior|lead)?\s*web3\s+(?:backend\s+)?(?:engineer|developer)\b",
    r"\b(?:senior|lead)?\s*contract\s+(?:engineer|developer)\b",
    r"后端(?:开发)?工程师",
    r"高级后端",
    r"智能合约(?:工程师|开发)",
    r"高级智能合约",
    r"合约(?:工程师|开发)(?!.*架构)",
    r"区块链(?:开发)?工程师(?!.*架构)",
    r"交易引擎.*(?:开发|工程师)",
    r"核心开发(?!.*架构)",
    r"\bgolang\s+(?:backend\s+)?(?:engineer|developer)\b",
    r"\bjava\s+(?:backend\s+)?(?:engineer|developer)\b",
]

ROLE_SKIP_RE = re.compile("|".join(ROLE_SKIP_KEYWORDS), re.IGNORECASE)
ROLE_PRIMARY_RE = re.compile("|".join(ROLE_PRIMARY_KEYWORDS), re.IGNORECASE)


def is_remote(*texts: str | None) -> bool:
    blob = " ".join(t for t in texts if t)
    return bool(REMOTE_RE.search(blob))


def classify_role_tier(title: str) -> str:
    """返回 primary / secondary / skip（仅看 title）。"""
    if not title:
        return "skip"
    t = title.lower()
    if ROLE_SKIP_RE.search(t):
        return "skip"
    if ROLE_PRIMARY_RE.search(t):
        return "primary"
    return "secondary"


def matches_target(title: str, description: str | None = "") -> bool:
    """多层排除 + 方向匹配；架构师/Infra/中间件/Staff·Principal 等一律不匹配。"""
    if not title:
        return False
    title_lower = title.lower()
    desc_lower = (description or "").lower()

    if HARD_EXCLUDE_RE.search(title_lower):
        return False

    if ROLE_SKIP_RE.search(title_lower):
        return False

    if EXCLUDE_RE.search(title_lower) and not STRONG_RE.search(title_lower):
        return False

    if NON_WEB3_NOISE.search(title_lower) and not STRONG_RE.search(title_lower):
        return False

    if STRONG_RE.search(title_lower):
        return True

    if SOFT_TITLE_RE.search(title_lower):
        if SOFT_DESC_RE.search(title_lower) or SOFT_DESC_RE.search(desc_lower):
            return True

    return False


def apply_job_flags(job: dict, *, matched: bool | None = None) -> dict:
    """统一计算 matches_target / is_remote / role_tier，写回 job dict。

    matched：外部已算好是否命中时传入（如 Telegram 专用过滤）。
    """
    title = job.get("title") or ""
    desc = job.get("description_text") or job.get("description") or ""
    mt = matched if matched is not None else matches_target(title, desc)
    if mt:
        tier = classify_role_tier(title)
        if tier == "skip":
            tier = "secondary"
    else:
        tier = "skip"
    job["matches_target"] = int(mt)
    job["is_remote"] = int(is_remote(
        job.get("location"), job.get("workplace_type"), desc,
    ))
    job["role_tier"] = tier
    return job


if __name__ == "__main__":
    samples = [
        ("Senior Backend Engineer", "build defi protocols"),
        ("Senior Backend Engineer", "internal CRM tooling"),
        ("Solidity Engineer", ""),
        ("Marketing Manager", ""),
        ("Blockchain Engineer 区块链开发工程师", ""),
        ("Backend Architect - Pay&Card Tech", ""),
        ("Infrastructure Stability Architect", ""),
        ("Staff / Senior Staff Software Engineer, Matching Engine", ""),
        ("Principal Backend Development Engineer", ""),
        ("Lead Backend Development Engineer", ""),
        ("Smart Contract Engineer", ""),
        ("Middleware Engineer", "web3 exchange"),
        ("Java Backend Engineer - Web3 Data", ""),
        ("Backend Java Engineer (Web3) - Binance Wallet", ""),
        ("Quant Developer (Rust), Liquidity Platform, Delta One", ""),
    ]
    for t, d in samples:
        tier = classify_role_tier(t)
        print(f"  match={matches_target(t, d):<5} tier={tier:<9} | {t}")
