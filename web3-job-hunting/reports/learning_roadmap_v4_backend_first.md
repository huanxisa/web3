# Web3 后端学习地图 v4（后端先行版 · 双路径）

> **本文档迭代由来**：用户在 v3 review 时指出 — *"我作为后端面试官不会问源码细节，只会问'你了解这个东西多少 + 你会怎么基于它设计后端方案'"* —— v3 把"读源码 + 答 5 题"作为周产出**用错了角色**：那是合约工程师的活。
>
> **v4 拆双路径**：
>
> | 路径 | 何时启动 | 周产出 | 简历对标岗位 |
> |---|---|---|---|
> | **后端篇**（先做）| 立刻开始 | 业务速读 + **2 道系统设计题（必带 PoC）** | Web3 后端 / CEX 风控 / 钱包后端 / 数据平台 |
> | **合约篇**（吃完后端再开）| 后端 8 周完成后 | 源码精读 + 5 题答案 + 单元测试 | Solidity 工程师 / 协议研发 |
>
> **关键差别**：
>
> | v3 旧 | v4 新（后端篇）|
> |---|---|
> | "4 天读 5 个 .sol 文件" | "**4 小时**业务速读（仅看 public API + events + 业务文档）"|
> | "答 5 道源码题（chi 累积器/RAY/scaledBalance）" | "**2 道系统设计题（带 100-200 行 PoC）**"|
> | "学合约怎么实现" | "学**怎么基于合约的事件流和状态接口设计后端系统**"|

---

## 一、为什么后端先行（数据 + 战术理由）

### 数据：884 个命中岗位的 title 词频

| 关键词 | 命中 | 角色 |
|---|---|---|
| Backend / Engineer / 后端 / Server | **520+** | 后端 |
| Java / Golang | **41 + 40 = 81 个语言级强匹配** | 后端 |
| Smart Contract Engineer / Solidity | 11 | 合约 |
| 工程师（中文） | 200+ | 后端为主 |

→ **后端岗位是合约岗位的 47x**。先吃后端 = 立刻命中 884 个岗位的 90%；合约岗位等吃完后端再啃也来得及。

### 战术：4 周 vs 8 周的回本时间

- **后端篇 8 周完成** → 简历有 16 个系统设计 + 3 个 PoC → 立刻可投
- **合约篇再补 4-6 周** → 简历再加 8 个 5 题答案 + Foundry 单元测试 → 升级到合约岗候选

→ 总时间 ≈ 12-14 周，但**前 8 周就能产出可投的简历**，不必"等所有都学完才能投"。

---

## 二、后端篇：8 周路径（项目顺序与 v3 一致，但每周内容重写）

```
┌─ Stage 1：DeFi 业务理解 + 后端设计（4 周）═══════════════════════════════
│   W1  Uniswap V3      → AMM 业务流 + DEX 聚合报价缓存 + LP 收益看板
│   W2  Aave V3         → 借贷业务流 + 健康因子监控 + 清算机器人 ⭐示范周
│   W3  MakerDAO        → 稳定币业务流 + CDP 风险仪表盘 + 稳定费收取分发
│   W4  Lido            → LST 业务流 + stETH rebase 推送 + 节点性能 pipeline
│   ────────────────────────
│   📦 产出：8 道系统设计方案 + Aave 健康因子监控 PoC（核心 demo #1）
│
├─ Stage 2：CEX/钱包后端深耕（3 周）═════════════════════════════════════
│   W5  dYdX V4         → 链上撮合业务流 + ERC20 indexer + WS push 服务
│   W6  Binance tss-lib → MPC 业务流 + keygen gRPC 服务 + 签名调度器
│   W7  Safe            → 多签业务流 + 提案聚合后端 + Module 扩展开发
│   ────────────────────────
│   📦 产出：6 道系统设计方案 + indexer PoC（核心 demo #2）+ MPC keygen PoC（核心 demo #3）
│
├─ Stage 3：差异化（2 周，3 选 1）═════════════════════════════════════════
│   W8  ① EigenLayer 后端  ② LayerZero 后端  ③ Pendle 后端
│   ────────────────────────
│   📦 产出：2 道系统设计方案 + 1 篇前沿叙事博客
│
└─ 总计：16 道系统设计方案 + 3 个 PoC + 8 篇业务故事
```

### 为什么是这个顺序（v4 沿用 v3，但视角变了）

| 周 | 项目 | **后端面试真问什么** |
|---|---|---|
| W1 | Uniswap V3 | "聚合器报价缓存 / LP 收益数据怎么算？" |
| W2 | Aave V3 | "**健康因子怎么实时监控**？清算机器人怎么设计？" |
| W3 | MakerDAO | "CDP 状态聚合 + 稳定费分发后端怎么做？" |
| W4 | Lido | "stETH rebase 推送 / Operator performance 数据 pipeline" |
| W5 | dYdX V4 | "链上事件 → Postgres + WS push 全链路怎么搭"（**纯后端**） |
| W6 | tss-lib | "MPC 钱包私钥分片怎么持久化 + 签名调度容错"（**纯后端**） |
| W7 | Safe | "多签提案聚合 / Module 扩展" |

