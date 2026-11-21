# Web3 后端学习地图 v3（通用版 · 8 项目 · 10 周）

> **本文档是 v1 + v2 的合并最终版**，定位差异：
>
> | 文档 | 定位 |
> |---|---|
> | v1 [`business_focused_repos_for_newcomers.md`](business_focused_repos_for_newcomers.md) | 12 个项目说明书（**做什么 / 怎么读**）|
> | v2 [`business_focused_repos_v2_data_driven.md`](business_focused_repos_v2_data_driven.md) | 5 个 GAP 补充（**为什么补**）|
> | **v3 本文** | **完整路径地图 + 内化产出计划**（**先读什么 / 读到什么程度 / 产出什么**）|
>
> **设计原则**：
>
> - ❌ 不绑定目标公司池（"哪家 CEX / 哪条 L2 都不限定"）
> - ✅ 按 **业务通用性 × 招聘官认可度 × 单位时间约面率** 三维排序
> - ✅ 每个 stage 都有可投递简历的 deliverable

---

## 一、最终路径图（10 周 / 8 必读 + 1 选读）

```
┌─ Stage 1：DeFi 基础盘（4 周）═══════════════════════════════════════════
│   W1  Uniswap V3        → AMM 集中流动性
│   W2  Aave V3           → 借贷利率 + 清算
│   W3  MakerDAO          → 稳定币 CDP + 拍卖
│   W4  Lido              → LST + 信标链交互
│   ────────────────────────
│   📦 内化产出：DeFi 协议研究博客 4 篇 + Aave Java/Go Adapter Demo
│   🎯 此时可投：DeFi 协议方 + 任何"懂 DeFi"的 CEX/钱包岗位
│
├─ Stage 2：CEX + 钱包硬实力（3 周）═══════════════════════════════════════
│   W5  dYdX V4           → 链上撮合 + Go Indexer 后端（一鱼三吃）
│   W6  Binance tss-lib   → MPC/TSS 钱包后端
│   W7  Safe              → 多签托管 + Module 机制
│   ────────────────────────
│   📦 内化产出：Go Indexer Demo（订单 → Postgres）+ MPC 私钥分片 Demo
│   🎯 此时可投：CEX 撮合岗 + 钱包/Custody 后端 + DAO 治理工具岗
│
├─ Stage 3：差异化概念（2 周，1 选 1）═══════════════════════════════════════
│   W8  三选一：
│       ① EigenLayer    → Restaking 概念（最热）
│       ② LayerZero V2  → 通用跨链桥
│       ③ Pendle        → 收益衍生品（PT/YT）
│   ────────────────────────
│   📦 内化产出：选 1 个写"前沿叙事博客"
│   🎯 此时可投：上述方向的协议 / 基建 / 工具岗
│
└─ Stage 4：写出来 + 讲出来（持续）═════════════════════════════════════════
    ▢ 简历项：1 段 = "DeFi 协议研究项目 + 5 个业务故事 + Aave Demo"
    ▢ GitHub：repos/aave-demo + repos/dydx-indexer-demo + repos/mpc-keygen-demo
    ▢ 公开物：Notion/掘金 8 篇博客（每个项目 1 篇）+ 1 份 Anki 复习卡片
    ▢ 面试卡：每个项目准备 5 个高频题答案（共 40 个）
```

**为什么是这个顺序**（最通用 → 最特化）：

| 周 | 项目 | 通用性 | 约面率 | 单位时间产出 | 排在这周的理由 |
|---|---|---|---|---|---|
| W1 | Uniswap V3 | ★★★★★ | ★★★★★ | ★★★★★ | 任何 Web3 后端面试 100% 会问 AMM |
| W2 | Aave V3 | ★★★★★ | ★★★★★ | ★★★★★ | 借贷+清算是 CEX/DeFi 共通必问 |
| W3 | MakerDAO | ★★★★★ | ★★★★★ | ★★★★ | 稳定币是华人面试官最爱问的（DAI 标杆）|
| W4 | Lido | ★★★★★ | ★★★★★ | ★★★★ | 所有 Staking/Restaking 都从 LST 起步 |
| W5 | dYdX V4 | ★★★★ | ★★★★★ | **★★★★★★** | **撮合+Indexer+Go 一鱼三吃**，最高性价比 |
| W6 | Binance tss-lib | ★★★ | ★★★★★ | ★★★★★ | MPC 是钱包岗的"立刻进面"关键词 |
| W7 | Safe | ★★★★ | ★★★★ | ★★★★ | 多签+Module 是 DeFi 后端必修 |
| W8 | 选 1 | ★★★ | ★★★★ | ★★★ | 差异化亮点，按个人兴趣选 |

