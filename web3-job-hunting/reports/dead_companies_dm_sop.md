# 4 家死火公司 LinkedIn / Twitter DM 探查 SOP

> **背景**：Aave / Scroll / Bitget / Magic Eden 在 web3.career 上的所有岗位都已发布 880-1126 天（1-3 年前）。
>
> **目标**：用 30-60 分钟判断这 4 家是「真死」还是「只是没公开 ATS」，**避免投入数小时写自建 ATS 抓取器后才发现是空欢喜**。
>
> **核心方法**：找他们的工程经理 / HR / 创始人 DM 探虚实，按回复信号判断。

---

## 一、判断模型（看 4 个信号）

| 信号 | 解读 | 行动 |
|---|---|---|
| ✅ **24h 内回复「在招」** | 真在招，只是没用公开 ATS | **立即问内推渠道，写抓取器** |
| ⚠️ **24h 内回复「暂停 / 缩招」** | 短期不招（裁员潮 / 预算冻结）| **观察 1-2 月，标记关注** |
| ❌ **48h 后已读不回 / 未读** | 大概率不在招 / HR 邮箱已淹没 | **降级为「业务学习用」** |
| 🟡 **自动回复 / 转 careers 邮箱** | 流程化，但 careers 邮箱可能没人维护 | **试发简历到 careers 邮箱看是否有自动回执** |

**回复率基线**（Web3 行业经验）：
- 华人创始公司（Scroll / Bitget）→ 中文 DM 回复率 30-50%
- 美国 / 欧洲公司（Aave / Magic Eden）→ 英文 DM 回复率 5-15%
- 整体如果 4 家发了 DM，**期望 1-2 家回复**就够判断

---

## 二、4 家公司具体探查路径（含 LinkedIn 直链）

### 1. Aave Companies / Avara

**已知线索**：
- 官方招聘页：<https://aave.com/careers>（**仍显示 10 个岗位**！包括 Engineering）
- 这意味着 Aave **大概率还在招**，只是不再用 web3.career
- 公司主体：Avara（不是 Aave Labs，名字改了）

**LinkedIn / Twitter 直链**：

