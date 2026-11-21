# W6 — Binance tss-lib 后端篇

> **MPC 业务 + keygen gRPC 服务 + 签名调度（**纯后端**）**
> 配套 [`../../../reports/learning_roadmap_v4_backend_first.md`](../../../reports/learning_roadmap_v4_backend_first.md) 第 W6 章节
> 仓库位置：`repos/mpc-wallet/binance-tss-lib/`
> 官方文档：<https://github.com/bnb-chain/tss-lib/blob/master/README.md>

---

## 📐 方向总览（总控视角 — 子 agent 必读，你执行前也看一眼）

> 这一段不指挥你"读第几行"，告诉你**这周往哪打 / 不打哪 / 用什么弹药**。
> **本周完全没有链上事件**——这是一个纯后端 P2P 协议系统设计周。

### A. 项目抉择 — 为什么这周是 Binance tss-lib

| 维度 | 内容 |
|---|---|
| **业务定位** | 行业最知名开源 ECDSA TSS（GG18 / GG20）实现，**Fireblocks / Cobo / Safeheron / BitGo 的 MPC 钱包底层范式** |
| **JD 数据支撑** | 钱包/MPC/Custody 方向 30 天 **22** 个命中（Cobo / Safeheron / PURVIEW / BitGo / BeQuant Go 后端高频）|
| **背景匹配度** | ⭐⭐⭐⭐⭐ — **官方仓库就是 Go**，把 lib 包成 gRPC = 纯后端工作；不需要懂密码学 |
| **为什么不选 ZenGo zengo-x/multi-party-ecdsa（Rust）** | 业务模型相同但语言不对口；Binance lib 是 Go 后端的事实标准 |
| **为什么不选 Lit Protocol / Web3Auth** | 抽象层太高（OAuth + threshold），后端工程化要点被隐藏；tss-lib 更"赤裸"，学透了别的都通 |

### B. 本周后端关注点 vs 不关注点

| ✅ **本周必学的后端模块** | ❌ **跳过的（密码学 / 数学）** |
|---|---|
| **DKG / Signing 业务流**（每 round 之间 P2P 消息类型 + 持久化时机）| Paillier 同态加密原理 |
| **gRPC 服务封装**（把 tss-lib 跨进程暴露 + N party 协作流）| Schnorr / EdDSA 数学推导 |
| **密钥分片持久化 + 加密存储**（HSM / KMS / 加密 DB 三种方案对比）| GG18 paper 的零知识证明步骤 |
| **多 party 消息可靠传输**（消息丢失 / 顺序 / 超时 / 重试）| MtA / MtAwc 协议细节 |
| **签名调度 + 流控**（防止 1 个慢 party 拖死系统）| EC discrete log 假设证明 |

→ **一句话**：本周两个 Go PoC 形态：
> **#1**「gRPC server × 3 互相 P2P，跑完 DKG 5 round → 各自持久化 shard → 客户端拿到聚合 pubkey」
> **#2**「上面的 3 节点协作签名 → 处理消息丢失 / 超时 / 1 party 掉线 → 输出最终签名」

### C. 仓库分级（已 clone — 子 agent 重点啃这里）

| 仓库路径 | 等级 | 必看模块 | 后端价值 |
|---|---|---|---|
| `repos/mpc-wallet/binance-tss-lib/ecdsa/keygen/local_party.go` | 🔴🔴 **必看，王炸** | 5 round 之间传什么消息 + Update / Start / Finish 状态机 | **PoC #1 的 gRPC wrapper 直接照着 round 划分**|
| `repos/mpc-wallet/binance-tss-lib/ecdsa/signing/local_party.go` | 🔴🔴 **必看** | signing 9 round 状态机 | **PoC #2 的协作签名调度对照**|
| `repos/mpc-wallet/binance-tss-lib/tss/party.go` | 🔴 **必看** | `tss.Party` 接口 + Update / WaitingFor | 你要包的接口边界 |
| `repos/mpc-wallet/binance-tss-lib/test/` | 🟡 参考 | 官方单元测试，**单机 N goroutine 模拟 N party**| 你 PoC 起手能直接 fork 一个测试改成 gRPC |
| `repos/mpc-wallet/binance-tss-lib/common/`、`crypto/` | 🟢 选看 | Paillier / 公共代数库 | **跳过，密码学已封装好**|

### D. 仓库分级（参考价值高，未 clone — 子 agent 按需补）

