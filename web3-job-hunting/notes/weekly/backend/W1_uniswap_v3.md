# W1 — Uniswap V3 后端篇

> **DEX 业务理解 + 报价缓存 + LP 收益看板**
> 配套 [`../../../reports/learning_roadmap_v4_backend_first.md`](../../../reports/learning_roadmap_v4_backend_first.md) 第 W1 章节
> **进度跟踪（逐文件导读）**：[`W1_uniswap_v3_reading_checklist.md`](./W1_uniswap_v3_reading_checklist.md)
> 仓库位置：`repos/dex/uniswap-v3-core/`
> 官方文档：<https://docs.uniswap.org/concepts/protocol/concentrated-liquidity>

---

## 📐 方向总览（总控视角 — 子 agent 必读，你执行前也看一眼）

> 这一段不指挥你"读第几行"，而是告诉你**这周要往哪打 / 不打哪 / 用什么弹药**。
> 具体的"读哪几行 / 写哪段代码"由子 agent 自己决策。

### A. 项目抉择 — 为什么这周是 Uniswap V3

| 维度 | 内容 |
|---|---|
| **业务定位** | EVM 上 TVL 最大的 DEX，集中流动性 + tick range 设计，**几乎所有 DEX 聚合器都集成它** |
| **JD 数据支撑** | DeFi 协议方向 30 天 **42** 个命中岗位的代表项目（数据：[`reports/business_focused_repos_v2_data_driven.md`](../../../reports/business_focused_repos_v2_data_driven.md) §一）|
| **背景匹配度** | ⭐⭐⭐⭐⭐ — 后端核心是「事件流解析 + 数学计算 + 时序聚合」，跟 Java/Go 后端肌肉记忆完全对口 |
| **为什么不选 V4** | V4 hooks/singleton 架构刚发布，生态/JD 仍以 V3 为主；V4 等 W8 差异化做亮点 |
| **为什么不选 Curve / Balancer** | StableSwap/Weighted Pool 业务窄；V3 的"集中流动性"是后端做 LP 看板/聚合报价时唯一非看不可的范式 |

### B. 本周后端关注点 vs 不关注点

| ✅ **本周必学的后端模块** | ❌ **跳过的（合约 / 数学 / 前端）** |
|---|---|
| 链上事件 → DB 的 indexer pipeline（Subgraph 是范本，你用 Go 复现）| `SqrtPriceMath.sol` 的数学推导（理解输入输出即可）|
| 多池子状态缓存 + 报价 API 设计 | tick spacing 的 Q64.96 定点数原理 |
| LP position 链下聚合（mint/burn/collect 三类事件汇总）| `UniswapV3Factory.sol` 的合约部署细节 |
| 24h/Hour 时序聚合写法 | 前端 swap UI / 价格曲线渲染 |
| reorg 处理 + 增量扫块策略 | Solidity 内联汇编 |

→ **一句话**：本周你的两个 Go PoC 形态都是：
> 「监听 Pool 合约 `Swap/Mint/Burn/Collect` event → 解码 → 用 `sqrtPriceX96` 换算 → 写 Postgres → 暴露 REST/WS 接口」

### C. 仓库分级（已 clone — 子 agent 重点啃这里）

| 仓库路径 | 等级 | 必看模块 | 后端价值 |
|---|---|---|---|
| `repos/dex/uniswap-v3-core/contracts/UniswapV3Pool.sol` | 🔴 **必看** | 14 个 public 函数 + 全 events（Swap/Mint/Burn/Collect/Initialize 等）| 你 indexer 的输入信号源 |
| `repos/dex/uniswap-v3-core/contracts/libraries/SqrtPriceMath.sol` `SwapMath.sol` `TickMath.sol` | 🟡 参考 | 只看函数签名和注释（不抠数学）| 写 Go PoC 时若要链下复现报价，对照接口翻译 |
| `repos/dex/uniswap-v3-core/contracts/libraries/Position.sol` | 🟡 参考 | LP position 数据结构 | 你的 DB schema 直接对照 |
| **`repos/dex/uniswap-v3-subgraph/src/common/pricing.ts`** | 🔴🔴 **必看，王炸** | `sqrtPriceX96ToTokenPrices` + `findEthPerToken` | **聚合器报价的核心 11 行**，直接翻译成 Go = PoC #1 一半 |
| **`repos/dex/uniswap-v3-subgraph/src/v3/mappings/`** | 🔴 **必看** | `swap.ts / mint.ts / burn.ts / collect.ts / initialize.ts / intervalUpdates.ts` | **后端 indexer 思维直接对照** — 同样的事件处理你怎么用 Go + Postgres 重写 |
| `repos/dex/uniswap-v3-subgraph/src/v3/schema.graphql` | 🟡 参考 | Pool / Position / Swap / Tick entity | 你的 Postgres schema 直接对照 |