---

## 二、每个项目的精读 Checklist

### W1 — Uniswap V3（AMM 标杆）

**📍 仓库**：`repos/dex/uniswap-v3-core/`

**🎯 4 天精读路径**：

| 天 | 文件 | 关注什么 | 自检题 |
|---|---|---|---|
| D1 | `contracts/UniswapV3Pool.sol`（**主入口**）| `mint` / `burn` / `swap` / `collect` 4 个核心 fn 的参数与状态变更 | 一个 swap 跨多个 tick，gas 怎么累积？ |
| D2 | `contracts/libraries/TickMath.sol` + `SqrtPriceMath.sol` | sqrtPriceX96 ↔ tick 的对数转换，给定 amountIn 算 sqrtPrice 变化 | 为什么用 sqrt(price) 而不是 price？为什么用 Q96 定点数？|
| D3 | `contracts/libraries/SwapMath.sol` + `Position.sol` | 单步 swap 计算（一个 tick 内）+ LP 持仓数据结构 | LP 提供流动性时如果 token0/token1 比例不对会发生什么？ |
| D4 | 总结 + 业务故事卡 | "V3 比 V2 资本效率高 1000x 是怎么算出来的"完整答案 | 5 道题全过 → 进入 W2 |

**🔑 设计关注点**（面试问的不是代码，是"为什么这么设计"）：

- **Tick spacing 机制**：为什么不是连续的价格区间，而是离散 tick？ → gas 优化
- **Position fee tracking**：每个 LP 的 fee 是怎么 lazy 累积的？ → `feeGrowthInside`
- **Oracle TWAP**：V3 的价格预言机为什么是"环形 buffer"？ → 链上 cardinality

**📝 内化产出**（每个项目都做）：
- 业务故事卡（300 字）：用日常话讲清"V3 在做什么 + 创新点"
- 5 道高频题答案（每题 200 字）：写完贴博客
- 1 段简历项：*"系统读过 Uniswap V3 核心 4 文件（Pool/TickMath/SqrtPriceMath/SwapMath），能从 Q96 定点数推导到 swap 跨 tick 的完整流程"*

---

### W2 — Aave V3（借贷+清算标杆）

**📍 仓库**：`repos/lending/aave-v3-core/` + `repos/lending/aave-utilities/`

**🎯 4 天精读路径**：

| 天 | 文件 | 关注什么 | 自检题 |
|---|---|---|---|
| D1 | `contracts/protocol/pool/Pool.sol` | `supply` / `borrow` / `repay` / `withdraw` / `liquidationCall` 5 个入口 | aToken 转账时余额怎么处理？为什么没有 Transfer event？|
| D2 | `contracts/protocol/tokenization/AToken.sol` + `VariableDebtToken.sol` | rebase token 实现 | aToken 的 balanceOf 是怎么"自动累息"的？|
| D3 | `contracts/protocol/libraries/logic/LiquidationLogic.sol` | 清算流程（健康因子 → bonus → swap） | liquidationCall 谁都能调，激励怎么设计？|
| D4 | `contracts/protocol/libraries/logic/ReserveLogic.sol` | Jump Rate 利率模型 | utilization 超 80% 时利率为什么突然变陡？|

**🔑 设计关注点**：

- **Isolation Mode**：为什么 GHO 这种新资产要开 isolation？ → 限制借贷规模隔离风险
- **E-Mode**：稳定币之间为什么 LTV 能到 95%？ → 风险分类降低系数
- **Flash Loan**：闪电贷在 Aave 是怎么实现的？为什么是同 tx 内归还？

