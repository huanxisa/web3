# W3 — MakerDAO 后端篇

> **稳定币业务 + CDP 风险仪表盘 + 稳定费分发**
> 配套 [`../../../reports/learning_roadmap_v4_backend_first.md`](../../../reports/learning_roadmap_v4_backend_first.md) 第 W3 章节
> 仓库位置：`repos/stablecoin/makerdao-dss/`
> 官方文档：<https://docs.makerdao.com/>

---

## 📐 方向总览（总控视角 — 子 agent 必读，你执行前也看一眼）

> 这一段不指挥你"读第几行"，告诉你**这周往哪打 / 不打哪 / 用什么弹药**。

### A. 项目抉择 — 为什么这周是 MakerDAO

| 维度 | 内容 |
|---|---|
| **业务定位** | DAI 是最老牌的去中心化稳定币，**CDP 抵押模型 + Dutch Auction 清算 + 全球结算**是稳定币业务的鼻祖范式 |
| **JD 数据支撑** | 稳定币方向 30 天 **5** 个命中（Ethena / Sky / Curve 团队都问"你懂 Maker 吗"）|
| **背景匹配度** | ⭐⭐⭐⭐ — CDP 仪表盘 / 拍卖竞价机器人都是后端老本行；Maker 文档质量高，业务讲解清晰 |
| **为什么不选 Ethena USDe** | Ethena 业务窄（delta neutral hedge），**面试官期望你先懂经典 CDP 模型**再聊 Ethena；Ethena 可放 W8 差异化 |
| **为什么不选 Curve crvUSD** | LLAMMA 清算算法新颖但生态小、JD 提及少；Maker 才是**稳定币业务的母题** |

### B. 本周后端关注点 vs 不关注点

| ✅ **本周必学的后端模块** | ❌ **跳过的（合约 / 数学 / 前端）** |
|---|---|
| **CDP（Vault）状态聚合**（vat.urns 链下镜像 + 抵押率计算）| `vat.sol` 的 Rad/Wad/Ray 定点数细节 |
| **Dutch Auction 监控 + 出价机器人**（Clip Kick → Take）| Spot/Pip 预言机的合约升级流程 |
| **稳定费 / 收益分发**（Jug accrual + Pot DSR rate）| GSM (Governance Security Module) 治理升级 |
| **风险仪表盘 时序聚合**（系统级 collateralization ratio / debt ceiling 利用率）| MIP 治理提案流程 |

→ **一句话**：本周两个 Go PoC 形态：
> **#1**「订阅 `Frob/Bark/Take` event → 维护 vault 状态 → 抵押率 + 系统总览看板」
> **#2**「订阅 `Kick` event 起的拍卖 → 链下定价模型计算可竞价区间 → take 上链」

### C. 仓库分级（已 clone — 子 agent 重点啃这里）

| 仓库路径 | 等级 | 必看模块 | 后端价值 |
|---|---|---|---|
| `repos/stablecoin/makerdao-dss/src/vat.sol` | 🔴 **必看** | `frob / grab` 函数 + 全 events + urns/ilks 数据结构 | 你 vault 状态镜像表的 schema 来源 |
| `repos/stablecoin/makerdao-dss/src/clip.sol` | 🔴 **必看** | `kick / take / redo` + Kick/Take events | 拍卖机器人的输入信号 |
| `repos/stablecoin/makerdao-dss/src/jug.sol` `pot.sol` | 🟡 参考 | 稳定费 / DSR 累积 | 收益分发计算公式 |
| `repos/stablecoin/makerdao-cdp-manager/` | 🔴 **必看** | CDP NFT id ↔ urn 映射 | 把"用户地址"转成"vault id"的索引层 |
| `repos/stablecoin/makerdao-auction-keeper/` | 🔴🔴 **必看，王炸** | Python 范例：怎么监控拍卖 + 链下定价 + take | **PoC #2 的官方范式直接对照翻译成 Go** |

### D. 仓库分级（参考价值高，未 clone — 子 agent 按需补）