| 仓库 | 等级 | 用途 | 何时补 |
|---|---|---|---|
| [bnb-chain/tss](https://github.com/bnb-chain/tss) | 🔴 **必看** | **官方包好的 CLI + libp2p 工程范例**，已经做了 PoC #1 的大半工作 | **W6 D2 起手就 clone** |
| [Safeheron mpc-snap-wallet](https://github.com/Safeheron) | 🟡 参考 | 商业级 MPC 钱包架构（节点协调 / KMS） | 系统设计阶段对照行业架构 |
| [taurusgroup/multi-party-sig](https://github.com/taurusgroup/multi-party-sig) | 🟡 参考 | CGGMP24 协议 Go 实现（更新的协议）| 不必看，了解即可 |
| [zengo-x/multi-party-ecdsa](https://github.com/ZenGo-X/multi-party-ecdsa) | 🟢 选看 | Rust 版同类工程 | 不必看 |

> ⚪ **强烈建议子 agent 第一步**：`git clone --depth=1 https://github.com/bnb-chain/tss web3-job-hunting/repos/mpc-wallet/binance-tss-cli`

### E. 2 道系统设计题的「考点」（面试官真问什么）

#### 题 #1 — MPC 钱包 keygen 后端服务（**核心 Demo #3，推 GitHub 公开**）

| 维度 | 内容 |
|---|---|
| **后端面试官真问** | "3 个节点跑在 3 台机器，消息怎么走？libp2p / gRPC / NATS 选哪个？" / "1 个节点慢了怎么办？" / "shard 怎么加密存储？" / "再来 1 个 party 加入（resharing）怎么办？" |
| **核心模块**（5 个）| 1) **gRPC Service**（KeyGen / Sign / Resharing 三个 RPC）2) **P2P Router**（每 round 消息按 from/to 路由）3) **State Persister**（每 round 完成快照到 DB / 文件）4) **Crypto Adapter**（包 tss-lib 的 Party 接口）5) **Coordinator**（3 节点都到齐再 Start） |
| **PoC 难点** | **跨进程 round 状态机管理**（不能让 party 卡在某 round 等消息超时）+ **shard 加密存储**（一旦泄露 = 私钥泄露） |
| **抄哪段代码起步** | `repos/mpc-wallet/binance-tss-lib/test/keygen_test.go` 单机 N goroutine 版本 → 拆成 N 个 gRPC 服务 |
| **特别提醒** | ⭐ 核心 Demo，**README 必写**："3 节点 docker-compose 起 → 客户端调一个 RPC → 看到 3 节点协作 → 输出公钥 + 3 份 shard" |

#### 题 #2 — MPC 签名调度器

| 维度 | 内容 |
|---|---|
| **后端面试官真问** | "签名时 1 个 party 掉线怎么办（GG20 支持 abort identification）？" / "同时来 100 个签名请求怎么调度（per-key 锁）？" / "签名耗时 5s，怎么提升吞吐？" / "怎么防止恶意 party 投毒？" |
| **核心模块**（4 个）| 1) **Request Queue**（per-key 串行 + 跨 key 并行）2) **Party Coordinator**（选取在线 party / 检查阈值 t+1）3) **Sign Executor**（drive signing 9 round 状态机）4) **Result Verifier**（验证签名 + 复发) |
| **PoC 难点** | **per-key 串行 vs 全局并行**（同一 key 不能同时跑两个签名）+ **超时 / abort 处理**（哪些是 abort，哪些是 timeout） |
| **抄哪段代码起步** | `signing/local_party.go` 状态机驱动 + 自己写 `Coordinator` 包 |

### F. 给子 agent 的执行边界

- ✅ **可以自由决策**：P2P 用 libp2p / gRPC stream / NATS、shard 存 SQLite / Postgres / 文件、节点间认证（TLS / Noise）
- ❌ **不要做**：① 跑去懂 GG18 paper 的零知识证明 ② 自己实现 Paillier 同态加密 ③ 替换为其他更新协议（CGGMP24 等）
- ⚠️ **遇到分歧问总控**：如果发现"3 节点跨进程跑不通" → 报告总控，可降级为 3 进程同机 docker

---

## D1（4h）— 业务速读

### 必读清单（**只读业务，不读源码**）

  - [ ] tss-lib README — MPC TSS 协议业务流（DKG / Signing / Resharing）
  - [ ] GG18 / GG20 论文摘要（懂业务流即可，不需要懂数学）
  - [ ] `ecdsa/keygen/local_party.go` — 只看 5 round 之间传什么消息（业务流）
  - [ ] `ecdsa/signing/local_party.go` — 同上
  - [ ] Fireblocks / Cobo 公开技术文档（行业落地范式）

### 关键 events（后端 indexer 的输入信号）

```
（无链上 event；MPC 是链下协议）— 关注：每 round 的 P2P 消息类型 + 持久化时机
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

### 系统设计题 #1：MPC 钱包 keygen 后端服务（**核心 Demo #3**）

> **场景**：Cobo / Safeheron / Fireblocks
> **PoC 焦点**：用 tss-lib 包成 gRPC，3 party 协作生成密钥 + 分片持久化
>
> 请用 [`../../_template/system_design.md`](../../_template/system_design.md) 模板填写完整 7 段（场景/规模/架构/Schema/API/Tradeoff/监控）+ 100-200 行 PoC。

#### 我的方案（在此填写或链接到独立 markdown）

> 例：参见 [`./W6_sd1_solution.md`](./W6_sd1_solution.md)


#### PoC 仓库（**本周必做**）

⭐ **本题是核心 Demo mpc-keygen-grpc**，推到 GitHub 公开

- [ ] 项目脚手架建好（5-8 个 Go 文件）
- [ ] 主流程跑通（happy path）
- [ ] README 写好（讲清"做什么/怎么跑/学到什么"）
- [ ] 推到 GitHub（链接：____________________）

---
### 系统设计题 #2：MPC 签名调度器

> **场景**：同上
> **PoC 焦点**：多 party 协作签名，处理消息丢失/超时/重试
>
> 请用 [`../../_template/system_design.md`](../../_template/system_design.md) 模板填写完整 7 段（场景/规模/架构/Schema/API/Tradeoff/监控）+ 100-200 行 PoC。

#### 我的方案（在此填写或链接到独立 markdown）

> 例：参见 [`./W6_sd2_solution.md`](./W6_sd2_solution.md)


#### PoC 仓库（**本周必做**）

PoC 放在 `repos/_demos/W6_2_xxx/`

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