→ 这些都是**真实后端面试题**，从你 884 命中岗位的 JD 反推出来的。

---

## 三、每周后端节奏（标准模板）

### D1（4h）— 业务速读

```
1. 通读项目官方文档 business 部分              1.5h
2. 看核心合约的 public function 签名           1h
   （只看接口！不看实现）
3. 列出全部 event（这是后端 indexer 输入）     0.5h
4. 画 1 张完整业务流程图（用户态/合约态/链下）  0.5h
5. 写"业务故事卡"（300 字讲清协议）            0.5h
```

→ 输出：业务故事卡 + 业务流程图 + event 清单（贴在周笔记开头）

### D2 + D3（每天 4-5h）— 系统设计题 #1（必带 PoC）

```
1. 题目 reading + 5 个用户故事（30 分钟）
2. 规模估算（QPS / 数据量 / 并发用户）        30 分钟
3. 架构图（ASCII 或 mermaid）                 1h
4. 数据库 schema 设计                         30 分钟
5. API 接口定义                               30 分钟
6. Tradeoff 论述（关键决策为什么这么选）      1h
7. 监控指标 + 异常处理 + 容灾                 30 分钟
8. PoC 代码（覆盖 1 个核心模块，100-200 行）  2-3h
```

→ 输出：1 份完整系统设计 markdown + 1 个可跑的 Go PoC 文件夹

### D4（4-5h）— 系统设计题 #2（必带 PoC）

同 D2-D3 流程，做第 2 道题。

### D5/D6（机动）— 整理、答辩、博客

- 把 2 道系统设计题写成博客（讲给行业看）
- 录 5 分钟自答视频（讲给自己看）
- 简历更新 1 段

### D7（30 分钟）— 周日内化

- 镜子讲 2 道系统设计题各 3 分钟
- Anki 加卡（可选）
- 检查自检表

---

## 四、每周 2 道系统设计题清单（**16 道全预设好**）

> 每道题都是从 884 个真实命中岗位的 JD 反推出来的"会被真问"的题。
>
> 详细模板见 [`../notes/_template/system_design.md`](../notes/_template/system_design.md)

### W1 — Uniswap V3（DEX 业务）

| # | 系统设计题 | PoC 焦点 | 真实场景 |
|---|---|---|---|
| 1.1 | **DEX 聚合器报价缓存系统** | 缓存全链所有 V3 池的 sqrtPrice + tick，给报价器毫秒级响应 | 1inch / 0x / Jupiter 后端核心 |
| 1.2 | **LP 收益看板** | 算每个 NFT position 的 fee earned + impermanent loss | DefiLlama / Revert Finance |

### W2 — Aave V3（借贷业务）⭐ 示范周（已写完整方案）

| # | 系统设计题 | PoC 焦点 | 真实场景 |
|---|---|---|---|
| 2.1 | **用户健康因子实时监控 + 推送系统** ⭐ | 监听 Borrow/Supply event，算 healthFactor，<阈值告警 | DeFi 钱包推送 / Aave 官方安全告警 |
| 2.2 | **清算机器人架构** | 扫描所有低健康度地址，模拟 liquidationCall 收益，bid 上链 | MEV / 清算 keeper 公司 |

### W3 — MakerDAO（稳定币业务）

| # | 系统设计题 | PoC 焦点 | 真实场景 |
|---|---|---|---|
| 3.1 | **CDP 风险预警仪表盘** | 实时聚合所有 Vault 的 c-ratio，分级告警 | DeFi Saver / Maker 官方面板 |
| 3.2 | **稳定费收取与分发后端** | 监听 jug.drip，聚合到协议金库，触发 DSR 分发 | Maker DAO Treasury 后端 |

### W4 — Lido（LST 业务）

| # | 系统设计题 | PoC 焦点 | 真实场景 |
|---|---|---|---|
| 4.1 | **stETH rebase 推送系统** | 监听 daily oracle update，给所有 stETH 持有者推送余额变化 | Coinbase Wallet / Trust Wallet 钱包后端 |
| 4.2 | **节点 Operator performance 数据 pipeline** | 抓信标链验证人 performance，聚合到每个 Operator 的奖励/罚没记录 | Lido DAO 数据后端 / Rated.network |

### W5 — dYdX V4（链上撮合 + Indexer，**纯后端**）

| # | 系统设计题 | PoC 焦点 | 真实场景 |
|---|---|---|---|
| 5.1 | **ERC20 链上 indexer**（**核心 Demo #2**） | 监听 Transfer event → Postgres，提供 REST 查询 | Etherscan / Alchemy / dYdX indexer |
| 5.2 | **持仓 + K 线 WebSocket push 服务** | 客户端订阅 → 实时推送链上事件转化的 K 线 | dYdX socks 服务 / Binance WS API |

### W6 — Binance tss-lib（MPC，**纯后端**）

