# Web3 后端 / 智能合约 求职研究项目

> 本项目用于沉淀「**Web3 后端 / 智能合约工程师 — 远程求职**」全过程的研究资料、JD 抓取脚本、数据库与中文报告。
> 时间起点：2026-05
> 求职画像：Web2 Go 后端转 Web3，目标钱多事少 + 纯远程 + 中文办公中文面试 + 接受 Token 激励。

---

## 一、行业组织盈利模式与风险速查

| 组织类型 | 主要盈利方式 | 现金流稳定性 | 跑路风险 |
|---|---|---|---|
| 头部 CEX（中心化交易所） | 交易手续费、上币费、合约爆仓、Launchpad 抽成、自营做市 | 极强 | 极低 |
| 二线 CEX / 衍生品交易所 | 同上但盘口浅 | 强 | 低-中 |
| 头部公链 / Layer2 基金会 | 代币储备、生态基金投资收益、Gas 收入 | 强（看币价） | 低 |
| 钱包 / 基础设施 SaaS（RPC、节点、索引） | API 调用费、订阅费、企业服务 | 较强（Web2 模式） | 低 |
| 头部 DeFi 协议（DEX、借贷、流动性质押） | 协议费、做市利润、积分激励 | 中-强 | 中 |
| 做市商 / 量化基金（Wintermute、GSR、Amber） | 套利、做市价差、自营交易 | 强 | 低-中 |
| 传统券商 / 银行的数字资产部门 | 托管费、合规交易通道、ETF 做市 | 极强 | 极低 |
| 矿企 / 质押服务商 | 出块奖励、佣金抽成 | 中（看币价） | 中 |
| RWA / 稳定币发行方 | 储备金利息、铸造销毁费 | 强 | 中 |
| GameFi / NFT / SocialFi 项目方 | 代币发行、NFT 销售 | 弱 | 高-极高 |

---

## 二、按入职难度的岗位分级（L0–L3）

| 级别 | 难度描述 | 代表岗位 |
|---|---|---|
| **L0** | 纯 Web2 技能即可 | CEX 业务后端、钱包产品后端、节点 SaaS 平台后端、链上数据分析、KYT 合规后端、矿企/质押运维后端 |
| **L1** | 懂链交互 + 简单合约 | CEX 钱包/充提后端、DApp 业务后端 + Indexer、通用业务合约（NFT/Staking/Vesting）、L2 公链 SDK/DevTool 后端 |
| **L2** | 深入 EVM + 协议设计 | 头部 DeFi 核心 Solidity、跨链桥/Sequencer、CEX 撮合引擎、合约审计、MPC/TSS 工程师 |
| **L3** | 研究背景 + PhD 加分 | 公链 Protocol Engineer（共识/P2P/VM）、ZK 工程师、形式化验证、MEV/链上量化套利 |

---

## 三、本次锁定方向与公司清单

### 钱多事少 × 纯远程 × 中文办公中文面试 × 接受 Token 的最优解

**主线 A（后端方向）**：**Layer2 / 公链基金会的 SDK / DevTool / Tooling 后端**
- 工作内容：写 SDK、CLI、文档示例、JSON-RPC 适配、开发者门户后端
- 节奏：无 7×24 on-call、无撮合压力、无安全审计的脑力消耗
- 薪酬区间：现金 80w–150w + Token 激励

**主线 B（合约方向）**：**CEX Web3 部门 + Launchpad 平台的业务合约工程师**
- 工作内容：写 NFT、Vesting、Staking、Launchpad、空投合约
- 节奏：OpenZeppelin / Foundry 模板复用为主，由产品排期驱动
- 薪酬区间：现金 50w–120w + 股权 / Token

### 各主线前 3 家目标公司（共 6 家）