**📝 内化产出**（**这周要写代码！**）：
- **Aave Java/Go Adapter Demo**（**简历核心**）：
  - 用 web3j（Java）或 go-ethereum（Go）连 Sepolia 测试网
  - 调用 `Pool.supply()` 存 USDC
  - 调用 `Pool.borrow()` 借 ETH
  - 监听 `LiquidationCall` event 并解析
  - 计算用户的实时 APY（参考 `aave-utilities` 的 TS 算法翻译）
  - 仓库结构：`repos/aave-demo/{cmd,internal/aave,internal/abi}` 5 个 Go 文件就够
- 简历项升级：*"基于 Aave V3 用 Go (web3-ethereum) 实现 DeFi Adapter，覆盖 supply/borrow/liquidation 监听全流程"*

---

### W3 — MakerDAO（稳定币 CDP 始祖）

**📍 仓库**：`repos/stablecoin/makerdao-dss/` + `repos/stablecoin/makerdao-auction-keeper/`

**🎯 3 天精读路径**：

| 天 | 文件 | 关注什么 | 自检题 |
|---|---|---|---|
| D1 | `src/vat.sol`（**核心账本**）| 双重记账（gem/dai/ilk/urn）数据结构 | DAI 的稳定费是怎么累积的？为什么用 chi 累积器而不是按秒计息？|
| D2 | `src/jug.sol` + `src/spot.sol` + `src/dog.sol` | 稳定费引擎 + 价格预言机 + 清算触发 | CDP 的 c-ratio (150%) 怎么决定？为什么不是 110% 或 200%？|
| D3 | `src/clip.sol`（**Dutch Auction 清算**）| Dutch Auction 拍卖逻辑 | Dutch Auction (LIQ 2.0) 比 English Auction 优势在哪？|

**🔑 设计关注点**：

- **Vat 的 ilk/urn 设计**：为什么所有抵押品共用一个 vault 账本？ → gas + 复用
- **PSM (Peg Stability Module)**：USDC 大量进入 Maker 后社区为什么批评？ → 中心化担忧
- **Emergency Shutdown**：紧急关停模块（end.sol）解决了什么治理问题？

**📝 内化产出**：
- 业务故事卡：DAI vs USDT vs USDC 三类稳定币的"信用基础"差异
- 5 道高频题答案
- ⚠️ **不写代码 demo**（合约都是 Solidity 0.5 老语法，写后端 demo ROI 低）

---

### W4 — Lido（LST 龙头）

**📍 仓库**：`repos/stablecoin/lido-dao/` + `repos/stablecoin/lido-oracle/`（Python，**有真实后端可读**）

**🎯 3 天精读路径**：

| 天 | 文件 | 关注什么 | 自检题 |
|---|---|---|---|
| D1 | `contracts/0.4.24/Lido.sol` + `StETH.sol` | rebase token 实现（**面试高频**） | stETH 是 rebase token，为什么 1inch / Uniswap 上是 wstETH？|
| D2 | `contracts/0.8.9/WithdrawalQueueERC721.sol` + `oracle/AccountingOracle.sol` | 退出队列 + 链下→链上预言机 | Withdrawal Queue 是 FIFO 还是按金额？|
| D3 | `lido-oracle/` Python 仓库 | **真实生产级 Python 后端阅读**：怎么从信标链拉数据 push 到合约 | AccountingOracle 为什么是 daily 不是 realtime？|

**🔑 设计关注点**：

- **rebase vs wrapped 的取舍**：rebase 体验好但破坏 ERC20 兼容（Aave 上不能直接抵押 stETH） → wstETH 解法
- **Withdrawal Queue 的 NFT 化**：为什么把退出请求做成 ERC721？ → 可转让 + 排队
- **CSM (Community Staking Module)**：Lido 占 ETH 30%+ 中心化担忧的应对

**📝 内化产出**：
- 业务故事卡 + 5 题答案
- **Python 后端读后笔记**：lido-oracle 是难得能读的 DeFi 后端，记录"它怎么把信标链 state 转成合约调用"的 3 个关键模块
- 简历项：*"读过 Lido Oracle Python 后端实现，理解链下信标链状态如何 push 到链上 AccountingOracle"*

---

### Stage 1 自检 → 进 Stage 2

完成 W1-W4 后，**对镜子讲 3 分钟**：

