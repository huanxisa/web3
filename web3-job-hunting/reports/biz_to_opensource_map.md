# 业务领域 → 开源项目 学习地图

> 把当前 30 个目标岗位的 JD 反向拆解成 **9 个核心业务方向**，每个方向给出：
> 1. **业务说明**：这条业务在做什么、面试官最常问什么
> 2. **涉及岗位**：哪几家公司、哪几个岗位属于这条
> 3. **推荐开源项目**：每个项目附 GitHub + 难度 + 学习重点 + 面试时怎么用
>
> **核心理念**：技术可以现学，**业务理解是面试时被识破的关键**。读源码不是为了"会写"，是为了能在面试时讲出 "Uniswap V3 为什么把 tick range 设计成这样、Curve 的 invariant 公式怎么推导" 这种业务故事。

---

## 索引

| # | 业务领域 | 涉及目标岗位数 | 推荐学习优先级 |
|---|---|---|---|
| 1 | **L2 / Rollup 核心基础设施（Sequencer · 客户端）** | 4 | ⭐⭐⭐⭐ |
| 2 | **ZK 零知识证明 / zkEVM 电路** | 1 | ⭐⭐（门槛极高） |
| 3 | **CEX Web3 Wallet 业务后端**（HD 钱包·MPC·多链充提） | 5 | ⭐⭐⭐⭐⭐ |
| 4 | **跨平台 Wallet SDK / 浏览器扩展 / 移动端钱包** | 3 | ⭐⭐⭐⭐ |
| 5 | **DeFi 协议集成 / DeFi Adapter** | 1 | ⭐⭐⭐⭐⭐ |
| 6 | **Stablecoin 多链发行 / RWA** | 1 | ⭐⭐⭐⭐ |
| 7 | **链上数据 Indexer / Web3 Data Platform** | 2 | ⭐⭐⭐⭐⭐ |
| 8 | **智能合约审计 / 链上安全 / 黑客复盘** | 5 | ⭐⭐⭐⭐⭐ |
| 9 | **CEX 通用 Java 后端 / Web3 AI 工程** | 8 | ⭐⭐⭐ |

> **建议路径**：先按你想投的公司（主线 A 看 1/2，主线 B 看 3-8）选 2-3 个领域深挖，每个领域读完 1 个开源项目就能在面试里讲一个完整的业务故事。

---

# 业务 1 · L2 / Rollup 核心基础设施（Sequencer · 客户端）

## 业务说明

L2（Layer 2）的核心是把以太坊的交易**打包到 L2 上执行**，再把状态根**结算回 L1**。围绕这条主链路，L2 团队需要写：

- **Sequencer（排序器）**：按顺序接收用户交易，决定打包顺序
- **Execution Client**：执行 EVM 交易（多数 L2 是 Geth 的 fork）
- **Batcher / Submitter**：把交易批次提交到 L1
- **Bridge Contract**：L1 ⇄ L2 资产桥
- **Prover Network**（zkRollup）：生成有效性证明

面试常问：
- "Sequencer 单点宕机怎么办？" → 中心化 vs 去中心化排序器
- "L2 的状态根多久 finalize？" → Optimistic 7 天 vs ZK 1 小时
- "MEV 在 L2 上怎么处理？" → PBS、cross-domain MEV
- "Reorg 在 L2 上有吗？" → soft reorg 与 hard finalization

## 涉及岗位

| 公司 | 岗位 | 必看的开源项目 |
|---|---|---|
| Mantle | Blockchain Engineer 区块链开发工程师 | OP Stack（Mantle 是 OP 系 L2 的演进） |
| Scroll | Blockchain Infrastructure Engineer | Scroll 自家 + Geth |
| Scroll | Web3 Infrastructure Back-end Developer | Scroll 自家 |
| Scroll | Web3 Protocol Researcher | Optimism + Arbitrum 论文 |

## 推荐开源项目

### 1.1 Optimism Bedrock（OP Stack） ⭐⭐⭐⭐⭐
- **GitHub**: <https://github.com/ethereum-optimism/optimism>
- **语言**: Go + Solidity
- **难度**: 中
- **学什么**:
  - `op-node/`：L2 节点的 derivation pipeline（怎么从 L1 calldata 重建 L2 状态）
  - `op-batcher/`：怎么把 L2 交易批次写回 L1
  - `op-proposer/`：怎么把 L2 状态根定期提交到 L1
  - `packages/contracts-bedrock/`：L1 端的 Portal / Bridge 合约
