# 强业务项目清单 v2（基于最新 884 命中岗位反推）

> **本文档定位**：v1 [`business_focused_repos_for_newcomers.md`](business_focused_repos_for_newcomers.md) 的**增量版**
>
> v1 = 12 个 DeFi/钱包/跨链项目（4 周冲刺基础）
> **v2 = 用 884 个真实命中岗位反推，找出 v1 没覆盖的 5 个高频业务方向，每个方向补 1-2 个仓库**
>
> **输入数据**：5 个数据源 884 命中岗位（ATS 80 + 飞书内推 348 + Telegram 290 + web3.career 关键词搜 117 + GitHub 招聘 issue 49）
> **筛选窗口**：近 30 天发布，确保跟当前招聘需求一致

---

## 一、数据驱动：JD 业务方向词频排名

> 把近 30 天 78 个命中岗位的 title + description 跑词频统计，按"业务关键词命中数"排序：

| 排名 | 业务方向 | 30天命中岗位 | v1 是否已覆盖 | 缺口 |
|---|---|---|---|---|
| 1 | DeFi 协议（AMM/借贷/收益） | 42 | ✅ Uniswap V3 + Aave V3 + Pendle | 已饱和 |
| 2 | 钱包/托管 / **MPC** / Custody | 22 | ⚠️ 只有 Safe 多签 | **缺 MPC/TSS 后端** |
| 3 | **撮合引擎** / Trading Engine / Order Book | 17 | ❌ 零覆盖 | **必补** |
| 4 | Staking / 质押 / LST / LRT | 15 | ✅ Lido + EigenLayer | 已饱和 |
| 5 | 永续 / Derivatives / Perp | 12 | ✅ GMX V2 | 可加 dYdX |
| 6 | 跨链桥 / Bridge | 12 | ⚠️ 只有 Circle CCTP | **缺通用桥** |
| 7 | 现货 / Spot 交易 | 11 | ❌ 与撮合合并 | 见 GAP-1 |
| 8 | Solana 生态 | 11 | ❌ 零覆盖 | 见说明 |
| 9 | Risk / 风控 | 6 | ❌ 零覆盖 | 业务点小，不补 |
| 10 | OTC / 做市 | 6 | ❌ 零覆盖 | 业务点小，不补 |
| 11 | 稳定币 | 5 | ✅ Maker + Ethena | 已饱和 |
| 12 | Indexer / 链上数据 | 4 | ⚠️ 只有 subgraph | **缺真后端 indexer** |

> **5 个 GAP**（按数据 + 用户语言 Go/Java 对口度排序）：
> 1. CEX 撮合引擎（17 命中，对应 Crypto.com / Binance / Bybit / Gate Java/Go 后端）→ **必补**
> 2. MPC 钱包后端（22 命中，PURVIEW/BITFIT/Bitgo Go 后端）→ **必补**
> 3. 通用跨链桥（12 命中，Wormhole 主 Go）→ **必补**
> 4. 链上 Indexer 后端（4 命中但 JD 默认提）→ **建议补**
> 5. Solana DeFi（11 命中但 Rust 为主）→ **降级为业务知识，不必读源码**

---

## 二、5 个 GAP 方向的项目推荐（S/A 双维度评级）

> **评级**：
> - **S** = 业务匹配 + 招聘官认可双 S → 必读
> - **A** = 单维度 S → 选读
> - **B** = 同质化项目，挑一个就行

### GAP 1 — CEX 撮合引擎（17 命中，零覆盖）

> **为什么必补**：v1 全是 DeFi 协议方思维，但**你目标公司池里 CEX 占 7 家**（Binance / Bybit / Gate / OKX / Bitget / Crypto.com / Coinbase），CEX 后端面试**必问撮合**。
>
> **对口岗位**（最近 14 天反复出现）：
> - Crypto.com **Senior Java Developer (Trading Platform)** ×3 次出现
> - Bybit **Backend Java Risk** + Perps Trading Engine
> - 飞书内推池里"Java 后台撮合 / 永续合约 / 现货"高频

