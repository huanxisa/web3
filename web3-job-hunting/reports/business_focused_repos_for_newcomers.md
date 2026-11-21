# 新人友好的强业务项目清单（按合约模块拆解）

> **筛选标准**（针对刚入行 Web3 的后端/合约新人）：
>
> 1. **强业务**：能讲清楚的商业故事（不是基建/框架/工具）
> 2. **可读性**：合约 + 关联后端 repo 开源可读
> 3. **变现快**：4 周内能从读懂到面试讲清楚
> 4. **R ≥ 3**：圈内有名，不至于面试官没听过
>
> **本文档只列**：合约模块 + 后端关联模块（不讲前端、不讲 SDK 给前端用的部分）

---

## 学习推荐路径（4 周冲刺）

| 周 | 学什么 | 学完能讲 |
|---|---|---|
| **W1** | Uniswap V3 | "AMM 怎么演化到集中流动性" |
| **W2** | Aave V3 | "DeFi 借贷的清算与利率模型" |
| **W3** | MakerDAO + Lido | "稳定币和 LST 怎么发行" |
| **W4** | 二选一：**Pendle**（收益衍生品）/ **EigenLayer**（Restaking）/ **GMX V2**（永续） | 差异化业务故事 |

完成后简历 = 4 个业务故事 + 4 个 GitHub demo，足够投 Binance / Bitget / Mantle 一面。

---

# 一、DEX 类

## 1. Uniswap V3 / V4 ⭐⭐⭐⭐⭐ 必学第 1 个

**业务一句话**：把流动性集中在用户指定的价格区间（tick range），让 LP 能像主动做市那样赚 fee，比 V2 的全区间分布资金效率高 1000x。

**主仓库**：<https://github.com/Uniswap/v3-core>

### 合约模块（必看 4 个）

| 文件 | 这个模块在做什么 | 必懂度 |
|---|---|---|
| `contracts/UniswapV3Pool.sol` | **核心池子**：mint/burn/swap/collect 全在这 | ★★★★★ |
| `contracts/libraries/TickMath.sol` | tick ↔ sqrtPrice 的对数转换 | ★★★★ |
| `contracts/libraries/SqrtPriceMath.sol` | 给定 amountIn 算 sqrtPrice 的变化 | ★★★★ |
| `contracts/libraries/SwapMath.sol` | 单步 swap 计算（一个 tick 内） | ★★★ |
| `contracts/libraries/Position.sol` | LP 持仓的数据结构 | ★★★ |
| `contracts/libraries/Tick.sol` | tick 状态管理（liquidity gross/net） | ★★ |

### 后端关联模块

| repo | 用途 |
|---|---|
| <https://github.com/Uniswap/v3-subgraph> | The Graph 索引：怎么把 swap event 聚合成 24h volume / TVL |

### 5 个面试高频问题（学完必答）

1. V3 比 V2 的资本效率高 1000x，是怎么算出来的？
2. `sqrtPriceX96` 为什么用平方根而不是直接价格？为什么用 Q96 定点数？
3. 一个 swap 跨多个 tick 时，gas 是怎么累积的？
4. LP 提供流动性时如果 token0/token1 比例不对，会发生什么？
5. V4 的 hooks 比 V3 多了什么能力？为什么要做 singleton 架构？

---

## 2. Curve（StableSwap） ⭐⭐⭐⭐ 第二个 DEX 必学

**业务一句话**：用 StableSwap 不变量公式（`A·n^n·Σx + D = A·D·n^n + D^(n+1)/(n^n·Πx)`）做稳定币之间的低滑点 swap，再用 veCRV 投票分配 emission。

**主仓库**：<https://github.com/curvefi/curve-contract>（用 Vyper，不是 Solidity）

### 合约模块（必看 3 个）

| 文件 | 这个模块在做什么 | 必懂度 |
|---|---|---|
| `contracts/pools/3pool/StableSwap3Pool.vy` | DAI/USDC/USDT 三池：核心 invariant | ★★★★★ |
| `contracts/tokens/CurveTokenV3.vy` | LP token | ★★★ |
| <https://github.com/curvefi/curve-veBoost> | veCRV 提升流动性挖矿权重 | ★★★★ |

### 后端关联模块

| repo | 用途 |
|---|---|
| <https://github.com/convex-eth/platform> | Convex（Curve 上层）的清算与策略机器人 |
| <https://thegraph.com/explorer/subgraphs/3fy93eAT56UJsRCEht8iFhfi6wjHWXtZ9dnnbQmvFopF> | Curve 官方 subgraph |