### D. 仓库分级（参考价值高，未 clone — 子 agent 按需补）

| 仓库 | 等级 | 用途 | 何时补 |
|---|---|---|---|
| [Uniswap/v3-sdk](https://github.com/Uniswap/v3-sdk) | 🟡 参考 | 官方 TS SDK，**链下报价计算的官方实现**（比 subgraph 更纯粹）| 做系统设计 #1 PoC 时若想看官方怎么算 quote |
| [DefiLlama/DefiLlama-Adapters](https://github.com/DefiLlama/DefiLlama-Adapters) 里的 `uniswap-v3.js` | 🟡 参考 | TVL 计算的工业实现 | 做系统设计 #2 LP 看板时对照 TVL 公式 |
| [Uniswap/interface](https://github.com/Uniswap/interface) | 🟢 选看 | 前端怎么用 SDK | 不必看（你做的是后端）|
| 1inch v5 / Jupiter | 🟢 选看 | 聚合算法范例（Solidity / Rust）| 跟你 Go 不对口，跳过 |

> ⚪ **要 clone 的话**：`git clone --depth=1 https://github.com/Uniswap/v3-sdk web3-job-hunting/repos/dex/uniswap-v3-sdk`

### E. 2 道系统设计题的「考点」（面试官真问什么）

#### 题 #1 — DEX 聚合器报价缓存系统

| 维度 | 内容 |
|---|---|
| **后端面试官真问** | "百万 QPS 怎么撑？" / "新 Swap event 来了，缓存怎么及时更新不脏？" / "多个池子的同一对 token 你选哪条路径报价？" / "reorg 时缓存怎么回滚？" |
| **核心模块**（3 个）| 1) **Listener**（订阅全链 Pool Swap event）2) **Cache**（Redis ZSET 按 token-pair 索引，存 sqrtPrice + tick + liquidity）3) **Quoter API**（REST，输入 tokenIn/Out/amount → 输出 quote） |
| **PoC 难点** | 不在算法，在**多 RPC fallback** + **reorg 12 块 buffer** + **缓存原子更新**（避免读到半新半旧）|
| **抄哪段代码起步** | `repos/dex/uniswap-v3-subgraph/src/common/pricing.ts` 的 11 行报价公式 + `swap.ts` 的事件解析 |

#### 题 #2 — LP 收益看板

| 维度 | 内容 |
|---|---|
| **后端面试官真问** | "fee earned 怎么算？" / "无常损失 IL 公式？" / "用户 100 个 position 怎么聚合查询？" / "24h volume 怎么不爆掉 DB？" |
| **核心模块**（4 个）| 1) **Indexer**（Mint/Burn/Collect/Swap 入 PG）2) **Aggregator**（按 position NFT id 聚合 fee + IL）3) **Time-series**（24h/7d/30d 聚合表）4) **API**（按用户地址查所有 position 收益） |
| **PoC 难点** | fee growth 累加（Uniswap V3 用 `feeGrowthInside0LastX128` / `feeGrowthInside1LastX128`，需要在事件流里跟踪差值）|
| **抄哪段代码起步** | `repos/dex/uniswap-v3-subgraph/src/common/position.ts` + `src/v3/mappings/mint.ts / burn.ts / collect.ts / intervalUpdates.ts` |

### F. 给子 agent 的执行边界

- ✅ **可以自由决策**：读哪几行、写哪个 PoC 模块、用哪个 Go 库、起什么 PoC 仓库名
- ❌ **不要做**：① 改本周项目选择 ② 改 2 道题目方向 ③ 改仓库分级 ④ 添加额外的"扩展阅读"让用户读不完
- ⚠️ **遇到分歧问总控**：如果发现"D 段未 clone 的仓库"做 PoC 时不可或缺 → 报告总控审批 clone

---

## D1（4h）— 业务速读

