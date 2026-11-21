# W5 — dYdX V4（Go 撮合 + Indexer 一鱼三吃）

> 配套 [`../../reports/learning_roadmap_v3_universal.md`](../../reports/learning_roadmap_v3_universal.md) W5 章节
> 仓库位置：`repos/trading-engine/dydx-v4-chain/`

---

## 📅 本周进度（每天打勾）

- [ ] D1
- [ ] D2
- [ ] D3
- [ ] D4
- [ ] 周末内化（业务卡 + 5 题 + 镜子讲）

---

## 📖 必读文件清单

  - [ ] `protocol/x/clob/keeper/clob_pair.go` — 撮合主模块（PlaceOrder/Match）
  - [ ] `protocol/x/clob/keeper/deleveraging.go` — 清算 + ADL 流程
  - [ ] `protocol/x/perpetuals/keeper/perpetuals.go` — 永续市场状态（funding/OI）
  - [ ] `indexer/services/ender/` — 链上 event → Postgres 全 Go
  - [ ] `indexer/services/socks/` + `comlink/` — WebSocket push + REST API

---

## 🎯 业务故事卡（300 字，1 段话讲清协议）

> 模板见 [`../_template/business_card.md`](../_template/business_card.md)

**一句话**（30 字内）：

**100 字业务背景**：

**100 字核心机制**：

**70 字创新点**：

---

## ❓ 5 题答案（每题 ≥ 200 字 + tradeoff 论述）

### Q1. 链上 OrderBook 与 CEX 内存撮合的延迟差距怎么解决？dYdX V4 用 Tendermint 1.5s 出块，怎么做到接近 CEX 体验？

### Q2. dYdX V4 的撮合是放在共识层还是应用层？为什么放在 ABCI app 里？

### Q3. 永续合约的 funding fee 在链上怎么计算和结算的？

### Q4. Indexer 服务（Go）怎么把链上 event 聚合成订单状态、用户持仓、K 线？数据库选型？

### Q5. 与 GMX V2（vAMM 模式）相比，订单簿模式优劣？

---

## ✅ Demo 检查（**本周必做**）

> 模板见 [`../_template/demo_readme.md`](../_template/demo_readme.md)
> 完成后存入 [`../demos/`](../demos/) 目录

- [ ] 项目脚手架建好（5 个 Go 文件以内）
- [ ] 主流程跑通（一条 happy path 能 work）
- [ ] README 写好（讲清"做什么 + 怎么跑 + 学到什么"）
- [ ] 推到 GitHub（公开仓库链接：____________________）


## 🪞 镜子讲述（3 分钟，不看资料）

- [ ] 我能不看屏幕讲完业务故事卡 4 段
- [ ] 我能讲清 5 题答案的核心论点
- [ ] 我能跟非技术朋友讲，他能听懂

→ 全 √ → 进下周。任一不通过 → 回去补，**不许进入下一周**。

---

## 📝 简历更新（**本周必做**）

在简历"项目经验"段末尾追加 1 行：

> 例（W1 完成后）：*"系统读过 Uniswap V3 核心 4 文件（Pool/TickMath/SqrtPriceMath/SwapMath），能从 Q96 定点数推导到 swap 跨 tick 的完整流程"*

我加的内容：

> ___________________________________________________________

---

## 🔗 输出物

- [ ] 业务故事卡：本文档已填
- [ ] 5 题答案：本文档已填 / 已贴 [博客链接]
- [ ] Demo（仅 W2/W5/W6）：[GitHub 链接]
- [ ] Anki 卡片（可选）：本周新增 ___ 张