### 5 个面试高频问题

1. StableSwap 公式相比 x*y=k 的滑点优势在哪？什么时候 StableSwap 退化成 x*y=k？
2. 参数 A（amplification）越大滑点越小，但代价是什么？
3. veCRV 锁仓 4 年的人投票权多少？这个机制为什么能稳定币价？
4. Curve War 是什么？Convex 在里面扮演什么角色？
5. 2023 Curve Vyper bug 攻击的根本原因是什么？

---

# 二、借贷类

## 3. Aave V3 ⭐⭐⭐⭐⭐ 必学第 2 个

**业务一句话**：用户存抵押品 → 按 LTV 借其他资产 → 利率随池子使用率动态变化 → 健康因子 <1 时被清算（清算人吃 5-10% 折扣）。

**主仓库**：<https://github.com/aave/aave-v3-core>

### 合约模块（必看 5 个）

| 文件 | 这个模块在做什么 | 必懂度 |
|---|---|---|
| `contracts/protocol/pool/Pool.sol` | **主入口**：supply/borrow/repay/withdraw/liquidationCall | ★★★★★ |
| `contracts/protocol/tokenization/AToken.sol` | 抵押凭证 token，rebase 累息 | ★★★★★ |
| `contracts/protocol/tokenization/VariableDebtToken.sol` | 借款凭证，浮动利率 | ★★★★ |
| `contracts/protocol/libraries/logic/LiquidationLogic.sol` | 清算引擎 | ★★★★★ |
| `contracts/protocol/libraries/logic/ReserveLogic.sol` | 利率模型（Jump Rate） | ★★★★ |
| `contracts/protocol/libraries/logic/ValidationLogic.sol` | 健康因子检查 | ★★★ |
| `contracts/protocol/libraries/math/WadRayMath.sol` | 18/27 位小数定点 | ★★ |

### 后端关联模块

| repo | 用途 |
|---|---|
| <https://github.com/aave/protocol-subgraphs> | 官方 subgraph：怎么把 Reserve / UserAccountData 转成 GraphQL |
| <https://github.com/aave/aave-utilities> | TS SDK：能学到怎么从合约 view 函数算出实时 APY |

### 5 个面试高频问题

1. **Isolation mode** 是什么？为什么 GHO 这种新资产要开 isolation？
2. **E-mode** 怎么把稳定币之间的 LTV 提高到 95%+？
3. aToken 是 rebase token，那它转账时余额是怎么处理的？为什么没有 Transfer event？
4. 清算时 `liquidationCall` 谁都能调用，激励怎么设计的？bonus 5-10% 是固定的吗？
5. Jump Rate 利率模型：当 utilization 超过 optimal（80%）时，斜率为什么突然变陡？

---

# 三、稳定币类（CEX 必懂）

## 4. MakerDAO DSS（DAI 始祖） ⭐⭐⭐⭐⭐ 第 3 个必学

**业务一句话**：用户抵押 ETH 开 CDP（Vault）→ 铸造 DAI → 还 DAI 时付 stability fee（年息）→ 抵押率 <150% 触发清算拍卖。

**主仓库**：<https://github.com/makerdao/dss>

### 合约模块（必看 4 个）

| 文件 | 这个模块在做什么 | 必懂度 |
|---|---|---|
| `src/vat.sol` | **核心账本**：所有抵押品/债务的双重记账 | ★★★★★ |
| `src/jug.sol` | 稳定费累积引擎 | ★★★★ |
| `src/spot.sol` | 价格预言机适配器 | ★★★★ |
| `src/dog.sol` | 清算触发器（dss 旧版叫 cat） | ★★★★ |
| `src/clip.sol` | Dutch Auction 清算拍卖 | ★★★★★ |
| `src/pot.sol` | DSR（DAI Saving Rate）存款利率 | ★★★ |
| `src/dai.sol` | DAI ERC20 实现 | ★★ |
| `src/end.sol` | 紧急关停（Emergency Shutdown） | ★★ |

### 后端关联模块

| repo | 用途 |
|---|---|
| <https://github.com/makerdao/dss-cdp-manager> | CDP 管理层（前端调用入口） |
| <https://github.com/makerdao/keeper> | 清算 bot 参考实现 |

### 5 个面试高频问题