### 必读清单（**只读业务，不读源码**）

  - [ ] `contracts/UniswapV3Pool.sol` — 只看 public function 签名（mint/burn/swap/collect）+ 全部 events
  - [ ] `contracts/UniswapV3Factory.sol` — createPool 入口与 PoolCreated event
  - [ ] Uniswap docs：Concentrated Liquidity 章节（业务）
  - [ ] Uniswap docs：Position Manager NFT 章节（业务）

### 关键 events（后端 indexer 的输入信号）

```
PoolCreated, Mint, Burn, Swap, Collect, Initialize
```

### 输出 1：业务故事卡（300 字）

> 模板见 [`../../_template/business_card.md`](../../_template/business_card.md)

**一句话**（30 字内）：

**100 字业务背景**：

**100 字核心机制**：

**70 字创新点**：

### 输出 2：业务流程图

> 用 ASCII 或 mermaid 画一张图，包含：
> - 用户态：用户做了什么操作
> - 合约态：合约触发了什么事件
> - 链下态：后端系统应该响应什么

```
[在这里画图]
```

---

## D2-D3 + D4（8-10h）— 2 道系统设计题（每题必带 PoC）

> 模板见 [`../../_template/system_design.md`](../../_template/system_design.md)

### 系统设计题 #1：DEX 聚合器报价缓存系统

> **场景**：1inch / 0x / Jupiter 后端核心
> **PoC 焦点**：缓存全链所有 V3 池的 sqrtPrice/tick/liquidity，给报价器毫秒级响应
>
> 请用 [`../../_template/system_design.md`](../../_template/system_design.md) 模板填写完整 7 段（场景/规模/架构/Schema/API/Tradeoff/监控）+ 100-200 行 PoC。

#### 我的方案（在此填写或链接到独立 markdown）

> 例：参见 [`./W1_sd1_solution.md`](./W1_sd1_solution.md)


#### PoC 仓库（**本周必做**）

PoC 放在 `repos/_demos/W1_1_xxx/`

- [ ] 项目脚手架建好（5-8 个 Go 文件）
- [ ] 主流程跑通（happy path）
- [ ] README 写好（讲清"做什么/怎么跑/学到什么"）
- [ ] 推到 GitHub（链接：____________________）

---
### 系统设计题 #2：LP 收益看板

> **场景**：DefiLlama / Revert Finance
> **PoC 焦点**：算每个 NFT position 的 fee earned + impermanent loss
>
> 请用 [`../../_template/system_design.md`](../../_template/system_design.md) 模板填写完整 7 段（场景/规模/架构/Schema/API/Tradeoff/监控）+ 100-200 行 PoC。

#### 我的方案（在此填写或链接到独立 markdown）

> 例：参见 [`./W1_sd2_solution.md`](./W1_sd2_solution.md)


#### PoC 仓库（**本周必做**）

PoC 放在 `repos/_demos/W1_2_xxx/`

- [ ] 项目脚手架建好（5-8 个 Go 文件）
- [ ] 主流程跑通（happy path）
- [ ] README 写好（讲清"做什么/怎么跑/学到什么"）
- [ ] 推到 GitHub（链接：____________________）

---


---

## 周日内化（30 分钟）

### 镜子讲述（5 分钟，不看资料）

- [ ] 我能讲清这周协议的业务流（用户做什么 / 链上发生什么 / 后端响应什么）
- [ ] 我能讲清系统设计题 #1 的架构 + 关键 tradeoff
- [ ] 我能讲清系统设计题 #2 的架构 + 关键 tradeoff
- [ ] 我能回答 1 个面试官追问（"如果规模翻 100 倍呢？" / "RPC 延迟 100ms 怎么办？"）

→ 全 √ → 进下周。任一不通过 → 回去补，**不许进入下一周**。

### 简历更新（**本周必做**）

在简历"项目经验"末尾追加 1 行：

> 例：W2 完成后加 — *"针对 Aave V3 设计了健康因子实时监控 + 推送系统（10 万用户规模），用 Go 实现了 Listener + Calculator + Notifier 全链路 PoC（覆盖 RPC fallback / reorg 处理 / Webhook 重试）"*

我加的内容：

> ___________________________________________________________

### 输出物 checklist

- [ ] 业务故事卡：本文档已填
- [ ] 业务流程图：本文档已填
- [ ] 系统设计题 #1：完整 7 段 + PoC 推 GitHub
- [ ] 系统设计题 #2：完整 7 段 + PoC 推 GitHub
- [ ] 博客（可选）：[链接]
- [ ] Anki 卡片（可选）：本周新增 ___ 张