> "DeFi 我读过 4 个核心协议：Uniswap 是 AMM、Aave 是借贷、Maker 是稳定币、Lido 是 LST。
> 它们的核心机制各自是 _____、_____、_____、_____。
> 我自己用 Go 写过 Aave Adapter Demo，能调用 supply/borrow + 监听清算事件。"

讲不出来 → 回去补；讲得出来 → 进 W5。

---

### W5 — dYdX V4（**全 v3 性价比最高的项目** · Go + 撮合 + Indexer 三位一体）

**📍 仓库**：`repos/trading-engine/dydx-v4-chain/`

**🎯 5 天精读路径**（**比其他周长 2 天，因为一鱼三吃**）：

| 天 | 模块 | 关注什么 | 自检题 |
|---|---|---|---|
| D1 | `protocol/x/clob/keeper/clob_pair.go` + `orders.go` | **撮合主模块**：PlaceOrder/CancelOrder/Match 数据结构 | 链上 OrderBook 与 CEX 内存撮合的延迟差距怎么解决？|
| D2 | `protocol/x/clob/keeper/deleveraging.go` + `liquidations.go` | 清算 + ADL（Auto-Deleveraging）流程 | ADL 什么情况触发？为什么 LP 输不起？|
| D3 | `protocol/x/perpetuals/keeper/perpetuals.go` + `prices/keeper/oracle.go` | 永续市场状态（funding/OI）+ 链下价格 push | Funding fee 在链上怎么计算和结算的？|
| D4 | `indexer/services/ender/`（**Go 真后端 indexer**）| 链上 event → Postgres 全 Go 实现 | 数据库 schema 怎么设计？怎么处理重组？|
| D5 | `indexer/services/socks/` + `comlink/` | WebSocket push + REST API 服务 | K 线 / 持仓推送给前端的协议设计？|

**🔑 设计关注点**（这部分会让你在 CEX 后端面试一开口就懂行）：

- **撮合放在共识层还是应用层**：dYdX 选了 ABCI app（应用层），原因？
- **Tendermint 1.5 秒出块 vs CEX 微秒级**：怎么做到接近 CEX 体验？
- **Indexer 怎么处理 chain reorg**：dYdX V4 如果出块回滚，已写入 Postgres 的订单状态怎么回滚？
- **EventManager 模式**：怎么把链上 event 解析+聚合+持久化解耦？

**📝 内化产出**（**这周是简历最强一段**）：

- **Go Indexer Demo**（推荐）：
  - 用 `go-ethereum/ethclient` 监听 Sepolia 测试网某 ERC20 的 Transfer 事件
  - 写入 Postgres（参考 dYdX `ender` 的 EventManager 模式）
  - 提供 REST API 查询任意地址的转账历史
  - 最简版：`repos/indexer-demo/{cmd,internal/listener,internal/repo}` 6 个 Go 文件
- 简历项升级：*"基于 dYdX V4 indexer 架构，用 Go 实现 ERC20 链上事件 indexer Demo（go-ethereum + Postgres），覆盖订阅/解析/持久化/REST 全链路"*
- **业务故事**：*"我读过 dYdX V4 的链上撮合，他们用 Cosmos SDK 把订单簿做成 ABCI module，PlaceOrder 和 Match 函数在 `clob/keeper/` 里几百行 Go 实现核心逻辑。CEX 的撮合放在 Java 应用层，本质上是同一套对手簿撮合，差别只在共识与本地内存。"*

---

### W6 — Binance tss-lib（MPC/TSS 钱包后端）

**📍 仓库**：`repos/mpc-wallet/binance-tss-lib/`

**🎯 3 天精读路径**：

| 天 | 模块 | 关注什么 | 自检题 |
|---|---|---|---|
| D1 | `ecdsa/keygen/` 全部 5 round | DKG 分布式密钥生成（私钥从未在任何一方完整存在） | 怎么确保某方不会"装作收到"实则没收到分片？|
| D2 | `ecdsa/signing/` 全部 round | 门限签名（M-of-N 方协作产生签名） | GG18 vs GG20 的安全漏洞修复？|
| D3 | `tss/messages.go` + `crypto/paillier/` | 多方消息路由 + Paillier 同态加密 | 怎么处理消息丢失/乱序？|

**🔑 设计关注点**：