#### 1.1 dYdX V4（Cosmos chain + 链上 OrderBook + Go）⭐⭐⭐⭐⭐ **S**

**业务一句话**：把订单簿从 CEX 完全搬到链上，**用 Cosmos SDK + Tendermint 共识 + 自定义撮合 module 实现链上 LOB**（Liquid Order Book），日均 10 亿美金成交量，是当前**唯一成功的链上订单簿衍生品 DEX**。

**主仓库**：<https://github.com/dydxprotocol/v4-chain>（**Go 主导**，与你语言对口）

| 模块 | 这个模块在做什么 | 必懂度 |
|---|---|---|
| `protocol/x/clob/keeper/orders.go` | **订单簿主模块**（PlaceOrder / CancelOrder / Match） | ★★★★★ |
| `protocol/x/clob/keeper/liquidations.go` | 永续清算引擎 | ★★★★★ |
| `protocol/x/clob/types/match.go` | Match 撮合数据结构 | ★★★★ |
| `protocol/x/perpetuals/keeper/perpetuals.go` | 永续市场状态（funding / OI） | ★★★★ |
| `protocol/x/prices/keeper/oracle.go` | 价格预言机（链下 push） | ★★★ |
| `indexer/services/ender/` | **链上事件 → Postgres 全 Go 实现** | ★★★★★ |

**面试 5 高频问题**：
1. 链上 OrderBook 与 CEX 内存撮合的延迟差距怎么解决？dYdX V4 用 Tendermint 出块时间是 1.5 秒，怎么做到接近 CEX 体验？
2. dYdX V4 的撮合是放在共识层还是应用层？为什么放在 ABCI app 里？
3. 永续合约的 funding fee 在链上怎么计算和结算的？
4. Indexer 服务（Go）怎么把链上 event 聚合成订单状态、用户持仓、K 线？数据库选型？
5. 与 GMX V2（vAMM 模式）相比，订单簿模式优劣？

**直接面试卖点**：
> *"我研究过 dYdX V4 的链上撮合实现，他们用 Cosmos SDK 把订单簿做成共识层之上的 module，Match 函数在 `clob/keeper/orders.go` 里几百行 Go 实现核心逻辑，你们 Bybit 的撮合放在 Java 应用层，本质上是同一套对手簿撮合，差别只在共识与本地内存。"* → CEX 招聘官立刻知道你"懂业务"。

#### 1.2 LMAX Disruptor（Java，超低延迟 ring buffer）⭐⭐⭐⭐ **A**

**业务一句话**：LMAX 是英国早期的高频外汇交易所，开源了他们撮合引擎用的"超低延迟无锁队列"——**所有 Java CEX 撮合后端都在用或参考这个**（包括 Binance 早期撮合）。

**主仓库**：<https://github.com/LMAX-Exchange/disruptor>（Java，60K star）

| 模块 | 这个模块在做什么 | 必懂度 |
|---|---|---|
| `src/main/java/com/lmax/disruptor/RingBuffer.java` | 无锁 ring buffer（撮合事件队列） | ★★★★★ |
| `src/main/java/com/lmax/disruptor/EventHandler.java` | 事件处理器接口（撮合 worker） | ★★★★ |
| `src/main/java/com/lmax/disruptor/dsl/Disruptor.java` | DSL 构建器 | ★★★ |

**面试 3 高频问题**：
1. 撮合引擎为什么不用 BlockingQueue 用 RingBuffer？解决了什么问题？
2. 单线程撮合 vs 多线程撮合，CEX 为什么主流是单线程？（顺序保证 + L1 cache 命中）
3. 撮合到清算到资金账户更新，怎么做到跨服务的"原子一致"？

**为什么也推荐**：你已经看过 [`web3-interview-sharing/Web3综合资料库/CEX交易所资料/CEX撮合订单系统架构设计_顺序保证方案.pdf`](../../web3-interview-sharing/Web3综合资料库/CEX交易所资料/) 这份资料 → Disruptor 是它在工程上的**最直接落地参考**。