- **面试故事**："Mantle 是 OP 派生链，所以我读了 Optimism Bedrock 的 op-node 源码，理解了 L1 → L2 的 derivation pipeline 是怎么把 L1 上的 batch calldata 重新解析成 L2 区块的。"

### 1.2 Scroll 自家代码 ⭐⭐⭐⭐⭐（Scroll 投递必读）
- **GitHub**: <https://github.com/scroll-tech>
  - `go-ethereum`：Scroll 的 Geth fork → <https://github.com/scroll-tech/go-ethereum>
  - `scroll`：rollup 主体仓库 → <https://github.com/scroll-tech/scroll>
- **语言**: Go + Rust
- **难度**: 高
- **学什么**:
  - Scroll 怎么改 Geth 的 EVM 执行器，让每条指令都能生成 trace 给 prover
  - L1 / L2 桥接合约：`scroll/contracts/`
  - Coordinator 服务：怎么调度 prover 网络生成 ZK proof
- **面试故事**：直接答出 "我读过 scroll-tech/go-ethereum 的 fork diff，知道你们在 EVM 执行器里加了哪些 trace_*  方法给 zkEVM 用" —— 这一句就能区分你和 80% 的应聘者。

### 1.3 Arbitrum Nitro ⭐⭐⭐⭐
- **GitHub**: <https://github.com/OffchainLabs/nitro>
- **语言**: Go
- **难度**: 中-高
- **学什么**:
  - Arbitrum 的 Stylus（让 Rust/C++ 能在 Arbitrum 上写合约）
  - Sequencer 单点 + Anti-trust 设计
  - WASM 验证器（fraud proof 实现）
- **面试故事**：用作横向对比 —— "Optimistic Rollup 用 Nitro 这种 fraud proof，ZK Rollup 用 Scroll/Polygon zkEVM 这种 validity proof，两者在 finality 时间和 prover 成本上的 trade-off 是…"

### 1.4 Reth（Rust Ethereum 客户端）⭐⭐⭐
- **GitHub**: <https://github.com/paradigmxyz/reth>
- **语言**: Rust
- **难度**: 高
- **学什么**:
  - 模块化的客户端架构（Engine API / Stages / DB layer）
  - 比 Geth 更现代的代码组织方式，看完能理解"L2 客户端为什么基本都是 fork"
- **面试故事**：在聊"为什么 L2 客户端用 Geth fork 而不是 Reth"时，能讲出 Reth 的 Engine API 设计 + Geth 历史包袱的对比。

---

# 业务 2 · ZK 零知识证明 / zkEVM 电路

## 业务说明

ZK 证明系统在做的事：把 EVM 执行的每一步**编码成数学约束（电路 / circuit）**，然后用密码学证明 "我确实正确执行了这个 EVM 程序"。

这是 Web3 工程师天花板，门槛包括：
- **数学**：椭圆曲线、有限域、FFT、KZG commitment
- **密码学**：SNARK / STARK / FRI / Plonk / Halo2
- **工程**：Rust 极致优化、GPU 加速 prover

面试常问：
- "Plonk 和 Groth16 的区别？为什么 zkEVM 主要用 Plonk 系？"
- "什么是 lookup table，Halo2 怎么用？"
- "你的 zkEVM 怎么处理 MSTORE 这种内存操作？"

## 涉及岗位

| 公司 | 岗位 | 必看 |
|---|---|---|
| Scroll | Web3 Senior ZK Engineer | Halo2 + Scroll zkEVM 电路 |

## 推荐开源项目

### 2.1 Halo2 ⭐⭐⭐⭐⭐（Scroll 用的就是这个）
- **GitHub**: <https://github.com/zcash/halo2>
- **语言**: Rust
- **难度**: 极高
- **学什么**: PLONK 的电路构造原语、constraint system DSL
- **配套教材**: <https://zcash.github.io/halo2/>（Halo2 The Book）

### 2.2 Scroll zkEVM Circuits ⭐⭐⭐⭐⭐
- **GitHub**: <https://github.com/scroll-tech/zkevm-circuits>
- **语言**: Rust（基于 Halo2）
- **学什么**: 怎么把 EVM 的每条指令实现为电路（add / mul / mload / sstore…）
- **面试故事**：能讲出"Scroll 的 zkEVM 把 STORAGE 操作的 MPT proof 做了哪些优化" —— 直接破格录取级别。