1. CDP 的 c-ratio（150%）是怎么决定的？为什么不是 110% 或 200%？
2. DAI 的稳定费（stability fee）是怎么累积的？为什么用 `chi` 这个累积器而不是按每秒计息？
3. Dutch Auction 清算（V2 后的 LIQ 2.0）相比 English Auction 优势在哪？
4. DSR（DAI 存款利率）的资金来源是什么？协议怎么保证 DSR 收益？
5. PSM（Peg Stability Module）是什么？为什么 USDC 大量进入 Maker 后大家都在批评？

---

## 5. Lido（最大 LST） ⭐⭐⭐⭐⭐

**业务一句话**：用户存 ETH → 协议把 ETH 委托给经过验证的 node operator → 用户收到 stETH（rebase token，每天涨）→ 想退出走 withdrawal queue。

**主仓库**：<https://github.com/lidofinance/lido-dao>

### 合约模块（必看 5 个）

| 文件 | 这个模块在做什么 | 必懂度 |
|---|---|---|
| `contracts/0.4.24/Lido.sol` | **核心**：质押 + stETH 铸造 | ★★★★★ |
| `contracts/0.4.24/StETH.sol` | rebase token 实现（**这是面试高频**） | ★★★★★ |
| `contracts/0.6.12/WstETH.sol` | wstETH（非 rebase 包装版） | ★★★★ |
| `contracts/0.8.9/WithdrawalQueueERC721.sol` | 退出队列（NFT 化） | ★★★★ |
| `contracts/0.8.9/oracle/AccountingOracle.sol` | 链下→链上的状态预言机（rebase 触发器） | ★★★★ |
| `contracts/0.8.9/StakingRouter.sol` | 多 module 路由（Curated / SimpleDVT / CSM） | ★★★ |

### 后端关联模块

| repo | 用途 |
|---|---|
| <https://github.com/lidofinance/lido-subgraph> | Lido 官方 subgraph |
| <https://github.com/lidofinance/lido-oracle> | Python 预言机节点（**有真实 Python 后端可读**） |

### 5 个面试高频问题

1. stETH 是 rebase token，那为什么 1inch / Uniswap 上是 wstETH？两者怎么转换？
2. 一笔 ETH 存进 Lido 后，怎么从用户钱包到验证人？中间有几跳？
3. AccountingOracle 怎么从信标链拉数据？为什么是 daily 不是 realtime？
4. Withdrawal Queue 排队是 FIFO 还是按金额？长尾用户怎么办？
5. Lido 占 ETH 质押 30%+ 的中心化风险，社区怎么应对（CSM / DVT）？

---

## 6. Ethena USDe（Delta-Neutral 稳定币） ⭐⭐⭐⭐ Binance Stablecoin 岗位强相关

**业务一句话**：用户存 stETH → 协议在 CEX 永续上做等量空单 → 现货上涨 = 空单亏；现货下跌 = 空单赚 → 净值锚定 1 美元（delta neutral）→ 用户拿 USDe 还能领 funding rate 收益。

**主仓库**：<https://github.com/ethena-labs/ethena>

### 合约模块（必看 3 个）

| 文件 | 这个模块在做什么 | 必懂度 |
|---|---|---|
| `contracts/USDe.sol` | USDe ERC20 + mint/burn 限制 | ★★★★ |
| `contracts/EthenaMinting.sol` | 申购/赎回入口（off-chain 签名 + on-chain 执行） | ★★★★★ |
| `contracts/StakedUSDe.sol` | sUSDe（质押 USDe 拿 funding rate 收益） | ★★★★ |
| `contracts/StakedUSDeV2.sol` | V2 版（增加 cooldown） | ★★★★ |

### 后端关联模块

> Ethena 的链下对冲引擎（CEX delta hedge）是闭源的，**这是 Binance Stablecoin 岗位"差异化"的机会**：
> 你能在面试讲"Ethena 的 hedge engine 闭源，但我能根据公开论文反推它的执行逻辑"。

| 资源 | 用途 |
|---|---|
| <https://ethena-labs.gitbook.io/ethena-labs/> | 官方文档 |
| <https://defillama.com/protocol/ethena> | Funding rate 收益历史数据（学完能讲"什么时候 USDe 不赚钱"） |

### 5 个面试高频问题

1. Delta neutral 在 funding rate 为负的极端行情下会怎样？
2. Ethena 的 collateral 用 stETH 而不是 ETH，多了哪些风险？
3. sUSDe 的 cooldown（7 天）是为了防什么攻击？
4. USDe 跨到其他链是用 LayerZero 还是 CCTP？为什么？
5. 与 Maker DSR 比，sUSDe 的收益率为什么会高很多？长期可持续吗？