---

### GAP 2 — MPC 钱包后端（22 命中，仅 Safe 多签覆盖）

> **为什么必补**：22 个钱包岗里大多是 **MPC/TSS 方向**（Threshold Signature Scheme），Safe 是**链上多签**，与 MPC 完全是两个流派。
>
> **对口岗位**（最近 14 天）：
> - **PURVIEW** Web3 Fireblocks Custody Infrastructure Developer（Java/Python/Go/Solidity）
> - **BITFIT LABS** Web3 Senior Backend / **MPC Wallet Engineer (Golang)**
> - **Bitgo** Web3 Senior Offensive Security Engineer
> - 飞书内推池里 Cobo / Safeheron 等"MPC 钱包后端"高频

#### 2.1 Binance tss-lib（Go MPC 算法库）⭐⭐⭐⭐⭐ **S**

**业务一句话**：Binance 开源的 **MPC-TSS 阈值签名库**，实现了 **GG18/GG20 ECDSA 协议**——**所有华人 MPC 钱包公司（Safeheron / Cobo / SinoHope）都基于这个 fork**，是 Web3 MPC 的事实标准。

**主仓库**：<https://github.com/bnb-chain/tss-lib>（Go，2.1K star）

| 模块 | 这个模块在做什么 | 必懂度 |
|---|---|---|
| `ecdsa/keygen/` | **DKG 分布式密钥生成**（多方协议产生分片，私钥从未在任何一方完整存在） | ★★★★★ |
| `ecdsa/signing/` | **门限签名**（M-of-N 方协作产生签名，无需聚合私钥） | ★★★★★ |
| `ecdsa/resharing/` | **密钥重分片**（增删 party 时重新分发） | ★★★★ |
| `crypto/paillier/` | **Paillier 同态加密**（MPC 协议的密码学基石） | ★★★ |
| `crypto/zkp/` | 零知识证明（验证各方诚实参与） | ★★★ |
| `tss/messages.go` | 多方消息路由（**面试常考**：怎么处理消息丢失/乱序） | ★★★★ |

**面试 5 高频问题**：
1. MPC vs 多签：链上多签把"门限"放链上，MPC 把"门限"放链下，业务上各有什么 tradeoff？
2. GG18 vs GG20：GG20 修了 GG18 的什么安全漏洞？（GG18 的 attack on Round 6）
3. DKG 协议中，怎么确保某方不会"装作收到"实则没收到分片？
4. 怎么设计一个 MPC 钱包的运维体系？分片存哪？私钥分片备份怎么做？
5. Fireblocks 的 MPC 黑盒做了什么 Binance tss-lib 没做的？

**直接面试卖点**：
> *"我读过 Binance tss-lib 的 GG20 实现，他们的 keygen round 1-5 在 `ecdsa/keygen/` 里，每一步的消息发送和验证都很清晰，PURVIEW 和 BITFIT 的 JD 提的 MPC 后端，本质就是把这套 lib 包成 gRPC 服务 + Postgres 持久化分片状态。"*

#### 2.2 ZenGo Multi-party ECDSA（Rust 实现，对照学习）⭐⭐⭐⭐ **A**

**业务一句话**：ZenGo（以色列 MPC 钱包）开源的**纯 Rust MPC ECDSA 实现**，做对照能更清晰理解协议本质。

**主仓库**：<https://github.com/ZenGo-X/multi-party-ecdsa>

**只看一个文件**：`examples/gg20_keygen_client.rs` + `examples/gg20_signing_client.rs`——**完整可跑的 Demo**。

#### 2.3 WalletConnect Monorepo（**接 dApp 协议，DApp 钱包必学**）⭐⭐⭐⭐ **A**

**业务一句话**：用户钱包（手机 App）↔ DApp（PC 浏览器）的**链下消息中转协议**，所有 Web3 钱包都集成。