### 2.3 Awesome ZK 学习路径 ⭐⭐⭐
- **GitHub**: <https://github.com/zksync-community-hub/awesome-zksync>
- **GitHub**: <https://github.com/matter-labs/awesome-zero-knowledge-proofs>
- **学什么**: 从入门到进阶的 ZK 学习地图、必读论文清单
- **建议**: 先看 0xPARC 的 ZK Learning Group 录播 → 再啃 Halo2 The Book → 再读 Scroll 电路代码

---

# 业务 3 · CEX Web3 Wallet 业务后端（HD 钱包 · MPC · 多链充提）

## 业务说明

CEX 的钱包系统是金额最大、Bug 最致命的后端。**核心模块**：

- **HD 钱包派生**：BIP32 / BIP44，一棵树派生千万用户的地址
- **多链适配**：EVM（账户模型）、UTXO（BTC/LTC）、Tron、Solana、Sui
- **充值监听**：扫每条链的新区块，识别属于本平台的充值
- **提现签名**：从冷钱包/MPC 出钱，Nonce 管理、重放保护
- **归集服务**：把零散的小额充值定时归集到热钱包
- **MPC（多方计算签名）**：替代单一私钥，3 方各持一份
- **风控**：黑名单地址、异常金额、混币器溯源

面试常问：
- "EVM 链 reorg 时充值怎么办？" → 多确认数 + reorg detection
- "提现并发请求怎么保证 Nonce 不冲突？" → 单点 Nonce 分配器 / Redis 序列号
- "MPC 比 Multi-Sig 好在哪？" → on-chain 隐私 + Gas 节省 + 兼容多链
- "热冷钱包比例多少？" → 行业 5%-10% 热，剩余冷

## 涉及岗位

| 公司 | 岗位 | 必看 |
|---|---|---|
| Binance | Backend Java Engineer (Web3) - Binance Wallet | Trust Wallet Core + WalletKit |
| Binance | Lead Security Engineer (Web3 Wallet/DeFi) | Fireblocks 论文 + tss-lib |
| Bitget | Blockchain Engineer (Digital Wallet) | Trust Wallet Core |
| Binance | Senior Backend Engineer - Java | 通用后端 + 钱包业务 |
| Binance | Senior Java Engineer | 通用后端 |

## 推荐开源项目

### 3.1 Trust Wallet Core ⭐⭐⭐⭐⭐（Binance 旗下、必读）
- **GitHub**: <https://github.com/trustwallet/wallet-core>
- **语言**: C++ / Rust，多语言绑定（Java/Kotlin/Swift）
- **难度**: 中
- **学什么**:
  - 130+ 链的统一抽象：Address、Transaction、Signer
  - 怎么写一个 "Coin" 模板支持新链
  - HD 钱包派生 + BIP39/44 实现
- **面试故事**：投 Binance Wallet 时直接说"我读了你们的 wallet-core，理解了 src/Coin.cpp 的工厂模式怎么扩展新链。" —— Binance HR 听到会立刻识别。

### 3.2 Cobo MPC（tss-lib）⭐⭐⭐⭐⭐
- **GitHub**: <https://github.com/binance-chain/tss-lib>（Binance 出品）
- **GitHub**: <https://github.com/CoboGlobal/mpc-eddsa-engine>
- **语言**: Go
- **难度**: 高
- **学什么**:
  - GG18 / GG20 / CGGMP21 三方签名算法
  - 怎么把 ECDSA 拆成 3 方门限签名
- **面试故事**：聊 MPC 时能说出"Binance tss-lib 用的是 GG20 的优化版本，相比 GG18 把通信轮数从 9 轮降到 6 轮"。

### 3.3 Fireblocks 公开技术博客 ⭐⭐⭐⭐
- **链接**: <https://www.fireblocks.com/blog/category/research>
- **学什么**: 行业最权威的 MPC + HSM + 多链托管设计公开资料

### 3.4 BTCPay Server ⭐⭐⭐
- **GitHub**: <https://github.com/btcpayserver/btcpayserver>
- **语言**: C#
- **学什么**: 一个完整的 BTC 支付/钱包后端，包括 invoice、HD 钱包、扫块、UTXO 管理
- **价值**: BTC UTXO 模型最权威的开源参考

### 3.5 OKX Wallet SDK（开源部分）⭐⭐⭐⭐
- **GitHub**: <https://github.com/okx/js-wallet-sdk>
- **学什么**: OKX 钱包是怎么把 30+ 链统一封装成 JS SDK 的
- **价值**: 投 OKX 时这个 repo 是绕不开的

