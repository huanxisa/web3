# 开源项目最终精选（业务深度 × 招聘认可度 二维评分）

> **评分模型**（你的提议）：
>
> - **业务深度 D（Depth）**：针对你目标 JD 这个 repo 能讲多深 → 1-5 分
> - **招聘认可度 R（Recognition）**：圈内识别度，面试官听到名字反应 → 1-5 分
>
> **决策规则**：
>
> | 情况 | 处理 |
> |---|---|
> | D ≥ 4 且 R ≥ 4 | **S 级**，必学 |
> | 一维 ≥ 4，另一维 = 3，且有"同质项目"  | 同质组里**只挑一个**代表 |
> | D ≥ 4 但 R ≤ 2 | 仅"投特定公司"才学，**不写一线简历** |
> | D ≤ 2 且 R ≤ 2 | **淘汰** |

---

## 一、象限分布矩阵（一图看懂）

```
                  招聘认可度 R
           1     2     3     4     5
        ┌─────┬─────┬─────┬─────┬─────┐
   D=5  │     │ Mantle│Scroll│Halo2│★UniV3★│
        │     │ Angle │zkEVM │CCTP │★Aave★│
        │     │  PDF  │      │LZ-V2│★OZ  ★│
        │     │       │      │     │★MMask★│
        │     │       │      │     │★Trust★│
        │     │       │      │     │★Safe★│
        │     │       │      │     │★MkrDAO★│
        │     │       │      │     │★Lido★│
        │     │       │      │     │★EigenL★│
        │     │       │      │     │★Pendle★│
        │     │       │      │     │★HyperL★│
        │     │       │      │     │★Curve★│
        │     │       │      │     │★OP-St★│
        │     │       │      │     │★Geth★│
        │     │       │      │     │★ChLink★│
        │     │       │      │     │★TheGph★│
        │     │       │      │     │★Foundry★│
        │     │       │      │     │★Anchor★│
        │     │       │      │     │★DefiHack★│
        │     │       │      │     │★Solodit★│
        ├─────┼─────┼─────┼─────┼─────┤
   D=4  │     │       │tss-lib│Pyth │ UniV2│
        │     │       │Silo   │GMX V2│ Liquity│
        │     │       │Marinade│Reth │ DVD  │
        │     │       │Metaplex│Wormhole│ Comet│
        │     │       │Spark  │CCIP │ Ondo │
        │     │       │ etl   │ etl │ Slither│
        │     │       │Spellbk│OZ-Up│ Erigon│
        ├─────┼─────┼─────┼─────┼─────┤
   D=3  │     │       │Frax   │Rabby│ ArbNitro│
        │     │       │Across │1inch│ OpenSea│
        │     │       │       │LMAX │       │
        ├─────┼─────┼─────┼─────┼─────┤
   D=2  │ ── 淘汰区 ──    │       │       │
        │BTCPay │Cobo  │       │       │       │
        │exch-core│Subsquid│   │       │       │
        │SmrDex │Goldsky│       │       │       │
        │Clipper│       │       │       │       │
        └─────┴─────┴─────┴─────┴─────┘
```

★ = S 级必学

---

## 二、S 级必学（D≥4 且 R≥4）共 20 个

> **简历必备**。每个都给 D/R 分 + 一句简历话术。

| # | 项目 | D | R | 业务方向 | 简历话术 |
|---|---|---|---|---|---|
| 1 | **Uniswap V3 Core** | 5 | 5 | DEX | "推导过 sqrtPriceX96 的 Q96 定点数" |
| 2 | **Aave V3 Core** | 5 | 5 | 借贷 | "理解 eMode / isolation mode 差异" |
| 3 | **OpenZeppelin Contracts** | 5 | 5 | 合约基建 | "用过 UUPS / Transparent / Beacon" |
| 4 | **Foundry** | 5 | 5 | 合约工具 | "写过完整 invariant test" |
| 5 | **MetaMask core** | 5 | 5 | 钱包 | "读过 keyring-controller 多账户管理" |
| 6 | **Trust Wallet Core** | 5 | 5 | 钱包（Binance 旗下） | "扩展过 Coin 模板支持新链" |
| 7 | **Safe (Gnosis)** | 5 | 5 | 多签 | "理解 EIP-1271 + module 扩展" |
| 8 | **Geth** | 5 | 5 | 客户端 | "读过 core/state 的 MPT 实现" |
| 9 | **OP Stack** | 5 | 5 | L2 | "理解 op-node derivation pipeline" |
| 10 | **The Graph** | 5 | 5 | Indexer | "上线过 5 个 subgraph，懂 reorg" |
| 11 | **Chainlink** | 5 | 5 | Oracle | "集成过 Price Feed + VRF" |
| 12 | **MakerDAO DSS** | 5 | 5 | 稳定币 | "读过 VAT / JUG / SPOT 核心合约" |
| 13 | **Lido** | 5 | 5 | LST | "读过 withdrawalQueue + oracle rebase" |
| 14 | **Curve** | 5 | 5 | StableSwap | "推导过 invariant 公式" |
| 15 | **Circle CCTP** | 5 | 5 | 跨链稳定币 | "实现过 CCTP burn-and-mint" |
| 16 | **LayerZero V2** | 5 | 5 | 跨链 | "用 OFT 实现过 omnichain token" |
| 17 | **EigenLayer** | 5 | 5 | Restaking 热点 | "理解 LST/LRT 与 Operator 罚没" |
| 18 | **Pendle** | 5 | 5 | 收益衍生品热点 | "理解 PT/YT 拆分原理" |
| 19 | **Hyperliquid** | 5 | 5 | onchain orderbook | "研究过 onchain orderbook + EVM L1 双引擎" |
| 20 | **Anchor (Solana)** | 5 | 5 | Solana 框架 | "用 Anchor 写过 SPL Token Vault" |

