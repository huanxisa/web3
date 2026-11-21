# 套利与 MEV —— DeFi 价格发现的执行层

> **分支主题**：从 AMM 定价原理延伸，理解链上套利的完整链路。  
> **前置阅读**：[`W1_uniswap_v3_reading_checklist.md`](../weekly/backend/W1_uniswap_v3_reading_checklist.md)（理解 x·y=k 和 tick 机制后再读本文）  
> **适用方向**：后端工程 / 量化基础 / MEV 工程（L3 方向）  
> **创建时间**：2026-09-07

---

## 一、为什么套利重要（不只是赚钱）

套利不只是「赚差价」，它是 AMM 能正常工作的**核心机制**：

```
AMM 只能被动响应交易
套利者 = AMM 价格和市场真实价格之间的"桥梁"
没有套利者 → AMM 价格偏离市场 → LP 承担损失 → 无人愿意当 LP
```

**套利让 AMM 的简单数学模型（x·y=k）能反映真实市场价格**。这是整个 DeFi 可以运转的基础假设。

---

## 二、核心数学：套利收敛的必然性

### 前提

只要两个市场都满足「物以稀为贵」（单调价格响应）：
- AMM：价格 = y/x，x 减少则价格上升 ✓
- 外部市场：有人买则价格上升 ✓

### 收敛过程

设 AMM 价格 P_amm > 外部市场价格 P_ex：

```
每轮套利：
  ① 在外部市场买 token0（便宜）→ P_ex 上升
  ② 把 token0 卖入 AMM（贵）   → P_amm 下降
  
差值 D = P_amm - P_ex 严格单调递减
```

**无摩擦时**：D → 0，完全收敛  
**有手续费 f 时**：D 收敛至 `|P_amm - P_ex| < f`，形成价格带

### 价格冲击与 k 的关系

固定交易量 Δx，价格冲击：

```
ΔP/P ≈ -2Δx / √(k/P) = -2Δx√P / √k

即：价格冲击 ∝ 1/√k = 1/L
```

L（= √k）越大 → 同样套利量引起的价格变化越小 → 套利空间越快消失。

---

## 三、套利的完整执行链路

```
┌─────────────────────────────────────────────────────────────┐
│                     套利 Bot 架构                            │
│                                                             │
│  1. 监听层         2. 计算层          3. 执行层             │
│  ──────────        ──────────         ──────────            │
│  订阅 mempool      枚举路径           构建 tx bundle          │
│  监听新块          计算价差           通过 Flashbots 发送     │
│  捕获 Swap event   扣除 gas 估算      链上合约原子执行        │
│                    确认净利润 > 0     闪电贷零资本套利        │
└─────────────────────────────────────────────────────────────┘
```

### 3.1 监听层：两种信息来源

| 来源 | 时机 | 优势 | 劣势 |
|---|---|---|---|
| **Mempool**（pending tx）| tx 确认前 | 最快，可抢先 | 可能被其他 bot 抢跑 |
| **新块事件** | tx 已确认 | 确定性高 | 慢一个块 |

### 3.2 计算层：套利利润公式

```
净利润 = 套利收益 - gas 成本 - 手续费

套利收益：
  在 DEX A 卖出 Δtoken0，得到 Δy_A（按 A 的 x·y=k 算）
  在 DEX B 买入 Δtoken0，花费 Δy_B（按 B 的 x·y=k 算）
  套利收益 = Δy_A - Δy_B

gas 成本：
  ≈ (gasUsed × baseFee + priorityFee) × ETH_price
  单笔套利 tx 约 200,000 ~ 500,000 gas

触发条件：净利润 > 0（实际要 > 0 一定 buffer，防止 gas 波动）
```

### 3.3 执行层：闪电贷实现零资本套利

```
同一笔 tx 内（原子执行，要么全成功要么全回滚）：

① 从 Aave 借出 1,000,000 USDC（闪电贷，零抵押）
② 在 DEX A（价格 1900）买入 526 ETH，花费 1,000,000 USDC
③ 在 DEX B（价格 2000）卖出 526 ETH，得到 1,052,000 USDC
④ 还给 Aave：1,000,000 + 900（0.09% 手续费）= 1,000,900 USDC
⑤ 净利润 = 1,052,000 - 1,000,900 = 51,100 USDC（扣 gas 后）

如果步骤 ③ 价格已被别人抢走 → 整笔 tx revert，零损失
```

---

## 四、MEV（最大可提取价值）全景

MEV = 矿工/验证者/搜索者通过控制交易顺序能提取的最大价值。

### 4.1 MEV 的三种主要形式

| 类型 | 机制 | 示例 |
|---|---|---|
| **套利（Arbitrage）** | 跨 DEX 价差 | Uniswap A 买，Sushiswap 卖 |
| **清算（Liquidation）** | 借贷协议抵押不足时抢先清算 | Aave 清算机器人 |
| **三明治攻击（Sandwich）** | 夹击大单：在目标 tx 前买入，后卖出 | 有害，损害普通用户 |

### 4.2 MEV 基础设施生态