---

# 业务 4 · 跨平台 Wallet SDK / 浏览器扩展 / 移动端钱包

## 业务说明

钱包不只是后端，**前端钱包** 才是用户交互入口：
- **浏览器扩展**：MetaMask、Rabby、OKX Wallet（Chrome Extension）
- **移动钱包**：Trust Wallet、imToken、TokenPocket
- **跨端共享代码**：业务逻辑用 Rust/TypeScript 写一次，编译给 iOS/Android/Web/Desktop 用

OKX 那 3 个 Rust Cross-Platform Engineer 干的就是这个。

面试常问：
- "Provider Inject 是怎么实现的？" → window.ethereum
- "WalletConnect 是怎么连接 DApp 的？" → WC v2 协议、Pairing/Session
- "EIP-1193 / EIP-6963 是什么？" → 钱包标准化提案

## 涉及岗位

| 公司 | 岗位 | 必看 |
|---|---|---|
| OKX | Senior Software Engineer, Rust (Cross-Platform) | MetaMask + WalletConnect + Trust Core |
| OKX | Staff Software Engineer, Rust (Cross-Platform) ×2 | 同上 |

## 推荐开源项目

### 4.1 MetaMask ⭐⭐⭐⭐⭐
- **GitHub**: <https://github.com/MetaMask/metamask-extension>
- **monorepo**: <https://github.com/MetaMask/core>
- **语言**: TypeScript
- **学什么**:
  - `packages/keyring-controller`：钱包多账户管理
  - `packages/transaction-controller`：交易状态机
  - `packages/network-controller`：多链 RPC 切换
- **面试故事**："MetaMask 用 controller 模式把每个能力（账户、交易、签名、网络）拆成独立模块，OKX Wallet 也是类似架构。"

### 4.2 Rabby Wallet ⭐⭐⭐⭐
- **GitHub**: <https://github.com/RabbyHub/Rabby>
- **语言**: TypeScript
- **学什么**: DeBank 出品的钱包，**模拟交易（pre-execution）**特性最值得学
- **面试故事**：能讲 Rabby 的 transaction simulation 是怎么用 forking node 做的。

### 4.3 WalletConnect SDK ⭐⭐⭐⭐⭐
- **GitHub**: <https://github.com/WalletConnect/walletconnect-monorepo>
- **GitHub**（Rust 版本）: <https://github.com/WalletConnect/WalletConnectKotlinV2>
- **学什么**: 跨钱包 / 跨链通信的事实标准协议
- **关键概念**: Pairing、Session、Relay、JSON-RPC over WebSocket

### 4.4 Trust Wallet Core（再次推荐） ⭐⭐⭐⭐⭐
- 见 3.1，**这就是 OKX Cross-Platform 岗位的最佳学习对标**

---

# 业务 5 · DeFi 协议集成 / DeFi Adapter

## 业务说明

CEX 想要把 DeFi 收益打包给散户用（"挖矿宝"、"理财"），需要写 **DeFi Adapter**：

> 给定一个 DeFi 协议（Aave / Compound / Uniswap V3 / Lido），抽象出**统一的接口**：deposit、withdraw、queryBalance、queryAPY，然后让 CEX 业务系统能像调用本地 API 一样调用这些链上协议。

面试常问：
- "你怎么从 Uniswap V3 链上数据计算实时 APR？" → 24h volume × fee tier / TVL
- "Aave 的 aToken 是怎么 rebase 的？为什么没有 transfer event？"
- "Lido 的 stETH 怎么处理 delegation 收益？" → daily rebase via oracle

## 涉及岗位

| 公司 | 岗位 |
|---|---|
| Binance | Java Engineer — DeFi/Web3 |

## 推荐开源项目

### 5.1 DefiLlama Adapters ⭐⭐⭐⭐⭐（最直接对标）
- **GitHub**: <https://github.com/DefiLlama/DefiLlama-Adapters>
- **语言**: TypeScript
- **学什么**: 1000+ 个 DeFi 协议的 TVL 适配器，每个协议怎么 query liquidity 都有现成代码
- **面试故事**："我读了 DefiLlama 的 adapters/lido / aave-v3 / uniswap-v3 实现，理解了不同 DeFi 协议的 TVL 计算公式" —— 这是 DeFi Adapter 岗位的灵魂答案。