> **注**：DeFi Hack Labs / Damn Vulnerable DeFi / Solodit 三件套是安全岗位的 S 级，但属于"工具/教程"非"产品 repo"，单独列在第三章。

---

## 三、同质组：每组只挑 1 个代表（避免重复学习）

> **原则**：同一业务方向，学完代表项目后，其他同类**了解概念即可**，不要重复读源码。

### 借贷协议（学 Aave V3 一个就够了）

| 代表（学这个） | D | R | 同质项目（不重复学，知道存在即可） |
|---|---|---|---|
| **Aave V3** | 5 | 5 | Compound V3 (Comet) D4R4 / Spark D3R4（Aave fork）/ Silo Finance D3R3 / Unitus D3R2 / Morpho D4R4 |

→ 面试时被问到 Compound 区别只需答："Compound V3 把 collateral 改成单资产，更适合保守用户。"

### 算法稳定币（学 MakerDAO 一个）

| 代表 | D | R | 同质 |
|---|---|---|---|
| **MakerDAO DSS** | 5 | 5 | Liquity V2 D4R3 / Frax D3R3 / Reflexer D2R2 |

→ Liquity 可作为"完全去中心化"差异化谈点；其他不必看。

### RWA 稳定币（学 Ondo 一个）

| 代表 | D | R | 同质 |
|---|---|---|---|
| **Ondo USDY** | 4 | 4 | Mountain Protocol D3R3 / Hashnote D2R3 |

→ RWA 方向 Ondo 一家独大，跟着它学就够。

### Delta-Neutral 稳定币（投 Binance Stablecoin 必看）

| 代表 | D | R | 同质 |
|---|---|---|---|
| **Ethena USDe** | 4 | 4 | （独此一家，没有同质） |

### 永续 DEX（学 Hyperliquid 优先，备选 GMX V2）

| 代表 | D | R | 同质 |
|---|---|---|---|
| **Hyperliquid** | 5 | 5 | GMX V2 D4R4 / dYdX V4 D4R4 / Synthetix D3R4 |

→ Hyperliquid（onchain orderbook 路线）和 GMX（pool-based 路线）是两种不同思路，**真正深耕衍生品方向再学第二个**，否则只学 Hyperliquid。

### L2 客户端（学 Geth + OP Stack 两个）

| 代表 | D | R | 同质 |
|---|---|---|---|
| **Geth + OP Stack** | 5 | 5 | Arbitrum Nitro D4R5 / Reth D3R4 / Erigon D4R4 |

→ Arbitrum 横向对比谈一两句即可（"Optimistic 用 fraud proof，ZK 用 validity proof"），不必精读源码。Reth 是兴趣加分。

### Indexer（学 The Graph 一个）

| 代表 | D | R | 同质 |
|---|---|---|---|
| **The Graph** | 5 | 5 | Subsquid D3R2 / Goldsky D4R3（闭源）/ ethereum-etl D4R3 / Erigon D4R4 |

→ ethereum-etl 是**第二个值得学**的，因为它专门讲数据导出（Web3 Data 岗位用得上）。

### Oracle（学 Chainlink 一个 + Pyth 一句话提）

| 代表 | D | R | 同质 |
|---|---|---|---|
| **Chainlink** | 5 | 5 | Pyth Network D4R4 / RedStone D3R3 / API3 D2R2 |

→ Pyth 作为 "新一代 pull-based" 谈点，提一句即可。

