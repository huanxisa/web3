# W3 — MakerDAO DSS（稳定币 CDP 始祖）

> 配套 [`../../reports/learning_roadmap_v3_universal.md`](../../reports/learning_roadmap_v3_universal.md) W3 章节
> 仓库位置：`repos/stablecoin/makerdao-dss/`

---

## 📅 本周进度（每天打勾）

- [ ] D1
- [ ] D2
- [ ] D3
- [ ] D4
- [ ] 周末内化（业务卡 + 5 题 + 镜子讲）

---

## 📖 必读文件清单

  - [ ] `src/vat.sol` — 核心账本，双重记账（gem/dai/ilk/urn）
  - [ ] `src/jug.sol` — 稳定费累积引擎
  - [ ] `src/spot.sol` — 价格预言机适配器
  - [ ] `src/dog.sol` — 清算触发器
  - [ ] `src/clip.sol` — Dutch Auction 清算拍卖

---

## 🎯 业务故事卡（300 字，1 段话讲清协议）

> 模板见 [`../_template/business_card.md`](../_template/business_card.md)

**一句话**（30 字内）：

**100 字业务背景**：

**100 字核心机制**：

**70 字创新点**：

---

## ❓ 5 题答案（每题 ≥ 200 字 + tradeoff 论述）

### Q1. CDP 的 c-ratio (150%) 是怎么决定的？为什么不是 110% 或 200%？

### Q2. DAI 的稳定费是怎么累积的？为什么用 chi 累积器而不是按每秒计息？

### Q3. Dutch Auction 清算（V2 后的 LIQ 2.0）相比 English Auction 优势在哪？

### Q4. DSR（DAI 存款利率）的资金来源是什么？协议怎么保证 DSR 收益？

### Q5. PSM（Peg Stability Module）是什么？为什么 USDC 大量进入 Maker 后大家都在批评？

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
