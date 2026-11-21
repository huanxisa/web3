# W4 — Lido 后端篇

> **LST 业务 + stETH rebase 推送 + Operator 数据 pipeline**
> 配套 [`../../../reports/learning_roadmap_v4_backend_first.md`](../../../reports/learning_roadmap_v4_backend_first.md) 第 W4 章节
> 仓库位置：`repos/stablecoin/lido-dao/ + lido-oracle/`
> 官方文档：<https://docs.lido.fi/>

---

## 📐 方向总览（总控视角 — 子 agent 必读，你执行前也看一眼）

> 这一段不指挥你"读第几行"，告诉你**这周往哪打 / 不打哪 / 用什么弹药**。

### A. 项目抉择 — 为什么这周是 Lido

| 维度 | 内容 |
|---|---|
| **业务定位** | 以太坊 LST（流动性质押代币）龙头，TVL 长期居 DeFi 第一，**stETH 是 DeFi 二级市场的"质押 ETH 货币"** |
| **JD 数据支撑** | Staking/LST/LRT 方向 30 天 **15** 个命中（Lido / Coinbase Wallet / 各家钱包都问"stETH rebase 怎么处理"）|
| **背景匹配度** | ⭐⭐⭐⭐⭐ — **`lido-oracle` 是真后端 Python 仓库**（信标链数据 push 到合约），跟你后端日常完全对口 |
| **为什么不选 RocketPool** | RP 业务模型相似但 TVL/JD 提及 1/10；Lido 的 oracle 设计是行业范本 |
| **为什么不选 EigenLayer / restaking** | restaking 是 Lido 后续叙事，**先懂 LST 的 rebase / share 模型，再去碰 LRT 才有意义**；EigenLayer 放 W8 |

### B. 本周后端关注点 vs 不关注点

| ✅ **本周必学的后端模块** | ❌ **跳过的（合约 / 数学 / 前端）** |
|---|---|
| **stETH share / balance 模型**（rebase 后所有持有人余额自动变化，钱包后端必须处理）| Lido DAO 治理细节 |
| **链下 oracle pipeline**（lido-oracle Python：抓信标链 → 聚合 → submit 到合约）| stVaults / Triggerable Exit 等新功能（生态尚未稳定）|
| **大规模持有者推送**（百万地址 rebase 余额变更通知）| BLS 签名 / 验证人退出协议 |
| **Operator performance 时序聚合**（每个 NO 的 effectiveness / penalty）| Cube-Curve withdrawal queue 数学 |

→ **一句话**：本周两个 Go PoC 形态：
> **#1**「订阅 `TokenRebased` event → 全量持有者重算 balance → 余额差异 > 阈值则推送」
> **#2**「定时拉信标链 API → 聚合每个 NO 的 attestations / proposals → 入 Postgres → 暴露 metrics API」

### C. 仓库分级（已 clone — 子 agent 重点啃这里）

| 仓库路径 | 等级 | 必看模块 | 后端价值 |
|---|---|---|---|
| `repos/stablecoin/lido-dao/contracts/0.4.24/Lido.sol` | 🔴 **必看** | `submit / _submit / _getTotalShares` + Submit/SharesBurnt events | rebase / share 模型的合约级真相 |
| `repos/stablecoin/lido-dao/contracts/0.8.9/oracle/AccountingOracle.sol` | 🔴 **必看** | `submitReportData` + ReportSubmitted event | oracle 链上接收口 |
| **`repos/stablecoin/lido-oracle/`** | 🔴🔴 **必看，王炸** | `src/services/accounting/` + `src/providers/consensus/` | **后端 Python 真实生产代码** — 信标链数据怎么聚合 → 怎么 push 到链上 |
| `repos/stablecoin/lido-subgraph/` | 🔴 **必看** | `src/lido.ts` mapping | 后端 indexer 思维直接对照 |

### D. 仓库分级（参考价值高，未 clone — 子 agent 按需补）

| 仓库 | 等级 | 用途 | 何时补 |
|---|---|---|---|
| [lidofinance/lido-ethereum-sdk](https://github.com/lidofinance/lido-ethereum-sdk) | 🟡 参考 | TS SDK 看官方怎么 wrap stETH 的 share 换算 | PoC #1 时对照 |
| [rated-labs/public-api-docs](https://docs.rated.network/) | 🟡 参考 | Operator performance 行业范本 API 设计 | PoC #2 时对照 |
| [ChainSafe/lodestar 信标链 API](https://github.com/ChainSafe/lodestar) | 🟢 选看 | 信标链 API 怎么调 | 不必看 |

### E. 2 道系统设计题的「考点」（面试官真问什么）

#### 题 #1 — stETH rebase 推送系统

| 维度 | 内容 |
|---|---|
| **后端面试官真问** | "100 万 stETH 持有者，每次 rebase 都要重算余额，怎么扛？" / "怎么避免给所有人都发推送（noise 太大）？" / "rebase 后 DEX 池子价格变化，怎么联动告警？" |
| **核心模块**（4 个）| 1) **Listener**（订阅 `TokenRebased`）2) **Holder Snapshot**（链下镜像所有 stETH 持有者 shares）3) **Diff Calc**（rebase 后增量 / 衰减计算）4) **Push Filter**（按变化幅度 / 用户偏好分级推送）|
| **PoC 难点** | **100 万级用户的批量 share → balance 换算性能**（multicall + 并行 worker）+ **推送去重**（合并 24h 内多次 rebase）|
| **抄哪段代码起步** | `Lido.sol::getPooledEthByShares` + `lido-subgraph` 的 holder 聚合模式 |