- **MPC vs 多签**：MPC 把"门限"放链下、Safe 把"门限"放链上，业务取舍？
- **DKG 重分片**：增删 party 时不重新生成主私钥，怎么做到？
- **PUR 行业落地**：Fireblocks / Cobo / Safeheron 怎么把这套 Go lib 包成生产级服务？

**📝 内化产出**：
- **MPC Demo**（**钱包岗杀手锏**）：
  - 用 tss-lib 在本地起 3 个 goroutine 模拟 3 个 party
  - 跑完整的 keygen → signing 流程，输出 ECDSA 签名
  - 用 secp256k1 还原出公钥并验证签名
  - 仓库结构：`repos/mpc-demo/{main.go,party.go,storage.go}` 3 个 Go 文件
- 简历项：*"基于 Binance tss-lib 实现 3-of-3 MPC ECDSA Demo，完整跑通 DKG + 门限签名流程"*

---

### W7 — Safe（多签托管标准）

**📍 仓库**：`repos/innovation/safe-smart-account/` + `repos/innovation/safe-transaction-service/`（**Python 真后端**）

**🎯 3 天精读路径**：

| 天 | 文件 | 关注什么 | 自检题 |
|---|---|---|---|
| D1 | `contracts/Safe.sol` + `OwnerManager.sol` | execTransaction 怎么验证 M-of-N 签名 | 签名按什么顺序排？为什么这么排？|
| D2 | `contracts/base/ModuleManager.sol` + `GuardManager.sol` | Module 扩展机制 + 交易守卫 | Module 机制有什么用？举一个真实 Module 例子（Allowance/Recovery）？|
| D3 | `safe-transaction-service/` Python 后端 | 交易聚合、签名收集、push 通知 | 为什么需要存所有签名？为什么不上链？|

**🔑 设计关注点**：

- **EIP-1271**：合约钱包给 DApp 签名怎么验证？
- **Module + Guard 的关系**：Module 加功能、Guard 加约束，组合可以做什么？
- **CEX 冷钱包用 Safe**：会加哪些 Module 来增强安全（多人审批 + 时间锁 + 限额）？

**📝 内化产出**：
- 业务故事卡：MPC vs 多签 vs Safe Module，3 类钱包托管的差异
- 简历项：*"读过 Safe 多签合约 + Python transaction service，理解 M-of-N 签名收集、Module 扩展、EIP-1271 合约钱包签名"*

---

### Stage 2 自检 → 进 Stage 3

完成 W5-W7 后，**对镜子讲 3 分钟**：

> "CEX 后端我读过 dYdX V4，撮合放共识层 + Indexer 全 Go，自己写过 ERC20 indexer demo。
> 钱包后端我读过两类托管模型：MPC（tss-lib）和多签（Safe），自己跑通过 3-of-3 MPC keygen+signing。
> 跨链桥读过 CCTP（burn-mint 模式），下周补 LayerZero 的 lock-mint + DVN 模型。"

讲不出来 → 回去补；讲得出来 → 进 W8。

---

### W8 — 三选一（按"想长期深耕的方向"选）

| 选项 | 仓库 | 学完能讲 | 适合谁 |
|---|---|---|---|
| **① EigenLayer** | `repos/innovation/eigenlayer-contracts/` + `eigensdk-go/` | "Restaking 怎么把 ETH 安全性变成市场" | 想做 L2 / 基建 / Operator 节点 |
| **② LayerZero V2** | `repos/bridge/layerzero-v2/` | "通用桥的 DVN 安全模型 + 跨链 DApp 设计" | 想做跨链 DApp / 桥后端 |
| **③ Pendle V2** | `repos/derivatives/pendle-core-v2/` | "PT/YT 怎么把利率拆成可交易资产" | 想做 DeFi 利率衍生品 |

**统一精读节奏**：3 天 / 3-5 个核心文件，每个文件 ≤ 1.5 小时。详见 v1 文档对应章节。

**📝 内化产出**：
- 选 1 个写"前沿叙事博客"（800 字）
- 业务故事卡 + 5 题答案

---

## 三、内化产出汇总（10 周后简历可写什么）

完成 W1-W8 后，简历"项目经验"一段长这样：

