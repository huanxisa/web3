# 简历（Web3 后端方向）— 模板版

> **使用说明**：
> - 所有 `___` 是占位符，每周完成对应内容后由 agent 填充
> - 完成 W8 后用 [`kickoff_prompt.md` 模板 F](../_agent/kickoff_prompt.md) 让 agent 做最终定稿
> - 最终输出 1 页 PDF 投递

---

## 基本信息

- **姓名**：___
- **联系方式**：___（手机 / 邮箱）
- **GitHub**：<https://github.com/___>
- **博客 / 个人站**：___（可选）
- **求职方向**：Web3 后端工程师（DeFi 协议后端 / CEX 钱包后端 / MPC 托管 / 链上数据平台）
- **工作偏好**：纯远程 / Hybrid 优先（中文友好团队）

---

## 一、技术栈

### 后端核心
- **语言**：Java（5+ 年主力）/ Go（独立完成 3 个 Web3 PoC）/ Python（脚本）
- **框架**：Spring Boot / Spring Cloud / Gin / gRPC
- **存储**：MySQL / PostgreSQL / Redis / Kafka
- **可观测**：Prometheus / Grafana / ELK
- **DevOps**：Docker / K8s / GitHub Actions

### Web3 链上集成
- **链上 SDK**：go-ethereum (`abigen` / `bind` / `ethclient`) / web3j
- **链上数据**：事件订阅 / RPC fallback / **reorg 处理** / The Graph subgraph
- **DeFi 业务**：AMM 报价 / 借贷健康因子 / CDP 风险监控 / LST rebase / 永续 funding
- **托管**：MPC TSS（基于 binance/tss-lib）/ Safe 多签 Module

---

## 二、项目经验

### 1. Web3 后端体系研究 — 8 个主流协议系统设计 + 3 个开源 PoC（2026.05 - 2026.07）

**项目背景**：从 884 个真实 Web3 后端 JD 的需求反推，系统拆解 8 个主流协议的业务，独立完成 16 套系统设计方案 + 3 个开源 Go PoC，沉淀从合约接口到后端系统的全链路工程能力。

**核心交付物**：

#### Demo 1: aave-health-monitor（W2 产出）
- **GitHub**：<https://github.com/___/aave-health-monitor>  ← W2 完成后填
- **业务**：监听 Aave V3 Borrow/Supply event，实时计算 10 万用户健康因子，<阈值触发 Webhook 告警
- **技术亮点**：
  - 用 `go-ethereum + abigen` 解码 Pool 合约事件
  - **多 RPC fallback** + **reorg 回滚** 处理链上数据可靠性
  - PostgreSQL + Redis 分层存储用户头寸 + 实时排行榜
  - Prometheus 暴露 `health_factor_below_1_total`、`rpc_lag_blocks` 等指标
- **简历对标岗位**：DeFi 钱包风控后端 / Aave/Compound 集成方

#### Demo 2: erc20-indexer（W5 产出）
- **GitHub**：<https://github.com/___/erc20-indexer>  ← W5 完成后填
- **业务**：扫描任意 ERC20 合约的 Transfer 事件 → Postgres，提供 REST 查询余额历史
- **技术亮点**：
  - **增量扫块** + 起停可恢复（断点续传）
  - **batch eth_getLogs** 优化（相比逐区块快 100x）
  - reorg 处理（保留最近 12 块原始数据，超过 finality 才落主表）
  - 支持任意 ERC20 contract 一键接入
- **简历对标岗位**：CEX 充提后端 / 链上数据平台 / Etherscan 类项目

#### Demo 3: mpc-keygen-grpc（W6 产出）
- **GitHub**：<https://github.com/___/mpc-keygen-grpc>  ← W6 完成后填
- **业务**：基于 binance/tss-lib 实现 3-of-3 ECDSA 分布式密钥生成，gRPC 暴露给业务系统
- **技术亮点**：
  - 3 个 party 协作 DKG（Distributed Key Generation），不出现完整私钥
  - 分片用 AES-GCM 加密 + Postgres 持久化（KMS 主密钥外部托管）
  - gRPC + 健康检查 + 超时重试
  - 单测覆盖"任 1 个 party 离线"的恢复场景
- **简历对标岗位**：MPC 钱包后端（Cobo / Safeheron / Fireblocks 类）/ 托管服务

#### 16 套系统设计方案（按周排列）

