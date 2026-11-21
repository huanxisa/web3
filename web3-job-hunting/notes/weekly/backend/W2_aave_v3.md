# W2 — Aave V3 后端篇

> **借贷业务 + 健康因子监控 + 清算机器人 ⭐ 完整示范周**
> 配套 [`../../../reports/learning_roadmap_v4_backend_first.md`](../../../reports/learning_roadmap_v4_backend_first.md) 第 W2 章节
> 仓库位置：`repos/lending/aave-v3-core/`
> 官方文档：<https://docs.aave.com/developers/core-contracts/pool>

---

## 📐 方向总览（总控视角 — 子 agent 必读，你执行前也看一眼）

> 这一段不指挥你"读第几行"，而是告诉你**这周要往哪打 / 不打哪 / 用什么弹药**。
> 具体的"读哪几行 / 写哪段代码"由子 agent 自己决策。
> 本周提供完整解答示范：[`./W2_sd1_health_monitor_solution.md`](./W2_sd1_health_monitor_solution.md)（**先看一遍这个再开始**）。

### A. 项目抉择 — 为什么这周是 Aave V3

| 维度 | 内容 |
|---|---|
| **业务定位** | EVM 上 TVL 最大借贷协议，**健康因子 / 清算 / 利率模型**是 DeFi 借贷的标准范式 |
| **JD 数据支撑** | DeFi 协议方向 30 天 **42** 个命中岗位的核心代表项目（[`reports/business_focused_repos_v2_data_driven.md`](../../../reports/business_focused_repos_v2_data_driven.md) §一）|
| **背景匹配度** | ⭐⭐⭐⭐⭐ — 借贷的所有后端动作（事件监听 → 风险计算 → 告警 → 推送）都是 Java/Go 后端标准动作，**比 DEX 还更熟悉** |
| **为什么不选 Compound** | Compound V3 业务模式相似但市占率更小；Aave V3 跨链部署 + flashloan + GHO 稳定币，**业务覆盖面 3x**，JD 提及频率更高 |
| **为什么不选 Morpho / Spark** | 是 Aave 之上的二级协议，理解 Aave 后顺便 30 分钟看完即可，不值得占一周 |

### B. 本周后端关注点 vs 不关注点

| ✅ **本周必学的后端模块** | ❌ **跳过的（合约 / 数学 / 前端）** |
|---|---|
| **健康因子计算**（链下复现 `getUserAccountData` 逻辑）| `ReserveLogic.sol` 利率指数 Ray 数学推导 |
| **大规模用户态扫描**（10 万用户 healthFactor 每分钟轮询）| `BorrowLogic.sol` / `LiquidationLogic.sol` 内部实现细节 |
| **清算机会发现 + 模拟收益**（链下 simulate liquidationCall）| flashloan callback 合约模板 |
| **事件流 indexer**（Supply/Borrow/Liquidation 入 PG）| eMode / Isolation Mode 的合约级配置 |
| **告警 / 推送 / Webhook** 的可靠性保证 | aToken / variableDebtToken 的 ERC20 wrap 实现 |

→ **一句话**：本周两个 Go PoC 形态：
> **#1**「订阅 Pool Supply/Borrow event → 算 healthFactor → < 阈值 → Webhook 推送」
> **#2**「定时扫所有借款人 → 算可清算的 → simulate 收益 > gas → bid 上链」

### C. 仓库分级（已 clone — 子 agent 重点啃这里）

| 仓库路径 | 等级 | 必看模块 | 后端价值 |
|---|---|---|---|
| `repos/lending/aave-v3-core/contracts/protocol/pool/Pool.sol` | 🔴 **必看** | `supply / borrow / repay / withdraw / liquidationCall` public 签名 + 全 events | indexer 输入信号 |
| `repos/lending/aave-v3-core/contracts/protocol/libraries/logic/GenericLogic.sol` | 🔴🔴 **必看，王炸** | `calculateUserAccountData` 函数注释 | **健康因子链下复现的官方算法** — 直接翻译成 Go = PoC #1 核心 |
| `repos/lending/aave-v3-core/contracts/protocol/libraries/configuration/ReserveConfiguration.sol` | 🟡 参考 | LTV / LiquidationThreshold 配置位图 | 健康因子计算的输入参数从哪里取 |
| `repos/lending/aave-protocol-subgraphs/` | 🔴 **必看** | `src/mapping/` 下 supply / borrow / liquidation 处理器 | **后端 indexer 思维直接对照** |
| `repos/lending/aave-utilities/` | 🔴 **必看** | TS SDK 的 `formatUserSummary` / 健康因子格式化 | **健康因子链下计算的官方 TS 实现，直接对照翻译成 Go** |

### D. 仓库分级（参考价值高，未 clone — 子 agent 按需补）