### 跨链桥（学 CCTP + LayerZero V2 两个）

| 代表 | D | R | 同质 |
|---|---|---|---|
| **Circle CCTP + LayerZero V2** | 5 | 5 | Wormhole D4R4 / Chainlink CCIP D4R4 / Across D3R3 / Hop D2R3 |

→ CCTP（专做 USDC）和 LayerZero（通用消息）是两种不同范式，都要懂；其他知道存在即可。

### Solana 工具链（学 Anchor 一个 + 按方向加 1 个）

| 代表 | D | R | 同质 / 配套 |
|---|---|---|---|
| **Anchor** | 5 | 5 | + **Metaplex**（NFT 方向）D4R4 / + **Marinade**（LST 方向）D4R4 / SPL stake-pool D4R3 |

### 钱包前端（MetaMask 必学，Rabby 锦上添花）

| 代表 | D | R | 同质 |
|---|---|---|---|
| **MetaMask** | 5 | 5 | Rabby D4R3（差异化）/ Phantom D3R5（Solana 钱包）|

→ Rabby 的 transaction simulation 是面试加分项，可以读但不必深读。

---

## 四、深度专属（D 高 R 低）：投特定公司才学

> 这些项目**写在通用简历里没人懂**，但**投特定公司时招聘官 100% 认**。

| 项目 | D | R | 仅当你投 | 为什么必看 |
|---|---|---|---|---|
| **Scroll zkevm-circuits** | 5 | 3 | Scroll | 投 Scroll 时简历里不写这个 = 没诚意 |
| **Scroll go-ethereum fork** | 5 | 3 | Scroll | 同上 |
| **Halo2** | 5 | 4 | Scroll / 任何 ZK 岗 | ZK 圈认，但圈外不认 |
| **Mantle 自家 repos** | 5 | 2 | Mantle | 投 Mantle 必看，但圈外人不知道 |
| **Angle Protocol** | 5 | 2 | Binance Stablecoin | 多币种稳定币 SOTA，资料库有中文 PDF 帮你深挖 |
| **Binance tss-lib** | 4 | 3 | Binance Wallet / Bitget | 有 Binance 招牌，圈内有印象 |
| **DefiLlama Adapters** | 5 | 3 | Binance DeFi Adapter 岗 | 那个岗位的灵魂 |

→ 写简历时，这些项目**只放在投特定公司的版本**，不放通用版。

---

## 五、安全审计专属"必学三件套"（独立分类）

| 项目 | D | R | 类型 |
|---|---|---|---|
| **Damn Vulnerable DeFi** | 5 | 4 | 教程 |
| **DeFi Hack Labs** | 5 | 4 | 复现库 |
| **Solodit** | 5 | 4 | 报告聚合站 |
| **Slither** | 4 | 4 | 工具 |

→ 投 Binance 5 个安全岗位 = 这 4 个全是必备。

---

## 六、淘汰清单（D 和 R 都 ≤ 2，浪费时间）

| 项目 | D | R | 淘汰原因 | 替代 |
|---|---|---|---|---|
| BTCPay Server | 2 | 1 | C# 圈子小，BTC 偏门 | 用 Bitcoin Core 文档替代 |
| Cobo MPC | 3 | 1 | 圈外不知名 | Binance tss-lib（有 Binance 招牌） |
| Subsquid | 3 | 2 | The Graph 同质且不及 | The Graph |
| Goldsky | 4 | 2 | 闭源没源码可读 | Erigon / ethereum-etl |
| exchange-core | 3 | 2 | Java 圈外不熟 | Hyperliquid spec（onchain orderbook） |
| SmarDex / THENA / Clipper | 2 | 1 | 小众 DEX | Uniswap V3 + Curve 已涵盖 |
| Mintswap / Mooar | 2 | 1 | 小众 NFT | Magic Eden（Metaplex） |

---

## 七、最终精选 28 个 = 20 个 S + 4 个安全 + 4 个 Solana/同质代表

| 优先级 | 项目数 | 适用面 |
|---|---|---|
| **必学（S 级 20 个）** | 20 | 任何一线 Web3 岗位简历都加分 |
| **安全岗专属 4 件套**（DVD / DeFi Hack Labs / Solodit / Slither） | 4 | 投 Binance 5 个安全岗 |
| **Solana 配套 2 个**（Metaplex / Marinade） | 2 | 投有 Solana 要求的岗 |
| **深度专属（投特定公司必看）** | 7 | 见第四章 |
| **可选差异化加分**（Rabby / ethereum-etl） | 2 | 锦上添花 |

**总计：35 个项目**（其中 20 个 S 级是核心战场）

---