| 主线 | 公司 | 中文度 | 远程范围 | 备注 |
|---|---|---|---|---|
| A1 | **Scroll** | ⭐⭐⭐⭐⭐ | 全球远程 | ZK L2，张烨/Ye Zhang 团队，北京/纽约/远程 |
| A2 | **Mantle** | ⭐⭐⭐⭐⭐ | 全球远程 | BitDAO 系，国库 30+亿美金，Token 大方 |
| A3 | **Manta Network** | ⭐⭐⭐⭐⭐ | 全球远程 | 华人创始人，ZK L2，Tooling 团队几乎纯中文 |
| B1 | **OKX Web3 (Wallet/DEX/DeFi)** | ⭐⭐⭐⭐⭐ | 全球远程 | 中文办公，Web3 钱包合约长期开放 |
| B2 | **Binance Web3 Wallet** | ⭐⭐⭐⭐⭐ | 全球远程 | 中文环境，业务合约岗常年招 |
| B3 | **Bitget Wallet (前 BitKeep)** | ⭐⭐⭐⭐⭐ | 全球远程 | 中文团队，扩张期 HC 多，节奏宽松 |

---

## 四、Token vs 现金 —— 接受 Token 前必须知道的事

### Token 的优点
1. **上限远高于现金**：Token 上线后市值翻 5–20 倍是常态（典型如 ARB/OP/SUI 早期员工），同岗位现金部分可能不变，但 Token 部分能多赚一套房。
2. **基金会型公司专属福利**：Layer2/公链基金会通常用国库代币发，**不消耗公司现金流**，所以基金会舍得给。
3. **税务优化**：境外团队多用 Token 形式发，避免国内个税顶格 45% + 公积金的合规成本。

### Token 的风险（按严重度排序）

| 风险 | 说明 | 缓解策略 |
|---|---|---|
| **Token 未上线时是 IOU** | 入职时只是承诺，公司倒闭、放弃发币、合规叫停都会归零 | 优先选已发币的公司；未发币的至少要 A 轮以上 |
| **Vesting 长 + Cliff** | 行业标准 4 年线性解锁，第 1 年 cliff（前 12 个月一颗都没有），半路离职拿不全 | 谈 offer 时争取缩短 cliff 到 6 个月 / 缩短 vesting 到 3 年 |
| **解锁后市场抛压** | 团队 Token 大批解锁时往往砸盘 70%+ | 拿到就分批卖，不要 all-in 持有 |
| **币价波动大** | 同样 100 万美金 Token，发的时候是顶峰，3 个月后剩 30 万 | 谈 offer 时争取 **按发放当日 30 日 TWAP 计价** |
| **流动性差 / 锁仓代币** | 部分 Token 上线后 24 小时成交量 < 100 万美金，根本卖不掉 | 入职前查 CMC 上的 24h volume |
| **税务复杂** | 境内员工卖币利得需自行申报，境外发放主体可能需补缴 | 设立香港/新加坡身份；或让公司用 USDC 工资形式发放 |

### 推荐的薪酬结构组合（建议谈判时争取）

```
现金部分    : ≥ 70%   （最低底线，保证生活和应急）
Token 部分  : ≤ 30%   （上行 alpha，可承受归零）
```

**红线**：如果 offer 给到 现金 < 50% + Token > 50%，直接 pass —— 99% 概率是公司现金流紧张。

---

## 五、本项目目录结构

```
web3-job-hunting/
├── README.md              # 本文件：求职研究总结
├── scripts/                  # JD 抓取与处理脚本
│   ├── fetcher.py            # 各家公司 ATS JD 抓取（Greenhouse/Lever/Ashby/web3.career）
│   ├── feishu_extract.py     # 飞书共享表 Playwright 抓取（手动/有头/无头）
│   ├── feishu_sync.py        # 飞书 cells.csv → SQLite 入库
│   ├── storage.py            # SQLite 存储模型（带 source 字段，区分 ats / feishu_referral）
│   ├── filters.py            # 目标岗位过滤规则
│   ├── translator.py         # 英文 JD 翻译为中文
│   ├── extract_languages.py  # 从 JD 抽取编程语言
│   ├── reporter.py           # 生成中文 JD 汇总 Markdown
│   └── update.py             # 一键增量更新（ATS + 飞书 + diff + 翻译 + 报告）
├── data/
│   ├── jobs.db               # SQLite 数据库
│   └── raw/feishu/           # 飞书 dump（gitignore，含登录态相关）
├── .playwright_profile/       # Playwright 持久化登录态（gitignore）
├── raw/                      # 原始 HTML/JSON 抓取结果（用于复查）
└── reports/                  # 中文报告输出
    └── jd_summary.md
    └── digest/
        ├── LATEST.md           # 日常主阅读：近 30 天主投岗位
        └── new_jobs_YYYYMMDD.md  # 按日归档
```