### 5.2 Zapper / DeBank API 模式 ⭐⭐⭐⭐
- **学习资料**:
  - DeBank 文档: <https://docs.cloud.debank.com/>
  - Zapper API: <https://protocol.zapper.xyz/>
- **学什么**: 行业领先的 "用户多协议持仓聚合" API 设计

### 5.3 Uniswap V3 SDK ⭐⭐⭐⭐⭐
- **GitHub**: <https://github.com/Uniswap/v3-sdk>
- **语言**: TypeScript
- **学什么**:
  - 怎么计算 V3 的 swap quote（不需要发交易就能算）
  - Tick range / Position 的数学
- **面试故事**：能讲 V3 的 sqrtPriceX96 为什么用 Q96 定点数。

### 5.4 Aave V3 Core ⭐⭐⭐⭐⭐
- **GitHub**: <https://github.com/aave/aave-v3-core>
- **语言**: Solidity
- **学什么**: 借贷协议的最佳实现，aToken / debtToken 设计、清算引擎、isolation mode

---

# 业务 6 · Stablecoin 多链发行 / RWA

## 业务说明

稳定币业务在做的事：
- **发行**：用户存 USD → 平台铸造 1 枚 USDX
- **赎回**：用户烧 1 枚 USDX → 平台兑付 USD
- **跨链**：USDX 在 Ethereum、BSC、Tron 上都要可用，怎么保证总量一致 → CCTP 模式
- **储备金管理**：买短期国债产生收益（Tether 模式）

Binance 在做 BFUSD / USD1 等稳定币，所以才有 Stablecoin 后端岗位。

面试常问：
- "USDC 的 CCTP 跨链是怎么工作的？" → burn-and-mint，Circle 当 attestation 服务
- "Ondo USDY 是怎么把短债收益分给持有人的？" → 每日 rebase，类似 stETH
- "Ethena USDe 的 delta-neutral 是怎么实现的？" → 现货 + 永续对冲

## 涉及岗位

| 公司 | 岗位 |
|---|---|
| Binance | Senior Web3 and Backend Developer - Stablecoins |

## 推荐开源项目

### 6.1 Circle CCTP（Cross-Chain Transfer Protocol） ⭐⭐⭐⭐⭐
- **GitHub**: <https://github.com/circlefin/evm-cctp-contracts>
- **语言**: Solidity
- **学什么**: USDC 跨链的 burn-and-mint 实现，怎么用 attestation 服务做跨链验证
- **面试故事**："Binance 的稳定币如果要支持跨链，CCTP 是必看的范本，它的 MessageTransmitter + TokenMinter 双合约设计是行业标准。"

### 6.2 MakerDAO DSS（DAI 稳定币系统） ⭐⭐⭐⭐
- **GitHub**: <https://github.com/makerdao/dss>
- **语言**: Solidity
- **学什么**: 第一代算法稳定币的完整实现，VAT / JUG / SPOT / FLAP 等核心合约
- **难度**: 高（代码风格非常 Haskell），但读完受益终生

### 6.3 Liquity（去中心化稳定币 LUSD） ⭐⭐⭐⭐
- **GitHub**: <https://github.com/liquity/dev>
- **语言**: Solidity
- **学什么**: 比 Maker 更简洁的稳定币设计，Stability Pool / Recovery Mode 机制

### 6.4 Ondo Finance（USDY · 短债 RWA 稳定币） ⭐⭐⭐⭐
- **GitHub**: <https://github.com/ondoprotocol/usdy-contracts>
- **学什么**: RWA 稳定币的合规设计、白名单机制、rebase 逻辑

### 6.5 Ethena USDe（Delta-Neutral 稳定币） ⭐⭐⭐
- **GitHub**: <https://github.com/ethena-labs/ethena>
- **学什么**: 用永续合约做 delta hedge 的合约设计

---

# 业务 7 · 链上数据 Indexer / Web3 Data Platform

## 业务说明

链上数据业务的本质：**把 RPC 节点输出的原始数据 → 整理成业务能查询的数据库表**。

具体环节：
- **扫块（Block Indexer）**：从 Geth 拉每个新区块、每条 log、每条 trace
- **事件解析（Event Decoder）**：根据 ABI 把 log 解析成结构化事件
- **数据聚合（Aggregator）**：算 token price / TVL / liquidity / volume
- **多链统一**：EVM、Solana、Bitcoin 都要接入
- **实时性**：Kafka / Flink / RocksDB 这些 Web2 高并发栈