---

# 四、衍生品类（高薪方向）

## 7. GMX V2 ⭐⭐⭐⭐ 永续 DEX 标杆

**业务一句话**：用户开杠杆永续 → 资金从 GM 池借 → trader 盈利 = LP 亏损（zero-sum）→ funding fee + borrow fee 让 LP 长期赚到（市场上 70% 散户亏损）。

**主仓库**：<https://github.com/gmx-io/gmx-synthetics>

### 合约模块（必看 5 个）

| 文件 | 这个模块在做什么 | 必懂度 |
|---|---|---|
| `contracts/exchange/OrderHandler.sol` | 订单创建/取消/执行 | ★★★★★ |
| `contracts/market/MarketUtils.sol` | 市场状态（OI、funding、PnL） | ★★★★★ |
| `contracts/position/PositionUtils.sol` | 持仓的开/加/减/平 | ★★★★ |
| `contracts/oracle/Oracle.sol` | 链下签名价格 + 链上验证 | ★★★★ |
| `contracts/pricing/SwapPricingUtils.sol` | swap 滑点定价 | ★★★ |
| `contracts/liquidation/LiquidationUtils.sol` | 清算 | ★★★★ |

### 后端关联模块

| repo | 用途 |
|---|---|
| <https://github.com/gmx-io/gmx-synthetics-subgraph> | 官方 subgraph |
| <https://github.com/gmx-io/gmx-interface> | 前端 + 链下 keeper bot 逻辑 |

### 5 个面试高频问题

1. GMX V2 的 keeper 机制：为什么要两阶段 commit-reveal？防什么 MEV？
2. funding fee 与 borrow fee 的差别？
3. GM 池里 long token / short token / index token 三个分别承担什么风险？
4. ADL（自动减仓）什么情况触发？为什么 LP 输不起？
5. V2 比 V1 的 GLP 模式好在哪？

---

## 8. Pendle（收益衍生品） ⭐⭐⭐⭐⭐ 2024-2026 最热

**业务一句话**：把生息资产（如 stETH）拆成 PT（Principal Token）+ YT（Yield Token）→ PT 锁本金固定收益、YT 赌利率波动 → 解锁 DeFi 利率市场。

**主仓库**：<https://github.com/pendle-finance/pendle-core-v2-public>

### 合约模块（必看 4 个）

| 文件 | 这个模块在做什么 | 必懂度 |
|---|---|---|
| `contracts/core/StandardizedYield/SYBase.sol` | SY token：把任何生息资产标准化 | ★★★★★ |
| `contracts/core/YieldContractsV2/PendleYieldToken.sol` | YT 实现 | ★★★★★ |
| `contracts/core/YieldContractsV2/PendlePrincipalToken.sol` | PT 实现 | ★★★★★ |
| `contracts/core/Market/PendleMarket.sol` | PT/SY 的 AMM 池（基于 Notional 的公式） | ★★★★ |
| `contracts/router/PendleRouter.sol` | 用户操作入口（路由） | ★★★ |

### 后端关联模块

| repo | 用途 |
|---|---|
| Pendle 的 Subgraph 官方未公开 GitHub，但 thegraph.com 上能查到 |  |
| <https://api-v2.pendle.finance/core/docs> | API 文档：能看到他们怎么算 implied APY / fixed rate |

### 5 个面试高频问题

1. PT 和 zero-coupon bond 在数学上是不是一回事？两者的差别？
2. YT 的价格随时间衰减到 0，这意味着什么？什么人会买 YT？
3. Pendle Market 的 AMM 公式（基于时间）和 Uniswap 的 x*y=k 有什么不同？
4. SY 标准化封装一个生息资产，主要做了哪几件事？
5. 在 Pendle 上买 stETH 的 fixed yield，如果 Lido 提前发生 slashing 会怎样？

---

# 五、创新业务

## 9. EigenLayer（Restaking 龙头） ⭐⭐⭐⭐⭐ 2024-2026 概念之王

**业务一句话**：质押过的 ETH（如 stETH / 原生 ETH）可以二次质押给其他协议（AVS - Actively Validated Service），换取额外收益，但要承担额外 slashing 风险。

**主仓库**：<https://github.com/Layr-Labs/eigenlayer-contracts>

### 合约模块（必看 5 个）

