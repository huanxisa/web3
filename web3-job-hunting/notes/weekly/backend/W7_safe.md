# W7 — Safe 后端篇

> **多签业务 + 提案聚合后端 + Module 扩展**
> 配套 [`../../../reports/learning_roadmap_v4_backend_first.md`](../../../reports/learning_roadmap_v4_backend_first.md) 第 W7 章节
> 仓库位置：`repos/innovation/safe-smart-account/ + safe-transaction-service/`
> 官方文档：<https://docs.safe.global/>

---

## 📐 方向总览（总控视角 — 子 agent 必读，你执行前也看一眼）

> 这一段不指挥你"读第几行"，告诉你**这周往哪打 / 不打哪 / 用什么弹药**。

### A. 项目抉择 — 为什么这周是 Safe

| 维度 | 内容 |
|---|---|
| **业务定位** | EVM 上事实标准的智能合约钱包，**所有 DAO 国库 / 项目方多签都用 Safe**；`safe-transaction-service` 是社区使用最广的"链下签名聚合后端" |
| **JD 数据支撑** | 钱包/MPC/Custody 方向 22 命中中**多签子集**；DAO 后端 / 合约钱包后端高频提及 |
| **背景匹配度** | ⭐⭐⭐⭐ — `safe-transaction-service` 是 Python/Django 后端，跟你**纯后端经验直接对口**；业务模型简单（M-of-N 签名收集） |
| **为什么不选 ERC-4337 账户抽象** | ERC-4337 业务模型新（bundler / paymaster），生态未稳；Safe 是**当下生产用量最大的合约钱包**，4337 可作为 Safe 之上的扩展讨论 |
| **为什么不选 Argent / Sequence 等其他 SCW** | 闭源 / 私链；Safe 是唯一**开源 + 链下 service 也开源**的范本 |

### B. 本周后端关注点 vs 不关注点

| ✅ **本周必学的后端模块** | ❌ **跳过的（合约 / 升级 / 前端）** |
|---|---|
| **EIP-712 签名收集 + 验证**（链下 owner 签名，攒够 M 个再上链）| Safe 合约本身的升级流程（Master Copy / Singleton 模式）|
| **多签提案的状态机**（pending → ready → executed → failed）| EIP-1271 给 DApp 签名的合约级实现 |
| **Owner 变更 / Module 启用的事件 indexer**（链上状态镜像）| Safe Apps / 前端 SDK |
| **Module 设计模式**（链下 server 在限额内自动 exec）| Guard / SignatureVerifier 等 niche 合约 |
| **Nonce / Replay 防护**（多签场景下的并发提案管理）| Safe 4337 module 的 bundler 集成（W8 再聊）|

→ **一句话**：本周两个 Go PoC 形态：
> **#1**「Owner 提交链下 EIP-712 签名 → 服务端收集 M 个 → 拼成 `execTransaction` 上链 → REST/WS 通知」
> **#2**「写一个 Allowance Module（合约）→ 链下 server 在限额内自动 exec → 含限额监控 + 风控」

### C. 仓库分级（已 clone — 子 agent 重点啃这里）

| 仓库路径 | 等级 | 必看模块 | 后端价值 |
|---|---|---|---|
| `repos/innovation/safe-smart-account/contracts/Safe.sol` | 🔴 **必看** | `execTransaction` + `checkSignatures` + 全 events | 链下要凑的 signature 拼接格式 |
| `repos/innovation/safe-smart-account/contracts/base/OwnerManager.sol` | 🟡 参考 | Owner 管理事件 | indexer 输入 |
| **`repos/innovation/safe-transaction-service/`** | 🔴🔴 **必看，王炸** | `safe_transaction_service/safe_messages/` + `history/services/` | **官方 Python 后端，PoC #1 直接对照范本** |
| `repos/innovation/safe-eth-py/safe_eth/safe/` | 🔴 **必看** | `Safe` / `SafeTx` 类的 EIP-712 hash 构造 + signature 验证 | **PoC #1 的 EIP-712 编码逻辑直接抄过来翻 Go** |
| `repos/innovation/safe-modules/` | 🔴 **必看** | `allowances/contracts/AllowanceModule.sol` | **PoC #2 的合约模板直接抄** |

### D. 仓库分级（参考价值高，未 clone — 子 agent 按需补）