> 每套包含：场景 / 规模估算 / 架构图 / DB Schema / API 接口 / Tradeoff 论述 / 监控指标 / PoC 代码

- **W1 Uniswap V3**：DEX 聚合器报价缓存 / LP 收益看板
- **W2 Aave V3**：健康因子监控（Demo 1） / 清算机器人架构
- **W3 MakerDAO**：CDP 风险预警仪表盘 / 稳定费收取与分发后端
- **W4 Lido**：stETH rebase 推送系统 / Operator performance 数据 pipeline
- **W5 dYdX V4**：ERC20 indexer（Demo 2） / 持仓+K 线 WebSocket push
- **W6 tss-lib**：MPC keygen 服务（Demo 3） / MPC 签名调度器
- **W7 Safe**：多签提案聚合后端 / Safe Module 扩展开发
- **W8 ___**：___ / ___（W8 选定 ① EigenLayer / ② LayerZero / ③ Pendle 后填）

**8 篇业务故事博客**：<https://___>（可选，发完填）

---

### 2. ___（前一份工作的核心项目，按 STAR 法重写）

> 占位 — 你原来简历里最强的 1-2 个项目，按以下结构改写：

- **背景**：业务规模 / 团队规模 / 你的角色
- **挑战**：解决了什么具体问题（流量峰值 / 延迟降低 / 数据一致性 / ...）
- **方案**：用了什么技术 + 为什么这么选
- **结果**：可量化数字（QPS 提升 / 故障率下降 / 成本节省）

---

### 3. ___（第二份核心项目）

> 占位 — 同上结构

---

## 三、工作经历

### ___ 公司（YYYY.MM - YYYY.MM）— ___ 工程师

> 占位 — 1-3 段 bullet 描述，每段一个可量化成果

- ___
- ___
- ___

### ___ 公司（YYYY.MM - YYYY.MM）— ___ 工程师

- ___
- ___

---

## 四、教育背景

- ___ 大学 / ___ 专业 / ___ 学位（YYYY-YYYY）

---

## 五、Web3 知识深度（面试官想看的）

> 这一段是 **Web3 求职的"加分钩子"**，列你 8 周内化的知识广度

### DeFi 协议
- **DEX**：理解 Uniswap V3 集中流动性 / tick 范围 / position NFT / fee tier 设计
- **借贷**：理解 Aave V3 的 LTV / Liquidation Threshold / Liquidation Bonus / eMode 隔离模式
- **稳定币**：理解 MakerDAO CDP 模型 / 稳定费 jug.drip / 喂价 spotter / 拍卖清算机制
- **LST**：理解 Lido stETH rebase 机制 / oracle 报告 / Operator 节点性能指标
- **永续**：理解 dYdX V4 全链上撮合 / funding rate / margin 模型

### 链上工程
- **事件 indexer**：理解 reorg 处理 / 增量扫块 / multi-RPC fallback
- **链下计算**：能用 Go 复现 healthFactor / impermanentLoss / fee earned 等链上数学
- **WebSocket push**：理解订阅模型 / 心跳 / 断线重连 / back-pressure

### 托管与多签
- **MPC TSS**：理解 GG18/GG20 协议 / DKG / threshold signing / 不出现完整私钥
- **Safe 多签**：理解 owner threshold / Module 扩展 / Guard / 链下签名聚合上链

### 跨链与 L2（W8 选定后填）
- ___

---

## 六、其他

- **开源贡献**：3 个公开 Go PoC + 8 篇业务分析博客
- **语言**：英语（___ 等级 / 工作沟通可）/ 中文（母语）
- **可入职时间**：___

---

## 附：投递时的"一句话自我介绍"

> Java 后端 5 年 + Go 实战，独立完成 8 个 Web3 主流协议（Uniswap/Aave/Lido/dYdX/Safe/MPC...）的系统设计 + 3 个开源 PoC，能直接上手 DeFi 协议后端、CEX 充提、MPC 钱包托管这类岗位。GitHub: ___

---

## 维护说明

| 文件 | 何时改 |
|---|---|
| 本文件 | W2 / W4 / W6 / W8 收官时由 agent 填占位 |
| [`one_line_updates.md`](./one_line_updates.md) | 每周收官追加 1 行 |
| [`interview_stories.md`](./interview_stories.md) | 每周收官填 1 段 5 分钟讲述 |
