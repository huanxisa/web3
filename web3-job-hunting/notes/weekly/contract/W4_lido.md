# W4 — Lido（LST 龙头 + 真 Python 后端）

> 配套 [`../../reports/learning_roadmap_v3_universal.md`](../../reports/learning_roadmap_v3_universal.md) W4 章节
> 仓库位置：`repos/stablecoin/lido-dao/ + lido-oracle/`

---

## 📅 本周进度（每天打勾）

- [ ] D1
- [ ] D2
- [ ] D3
- [ ] D4
- [ ] 周末内化（业务卡 + 5 题 + 镜子讲）

---

## 📖 必读文件清单

  - [ ] `contracts/0.4.24/Lido.sol` — 核心：质押 + stETH 铸造
  - [ ] `contracts/0.4.24/StETH.sol` — rebase token 实现
  - [ ] `contracts/0.6.12/WstETH.sol` — wstETH 包装版
  - [ ] `contracts/0.8.9/WithdrawalQueueERC721.sol` — 退出队列 NFT 化
  - [ ] `lido-oracle/` Python 仓库 — 信标链 → 链上 push（**真后端**）

---

## 🎯 业务故事卡（300 字，1 段话讲清协议）

> 模板见 [`../_template/business_card.md`](../_template/business_card.md)

**一句话**（30 字内）：

**100 字业务背景**：

**100 字核心机制**：

**70 字创新点**：

---

## ❓ 5 题答案（每题 ≥ 200 字 + tradeoff 论述）

### Q1. stETH 是 rebase token，那为什么 1inch / Uniswap 上是 wstETH？两者怎么转换？

### Q2. 一笔 ETH 存进 Lido 后，怎么从用户钱包到验证人？中间有几跳？

### Q3. AccountingOracle 怎么从信标链拉数据？为什么是 daily 不是 realtime？

### Q4. Withdrawal Queue 排队是 FIFO 还是按金额？长尾用户怎么办？

### Q5. Lido 占 ETH 质押 30%+ 的中心化风险，社区怎么应对（CSM / DVT）？

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