| # | 系统设计题 | PoC 焦点 | 真实场景 |
|---|---|---|---|
| 6.1 | **MPC 钱包 keygen 后端服务**（**核心 Demo #3**） | 用 tss-lib 包成 gRPC，3 party 协作生成密钥 + 分片持久化 | Cobo / Safeheron / Fireblocks |
| 6.2 | **MPC 签名调度器** | 多 party 协作签名，处理消息丢失/超时/重试 | 同上 |

### W7 — Safe（多签托管）

| # | 系统设计题 | PoC 焦点 | 真实场景 |
|---|---|---|---|
| 7.1 | **Safe 多签提案聚合后端** | 收集 owner 链下签名，凑够 M 个后聚合上链 | safe-transaction-service |
| 7.2 | **Safe Module 扩展开发** | 写一个 Allowance Module，让链下 server 在限额内自动 exec | DAO Treasury 自动化工具 |

### W8 — 三选一（按个人兴趣）

| 选项 | 2 道题 |
|---|---|
| ① EigenLayer | 8.1 Operator 任务调度后端 / 8.2 Restaking TVL 数据 pipeline |
| ② LayerZero | 8.1 跨链消息中继器（仿 Worker） / 8.2 多链 DApp 交易状态聚合 |
| ③ Pendle | 8.1 PT/YT 价格 oracle 后端 / 8.2 收益策略路由器 |

---

## 五、3 个核心 Demo（简历重点项）

| Demo | 哪周做 | 仓库结构 | 简历卖点 |
|---|---|---|---|
| **#1 aave-health-monitor** | W2.1 | `cmd/main.go` + `internal/{listener,calculator,notifier}/` | "10 万用户实时健康因子监控 + Webhook 推送" |
| **#2 erc20-indexer** | W5.1 | `cmd/main.go` + `internal/{listener,parser,repo,api}/` | "go-ethereum + Postgres + reorg 处理 + REST API" |
| **#3 mpc-keygen-grpc** | W6.1 | `cmd/server/main.go` + `internal/{tss,storage,grpc}/` | "用 tss-lib 包 gRPC，3 party DKG + Postgres 分片持久化" |

→ 这 3 个 Demo 推到 GitHub 公开 + README 详写设计取舍 = **简历最强一段**。

---

## 六、合约篇（占位，后端 8 周后再开）

> **不要现在做** — 你已经有 [`business_focused_repos_for_newcomers.md`](business_focused_repos_for_newcomers.md) v1 文档了，那是合约视角的 8 项目精读路径。
>
> 等你完成后端篇 8 周后，回头按 v1 / v3 文档的"5 题答案"路径补合约深度即可。
>
> **合约篇与后端篇的关系**：
>
> ```
>                后端篇（W1-W8 后端视角）
>                ↓
>   完成 → 投递后端岗位 → 拿到面试 → 累积反馈
>                ↓
>   有时间 → 合约篇（W1-W8 合约视角，复用同样 8 个项目）
>                ↓
>   完成 → 投递合约岗位 / 升级技术广度
> ```

---

## 七、配套工具链

```
notes/
├── _template/
│   ├── business_card.md     业务故事卡（保留 v3）
│   ├── system_design.md     ⭐ v4 新增：7 段系统设计模板
│   └── demo_readme.md       PoC 仓库 README 模板
├── weekly/
│   ├── backend/             ⭐ 后端篇 8 周（v4 主战场）
│   │   ├── W1_uniswap_v3.md       2 道系统设计题预设
│   │   ├── W2_aave_v3.md          ⭐ 示范周（健康因子完整方案）
│   │   ├── W3_makerdao.md
│   │   ├── W4_lido.md
│   │   ├── W5_dydx_v4.md
│   │   ├── W6_binance_tss_lib.md
│   │   ├── W7_safe.md
│   │   └── W8_差异化亮点_3选1.md
│   └── contract/            合约篇（待启动，先放占位）
│       └── README.md        说明"等吃完后端再开"
└── demos/                   3 个核心 Demo 的 README + 复盘
    ├── aave-health-monitor.md
    ├── erc20-indexer.md
    └── mpc-keygen-grpc.md
```

---

## 八、立即开始

```bash
# Step 1：看示范周（W2 Aave 已经写好完整 with-PoC 系统设计）
cursor web3-job-hunting/notes/weekly/backend/W2_aave_v3.md

# Step 2：从 W1 启动
cursor web3-job-hunting/notes/weekly/backend/W1_uniswap_v3.md

# Step 3：每周日内化
# 用 system_design.md 模板写 2 道题，加 PoC 推 GitHub
```

---

## 九、自检线（每个 Stage 末尾）

完成 W4 / W7 / W8 时，对照检查：

- [ ] 16 道系统设计题中已完成 ___ 道（每道有架构图 + Schema + Tradeoff + PoC）
- [ ] 3 个核心 Demo 推到 GitHub（公开链接）
- [ ] 8 篇业务故事写在 Notion / 博客（公开链接）
- [ ] 简历"项目经验"写一段对标后端 senior 岗
- [ ] 镜子练习：能 5 分钟讲清 2 道系统设计题

→ 任一项不通过 → 回去补，**不许进入下一 Stage**。