| 文件 | 这个模块在做什么 | 必懂度 |
|---|---|---|
| `src/contracts/core/StrategyManager.sol` | LST 类抵押品入金 | ★★★★★ |
| `src/contracts/pods/EigenPod.sol` | 原生 ETH 抵押品（信标链验证） | ★★★★★ |
| `src/contracts/core/DelegationManager.sol` | 委托给 Operator | ★★★★★ |
| `src/contracts/core/AVSDirectory.sol` | AVS（被服务方）注册 | ★★★★ |
| `src/contracts/core/Slasher.sol` | 罚没（V2 还在迭代） | ★★★★ |
| `src/contracts/strategies/StrategyBase.sol` | 单资产策略 | ★★★ |

### 后端关联模块

| repo | 用途 |
|---|---|
| <https://github.com/Layr-Labs/eigenda> | EigenDA（数据可用性，用 Go 写）—— **Mantle 招聘 JD 直接提到这个** |
| <https://github.com/Layr-Labs/eigensdk-go> | Operator 节点 SDK（**Go 后端可读**） |

### 5 个面试高频问题

1. Restaking 和普通 LST 的本质区别？为什么说它是"以太坊安全性的市场"？
2. AVS 是什么？举一个真实例子（如 EigenDA）。
3. Operator 怎么决定接哪些 AVS 任务？罚没风险怎么管理？
4. LRT（Liquid Restaking Token，如 ether.fi 的 eETH）和 LST 的差别在哪？
5. 二次质押的"系统性风险"是什么？2024 Vitalik 担忧的是哪部分？

---

## 10. Safe（前 Gnosis Safe） ⭐⭐⭐⭐ 多签托管标准

**业务一句话**：M-of-N 多签智能合约钱包 → 所有 DAO、DeFi 协议、CEX 冷钱包都用它 → 托管 1000 亿+ 美元资产。

**主仓库**：<https://github.com/safe-global/safe-smart-account>

### 合约模块（必看 4 个）

| 文件 | 这个模块在做什么 | 必懂度 |
|---|---|---|
| `contracts/Safe.sol` | **核心多签**：execTransaction 入口 | ★★★★★ |
| `contracts/base/OwnerManager.sol` | M-of-N owner 管理 | ★★★★ |
| `contracts/base/ModuleManager.sol` | **Module 扩展机制**（自定义功能插件） | ★★★★★ |
| `contracts/base/GuardManager.sol` | 交易守卫（pre/post hook） | ★★★ |
| `contracts/handler/CompatibilityFallbackHandler.sol` | EIP-1271 签名验证 | ★★★★ |

### 后端关联模块

| repo | 用途 |
|---|---|
| <https://github.com/safe-global/safe-transaction-service> | **Safe 官方 Python 后端**（Django）：交易聚合、签名收集、push 通知 → **这是难得的 DeFi 后端可读项目** |
| <https://github.com/safe-global/safe-eth-py> | Python SDK |

### 5 个面试高频问题

1. Safe 的 `execTransaction` 怎么验证 M-of-N 签名？签名按什么顺序排？
2. EIP-1271 是什么？Safe 怎么实现"合约钱包给 DApp 签名"？
3. Module 机制有什么用？举一个真实 Module 例子（如 Allowance Module、Recovery Module）。
4. Safe 的 transaction service 后端为什么需要存所有签名？为什么不上链？
5. CEX 用 Safe 做冷钱包托管时，会加哪些 Module 来增强安全？

---

## 11. Circle CCTP（USDC 跨链标准） ⭐⭐⭐⭐⭐

**业务一句话**：用户在源链 burn USDC → Circle Attestation Service 出具签名 → 用户在目标链用签名 mint USDC → 0 滑点 0 手续费的跨链。

**主仓库**：<https://github.com/circlefin/evm-cctp-contracts>

### 合约模块（必看 4 个）

| 文件 | 这个模块在做什么 | 必懂度 |
|---|---|---|
| `src/TokenMessenger.sol` | **入口**：depositForBurn / receiveMessage | ★★★★★ |
| `src/MessageTransmitter.sol` | 链间消息验证（Attester 多签） | ★★★★★ |
| `src/TokenMinter.sol` | 跨链 mint/burn 实现 | ★★★★ |
| `src/messages/Message.sol` | 跨链消息编码 | ★★★ |

### 后端关联模块

| 资源 | 用途 |
|---|---|
| <https://developers.circle.com/stablecoins/docs/cctp-api> | **Circle Attestation API 文档**：能学到一个跨链 service 怎么对外暴露 REST API |
| <https://github.com/circlefin/cctp-sample-app> | Sample 集成（含后端调用范例） |

