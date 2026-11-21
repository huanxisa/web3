# W5 — dYdX V4 后端篇

> **链上撮合业务 + ERC20 indexer + WS push 服务（**纯后端**）**
> 配套 [`../../../reports/learning_roadmap_v4_backend_first.md`](../../../reports/learning_roadmap_v4_backend_first.md) 第 W5 章节
> 仓库位置：`repos/trading-engine/dydx-v4-chain/`
> 官方文档：<https://docs.dydx.exchange/>

---

## 📐 方向总览（总控视角 — 子 agent 必读，你执行前也看一眼）

> 这一段不指挥你"读第几行"，告诉你**这周往哪打 / 不打哪 / 用什么弹药**。
> **本周是 CEX 后端 + 撮合 + Indexer 三个面试高频方向的合一招**。

### A. 项目抉择 — 为什么这周是 dYdX V4

| 维度 | 内容 |
|---|---|
| **业务定位** | 当前**唯一成功的链上订单簿衍生品 DEX**（Cosmos SDK + 自定义撮合 module + 全 Go indexer），日成交 10 亿+ |
| **JD 数据支撑** | **撮合引擎 17 命中 + Indexer 4 命中 + Perp 12 命中 = 33 命中**（CEX Java/Go 后端 + DeFi 链上数据所有公司必问）|
| **背景匹配度** | ⭐⭐⭐⭐⭐ — **全 Go 后端，跟你语言原生对口**；indexer + WS push 是经典后端架构 |
| **为什么不选 Binance 撮合（闭源）** | 没法读，靠纸面学习；dYdX V4 是**唯一开源 + 工业级 + Go**的撮合 + indexer 参考 |
| **为什么不选 Hyperliquid** | 闭源 Rust，且业务模型与 V3 重叠；dYdX V4 是更通用的"链上 CEX"范式 |

### B. 本周后端关注点 vs 不关注点

| ✅ **本周必学的后端模块** | ❌ **跳过的（合约 / 数学 / 前端）** |
|---|---|
| **链上 LOB（Limit Order Book）数据结构 + Match 流程**（理解 PlaceOrder/CancelOrder/Match 业务）| Cosmos SDK ABCI 共识 / Tendermint 投票细节 |
| **Indexer 多服务架构**（ender / socks / comlink / roundtable 各服务分工）| 永续合约的 funding rate 数学推导 |
| **链上 event → Postgres → REST/WS** 全 Go pipeline | `protocol/x/perpetuals/` 内部余额结算 |
| **WS 推送架构**（per-room broadcast / 限流 / 重连）| dYdX 自己的 stake / governance 治理 |
| **大规模时序数据**（K 线 / orderbook snapshot / trades 聚合）| 永续清算的 isolated margin 复杂逻辑 |

→ **一句话**：本周两个 Go PoC 形态：
> **#1**「监听某 ERC20 合约 `Transfer` event → Postgres → 提供 REST 查询 + reorg 处理」（**通用 indexer**，迁移到任意链任意合约）
> **#2**「订阅 indexer 的事件流 → 转 K 线 / orderbook 增量 → WS push 给客户端」

### C. 仓库分级（已 clone — 子 agent 重点啃这里）

| 仓库路径 | 等级 | 必看模块 | 后端价值 |
|---|---|---|---|
| **`repos/trading-engine/dydx-v4-chain/indexer/services/ender/`** | 🔴🔴 **必看，王炸** | `src/handlers/order-handler.ts` + `fill-handler.ts` | **工业级链上 indexer 范本，你 PoC #1 的方法论模板** |
| `repos/trading-engine/dydx-v4-chain/indexer/services/socks/` | 🔴 **必看** | WS 服务架构 + room / channel 设计 | PoC #2 WS push 的工业范本 |
| `repos/trading-engine/dydx-v4-chain/indexer/services/comlink/` | 🔴 **必看** | REST API 入口 + 多 worker 服务分工 | 后端服务拆分思路 |
| `repos/trading-engine/dydx-v4-chain/protocol/x/clob/keeper/orders.go` | 🟡 参考 | PlaceOrder / Match Go 实现 | 业务侧理解链上撮合，不抄 |
| `repos/trading-engine/dydx-v4-chain/protocol/x/clob/keeper/liquidations.go` | 🟡 参考 | 链上清算流 | 业务侧理解 |
| `repos/trading-engine/lmax-disruptor/` | 🟢 选看 | LMAX 经典 ring buffer 论文/代码 | CEX 内存撮合的经典范式，**面试问到再翻**|

### D. 仓库分级（参考价值高，未 clone — 子 agent 按需补）