**主仓库**：<https://github.com/WalletConnect/walletconnect-monorepo>（TypeScript）+ <https://github.com/reown-com/reown-go>（Go SDK，**用户语言对口**）

| 模块 | 这个模块在做什么 | 必懂度 |
|---|---|---|
| `packages/sign-client/` | Sign API（请求签名/发送交易） | ★★★★★ |
| `packages/core/relayer/` | **WebSocket 中继器**（用户和 DApp 不直连） | ★★★★ |
| `protocols/v2/` | Pairing + Session 双层握手 | ★★★★ |

**为什么推荐**：22 个钱包岗里有些是"DApp 钱包"（不是 Custody 而是用户钱包后端），WalletConnect 是它们的**网络后端必修**。

---

### GAP 3 — 通用跨链桥（12 命中，仅 CCTP 覆盖）

> **为什么必补**：CCTP 是 Circle 自己的 burn-mint 模式，**通用桥（LayerZero / Wormhole）是另一套架构**——Lock-Mint 模式 + 中继器网络，业务模型完全不同。
>
> **对口岗位**：
> - 飞书内推池里"跨链桥后端"高频，特别是华人 LayerZero 生态项目方
> - Wormhole 在招 Go 后端

#### 3.1 LayerZero V2（业务故事最强的桥）⭐⭐⭐⭐⭐ **S**

**业务一句话**：用户在源链 lock token → LayerZero 的 **DVN（Decentralized Verifier Network，多个独立验证器）** 各自验证 → 目标链合约收到至少 N 个 DVN 签名后释放 token，**安全性由用户应用自选 DVN 组合**（可定制）。

**主仓库**：<https://github.com/LayerZero-Labs/LayerZero-v2>（Solidity 主导）+ <https://github.com/LayerZero-Labs/Worker>（**Go 链下中继器**）

| 模块 | 这个模块在做什么 | 必懂度 |
|---|---|---|
| `packages/layerzero-v2/contracts/EndpointV2.sol` | **跨链消息入口**（send / lzReceive） | ★★★★★ |
| `packages/layerzero-v2/contracts/messagelib/UlnConfig.sol` | DVN 配置（核心创新点） | ★★★★★ |
| `packages/oapp-evm/contracts/OApp.sol` | 用户应用基类（**所有跨链 dApp 继承这个**） | ★★★★ |
| Worker 仓库的 `executor/` 目录 | **链下执行器**（Go 实现） | ★★★★ |

**面试 5 高频问题**：
1. LayerZero V1 → V2 的核心改进是什么？（V2 的 DVN 替代 V1 的 Oracle+Relayer 二人模型）
2. LayerZero 的"用户应用自选 DVN"是把信任责任转嫁给应用方，这设计的优劣？
3. Wormhole 19 个 Guardian 多签 vs LayerZero N-of-M DVN，安全模型差异？
4. lock-and-mint 与 burn-and-mint（CCTP）的本质差别？跨链桥的"流动性碎片化"问题？
5. 跨链桥被攻击的 5 种典型方式（重放 / 验证器被收买 / 合约 bug / oracle 被骗 / 中继器作恶）？

#### 3.2 Wormhole（Go 后端最完整）⭐⭐⭐⭐ **A**

**业务一句话**：Solana 生态里最大的桥，**19 个 Guardian 多签**验证模型，**Guardian 节点是 Go 写的**，托管 50 亿+ TVL。

**主仓库**：<https://github.com/wormhole-foundation/wormhole>（**Go 主导**）

| 模块 | 这个模块在做什么 | 必懂度 |
|---|---|---|
| `node/pkg/processor/` | **Guardian 共识处理器**（核心 Go 业务） | ★★★★★ |
| `node/pkg/watchers/` | 多链 watcher（监听各链事件） | ★★★★ |
| `ethereum/contracts/Wormhole.sol` | 以太坊端合约（Verify + Mint） | ★★★★ |