### 5 个面试高频问题

1. CCTP 的 burn-and-mint 相比 LayerZero 的 lock-and-mint 优势在哪？
2. Attestation 服务是中心化的，这个信任假设可接受吗？
3. CCTP V2 的 Fast Transfer 比 V1 快在哪？引入了什么新风险？
4. CEX（如 Binance）做跨链充提如果接 CCTP，比自建桥省了什么？
5. 如果用户在源链 burn 后 Attestation 签名永远不出，怎么办？

---

# 六、补充说明

## 关于 OpenZeppelin（库）

不需要"读源码"，**用就完了**。但你必须**用过**：
- 所有合约都 `import "@openzeppelin/contracts/..."` 起步
- 重点掌握：`ERC20` / `ERC721` / `Ownable` / `AccessControl` / `ReentrancyGuard` / `SafeERC20` / `Pausable` / 三种 Proxy（UUPS / Transparent / Beacon）

## 关于 Foundry（工具）

不需要"读源码"，**用就完了**。但你必须**会用**：
- `forge test` 写单元测试
- `forge fuzz` 写模糊测试
- `forge invariant` 写不变量测试（**安全岗位面试加分**）
- `cast` 发链上交易和 query

→ 学完上面 12 个业务项目时，你天然会用 OZ 和 Foundry 了。

## 关于"基建/客户端类"为什么不推荐新人

| 项目 | 为什么不适合新人 |
|---|---|
| Geth / Reth | 改一行代码要懂整个 EVM + 客户端架构（≥6 个月） |
| OP Stack | 同上，且 derivation pipeline 是研究生级难度 |
| The Graph | Indexer 工作流复杂，但**业务故事少**，面试讲不出彩 |
| MetaMask / Trust Wallet Core | 工程量大，钱包后端业务薄 |
| Anchor | Solana 框架，**先选好语言再学**（Rust 学习曲线陡） |
| Hyperliquid | 闭源，只能看 spec，没源码可读 |

→ 这些适合 **入行 1-2 年后** 选 1-2 个深耕，新人**先用业务项目刷出 4 个故事最值钱**。

---

# 七、实战清单：4 周 4 个业务故事

| 周 | 项目 | 必读模块（5 文件以内） | 学完输出 |
|---|---|---|---|
| W1 | **Uniswap V3** | `UniswapV3Pool.sol` + `TickMath.sol` + `SqrtPriceMath.sol` | 一篇博客："V3 集中流动性的数学" |
| W2 | **Aave V3** | `Pool.sol` + `AToken.sol` + `LiquidationLogic.sol` + `ReserveLogic.sol` | 用 Java/Go 写一个 demo：调用测试网 Aave supply + borrow + 监听清算 |
| W3 | **MakerDAO** + **Lido** | Maker: `vat.sol` + `clip.sol`；Lido: `Lido.sol` + `StETH.sol` + `WithdrawalQueue` | 一篇博客："稳定币与 LST 的发行机制" |
| W4 | **Pendle** 或 **EigenLayer** 或 **GMX V2**（按目标公司选） | 各自 4-5 个核心合约 | 业务故事卡片 |

完成 4 周后，简历上能写：

> **DeFi 协议研究项目（个人）**
> 系统拆解过 Uniswap V3 / Aave V3 / MakerDAO / Lido / Pendle 5 个 DeFi 龙头协议的核心合约（共 30+ 文件），输出 4 篇业务分析博客。基于 Aave V3 用 Java 实现了 DeFi Adapter Demo，覆盖 supply/borrow/liquidation 监听全流程。

→ **这一段直接对标 Binance DeFi/Web3 Java Engineer 岗位的 JD**。

---

# 八、可能的下一步

| 选项 | 说明 |
|---|---|
| **A** | 选 W1 的 Uniswap V3 出**3 天速读笔记**：每天读哪几个文件、关键概念、自己写代码片段 |
| **B** | 选 W2 的 Aave V3 出**Java DeFi Adapter 集成 Demo**：用 web3j 调用测试网 Aave 的完整代码 |
| **C** | 把这份 12 个项目的"业务故事卡片"汇总成一份 Anki 复习材料（每张卡片：项目 + 一句话 + 5 个高频题） |
| **D** | 在我们项目里建 `repos/` 目录，把这 12 个 repo 用 git submodule 加进去，方便你本地直接 `cursor` 打开读 |