面试常问：
- "怎么处理 reorg？" → soft head buffer + reorg rollback
- "怎么算实时 TVL？" → snapshot + incremental update
- "为什么要用 Trace 而不只是 Log？" → internal call 不发 log

## 涉及岗位

| 公司 | 岗位 |
|---|---|
| Binance | Java Backend Engineer - Web3 Data |
| Binance | Golang Developer, Binance Square |

## 推荐开源项目

### 7.1 The Graph ⭐⭐⭐⭐⭐
- **GitHub**: <https://github.com/graphprotocol/graph-node>
- **语言**: Rust
- **学什么**:
  - graph-node 怎么订阅 Geth 的事件
  - subgraph mapping 怎么把 log 转成 GraphQL schema
  - 怎么处理 reorg

### 7.2 Subsquid ⭐⭐⭐⭐
- **GitHub**: <https://github.com/subsquid/squid-sdk>
- **语言**: TypeScript
- **学什么**: 比 The Graph 更现代的 Indexer，性能可达 10x，**支持 Trace 数据**

### 7.3 Goldsky Mirror ⭐⭐⭐⭐
- **官方文档**: <https://docs.goldsky.com/mirror/sources/dataset-reference>
- **学什么**: 行业最快的 indexer 后端架构
- **价值**: 没开源，但官方文档对 schema 设计的解释非常到位

### 7.4 BlockchainETL ⭐⭐⭐⭐⭐（Google 出品）
- **GitHub**: <https://github.com/blockchain-etl/ethereum-etl>
- **语言**: Python
- **学什么**: 怎么把 Ethereum 全链历史数据导出到 CSV / Parquet / BigQuery
- **面试故事**：能讲出"我用 ethereum-etl 把 1000 万个区块的 Transfer event 导到 BigQuery，跑了一个 ERC20 holder 排行榜" —— 真实可落地的项目经验。

### 7.5 Erigon（高性能 Geth 替代品）⭐⭐⭐
- **GitHub**: <https://github.com/erigontech/erigon>
- **语言**: Go
- **学什么**: 怎么把 Geth 的硬盘占用从 2TB 优化到 800GB，trace 性能提升 10x
- **价值**: Indexer 业务必须知道 Erigon 的存在

### 7.6 Dune Spellbook ⭐⭐⭐
- **GitHub**: <https://github.com/duneanalytics/spellbook>
- **学什么**: Dune 上的 SQL 模型，能学到行业怎么写 DeFi 业务的 SQL

---

# 业务 8 · 智能合约审计 / 链上安全 / 黑客复盘

## 业务说明

CEX 安全团队三件事：
1. **合约审计**：上线前 review 第三方合约（用户存款的 DeFi 协议、CEX 自己的桥）
2. **链上风控**：实时监控异常交易、可疑地址
3. **黑客事件复盘**：每次行业黑客事件后做 post-mortem，更新自家防御规则

面试常问：
- "重入攻击是什么？怎么防？" → checks-effects-interactions、ReentrancyGuard
- "Flash Loan 攻击的常见模式？" → 操纵 oracle / 套利清算
- "Tornado Cash 怎么追踪资金流向？" → on-chain 启发式 + Heuristic clustering
- "你最近读了哪个事故的 post-mortem？" → Curve Vyper bug / Euler Finance hack

## 涉及岗位（5 个，主线 B 含金量最高的一类）

| 公司 | 岗位 |
|---|---|
| Binance | Smart Contract Auditor |
| Binance | Smart Contract Security Engineer (Security Audit) |
| Binance | Blockchain Security Engineer (Smart Contract Auditing) |
| Binance | Pioneer Talent Program - Software Engineer - Blockchain Security |
| Binance | Web3 Security Service Architect Engineer (Java) |

## 推荐开源项目

### 8.1 OpenZeppelin Contracts ⭐⭐⭐⭐⭐（基础必读）
- **GitHub**: <https://github.com/OpenZeppelin/openzeppelin-contracts>
- **学什么**: 行业标准合约库，每个合约都是写法范本
- **重点**: ERC20 / ERC721 / AccessControl / ReentrancyGuard / Proxy 模式