## 八、按你 30 个目标岗位 × 项目（最终版）

> 每个岗位列 **3 个 S + 0-2 个 D-高-专属**。**不再列同质化备胎**。

### 主线 A · L2 基建

| 公司·岗位 | S 级 3 个 | 公司专属（D 高 R 低） |
|---|---|---|
| **Mantle Blockchain Engineer** | OP Stack + Geth + EigenLayer | + Mantle 自家 repos |
| **Scroll Blockchain Infra** | Geth + OP Stack（横向对比）+ Foundry | + Scroll go-ethereum + zkevm-circuits |
| **Scroll Web3 Backend** | The Graph + Geth + Foundry | + Scroll repos |
| **Scroll ZK Engineer** | Halo2 + Foundry + Chainlink（concept） | + Scroll zkevm-circuits |
| **Scroll Protocol Researcher** | OP Stack + EigenLayer + Halo2 | + Scroll repos |

### 主线 B · CEX Web3

| 公司·岗位 | S 级 3 个 | 公司专属 |
|---|---|---|
| **Binance Wallet Java** | Trust Wallet Core + Safe + MetaMask | + tss-lib |
| **Binance DeFi Java** | Aave V3 + Uniswap V3 + Pendle | + DefiLlama Adapters |
| **Binance Stablecoin** | MakerDAO + Circle CCTP + Lido | + Ondo USDY + Angle Protocol |
| **Binance Web3 Data Java** | The Graph + Geth + Uniswap V3 | + ethereum-etl + Erigon |
| **Binance Smart Contract Auditor** ×3 | OpenZeppelin + Foundry + Aave V3 | + DVD + DeFi Hack Labs + Solodit + Slither |
| **Binance Security Architect** | OpenZeppelin + Foundry + Chainlink | + DVD + DeFi Hack Labs + Slither |
| **Binance Pioneer Security** | OpenZeppelin + Foundry + Aave V3 | + DeFi Hack Labs |
| **Binance Web3 AI** | Uniswap V3 + Aave V3 + LayerZero | + Coinbase AgentKit |
| **Binance Golang (Square)** | The Graph + Geth + Hyperliquid | + ethereum-etl |
| **Binance Java（其他通用）** | Aave V3 + Uniswap V3 + OpenZeppelin | （无） |
| **Bitget Wallet Engineer** | Trust Wallet Core + Safe + MetaMask | + tss-lib |
| **OKX Rust Cross-Platform** ×3 | Trust Wallet Core + MetaMask + Safe | + WalletConnect |

---

## 九、关键洞察：二维评分换来的 3 个真相

### 真相 1：S 级 20 个 ≠ 都要学

→ **按你目标岗位**从 S 级里精选 **5-7 个**深耕，其他 S 级**只需要在简历里"提一下"**（一句话级别），不必读源码。

### 真相 2：D 高 R 低的项目要"分版本"写简历

→ 投 Scroll 的简历可以大写"Scroll zkevm-circuits"，但投 Binance 的简历就只写"Halo2"（圈子稍宽）。
→ 投 Binance Stablecoin 的简历可以大写"Angle Protocol"（招聘官那个团队懂），但通用简历不写。

### 真相 3：同质化项目"懂概念但不读源码"是最优策略

→ 学完 Aave V3，对 Compound V3 / Spark / Silo / Morpho 你只需要能在面试中说出**一句话差异**：
- Compound V3："改成单资产 collateral，更保守"
- Spark："Aave V3 的 fork + DAI 接入"
- Silo："风险隔离，每个 token 独立 silo"
- Morpho："P2P matching 之上的 Aave/Compound wrapper"

→ 这些差异化句子值 30 分，但读源码花 30 小时只值 35 分，**ROI 极低**。

---

## 十、推荐的下一步

| 选项 | 说明 |
|---|---|
| **A** | 按这份清单**重写** `biz_to_opensource_map.md`：删掉淘汰项 + 补 S 级 + 同质化只留代表（地图从 600 行精简到 ~350 行） |
| **B** | 你告诉我目标投递的 Top 3 公司·岗位，我从 35 个项目里**精选 5 个**给你做 4 周冲刺计划（带每周读哪个目录、写什么 demo） |
| **C** | 我给 S 级 20 个里的 Top 5 出**3 天速读笔记**：标章节 + 必读源文件 + 必懂概念 + 简历话术模板 |
| **D** | 你给我看一下你现有简历，我帮你按这份清单**反向匹配**：哪些项目你现在的经验已经能讲、哪些是缺口 |

> 我个人推荐 **A + B 组合**：先把地图精简（避免你被低 ROI 项目消耗时间），然后选定目标做 4 周冲刺。