| 仓库 | 等级 | 用途 | 何时补 |
|---|---|---|---|
| [the-graph/graph-node](https://github.com/graphprotocol/graph-node) | 🟡 参考 | 通用 indexer 引擎，Rust 写的 | PoC #1 时对照思路（不抄代码）|
| [shadowstack/erc20-indexer 类似 Go demo](https://github.com/joeycouse/eth-indexer) | 🟡 参考 | 小型 Go indexer 范例 | PoC #1 起手参考 |
| [Hubble exchange / Apex protocol indexer](https://github.com/Hubble-Exchange/hubble-protocol) | 🟢 选看 | 同类范本 | 不必看 |

### E. 2 道系统设计题的「考点」（面试官真问什么）

#### 题 #1 — ERC20 链上 indexer（**核心 Demo #2，推 GitHub 公开**）

| 维度 | 内容 |
|---|---|
| **后端面试官真问** | "如何处理 reorg？" / "如何保证 exactly-once 写入？" / "上千个合约怎么扩展？" / "节点 RPC 限流怎么应对？" / "如何回放历史？" |
| **核心模块**（6 个）| 1) **Block Scanner**（按 block 顺序拉 log）2) **Decoder**（ABI 解析）3) **Reorg Buffer**（12 块 deferred commit）4) **Writer**（PG 批量 upsert）5) **REST API**（按 holder/transfer 查询）6) **Health/Metrics**（落后块数 / 速率）|
| **PoC 难点** | **reorg 处理**（最高频面试题）+ **批量 RPC 调用打包**（eth_getLogs 一次拉 N 块）+ **写入幂等** |
| **抄哪段代码起步** | `repos/trading-engine/dydx-v4-chain/indexer/services/ender/src/handlers/` 的事件处理范式 |
| **特别提醒** | ⭐ 这是核心 Demo，**README 要写漂亮，能跑通真实合约（USDC / USDT 任选一个）**|

#### 题 #2 — WebSocket 推送服务（K 线 / 持仓）

| 维度 | 内容 |
|---|---|
| **后端面试官真问** | "10 万订阅怎么撑？" / "客户端断线 + 增量恢复怎么做？" / "K 线 1m/5m/1h 多级聚合怎么不爆 CPU？" / "广播 vs 点对点 推送选哪个？" |
| **核心模块**（5 个）| 1) **Event Source**（来自 PoC #1 的 indexer 输出）2) **Room Manager**（per-symbol / per-user channel）3) **Aggregator**（trades → K 线滚动窗口）4) **WS Server**（gorilla/websocket + 心跳 + 限流）5) **Replay/Snapshot**（断线后给客户端补差量）|
| **PoC 难点** | **K 线滚动聚合的内存控制**（不能每根 K 线都全量回算）+ **per-connection 限流** |
| **抄哪段代码起步** | `repos/trading-engine/dydx-v4-chain/indexer/services/socks/` 的 WS 架构（TS）→ 翻译成 Go |

### F. 给子 agent 的执行边界

- ✅ **可以自由决策**：PoC 用 `go-ethereum` 还是 `nethermind` SDK、PG schema 设计、WS lib 选择
- ❌ **不要做**：① 跑去 fork dYdX V4 自己跑 Cosmos chain ② 试图复现完整撮合 module（不是后端核心）③ 抄 disruptor 的全套 Java 代码
- ⚠️ **遇到分歧问总控**：如果发现"想做撮合内核 demo 而不是 indexer" → 报告总控，可调整为 W5+ 加餐周

---

## D1（4h）— 业务速读

### 必读清单（**只读业务，不读源码**）

  - [ ] dYdX V4 docs：Architecture 章节（网络分层）
  - [ ] `indexer/services/ender/README.md` — Indexer 主服务设计
  - [ ] `indexer/services/socks/README.md` — WebSocket push 服务设计
  - [ ] `indexer/services/comlink/README.md` — REST API 服务设计
  - [ ] （**这周读真后端代码**）`indexer/services/ender/src/handlers/order-handler.ts`

### 关键 events（后端 indexer 的输入信号）

```
OrderPlaced, OrderFilled, OrderCanceled, FundingPayment, Liquidation, PositionUpdated
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

### 系统设计题 #1：ERC20 链上 indexer（**核心 Demo #2**）

> **场景**：Etherscan / Alchemy / dYdX indexer
> **PoC 焦点**：监听 Transfer event → Postgres，提供 REST 查询，处理 reorg
>
> 请用 [`../../_template/system_design.md`](../../_template/system_design.md) 模板填写完整 7 段（场景/规模/架构/Schema/API/Tradeoff/监控）+ 100-200 行 PoC。

#### 我的方案（在此填写或链接到独立 markdown）

> 例：参见 [`./W5_sd1_solution.md`](./W5_sd1_solution.md)


#### PoC 仓库（**本周必做**）

⭐ **本题是核心 Demo erc20-indexer**，推到 GitHub 公开

- [ ] 项目脚手架建好（5-8 个 Go 文件）
- [ ] 主流程跑通（happy path）
- [ ] README 写好（讲清"做什么/怎么跑/学到什么"）
- [ ] 推到 GitHub（链接：____________________）

---
### 系统设计题 #2：持仓 + K 线 WebSocket push 服务

> **场景**：dYdX socks / Binance WS API
> **PoC 焦点**：客户端订阅 → 实时推送链上事件转化的 K 线 / 持仓变化
>
> 请用 [`../../_template/system_design.md`](../../_template/system_design.md) 模板填写完整 7 段（场景/规模/架构/Schema/API/Tradeoff/监控）+ 100-200 行 PoC。

#### 我的方案（在此填写或链接到独立 markdown）

> 例：参见 [`./W5_sd2_solution.md`](./W5_sd2_solution.md)


#### PoC 仓库（**本周必做**）

PoC 放在 `repos/_demos/W5_2_xxx/`

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