---

## 六、工作流

### 6.1 一次性首装

```bash
cd web3-job-hunting
python3 -m venv .venv
source .venv/bin/activate
pip install -r scripts/requirements.txt
```

### 6.2 日常增量更新（推荐）

```bash
source .venv/bin/activate
python scripts/update.py    # 一条命令完成所有事情
```

**日常阅读顺序**：
1. [`reports/digest/LATEST.md`](reports/digest/LATEST.md) — **主投岗位日报**（近 30 天，仅后端/高级后端/智能合约）
2. [`reports/jd_summary.md`](reports/jd_summary.md) — 完整 JD 归档（含附录 secondary 岗）

`update.py` 自动做的事：

1. 快照当前数据库
2. 抓取 17 家公司最新岗位（约 100 秒）
3. 同步飞书内推池（如果 `data/raw/feishu/extract_*/cells.csv` 存在）
4. 计算 diff：新增 / 下架 / 标题变更
5. 把 diff 写到 `reports/diff_YYYYMMDD_HHMM.md`（可历史追溯）
6. 把已下架岗位的 `matches_target` 置 0（不再出现在报告里，但数据保留）
7. 自动翻译新增的目标岗位
8. 重新生成 `reports/jd_summary.md`
9. 生成 `reports/digest/new_jobs_YYYYMMDD.md` + 更新 `reports/digest/LATEST.md`
10. 打印当次摘要

### 6.3 飞书内推池抓取（独立流程，需有头浏览器）

飞书表用 SPA + Canvas 渲染，必须用 Playwright + 持久化登录抓。**首次抓**需要在 macOS Terminal.app 里跑（不能在 Cursor 内置终端）：

```bash
cd web3-job-hunting
source .venv/bin/activate

# 一次性安装 Playwright + Chromium（约 100 MB）
pip install playwright openpyxl
PLAYWRIGHT_BROWSERS_PATH=/Users/piliepeng/.cache/ms-playwright \
  playwright install chromium

# 首次抓取：默认有头模式，方便观察
PLAYWRIGHT_BROWSERS_PATH=/Users/piliepeng/.cache/ms-playwright \
  python scripts/feishu_extract.py --headed
```

抓取的数据：
- `data/raw/feishu/extract_<时间戳>/cells.csv`：499 行 × 22 列岗位池
- `screenshot.png`：表格截图，便于核对
- `extract_result.json`：浏览器内 `window.spread` 探查日志

之后跑 `python scripts/update.py` 会自动检测最新 CSV 并入库。

> 飞书内推表的特殊性：表里**只有岗位 + 企业类型 + JD + 薪资 + Base + 更新时间**，**没有公司名 / 联系人**。每条岗位的 `referral_id`（飞书表行号）是和分享人对接的暗号 —— 投递时把行号发给 ta，ta 给你具体公司。

### 6.4 分步骤运行（如需排查）

```bash
python scripts/fetcher.py            # 仅抓取 ATS
python scripts/feishu_sync.py        # 仅同步飞书内推（读最新 cells.csv）
python scripts/translator.py         # 仅翻译未译的
python scripts/extract_languages.py  # 仅重算语言（target_only=True）
python scripts/reporter.py           # 仅生成报告
python scripts/recompute_targets.py  # 仅按最新 filter 重算 matches_target/is_remote
```

## 数据源说明（为什么是 ATS API 而不是公司官网？）

| 公司 | 数据源 | 是否官方？ |
|---|---|---|
| Mantle | Ashby（`jobs.ashbyhq.com/windranger`） | ✅ Mantle 用的官方招聘 SaaS |
| Manta | Lever（`api.lever.co/v0/postings/MantaNetwork`） | ✅ Manta 用的官方招聘 SaaS |
| OKX | Greenhouse（`boards-api.greenhouse.io/v1/boards/okx/jobs`） | ✅ OKX 用的官方招聘 SaaS |
| Binance | Lever（`api.lever.co/v0/postings/binance`） | ✅ Binance 用的官方招聘 SaaS |
| Scroll | web3.career 聚合站 | ❌ 因为 Scroll 旧 Lever 端点已下线，新 ATS 找不到 |
| Bitget | web3.career 聚合站 | ❌ 因为 Bitget 自建系统有反爬虫保护 |