| 仓库 | 等级 | 用途 | 何时补 |
|---|---|---|---|
| [safe-global/safe-core-sdk](https://github.com/safe-global/safe-core-sdk) | 🟡 参考 | TS SDK 看官方怎么调 service | PoC #1 时对照 API |
| [Gnosis-Mech / Zodiac Roles](https://github.com/gnosis/zodiac-modifier-roles) | 🟡 参考 | Module 高级模式（角色 + 权限）| PoC #2 风控想升级时参考 |
| [safe-global/safe-deployments](https://github.com/safe-global/safe-deployments) | 🟢 选看 | 跨链地址 | 不必看 |
| [ERC-4337 reference bundler](https://github.com/eth-infinitism/bundler) | 🟢 选看 | bundler 范例 | 留到 W8 |

### E. 2 道系统设计题的「考点」（面试官真问什么）

#### 题 #1 — Safe 多签提案聚合后端

| 维度 | 内容 |
|---|---|
| **后端面试官真问** | "EIP-712 hash 怎么算？" / "签名顺序有要求吗（owners 必须按地址排序）？" / "owner 改了，pending 提案要不要作废？" / "并发提案怎么避免 nonce 冲突？" / "怎么保证 exactly-once 上链？" |
| **核心模块**（5 个）| 1) **REST API**（提案 CRUD + 签名上传）2) **Signature Validator**（EIP-712 hash + ecrecover + owner 检查）3) **State Machine**（pending → ready → submitting → executed）4) **Submitter**（凑齐就送链 + nonce 协调）5) **Event Indexer**（监听 ExecutionSuccess/Failure 关闭提案）|
| **PoC 难点** | **EIP-712 hash 必须 bit-by-bit 与合约一致**（错一个字节签名验不过）+ **并发提案的 nonce 协调** |
| **抄哪段代码起步** | `repos/innovation/safe-eth-py/safe_eth/safe/safe_tx.py` 的 hash 构造 → 翻成 Go |

#### 题 #2 — Safe Module 扩展（Allowance Module）

| 维度 | 内容 |
|---|---|
| **后端面试官真问** | "Module 是什么？跟 Owner 区别？" / "怎么防止 Module 被入侵后清空 Safe？" / "limit reset 周期怎么算（链上 vs 链下）？" / "delegate 切换怎么处理 in-flight 交易？" |
| **核心模块**（4 个）| 1) **Allowance Contract**（已有，直接拿）2) **Off-chain Bot**（监听 delegate 任务队列 → 调用 `executeAllowanceTransfer`）3) **Limit Monitor**（剩余额度 / 重置时间）4) **Audit Log**（每次自动 exec 留 trace + 告警）|
| **PoC 难点** | **如何让运维信任这个自动 bot**（限额硬上限 + 多签 owner 紧急 kill switch）|
| **抄哪段代码起步** | `repos/innovation/safe-modules/allowances/contracts/AllowanceModule.sol` + 自己写 Go bot |

### F. 给子 agent 的执行边界

- ✅ **可以自由决策**：Go 用什么 EIP-712 lib（go-ethereum / 自写）、PoC 用 Sepolia 还是 Anvil、API 用 REST / GraphQL
- ❌ **不要做**：① 自己改写 Safe 合约 ② 跑去做 ERC-4337 集成（留 W8）③ 试图把 `safe-transaction-service` 完全 1:1 翻成 Go（**只挑提案聚合这一个核心流**）
- ⚠️ **遇到分歧问总控**：如果发现"EIP-712 hash 在 Go 算出来和合约不一致" → 报告总控，优先用 `safe-eth-py` 生成测试向量对照

---

## D1（4h）— 业务速读

### 必读清单（**只读业务，不读源码**）

  - [ ] Safe docs：Smart Account 概念 + Owner / Module / Guard 三层模型
  - [ ] `contracts/Safe.sol` — 只看 execTransaction / setupOwners / enableModule 签名
  - [ ] `safe-transaction-service/` README — Python 后端业务流（链下签名收集 + 上链）
  - [ ] Safe docs：EIP-1271 章节（合约钱包给 DApp 签名）

### 关键 events（后端 indexer 的输入信号）

```
ExecutionSuccess, ExecutionFailure, AddedOwner, RemovedOwner, EnabledModule, ApproveHash
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

### 系统设计题 #1：Safe 多签提案聚合后端

> **场景**：safe-transaction-service
> **PoC 焦点**：收集 owner 链下签名，凑够 M 个后聚合上链 + REST/WS 通知
>
> 请用 [`../../_template/system_design.md`](../../_template/system_design.md) 模板填写完整 7 段（场景/规模/架构/Schema/API/Tradeoff/监控）+ 100-200 行 PoC。

#### 我的方案（在此填写或链接到独立 markdown）

> 例：参见 [`./W7_sd1_solution.md`](./W7_sd1_solution.md)


#### PoC 仓库（**本周必做**）

PoC 放在 `repos/_demos/W7_1_xxx/`

- [ ] 项目脚手架建好（5-8 个 Go 文件）
- [ ] 主流程跑通（happy path）
- [ ] README 写好（讲清"做什么/怎么跑/学到什么"）
- [ ] 推到 GitHub（链接：____________________）

---
### 系统设计题 #2：Safe Module 扩展开发

> **场景**：DAO Treasury 自动化工具
> **PoC 焦点**：写一个 Allowance Module，让链下 server 在限额内自动 exec
>
> 请用 [`../../_template/system_design.md`](../../_template/system_design.md) 模板填写完整 7 段（场景/规模/架构/Schema/API/Tradeoff/监控）+ 100-200 行 PoC。

#### 我的方案（在此填写或链接到独立 markdown）

> 例：参见 [`./W7_sd2_solution.md`](./W7_sd2_solution.md)


#### PoC 仓库（**本周必做**）

PoC 放在 `repos/_demos/W7_2_xxx/`

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
