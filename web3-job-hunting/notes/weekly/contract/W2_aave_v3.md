# W2 — Aave V3（借贷+清算标杆）

> 配套 [`../../reports/learning_roadmap_v3_universal.md`](../../reports/learning_roadmap_v3_universal.md) W2 章节
> 仓库位置：`repos/lending/aave-v3-core/`

---

## 📅 本周进度（每天打勾）

- [ ] D1
- [ ] D2
- [ ] D3
- [ ] D4
- [ ] 周末内化（业务卡 + 5 题 + 镜子讲）

---

## 📖 必读文件清单

  - [ ] `contracts/protocol/pool/Pool.sol` — supply/borrow/repay/withdraw/liquidationCall
  - [ ] `contracts/protocol/tokenization/AToken.sol` — rebase token 实现（面试高频）
  - [ ] `contracts/protocol/tokenization/VariableDebtToken.sol` — 借款凭证浮动利率
  - [ ] `contracts/protocol/libraries/logic/LiquidationLogic.sol` — 清算引擎
  - [ ] `contracts/protocol/libraries/logic/ReserveLogic.sol` — Jump Rate 利率模型

---

## 🎯 业务故事卡（300 字，1 段话讲清协议）

> 模板见 [`../_template/business_card.md`](../_template/business_card.md)

**一句话**（30 字内）：

**100 字业务背景**：

**100 字核心机制**：

**70 字创新点**：

---

## ❓ 5 题答案（每题 ≥ 200 字 + tradeoff 论述）

### Q1. Isolation mode 是什么？为什么 GHO 这种新资产要开 isolation？

### Q2. E-mode 怎么把稳定币之间的 LTV 提高到 95%+？

### Q3. aToken 是 rebase token，那它转账时余额是怎么处理的？为什么没有 Transfer event？

### Q4. 清算时 liquidationCall 谁都能调用，激励怎么设计的？bonus 5-10% 是固定的吗？

### Q5. Jump Rate 利率模型：当 utilization 超过 optimal（80%）时，斜率为什么突然变陡？

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