```
搜索者（Searcher）
  ↓ 发送 bundle（不经公开 mempool）
Flashbots Relay
  ↓ 传递给
Block Builder（如 BloXroute、Titan）
  ↓ 构建出价最高的区块
Validator / Proposer
  ↓ 选择并提交区块
Ethereum 主链
```

**关键角色**：
- **Searcher**：写套利 bot 的工程师，发现并执行机会
- **Builder**：聚合多个 Searcher 的 bundle，构建最优区块
- **Relay**：可信中间层，防止 Builder 窃取 Searcher 的策略

---

## 五、开源项目清单

### 5.1 入门级（可直接读懂）

| 项目 | 链接 | 语言 | 说明 |
|---|---|---|---|
| **flashbots/simple-arbitrage** | `github.com/flashbots/simple-arbitrage` | TypeScript | Uniswap V2 ↔ Sushiswap 套利，代码最简洁，适合入门 |
| **flashbots/mev-inspect-py** | `github.com/flashbots/mev-inspect-py` | Python | 分析链上历史 MEV 交易，数据分析用途 |

### 5.2 生产级框架

| 项目 | 链接 | 语言 | 说明 |
|---|---|---|---|
| **paradigmxyz/artemis** | `github.com/paradigmxyz/artemis` | Rust | MEV bot 框架，模块化：Collector → Strategy → Executor |
| **flashbots/mev-boost** | `github.com/flashbots/mev-boost` | Go | PBS（提议者-构建者分离）核心基础设施 |

### 5.3 你项目里已有的相关代码

| 路径 | 和套利的关系 |
|---|---|
| `repos/dex/smart-order-router/src/routers/alpha-router/alpha-router.ts` | 路径发现主流程，与套利计算同构 |
| `repos/dex/smart-order-router/src/routers/alpha-router/functions/best-swap-route.ts` | 多路径最优选择 |
| `repos/dex/smart-order-router/src/providers/v3/pool-provider.ts` | 批量拉取池子状态（套利 bot 的数据源）|

**路由引擎 vs 套利 bot 的区别**：

```
smart-order-router：帮用户找最优成交价（一个方向）
套利 bot：找两个市场的价差并同时执行（两个方向，闭环）
```

两者的底层计算逻辑几乎一样：都是「给定池子状态，计算最优路径」。

---

## 六、最小可行套利 Bot（伪代码骨架）

```typescript
// 极简跨 DEX 套利 bot
import { ethers } from 'ethers'

const POOL_UNISWAP = '0x...'
const POOL_SUSHI   = '0x...'

async function findArbitrage() {
  // 1. 拉两个池子的当前状态
  const [priceUni, priceSushi] = await Promise.all([
    getPoolPrice(POOL_UNISWAP),
    getPoolPrice(POOL_SUSHI),
  ])

  // 2. 计算价差和套利方向
  const diff = Math.abs(priceUni - priceSushi) / Math.min(priceUni, priceSushi)
  const gasCostUSD = await estimateGasCost()
  const tradeAmount = 10_000  // $10,000 USDC

  const grossProfit = diff * tradeAmount
  const netProfit   = grossProfit - gasCostUSD

  // 3. 有利可图才执行
  if (netProfit > 50) {  // 至少 $50 净利润
    const direction = priceUni > priceSushi ? 'uni→sushi' : 'sushi→uni'
    await executeArbitrage(direction, tradeAmount)
    console.log(`套利成功，净利润: $${netProfit.toFixed(2)}`)
  }
}

// 每个新块触发一次检查
provider.on('block', findArbitrage)
```

---

## 七、学习路径建议

```
当前位置                        可以探索
──────────────────              ──────────────────────────────────
理解 x·y=k 定价原理     →  读 simple-arbitrage 的套利计算逻辑
理解 smart-order-router →  理解路径枚举是套利计算的子集
理解 Pool.swap() 执行   →  理解闪电贷套利在单 tx 内的原子性
                         →  尝试写一个监听两个池子价差的脚本
```

### 面试价值

能说清套利机制，等于说清了：
1. AMM 为什么能持续反映真实价格（不偏离）
2. 为什么 LP 的资本效率和 k 有关
3. DeFi 价格发现的去中心化机制

---

## 八、关键术语速查

| 术语 | 含义 |
|---|---|
| **MEV** | Maximal Extractable Value，矿工/验证者可提取的最大价值 |
| **Searcher** | 编写 MEV bot 发现并执行套利机会的工程师/机构 |
| **Bundle** | 打包成一组的多笔 tx，要么全执行要么全回滚 |
| **Flashbots** | 提供 MEV 基础设施的团队，核心产品是 mev-boost |
| **Flash Loan** | 闪电贷，同一 tx 内借还，无需抵押 |
| **Sandwich Attack** | 三明治攻击，夹击目标大单抢利润，有害于普通用户 |
| **PBS** | Proposer-Builder Separation，提议者和构建者分离，防止验证者直接做 MEV |
| **Price Band** | 价格带，有手续费时套利收敛的终态：\|P_amm - P_ex\| < fee |

---

## 变更记录

| 日期 | 动作 |
|---|---|
| 2026-09-07 | 初版：从 AMM 讨论延伸，包含定价原理、执行链路、开源项目清单 |
