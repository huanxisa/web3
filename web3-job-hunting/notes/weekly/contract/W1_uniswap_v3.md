# W1 — Uniswap V3（AMM 标杆）

> 配套 [`../../reports/learning_roadmap_v3_universal.md`](../../reports/learning_roadmap_v3_universal.md) W1 章节
> 仓库位置：`repos/dex/uniswap-v3-core/`

---

## 📅 本周进度（每天打勾）

- [ ] D1
- [ ] D2
- [ ] D3
- [ ] D4
- [ ] 周末内化（业务卡 + 5 题 + 镜子讲）

---

## 📖 必读文件清单

  - [ ] `contracts/UniswapV3Pool.sol` — mint/burn/swap/collect 4 个核心 fn
  - [ ] `contracts/libraries/TickMath.sol` — sqrtPriceX96 ↔ tick 对数转换
  - [ ] `contracts/libraries/SqrtPriceMath.sol` — 给 amountIn 算 sqrtPrice 变化
  - [ ] `contracts/libraries/SwapMath.sol` — 单步 swap 计算（一个 tick 内）
  - [ ] `contracts/libraries/Position.sol` — LP 持仓数据结构

---

## 🎯 业务故事卡（300 字，1 段话讲清协议）

> 模板见 [`../_template/business_card.md`](../_template/business_card.md)

**一句话**（30 字内）：

**100 字业务背景**：

**100 字核心机制**：

**70 字创新点**：

---

## ❓ 5 题答案（每题 ≥ 200 字 + tradeoff 论述）

### Q1. V3 比 V2 的资本效率高 1000x，是怎么算出来的？

### Q2. sqrtPriceX96 为什么用平方根而不是直接价格？为什么用 Q96 定点数？

### Q3. 一个 swap 跨多个 tick 时，gas 是怎么累积的？

### Q4. LP 提供流动性时如果 token0/token1 比例不对，会发生什么？

### Q5. V4 的 hooks 比 V3 多了什么能力？为什么要做 singleton 架构？

---


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