| 仓库 | 等级 | 用途 | 何时补 |
|---|---|---|---|
| [aave/aave-v3-deploy](https://github.com/aave/aave-v3-deploy) | 🟢 选看 | 部署脚本，不必看 | 不补 |
| [DeFiLlama-Adapters/aave-v3](https://github.com/DefiLlama/DefiLlama-Adapters) | 🟡 参考 | TVL 计算工业实现 | 如果 PoC 需要算 TVL |
| [DeFiSaver / Instadapp 清算工具](https://github.com/defisaver/defisaver-v3-contracts) | 🟡 参考 | 实战清算 keeper 范例 | PoC #2 清算机器人 chips 参考 |

### E. 2 道系统设计题的「考点」（面试官真问什么）

#### 题 #1 — 用户健康因子实时监控 + 推送系统 ⭐（提供完整示范解答）

| 维度 | 内容 |
|---|---|
| **后端面试官真问** | "10 万用户每分钟扫一次怎么扛？" / "RPC 限流 / 失败怎么办？" / "reorg 时已发的告警怎么回滚？" / "Webhook 失败重试怎么不打爆下游？" |
| **核心模块**（4 个）| 1) **Listener**（订阅 Pool event）2) **Calculator**（链下复现 healthFactor，用 multicall 批量查）3) **Notifier**（< 阈值时 Webhook 推送 + 去重 + 退避）4) **State**（Postgres 存用户头寸快照）|
| **PoC 难点** | **批量计算性能**（10 万地址 × multicall）+ **告警去重**（同一用户连续告警合并）+ **reorg 12 块 buffer** |
| **抄哪段代码起步** | `aave-utilities/src/.../FormatUserSummaryAndIncentives.ts` 的健康因子算法 + `repos/lending/aave-v3-core/.../GenericLogic.sol::calculateUserAccountData` 的合约版对照 |
| **参考解答** | [`./W2_sd1_health_monitor_solution.md`](./W2_sd1_health_monitor_solution.md) — **必看，本周内化的样板** |

#### 题 #2 — 清算机器人架构

| 维度 | 内容 |
|---|---|
| **后端面试官真问** | "怎么发现可清算地址？" / "怎么估算清算收益 > gas？" / "如何抢 MEV？私池还是 public mempool？" / "失败怎么回滚 inventory？" |
| **核心模块**（5 个）| 1) **Scanner**（持续轮询健康因子 < 1）2) **Simulator**（用 `eth_call` 模拟 liquidationCall 收益）3) **Profit Filter**（收益 - gas - slippage > 阈值）4) **Submitter**（送 Flashbots / private pool）5) **PnL Tracker**（成败统计）|
| **PoC 难点** | 不在合约，在**与 RPC 节点的实时竞争**（latency budget < 100ms）+ **失败回滚 inventory** + **不同 chain 不同 mempool 策略** |
| **抄哪段代码起步** | `repos/lending/aave-v3-core/.../LiquidationLogic.sol` 的 liquidationCall 入口 + Aave 官方 `aave-flashloan-liquidator` 范例 |

### F. 给子 agent 的执行边界

- ✅ **可以自由决策**：读哪几行、写哪个 PoC 模块、选 Go 库、PoC 仓库命名
- ❌ **不要做**：① 改本周项目 ② 改 2 道题方向 ③ 跳过示范解答 [`./W2_sd1_health_monitor_solution.md`](./W2_sd1_health_monitor_solution.md) ④ 试图把 healthFactor 公式重新推导
- ⚠️ **遇到分歧问总控**：如果发现 `aave-utilities` 的 TS 算法在 Go 里很难复现 → 报告总控审批

---

## D1（4h）— 业务速读

### 必读清单（**只读业务，不读源码**）

  - [ ] `contracts/protocol/pool/Pool.sol` — 只看 public function（supply/borrow/repay/withdraw/liquidationCall）+ 全 events
  - [ ] Aave docs：Risk Parameters 章节（LTV / Liquidation Threshold / Liquidation Bonus）
  - [ ] Aave docs：Liquidations 章节（清算业务流程）
  - [ ] Aave docs：Interest Rate Model 章节（utilization 曲线）

### 关键 events（后端 indexer 的输入信号）

```
Supply, Withdraw, Borrow, Repay, LiquidationCall, ReserveUsedAsCollateralEnabled/Disabled, FlashLoan
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

### 系统设计题 #1：用户健康因子实时监控 + 推送系统 ⭐

> **场景**：DeFi 钱包推送 / Aave 安全告警
> **PoC 焦点**：监听 Borrow/Supply event，算 healthFactor，<阈值告警 + Webhook
>
> 请用 [`../../_template/system_design.md`](../../_template/system_design.md) 模板填写完整 7 段（场景/规模/架构/Schema/API/Tradeoff/监控）+ 100-200 行 PoC。

#### 我的方案（在此填写或链接到独立 markdown）

> 例：参见 [`./W2_sd1_solution.md`](./W2_sd1_solution.md)


#### PoC 仓库（**本周必做**）

⭐ **本题是核心 Demo aave-health-monitor**，推到 GitHub 公开

- [ ] 项目脚手架建好（5-8 个 Go 文件）
- [ ] 主流程跑通（happy path）
- [ ] README 写好（讲清"做什么/怎么跑/学到什么"）
- [ ] 推到 GitHub（链接：____________________）

---
### 系统设计题 #2：清算机器人架构

> **场景**：MEV / 清算 keeper 公司
> **PoC 焦点**：扫描所有低健康度地址，模拟 liquidationCall 收益，bid 上链
>
> 请用 [`../../_template/system_design.md`](../../_template/system_design.md) 模板填写完整 7 段（场景/规模/架构/Schema/API/Tradeoff/监控）+ 100-200 行 PoC。

#### 我的方案（在此填写或链接到独立 markdown）

> 例：参见 [`./W2_sd2_solution.md`](./W2_sd2_solution.md)


#### PoC 仓库（**本周必做**）

PoC 放在 `repos/_demos/W2_2_xxx/`

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