| 仓库 | 等级 | 用途 | 何时补 |
|---|---|---|---|
| [makerdao/spells-mainnet](https://github.com/makerdao/spells-mainnet) | 🟢 选看 | 治理 spells | 不补 |
| [DeFiLlama-Adapters/maker](https://github.com/DefiLlama/DefiLlama-Adapters) | 🟡 参考 | TVL 计算 | 做仪表盘聚合参考 |
| [B.Protocol Maker keeper](https://github.com/backstop-protocol) | 🟡 参考 | 二级清算保护 | 不必看 |

### E. 2 道系统设计题的「考点」（面试官真问什么）

#### 题 #1 — CDP 风险监控仪表盘

| 维度 | 内容 |
|---|---|
| **后端面试官真问** | "几十万 vault 怎么实时算抵押率？" / "ETH 价格暴跌时怎么避免雪崩式查询？" / "系统级 debt ceiling 怎么近实时？" |
| **核心模块**（4 个）| 1) **Listener**（Frob/Grab event）2) **State Sync**（vat.urns 链下镜像，multicall 批拉）3) **Risk Calc**（按 ilk 算抵押率 + 距清算线百分比）4) **Dashboard API**（系统 + 用户两个视角的查询接口）|
| **PoC 难点** | **价格 push 时全量重算的性能**（用增量 + heap 维护按风险排序的 top-N）|
| **抄哪段代码起步** | `repos/stablecoin/makerdao-cdp-manager/src/DssCdpManager.sol` + Maker 官方 `dashboard.makerdao.com` 公开 metrics |

#### 题 #2 — Dutch Auction 出价机器人

| 维度 | 内容 |
|---|---|
| **后端面试官真问** | "拍卖价格曲线怎么算？" / "什么时候 take 是最优？" / "和别的 keeper 抢怎么办？" / "失败时 inventory 怎么处理？" |
| **核心模块**（4 个）| 1) **Kick Listener**（新拍卖入队）2) **Price Curve**（按 Abacus stairstep / linear 计算当前 lot 价）3) **Profit Filter**（vs DEX 市价 + gas）4) **Submitter**（take 上链，含 nonce 管理 + Flashbots 私池可选）|
| **PoC 难点** | **链下价格曲线复现**（Abacus.sol 的递减算法）+ **多 keeper 竞争策略** |
| **抄哪段代码起步** | `repos/stablecoin/makerdao-auction-keeper/` 的 Python 版本逐步翻译成 Go |

### F. 给子 agent 的执行边界

- ✅ **可以自由决策**：读哪几行、PoC 仓库命名、Go 库选择
- ❌ **不要做**：① 跑去研究 Maker 治理 / MKR token / DAI Savings Rate 数学 ② 把整个 dss 全集翻一遍
- ⚠️ **遇到分歧问总控**：如果发现 `auction-keeper` Python 复现成本太高 → 报告总控简化 PoC 范围

---

## D1（4h）— 业务速读

### 必读清单（**只读业务，不读源码**）

  - [ ] `src/vat.sol` — 只看 ilk/urn 数据结构 + 主要 events
  - [ ] `src/clip.sol` — Dutch Auction 入口与 Take event
  - [ ] Maker docs：The Dai Stablecoin System 章节（业务白皮书）
  - [ ] Maker docs：Liquidations 2.0 章节

### 关键 events（后端 indexer 的输入信号）

```
Frob, Grab, Heal, NewVault, Bark, Take（拍卖成交），Kick（拍卖启动）
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

### 系统设计题 #1：CDP 风险预警仪表盘

> **场景**：DeFi Saver / Maker 官方面板
> **PoC 焦点**：实时聚合所有 Vault 的 c-ratio，分级告警 + 钱包推送
>
> 请用 [`../../_template/system_design.md`](../../_template/system_design.md) 模板填写完整 7 段（场景/规模/架构/Schema/API/Tradeoff/监控）+ 100-200 行 PoC。

#### 我的方案（在此填写或链接到独立 markdown）

> 例：参见 [`./W3_sd1_solution.md`](./W3_sd1_solution.md)


#### PoC 仓库（**本周必做**）

PoC 放在 `repos/_demos/W3_1_xxx/`

- [ ] 项目脚手架建好（5-8 个 Go 文件）
- [ ] 主流程跑通（happy path）
- [ ] README 写好（讲清"做什么/怎么跑/学到什么"）
- [ ] 推到 GitHub（链接：____________________）

---
### 系统设计题 #2：稳定费收取与分发后端

> **场景**：Maker DAO Treasury
> **PoC 焦点**：监听 jug.drip，聚合到协议金库，触发 DSR 分发
>
> 请用 [`../../_template/system_design.md`](../../_template/system_design.md) 模板填写完整 7 段（场景/规模/架构/Schema/API/Tradeoff/监控）+ 100-200 行 PoC。

#### 我的方案（在此填写或链接到独立 markdown）

> 例：参见 [`./W3_sd2_solution.md`](./W3_sd2_solution.md)


#### PoC 仓库（**本周必做**）

PoC 放在 `repos/_demos/W3_2_xxx/`

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