**为什么这些 API 比直接抓官网更可靠**：
- 公司官网招聘页通常是 SPA（React/Vue），抓 HTML 拿到的是空骨架
- ATS 的 REST/GraphQL API 是公司**自己的浏览器**调用的同一个端点，数据完全一致
- ATS API 公开免费、无需 key、无反爬虫，是业界标准做法

---

## ⭐ 分支专题

> 从主线学习延伸出的深度专题，每篇独立成文，可按需阅读。

| 专题 | 文档 | 简介 |
|---|---|---|
| **套利与 MEV** | [`notes/topics/arbitrage_and_mev.md`](notes/topics/arbitrage_and_mev.md) | AMM 套利收敛的数学证明、完整执行链路（监听→计算→闪电贷执行）、MEV 生态全景、开源 bot 清单 |
| **智能合约审计师** | [`notes/topics/smart_contract_auditor.md`](notes/topics/smart_contract_auditor.md) | 审计师是否需要学 Yul Assembly、核心语法速查、TickMath 模式剖析、12–16 周学习路线图、入行路径（Code4rena / 机构实习）|

---

## ⭐ 重要产出物

| 文档 | 用途 |
|---|---|
| [`reports/jd_summary.md`](reports/jd_summary.md) | **70 个目标岗位完整中文 JD**（带新鲜度标签 🟢🟡🟠🔴 + 顶部"立即可投"清单 + 末尾"⚠️ 仅参考"段）|
| [`reports/dead_companies_dm_sop.md`](reports/dead_companies_dm_sop.md) | **⭐ 死火公司探查 SOP**：Aave/Scroll/Bitget/Magic Eden 这 4 家是否真死，30-60 分钟 LinkedIn/Twitter DM 探查指南 |
| [`reports/backend_engineer_4weeks.md`](reports/backend_engineer_4weeks.md) | **⭐⭐⭐ 主推**：Go + Java 双语 4 周冲刺方案 v3，含语言决策树 + 实测语言分布 |
| [`reports/business_focused_repos_for_newcomers.md`](reports/business_focused_repos_for_newcomers.md) | 强业务项目模块拆解（12 个项目 × 合约/后端模块）|
| [`reports/repos_list_with_git_urls.md`](reports/repos_list_with_git_urls.md) | 12 个项目所有合约/后端 repo 的 Git 链接清单 + 按周分组 |
| [`scripts/clone_repos.sh`](scripts/clone_repos.sh) | 一键 clone 27 个 repo 到 `repos/` 下（按周可拆分 clone） |
| [`reports/final_repo_shortlist.md`](reports/final_repo_shortlist.md) | 进阶版：业务深度 × 招聘认可度 二维评分 |
| [`reports/recognized_repos_tier_list.md`](reports/recognized_repos_tier_list.md) | 中间产物：单维度（招聘认可度）排行榜 |
| [`reports/biz_to_opensource_map.md`](reports/biz_to_opensource_map.md) | 中间产物：单维度（业务深度）地图 |
| [`reports/diff_*.md`](reports/) | 每次 `update.py` 生成的增量 diff |

> **阅读顺序建议**：
> 1. 先看 [`backend_engineer_4weeks.md`](reports/backend_engineer_4weeks.md) 决定 Go 主 / Java 备的整体路径
> 2. 看 [`business_focused_repos_for_newcomers.md`](reports/business_focused_repos_for_newcomers.md) 学习每周项目的模块拆解
> 3. 用 [`scripts/clone_repos.sh`](scripts/clone_repos.sh) 把 repo 拉下来，对照模块边读边写

## 七、抓取结果（2026-05-12，新增飞书内推池 → 命中数翻 3 倍）

| 数据源 | 公司数 | 总岗位 | 命中目标 | 远程 |
|---|---|---|---|---|
| **ATS 抓取** | 17 | 911 | **70** | 70 |
| **飞书内推池** | 1（共享池）| 499 | **134** | 104 |
| **合计** | 18 | **1410** | **204** | **174** |