**为什么推 LayerZero 不是 Wormhole 优先**：业务故事 LayerZero 强（DVN 创新），但**纯 Go 后端阅读量 Wormhole 大**。Java 背景的同学可只读 LayerZero，Go 主修可两个都读。

---

### GAP 4 — 链上 Indexer 真后端（4 命中但 JD 普遍要求）

> **为什么补**：v1 只列了 subgraph（属于 The Graph 的查询层），但**真正的 Indexer 后端**（Postgres / ClickHouse 写入 + 实时同步链上事件）是另一套技术栈，**所有 CEX/钱包/分析平台后端都在做**。

#### 4.1 dYdX V4 Indexer（Go 实现，已在 GAP-1 提到）⭐⭐⭐⭐⭐ **S**

**重复利用**：上面 GAP-1 推 dYdX V4 已经包含 `indexer/services/` 目录，里面就是**完整生产级 Go Indexer 范例**：
- `ender`：链上事件 → Postgres（with EventManager 模式）
- `roundtable`：定时聚合任务（24h volume / open interest）
- `socks`：WebSocket push（K 线 / 持仓推送给前端）
- `comlink`：REST API 服务

→ **学完 dYdX V4 = 学了链上撮合 + 学了完整 Indexer 后端**，**性价比最高**。

#### 4.2 Erigon（Ethereum Indexer 客户端）⭐⭐⭐⭐ **A**

**业务一句话**：Go 实现的 Ethereum 全节点 + **极致优化的链上数据 indexer**（重排数据库布局，把 receipt/log 查询提速 10x）。

**主仓库**：<https://github.com/ledgerwatch/erigon>（Go，主流 RPC provider 后端）

**只看 3 个目录**：
- `core/state/database.go` — **数据库 schema 设计**（学怎么把 EVM state 拍平）
- `eth/stagedsync/` — **Staged Sync 模型**（区块同步分阶段，是 Erigon 核心创新）
- `cmd/rpcdaemon/` — **RPC 服务**（与节点解耦的 daemon）

→ 难度比 dYdX 高，**只推给"目标公司含 RPC 服务商（Alchemy / Infura / QuickNode）"** 的同学。

---

### GAP 5 — Solana DeFi（11 命中，但用户不主修 Rust）

> **降级处理**：Solana DeFi 项目对应的岗位多用 Rust，**与你 Java/Go 主语言不直接对口**。
>
> **建议**：**只读业务文档不读代码**，达到"能讲业务故事"即可。读源码的 ROI 太低。

#### 5.1 Drift Protocol V2（Solana 上的 Liquid Order Book）— 业务知识

**业务一句话**：Solana 上最大的链上永续 DEX，**混合订单簿模型**（vAMM + JIT Auction + Spot Order Book），用 Solana 400ms 出块特性做近 CEX 体验。

**只读**：<https://docs.drift.trade/about-v2/welcome> + 代码 README → 1 小时拿到业务故事即可。

#### 5.2 Jupiter Aggregator — 业务知识

**业务一句话**：Solana 最大的 DEX 聚合器，路由 100+ DEX 报价。

**只读**：<https://station.jup.ag/docs/old/swap-api/swap-api-for-developers> → 看路由算法的业务文档。

---

## 三、Go-First 视角：5 个 GAP 项目按"对口度"重排

> 你的画像：**Java 5+ 年熟透 + Go 能写**，目标公司大多 Go 优先。

| 优先级 | 项目 | 主语言 | 对应你哪类目标公司 | 工作量 |
|---|---|---|---|---|
| **P0 必读** | **dYdX V4**（GAP-1 + GAP-4 双覆盖） | Go | Crypto.com / Bybit Trading / 任何 CEX | 8-10h |
| **P0 必读** | **Binance tss-lib**（GAP-2） | Go | PURVIEW / BITFIT / Cobo / Safeheron 钱包后端 | 6-8h |
| **P1 重要** | **LayerZero V2 + Worker**（GAP-3） | Solidity + Go | LayerZero 生态项目方 / 跨链桥后端 | 6-8h |
| **P2 加分** | **LMAX Disruptor**（GAP-1 Java 补强） | Java | Binance / Bitget / Gate Java 后端 | 3-4h |
| **P2 加分** | **Wormhole Guardian**（GAP-3 Go 补强） | Go | Wormhole / Pyth / Solana 生态项目 | 4-6h |
| **P3 选读** | **Erigon**（GAP-4） | Go | RPC 服务商（Alchemy / Infura）| 8-10h |
| **降级** | Drift / Jupiter（GAP-5） | Rust | Solana 项目 — 只读业务文档 | 1-2h |

