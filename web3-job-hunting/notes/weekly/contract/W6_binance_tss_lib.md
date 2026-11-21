# W6 — Binance tss-lib（MPC/TSS 钱包后端）

> 配套 [`../../reports/learning_roadmap_v3_universal.md`](../../reports/learning_roadmap_v3_universal.md) W6 章节
> 仓库位置：`repos/mpc-wallet/binance-tss-lib/`

---

## 📅 本周进度（每天打勾）

- [ ] D1
- [ ] D2
- [ ] D3
- [ ] D4
- [ ] 周末内化（业务卡 + 5 题 + 镜子讲）

---

## 📖 必读文件清单

  - [ ] `ecdsa/keygen/` — DKG 分布式密钥生成（5 round）
  - [ ] `ecdsa/signing/` — 门限签名（M-of-N 协作）
  - [ ] `ecdsa/resharing/` — 密钥重分片
  - [ ] `crypto/paillier/` — Paillier 同态加密
  - [ ] `tss/messages.go` — 多方消息路由

---

## 🎯 业务故事卡（300 字，1 段话讲清协议）

> 模板见 [`../_template/business_card.md`](../_template/business_card.md)

**一句话**（30 字内）：

**100 字业务背景**：

**100 字核心机制**：

**70 字创新点**：

---

## ❓ 5 题答案（每题 ≥ 200 字 + tradeoff 论述）

### Q1. MPC vs 链上多签：MPC 把门限放链下、Safe 把门限放链上，业务上各有什么 tradeoff？

### Q2. GG18 vs GG20：GG20 修了 GG18 的什么安全漏洞？（GG18 的 attack on Round 6）

### Q3. DKG 协议中，怎么确保某方不会装作收到实则没收到分片？

### Q4. 怎么设计一个 MPC 钱包的运维体系？分片存哪？私钥分片备份怎么做？

### Q5. Fireblocks 的 MPC 黑盒做了什么 Binance tss-lib 没做的？

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