```
DeFi 协议研究与实现（个人项目，2026.05 — 2026.07）

系统拆解 Web3 主流协议核心代码：
  - DeFi 协议：Uniswap V3 / Aave V3 / MakerDAO DSS / Lido（4 个）
  - CEX/钱包基建：dYdX V4 链上撮合 / Binance tss-lib MPC / Safe 多签（3 个）
  - 前沿叙事：EigenLayer Restaking（or LayerZero / Pendle，二选一）
  覆盖 30+ 核心合约文件 + 3 个真实 Go/Python 后端项目（dYdX indexer / Lido Oracle / Safe Service）

输出 8 篇业务分析博客（在 [博客地址]），其中：
  - 《Uniswap V3 集中流动性的数学推导》
  - 《Aave V3 清算流程的工程取舍》
  - 《dYdX V4 链上撮合 vs CEX 内存撮合》
  - 《MPC 钱包的私钥分片与门限签名》

实现 3 个开源 Demo（[GitHub 链接]）：
  1. aave-demo（Go + go-ethereum）：supply/borrow/liquidation 监听
  2. erc20-indexer-demo（Go + Postgres）：参考 dYdX V4 Indexer 架构
  3. mpc-keygen-demo（Go + tss-lib）：3-of-3 ECDSA Demo
```

→ **这一段简历对标的岗位池**：所有 Web3 后端 + CEX 撮合/风控 + 钱包/Custody + DeFi 协议方 = **覆盖你 884 个命中岗位 90%+**。

---

## 四、配套：每周一个固定动作（防止读完就忘）

### 每周日晚 30 分钟"内化"流程

```
1. 业务故事卡（5 分钟）
   - 用 1 段话讲清这周读的协议在做什么 + 创新点
   - 写到 Notion 或 Anki，每周累加

2. 5 题答案（15 分钟）
   - 把当周文档里的 5 道高频题写成 200 字答案
   - 重点：用"权衡（tradeoff）"语言写，不写"这就是这样"

3. 1 段简历更新（5 分钟）
   - 在简历的"项目经验"末尾加一句
   - 例：W2 完成后加 "+ 实现 Aave V3 Adapter Demo (Go)"

4. 对镜子讲 3 分钟（5 分钟）
   - 假装面试官问"讲讲你最近研究的 X 协议"
   - 卡壳 → 回去补
   - 讲得流畅 → 进下周
```

### 每个 Stage 完成后的"自检表"

| 检查项 | 通过标准 |
|---|---|
| 业务故事 | 用 3 分钟讲清这个 stage 的核心机制（不看资料）|
| 5 题答案 | 每题能讲 200 字以上，且包含"为什么这么设计"|
| Demo 跑通 | Stage 1 至少 1 个 Demo / Stage 2 至少 2 个 Demo |
| 博客发出 | 至少 2 篇业务分析（公开链接）|

→ **任一项不通过，不要进入下一 stage**。宁可慢，不可虚。

---

## 五、立即开始

```bash
# 已 clone 的项目（如还没 clone 完）：
bash web3-job-hunting/scripts/clone_repos.sh --essential       # W1-W3 + Pendle
bash web3-job-hunting/scripts/clone_repos.sh --w3              # 补 W4 Lido
bash web3-job-hunting/scripts/clone_repos.sh --gap-essential   # W5-W7 + W8 之 LayerZero

# Stage 1 启动（W1 第一天）：
cd web3-job-hunting/repos/dex/uniswap-v3-core
cursor contracts/UniswapV3Pool.sol
# → 按 W1-D1 checklist 读 mint/burn/swap/collect 4 个 fn
```

---

## 六、可选附加项（4 周后再考虑）

读完 8 个项目后，如果还想加深：

| 选项 | 适合谁 |
|---|---|
| **WalletConnect 协议**（GAP-2 之 2.3） | 想做 DApp 钱包前后端 |
| **Wormhole Guardian**（GAP-3 之 3.2，全 Go）| 已经投了 Wormhole 但 LayerZero 不够 |
| **Erigon**（GAP-4 之 4.2）| 投 RPC 服务商（Alchemy / Infura）|
| **GMX V2**（v1 之 W4-C）| 想做永续 DEX 协议方 |
| **Curve / Ethena**（v1 之 第 2 / 第 6）| 稳定币方向想加深 |

> 这些是"长尾"，不影响主线 8 个项目的简历强度。