→ **新增 4 周的 P0 + P1 三个项目（dYdX / tss-lib / LayerZero），合计约 22-26 小时**，完全能塞进 v1 的 W4 后面或替换 W4。

---

## 四、整合到 4 周冲刺方案：v1.5 升级版

> v1 的 W1-W3 不动（DeFi 基本盘），**W4 升级为多选并行**：

| 周 | 学什么 | 学完能讲 |
|---|---|---|
| W1 | Uniswap V3 *（v1 不变）* | "AMM 集中流动性的数学" |
| W2 | Aave V3 *（v1 不变）* | "DeFi 借贷的清算与利率模型" |
| W3 | MakerDAO + Lido *（v1 不变）* | "稳定币和 LST 怎么发行" |
| **W4-A** | **dYdX V4** | "链上撮合 vs CEX 内存撮合的工程取舍" |
| **W4-B** | **Binance tss-lib** | "MPC 钱包的私钥分片与门限签名" |
| **W4-C** | **LayerZero V2** | "通用跨链桥的 DVN 安全模型" |

**W4 三选一策略**（按你目标公司池）：
- **目标 CEX 撮合岗**（Crypto.com / Bybit / Gate）→ 选 **W4-A dYdX V4** + 加分项 LMAX
- **目标 MPC 钱包岗**（PURVIEW / BITFIT / Cobo）→ 选 **W4-B tss-lib**
- **目标跨链桥 / L2 SDK**（LayerZero 生态 / Mantle / Scroll）→ 选 **W4-C LayerZero**

**进阶（4 周后再选）**：
- 想做"DeFi 协议方"深度 → v1 的 W4 选项 **Pendle / EigenLayer / GMX V2**
- 想做"DApp 钱包"前后端 → **WalletConnect**
- 想做"RPC 服务商"基建 → **Erigon**

---

## 五、立即落地：clone 命令补丁

打算更新 `scripts/clone_repos.sh`，新增 5 个 flag：

```bash
# 撮合引擎类（GAP-1）
bash scripts/clone_repos.sh --gap-trading      # dYdX V4 + LMAX Disruptor
# MPC 钱包类（GAP-2）
bash scripts/clone_repos.sh --gap-mpc          # tss-lib + multi-party-ecdsa + WalletConnect Go SDK
# 通用跨链桥（GAP-3）
bash scripts/clone_repos.sh --gap-bridge       # LayerZero V2 + Worker + Wormhole
# Indexer 后端（GAP-4）
bash scripts/clone_repos.sh --gap-indexer      # Erigon（dYdX 已含）
# 一键 GAP 全套（4 个 P0/P1 必读）
bash scripts/clone_repos.sh --gap-essential    # dYdX V4 + tss-lib + LayerZero + LMAX
```

---

## 六、最后一句话总结

> **v1（12 项目）**=  打 DeFi 协议方面试，业务覆盖 80%
> **v2（+5 GAP）** = 补足 **CEX 撮合 + MPC 钱包 + 通用跨链桥**，业务覆盖 95%+
>
> **最优路径**：v1 W1-W3 不动 → W4 按目标公司池选 W4-A/B/C 三选一 → 投递 4 周后再加 P2/P3 加分项。
>
> **数据来源**：本仓库 `scripts/update.py` 一键抓取的 884 个真实命中岗位（5 数据源），词频统计代码在 `reports/jd_summary.md` 同级目录可重跑验证。