#### 题 #2 — Operator performance 数据 pipeline

| 维度 | 内容 |
|---|---|
| **后端面试官真问** | "信标链 API 限流，怎么抓 30 万验证人？" / "怎么定义 NO 的 performance score？" / "数据 reorg / missed slot 怎么处理？" / "MEV-Boost relay 数据怎么整合？" |
| **核心模块**（5 个）| 1) **Beacon API Crawler**（按 slot 拉 attestations / proposals）2) **Validator Aggregator**（多 worker + Redis 去重）3) **NO Mapper**（validator pubkey → Lido NO id）4) **Time-series DB**（按 day/epoch 聚合）5) **Metrics API**（per-NO + 全局指标）|
| **PoC 难点** | **信标链 API 限流 + 数据量**（30 万 validator × 7200 slot/day）→ 分片 / 缓存 / 增量必学 |
| **抄哪段代码起步** | `lido-oracle/src/providers/consensus/client.py` 看怎么调信标链 API + rated.network 公开 API 设计 |

### F. 给子 agent 的执行边界

- ✅ **可以自由决策**：读 lido-oracle Python 的哪几个模块、PoC 用什么 Go beacon client（geth/teku/lighthouse SDK）
- ❌ **不要做**：① 试图用 Go 复现 BLS 聚合签名 ② 跑去研究 wstETH / unstETH 在 DEX 池子的数学
- ⚠️ **遇到分歧问总控**：如果发现"信标链 API 在 PoC 环境跑不通" → 报告总控用 mock 数据降级

---

## D1（4h）— 业务速读

### 必读清单（**只读业务，不读源码**）

  - [ ] `contracts/0.4.24/Lido.sol` — 只看 submit/claimRewards/withdraw 接口 + Submit/SharesBurnt events
  - [ ] `contracts/0.8.9/oracle/AccountingOracle.sol` — 只看 submitReportData 接口
  - [ ] Lido docs：stETH Mechanism / Withdrawals 业务章节
  - [ ] `lido-oracle/` Python 仓库 README — **后端工程师真后端**，看怎么从信标链 push 到合约

### 关键 events（后端 indexer 的输入信号）

```
Submit（用户存 ETH），SharesBurnt（rebase 后），WithdrawalRequested，TokenRebased
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

### 系统设计题 #1：stETH rebase 推送系统

> **场景**：Coinbase Wallet / Trust Wallet
> **PoC 焦点**：监听 daily oracle update，给所有 stETH 持有者推送余额变化
>
> 请用 [`../../_template/system_design.md`](../../_template/system_design.md) 模板填写完整 7 段（场景/规模/架构/Schema/API/Tradeoff/监控）+ 100-200 行 PoC。

#### 我的方案（在此填写或链接到独立 markdown）

> 例：参见 [`./W4_sd1_solution.md`](./W4_sd1_solution.md)


#### PoC 仓库（**本周必做**）

PoC 放在 `repos/_demos/W4_1_xxx/`

- [ ] 项目脚手架建好（5-8 个 Go 文件）
- [ ] 主流程跑通（happy path）
- [ ] README 写好（讲清"做什么/怎么跑/学到什么"）
- [ ] 推到 GitHub（链接：____________________）

---
### 系统设计题 #2：Operator performance 数据 pipeline

> **场景**：Lido DAO 数据后端 / Rated.network
> **PoC 焦点**：抓信标链验证人 performance，聚合到每个 Operator 的奖励/罚没记录
>
> 请用 [`../../_template/system_design.md`](../../_template/system_design.md) 模板填写完整 7 段（场景/规模/架构/Schema/API/Tradeoff/监控）+ 100-200 行 PoC。

#### 我的方案（在此填写或链接到独立 markdown）

> 例：参见 [`./W4_sd2_solution.md`](./W4_sd2_solution.md)


#### PoC 仓库（**本周必做**）

PoC 放在 `repos/_demos/W4_2_xxx/`

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