### 8.2 Damn Vulnerable DeFi（练手）⭐⭐⭐⭐⭐
- **GitHub**: <https://github.com/theredguild/damn-vulnerable-defi>
- **语言**: Solidity + Foundry
- **学什么**: 17 个 DeFi 攻击场景，每个都让你亲手写攻击合约
- **面试故事**："我做完了 Damn Vulnerable DeFi 全部 17 关，最难的 Curvy Puppet 用到了 Curve invariant + price manipulation。"

### 8.3 DeFi Hack Labs ⭐⭐⭐⭐⭐（必看）
- **GitHub**: <https://github.com/SunWeb3Sec/DeFiHackLabs>
- **学什么**: **复现真实链上攻击**（Euler、Cream、Yearn 等 100+ 案例），每个攻击都附 Foundry 测试代码可以直接跑
- **面试故事**：能在面试中拍胸脯说 "我复现过 2023 年 Euler Finance 那次 1.97 亿美金的攻击，攻击根源是 donateToReserves 没检查健康度" —— 直接征服面试官。

### 8.4 Slither（静态分析工具）⭐⭐⭐⭐
- **GitHub**: <https://github.com/crytic/slither>
- **语言**: Python
- **学什么**: Trail of Bits 出品，能扫出 80% 的常见漏洞模式
- **面试场景**: 安全岗一定会问 "你用过什么自动扫描工具？" → Slither + Mythril + Echidna 三件套

### 8.5 Foundry Fuzzing & Invariant Testing ⭐⭐⭐⭐⭐
- **GitHub**: <https://github.com/foundry-rs/foundry>
- **学习资料**: <https://book.getfoundry.sh/forge/invariant-testing>
- **学什么**: 用 invariant test 找出"任何状态下都不应该被破坏的属性"

### 8.6 Solodit ⭐⭐⭐⭐⭐（每天必刷）
- **网站**: <https://solodit.cyfrin.io/>
- **学什么**: 整合了 Code4rena、Sherlock、Cantina、OpenZeppelin、Trail of Bits 的所有公开审计报告，按漏洞类型分类，是审计师每天必读的"今日漏洞"。

### 8.7 SlowMist 安全报告库 ⭐⭐⭐⭐
- **GitHub**: <https://github.com/slowmist/Knowledge-Base>
- **学什么**: 中文安全报告 + 行业事件复盘，对你做"中文岗位面试时讲事故复盘"有奇效

---

# 业务 9 · CEX 通用 Java 后端 / Web3 AI 工程

## 业务说明

这一类是 Web2 高并发后端在 Web3 公司的延伸：
- **Spring Boot 微服务** + **Kafka / Redis / MySQL / RocksDB**
- **大数据**（Spark / Flink / Hadoop）
- **AI 工程**：LLM Agent、智能合约 AI 审计、AI Copilot for Trading

这部分 **你现有的 Web2 Go 经验已经能直接答 70%**，重点是补 Web3 特定场景（如订单簿、撮合、爆仓）。

## 涉及岗位（8 个）

| 公司 | 岗位 |
|---|---|
| Binance | Senior Java Engineer / Senior Backend Engineer - Java |
| Binance | Senior Software Engineer (Backend, Java)（Big Data） |
| Binance | Backend Java Engineer - Russian speaker（BigPay Fiat） |
| Binance | Full Stack Engineer（Compliance + Agentic AI） |
| Binance | Binance Accelerator Programm × 3（实习生） |
| Binance | Binance Accelerator Program - Web3 AI Engineer |

## 推荐开源项目

### 9.1 撮合引擎（CEX 核心）⭐⭐⭐⭐⭐
- **GitHub**: <https://github.com/exchange-core/exchange-core>
  - Java 撮合引擎，性能 5M tx/s
- **GitHub**: <https://github.com/databento/dbn>
  - 行业级行情数据格式
- **GitHub**: <https://github.com/openware/peatio>
  - 完整的开源 CEX（Ruby）
- **学什么**: 撮合的核心数据结构（OrderBook / PriceLevel / FIX 协议）

### 9.2 LMAX Disruptor ⭐⭐⭐⭐
- **GitHub**: <https://github.com/LMAX-Exchange/disruptor>
- **学什么**: 单线程撮合的并发框架，币安撮合也用类似思路

### 9.3 Hyperliquid 风格的 DEX 撮合 ⭐⭐⭐⭐
- **学习资料**: <https://hyperliquid.gitbook.io/hyperliquid-docs/for-developers/api>
- **学什么**: 链上订单簿是怎么实现的（不是 AMM）