| 用途 | 直链 |
|---|---|
| 🔥 **优先：LinkedIn 招聘页**（最直接证据）| <https://www.linkedin.com/jobs/search/?keywords=Avara%20OR%20Aave> |
| 公司主页 | <https://www.linkedin.com/company/avara-xyz/> · <https://www.linkedin.com/company/aave/> |
| 公司全部员工 | <https://www.linkedin.com/company/avara-xyz/people/> |
| 搜 HR / Talent | <https://www.linkedin.com/search/results/people/?keywords=Avara%20Recruiter%20OR%20Talent%20OR%20HR> |
| 搜 工程经理 / Backend Lead | <https://www.linkedin.com/search/results/people/?keywords=Avara%20Engineering%20Manager%20OR%20Backend%20Lead> |
| Twitter [@StaniKulechov](https://twitter.com/StaniKulechov)（创始人，⭐⭐ 少回）| 看动态而非 DM |
| Twitter [@MarcZeller](https://twitter.com/lemiscate)（社区核心，⭐⭐⭐ 活跃）| 可 DM 问内推 |
| Telegram `aavesome` 中文群 / [@aavebr](https://t.me/aavebr) | 社区水群获取信息 |

**DM 模板（英文）**：
```
Hi [Name],

I'm an L1-2 Web3 backend engineer with 5+ years Java/Go experience.
Currently building a Go DeFi adapter for Aave V3 on Sepolia as a portfolio
project (supply/borrow/liquidation listener with go-ethereum).

I noticed Aave's job listings on aggregator sites (web3.career, etc.) are
all 1+ year old, but aave.com/careers still shows ~10 open roles. Could you
share the most effective channel to apply for engineering roles right now?
Specifically interested in:
- Backend Engineer (DeFi Protocol)
- Smart Contract Engineer

Happy to share my GitHub demo if helpful.

Cheers,
[Your Name]
```

---

### 2. Scroll

**已知线索**：
- 官方招聘页：<https://scroll.io/careers>（需要核实是否还更新）
- 创始团队是华人（**张烨 / Ye Zhang，CTO**），优先中文 DM
- ZK 赛道近 1 年裁员严重，可能真在缩

**LinkedIn / Twitter 直链**：

| 用途 | 直链 |
|---|---|
| 🔥 **优先：LinkedIn 招聘页** | <https://www.linkedin.com/jobs/search/?keywords=scroll%20foundation> |
| 公司主页 | <https://www.linkedin.com/company/scroll-foundation/> · <https://www.linkedin.com/company/scrollio/> |
| 公司全部员工 | <https://www.linkedin.com/company/scroll-foundation/people/> |
| 搜 HR / Talent | <https://www.linkedin.com/search/results/people/?keywords=Scroll%20Foundation%20Recruiter%20OR%20Talent> |
| 搜 工程经理 / Backend Lead | <https://www.linkedin.com/search/results/people/?keywords=Scroll%20Foundation%20Engineering%20Manager%20OR%20Backend> |
| 搜 ZK 工程师 | <https://www.linkedin.com/search/results/people/?keywords=Scroll%20Foundation%20ZK%20Engineer> |
| Twitter [@yezhang1998](https://twitter.com/yezhang1998)（CTO 张烨，⭐⭐⭐⭐ 偶尔回中文）| **优先中文 DM** |
| Twitter [@Scroll_ZKP](https://twitter.com/Scroll_ZKP)（官号）| 客服性质 |

**DM 模板（中文）**：
```
你好 [姓名]，

我是 5 年 Java/Go 后端工程师，目前在用 go-ethereum 做 Aave V3 DeFi
adapter 的个人项目（Sepolia 已跑通 supply/borrow/清算监听）。

注意到 Scroll 在 web3.career 上的岗位都是 2023 年的，请问 Scroll 后端
方向目前是否还在招？如果在招，最有效的内推 / 投递渠道是什么？

希望了解 Scroll 的：
- ZK Layer2 SDK / DevTool 后端
- 区块链基础设施工程师方向

简历和 GitHub demo 随时可发您。

谢谢！
```

---

### 3. Bitget / Bitget Wallet

**已知线索**：
- Gracy Chen 是华人 CEO（女）
- Bitget Wallet 与 Bitget Exchange 是两个独立招聘体系
- 我们已经从 web3.career 抓到 9 个 Bitget 岗位（其中 2 个 target），但都是 2023 年
- **大概率还在招** —— Bitget 2024-2025 在 BD / 营销岗 HC 很大

**LinkedIn / Twitter 直链**：

| 用途 | 直链 |
|---|---|
| 🔥 **优先：Bitget 交易所招聘页** | <https://www.linkedin.com/jobs/search/?keywords=bitget> |
| 🔥 **优先：Bitget Wallet 招聘页** | <https://www.linkedin.com/jobs/search/?keywords=bitget%20wallet> |
| Bitget 公司主页 | <https://www.linkedin.com/company/bitget/> |
| Bitget Wallet 公司主页（独立体系）| <https://www.linkedin.com/company/bitgetwallet/> |
| Bitget 全部员工 | <https://www.linkedin.com/company/bitget/people/> |
| Bitget Wallet 全部员工 | <https://www.linkedin.com/company/bitgetwallet/people/> |
| 搜 HR / Talent | <https://www.linkedin.com/search/results/people/?keywords=Bitget%20Recruiter%20OR%20Talent%20OR%20HR> |
| 搜 钱包工程团队 | <https://www.linkedin.com/search/results/people/?keywords=Bitget%20Wallet%20Engineering%20OR%20Backend> |
| Twitter [@GracyBitget](https://twitter.com/GracyBitget)（CEO Gracy Chen）| 看心情 |
| Twitter [@BitgetWallet](https://twitter.com/BitgetWallet) | 客服 |
| 微信 / Telegram 中文招聘群 | **最有效的内推渠道** |

**DM 模板（中文）**：
```
你好 [姓名]，

我是 5 年 Java/Go 后端工程师（Web2 转 Web3），目前在做 Aave V3 +
go-ethereum 的 DeFi adapter 项目。看到 Bitget 在公开招聘平台的岗位都是
2023 年发的，请问 Bitget Wallet / 交易所后端方向目前是否还在招？

特别想了解：
- Bitget Wallet 区块链工程师
- 撮合引擎 / Web3 业务后端

如果方便，希望知道：
1. 当前是否有合适岗位？
2. 最有效的投递渠道？
3. 是否能内推？

简历可随时发您。谢谢！
```

---

### 4. Magic Eden

**已知线索**：
- 官方招聘页：<https://magiceden.io/jobs>（需要核实）
- 注意：**Ashby 上的 `magiceden` handle 不是 NFT 市场，是 iGaming 体育博彩公司！**
- 真正 NFT Magic Eden **可能完全切到了内推 + LinkedIn**
- NFT 赛道整体冷清，可能真缩了

**LinkedIn / Twitter 直链**：

| 用途 | 直链 |
|---|---|
| 🔥 **优先：LinkedIn 招聘页** | <https://www.linkedin.com/jobs/search/?keywords=magic%20eden> |
| 公司主页 | <https://www.linkedin.com/company/magiceden/> |
| 公司全部员工 | <https://www.linkedin.com/company/magiceden/people/> |
| 搜 HR / Talent | <https://www.linkedin.com/search/results/people/?keywords=Magic%20Eden%20Recruiter%20OR%20Talent> |
| 搜 工程经理 / Backend Lead | <https://www.linkedin.com/search/results/people/?keywords=Magic%20Eden%20Engineering%20Manager%20OR%20Backend%20Lead> |
| Twitter [@jbeezy](https://twitter.com/jbeezy)（CEO Jack Lu）| 极少回 |
| Twitter [@MagicEden](https://twitter.com/MagicEden)（官号）| 客服 |

**DM 模板（英文）**：
```
Hi [Name],

I'm a senior Java/Go backend engineer transitioning into Web3, currently
shipping a Go-based DeFi adapter for Aave V3.

Magic Eden's listings on aggregator job boards (web3.career) appear to be
1+ year old. Is the engineering team still actively hiring backend roles?

Specifically interested in NFT marketplace backend / cross-chain integrations.

Happy to share my GitHub portfolio.

Cheers,
[Your Name]
```

---

## 三、30-60 分钟执行节奏

### Step 1：5 分钟 —— 找 8 个 DM 对象

打开 LinkedIn，搜 4 个公司各 2 个对象（1 个工程经理 + 1 个 HR）。记到一个表里：

```
| 公司 | 平台 | 名字 | URL | 已发 DM | 回复时间 | 回复内容 |
|---|---|---|---|---|---|---|
| Aave | LinkedIn | xxx | linkedin.com/in/xxx | ❌ | - | - |
| Aave | Twitter | @MarcZeller | twitter.com/lemiscate | ❌ | - | - |
| Scroll | LinkedIn | xxx | ... | ❌ | - | - |
| Scroll | Twitter | @yezhang1998 | ... | ❌ | - | - |
| Bitget | LinkedIn | xxx | ... | ❌ | - | - |
| Bitget | 微信 | 招聘群 xxx | ... | ❌ | - | - |
| Magic Eden | LinkedIn | xxx | ... | ❌ | - | - |
| Magic Eden | LinkedIn | xxx | ... | ❌ | - | - |
```

### Step 2：20-30 分钟 —— 批量发 DM

复制上面的模板，按公司分别 DM。**所有 DM 同一时间发出**（不要分散）。

⚠️ **注意**：
- LinkedIn 免费账号每月 5 条 InMail 限制 → 优先用 InMail 给最关键 1-2 个
- 其他人通过「关注 → 互动 → 私信」三步走（更慢但更有效）
- 中文 DM **不要带产品/技术英文术语堆砌**（看起来像群发模板，回复率会暴跌）

### Step 3：等 48 小时

按下表统计：

| 公司 | 发了几条 DM | 收到几条回复 | 是否在招（自评）|
|---|---|---|---|
| Aave | __ | __ | □ 在招 / □ 暂停 / □ 死火 |
| Scroll | __ | __ | □ 在招 / □ 暂停 / □ 死火 |
| Bitget | __ | __ | □ 在招 / □ 暂停 / □ 死火 |
| Magic Eden | __ | __ | □ 在招 / □ 暂停 / □ 死火 |

### Step 4：根据结果决定下一步

| 探查结果 | 后续动作 |
|---|---|
| 4 家全死火 | ✅ 这条线彻底关闭，**精力 100% 投到 8 家活跃公司**；这 4 家只用于业务学习 |
| 1-2 家在招 | ✅ 写自建 ATS 抓取器（每家约 2 小时）+ 走内推渠道直接投 |
| 3-4 家在招 | ⭐ 立即写 4 家自建 ATS 抓取器，扩大投递面 |

---

## 四、附：4 家公司业务学习价值（即使死火也别删）

| 公司 | 学什么 | 学完哪段简历加分 |
|---|---|---|
| **Aave** | Pool / aToken / Liquidation / Flash loan / 利率模型 | "实现过 Aave V3 supply/borrow Go SDK demo" |
| **Scroll** | zkEVM Layer2 架构 / Sequencer / Prover | "理解 ZK Layer2 数据可用性 + 状态证明流程" |
| **Bitget** | CEX 钱包架构 / 撮合引擎 / 充提系统 | "对照 Bitget Wallet 设计实现过 Web3 钱包后端" |
| **Magic Eden** | NFT 多链订单簿 / 版税分发 / 跨链元数据 | "研究过 NFT 市场多链订单匹配机制" |

→ **不投递不代表不学**，业务知识沉淀到 [`backend_engineer_4weeks.md`](backend_engineer_4weeks.md) 已经规划好了。
