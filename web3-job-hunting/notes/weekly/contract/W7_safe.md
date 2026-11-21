# W7 — Safe（多签托管 + Module + Python 真后端）

> 配套 [`../../reports/learning_roadmap_v3_universal.md`](../../reports/learning_roadmap_v3_universal.md) W7 章节
> 仓库位置：`repos/innovation/safe-smart-account/ + safe-transaction-service/`

---

## 📅 本周进度（每天打勾）

- [ ] D1
- [ ] D2
- [ ] D3
- [ ] D4
- [ ] 周末内化（业务卡 + 5 题 + 镜子讲）

---

## 📖 必读文件清单

  - [ ] `contracts/Safe.sol` — execTransaction 入口
  - [ ] `contracts/base/OwnerManager.sol` — M-of-N owner 管理
  - [ ] `contracts/base/ModuleManager.sol` — Module 扩展机制
  - [ ] `contracts/base/GuardManager.sol` — 交易守卫
  - [ ] `safe-transaction-service/` Python 后端 — 交易聚合、签名收集

---

## 🎯 业务故事卡（300 字，1 段话讲清协议）

> 模板见 [`../_template/business_card.md`](../_template/business_card.md)

**一句话**（30 字内）：

**100 字业务背景**：

**100 字核心机制**：

**70 字创新点**：

---

## ❓ 5 题答案（每题 ≥ 200 字 + tradeoff 论述）

### Q1. Safe 的 execTransaction 怎么验证 M-of-N 签名？签名按什么顺序排？

### Q2. EIP-1271 是什么？Safe 怎么实现合约钱包给 DApp 签名？

### Q3. Module 机制有什么用？举一个真实 Module 例子（如 Allowance Module、Recovery Module）。

### Q4. Safe 的 transaction service 后端为什么需要存所有签名？为什么不上链？

### Q5. CEX 用 Safe 做冷钱包托管时，会加哪些 Module 来增强安全？

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