### 9.4 LangChain / LlamaIndex（AI 工程）⭐⭐⭐
- **GitHub**: <https://github.com/langchain-ai/langchain>
- **学什么**: AI Agent 怎么用工具调用、RAG、Memory
- **结合 Web3**: 看 <https://github.com/openai/openai-agents-python> + <https://github.com/coinbase/agentkit>

### 9.5 Coinbase AgentKit ⭐⭐⭐⭐
- **GitHub**: <https://github.com/coinbase/agentkit>
- **学什么**: Web3 × AI 落地的最佳范本，AI Agent 怎么自主签名链上交易

---

# 综合学习路径建议（按你的画像）

## 路径 A：投 Mantle / Scroll（主线 A）

```
第 1 周  ── 读 Optimism Bedrock 的 op-node 源码 + 论文，理解 derivation pipeline
第 2 周  ── 读 Scroll 的 go-ethereum fork diff，写一篇博客对比 Geth 和 Scroll 的差异
第 3 周  ── 在本地跑通 Scroll devnet，发一个跨链 ERC20 跨过 Scroll Bridge
第 4 周  ── 选 Halo2 The Book 看完前 4 章，能讲 Plonk vs Groth16
准备好讲：「我读过 Scroll 的 zkevm-circuits/src/evm_circuit/execution/storage.rs，
        理解了 SLOAD 操作怎么编码成约束。」
```

## 路径 B：投 Binance Wallet / DeFi（主线 B 主流）

```
第 1 周  ── 读 Trust Wallet Core 的 Coin 模板，自己加一条 "测试链"
第 2 周  ── 读 DefiLlama-Adapters 里 aave-v3 / uniswap-v3 / lido 三个适配器
第 3 周  ── 用 ethereum-etl 把 Curve 池的 100 万次 swap 抓下来，算每天的 volume
第 4 周  ── 复现 Damn Vulnerable DeFi 前 10 关 + 1 个 DeFi Hack Labs 的真实事件
准备好讲：「我读过 trustwallet/wallet-core 的 BIP44 派生实现，理解了为什么 ETH 用
        m/44'/60'/0'/0/x 这个路径，以及 Binance 的 BSC 怎么复用同一棵 HD 树。」
```

## 路径 C：投 Binance Smart Contract Security（主线 B 高薪）

```
第 1 周  ── OpenZeppelin Contracts 通读 + Damn Vulnerable DeFi 全 17 关
第 2 周  ── DeFi Hack Labs 复现 5 个真实攻击事件，每个写一份 post-mortem
第 3 周  ── 学 Foundry invariant testing，给一个 ERC4626 vault 写不变量测试
第 4 周  ── 每天刷 Solodit 至少 3 个 finding，整理成自己的 漏洞分类知识库
准备好讲：「2024 Curve Vyper 编译器 reentrancy lock 失效那次，我写过详细的
        post-mortem，根因是 Vyper 0.2.15 这个版本生成的字节码漏掉了
        nonreentrant 的 storage write。」
```

## 路径 D：投 Binance Web3 Data / Golang（你的 Go 背景最契合）

```
第 1 周  ── 读 The Graph graph-node 的 Rust 主流程，画出数据流图
第 2 周  ── 自己写一个 Go indexer，订阅 USDC Transfer event 入 Postgres
第 3 周  ── 用 BlockchainETL 把 1000 个区块的 trace 导出，算出 internal call 数
第 4 周  ── 学 Erigon 的 stage sync 设计，能讲清楚为什么比 Geth 快 5-10x
准备好讲：「我用 Go 写过一个 Indexer 跑 7 天没崩，处理了 10 万 reorg 边界，
        关键是用 finalized head 做 confirmation buffer。」
```

---

# 怎么用这份地图

1. **挑 1 条路径**（A/B/C/D），不要贪多
2. **每个项目读完都写一篇博客**（中英都行），博客链接放进简历里
3. **面试时主动提**：HR / 面试官问"你为什么对我们公司感兴趣"时，回答 "我读过你们的 X repo / 协议，发现 Y 设计很有意思……"
4. **避免死读源码**：每个项目的目标是能讲 **一个 5 分钟的业务故事**，不是能背出每行代码

---

> 这份地图后续可以扩展：每个业务领域出一份「**深度学习笔记**」，类似 `web3-interview-sharing/Web3综合资料库/` 里的 PDF。
> 如果你选定了 1-2 个领域，告诉我，我可以接着帮你输出第 1 篇深度笔记。