- 详细报告：[`reports/jd_summary.md`](reports/jd_summary.md)
- 飞书内推数据来源：《岗位资源管理对外版》（持续更新，按行号回飞书表对接分享人）

> 飞书内推池单独成段，**不参与时效性筛选**（内推渠道允许岗位较旧，分享人会按需重新激活）；
> ATS 部分仍按 🟢🟡🟠🔴 新鲜度分级。

| 主线 | 公司 | 抓取总数 | 目标匹配 | ATS 来源 |
|---|---|---|---|---|
| **A** | Scroll | 15 | **5** | web3.career |
| **A** | Mantle | 8 | **1** | Ashby（windranger） |
| **A** | Manta Network | 6 | **0** | Lever（MantaNetwork） |
| **B** | OKX | 292 | **3** | Greenhouse（okx） |
| **B** | Binance | 402 | **20** | Lever（binance） |
| **B** | Bitget | 9 | **1** | web3.career |
| **C 强业务** | **Coinbase** | 15 | **5** | web3.career |
| **C 强业务** | **Aave Companies** | 14 | **4** | web3.career |
| **C 强业务** | **Fireblocks** | 15 | **4** | web3.career |
| **C 强业务** | **Magic Eden** | 1 | **1** | web3.career |
| **C 强业务** | **Uniswap Labs** | 9 | **4** | Ashby（uniswap） |
| **C 学习用** | Circle / Lido / Pendle / Ondo | 31 | 0 | web3.career 未收录工程岗（中文不友好不投递）|
| **D 中文 CEX 新增** | **Bybit** ⭐ | 69 | **9** | Greenhouse（bybit）|
| **D 中文 CEX 新增** | **Gate.io** ⭐ | 25 | **8** | Lever（gate）|

### 强业务 + 中文友好双新增共 35 个高质量岗位

- **主线 C 强业务（18 个）**：Coinbase 5 + Aave 4 + Fireblocks 4 + Magic Eden 1 + Uniswap 4
- **主线 D 中文 CEX 新增（17 个）⭐**：Bybit 9 + Gate.io 8
  - Bybit：Lead Backend × 2 / Principal Blockchain (Java) / Principal Rust / 全部双标 Java + Golang
  - Gate.io：Backend Architect / R&D Engineer Golang / 交易引擎负责人 / 核心开发 / 杭州办公室
- **C 学习用（不投递）**：Circle / Lido / Ondo / Pendle 在 web3.career 上没有工程岗，且中文不友好

### 70 个匹配岗按工作语言分布（实测）

| 语言 | 岗位数 | 主要分布 |
|---|---|---|
| **Java** | **28** | Binance + Bybit + Gate（CEX 阵营）|
| **Golang** | **24** | Coinbase / Uniswap / Bybit / Gate / Binance / OKX 等 6+ 家 |
| Rust | 17 | Mantle / Aave / Bybit Principal Rust |
| Python | 16 | 全部公司辅助语言 |
| Solidity | 10 | 合约岗位 |
| TypeScript / JavaScript | 各 7-8 | Fireblocks / Uniswap |

→ **Go 24 已经追近 Java 28**，加上 Bybit/Gate 后真正实现"双语并行"。详见 [`reports/backend_engineer_4weeks.md`](reports/backend_engineer_4weeks.md)。

## 八、后续 TODO

- [x] 完成首轮 6 家 JD 抓取
- [x] 翻译英文 JD 为中文 + 生成报告
- [ ] 针对每家 JD 输出"个人 Gap List"
- [ ] 按 JD 关键词反推面试题库
- [ ] 重写一份贴合 Web3 的中文简历
- [ ] 整理内推渠道（中文招聘群 / Twitter 内推人）

## 九、SQLite 自助查询

```bash
# 查所有目标岗位
sqlite3 data/jobs.db "SELECT c.display_name, j.title, j.location FROM jobs j JOIN companies c ON c.slug=j.company_slug WHERE j.matches_target=1;"

# 查某一家公司全部岗位
sqlite3 data/jobs.db "SELECT title, location FROM jobs WHERE company_slug='binance';"

# 查带 'wallet' 的岗位
sqlite3 data/jobs.db "SELECT c.display_name, j.title FROM jobs j JOIN companies c ON c.slug=j.company_slug WHERE j.title LIKE '%wallet%';"
```
