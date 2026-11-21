# 简历每周一行更新区

> **用法**：每周收官（D7 周日内化）时，agent 帮你在末尾追加 1 行。
>
> **格式**：`- W{N} {project}: {这周做了什么 + 1 个最亮点}`
>
> **风格示范**（W2 已示范）：聚焦"做了什么"+"具体规模/技术亮点"。
> **不要写**："学习了 / 了解了 / 接触了" 这类模糊表达。

---

## 累积清单（按完成顺序追加）

- W2 Aave V3: 完成借贷协议健康因子实时监控系统设计 + 清算机器人架构方案，独立实现 Go PoC（Listener + Calculator + Notifier 三模块），覆盖 10 万用户规模 + reorg 处理 + Webhook 重试，开源至 GitHub  ← **示范行（用户完成 W2 后由 agent 改写真实链接）**

> 下方 ⬇ 留给后续 7 周追加

<!--
- W1 Uniswap V3: ___
- W3 MakerDAO: ___
- W4 Lido: ___
- W5 dYdX V4: ___
- W6 tss-lib: ___
- W7 Safe: ___
- W8 ___: ___
-->

---

## 简历段汇总（W8 完成后的最终版本）

> agent 在 W8 收官时，把上面 8 行整合成一段连贯的简历项目描述，贴到 [`resume_template.md`](./resume_template.md) 的"项目经验"段。
>
> **整合模板**：
>
> > **Web3 后端体系研究项目（个人项目，2026.05 - 2026.07）**
> >
> > 系统拆解 8 个 Web3 主流协议（Uniswap V3 / Aave V3 / MakerDAO / Lido / dYdX V4 / Binance tss-lib / Safe / ___）的业务，独立完成 16 套系统设计方案 + 3 个开源 Go PoC，技术覆盖：
> >
> > - **DeFi 业务建模**：AMM 报价 / 借贷健康因子 / CDP 风险监控 / LST rebase / 永续 funding
> > - **链上数据工程**：go-ethereum 事件订阅 / multi-RPC fallback / reorg 处理 / 增量扫块
> > - **后端架构**：Postgres + Redis 分层存储 / Kafka 事件流 / gRPC + WebSocket 服务
> > - **托管与多签**：MPC TSS（基于 binance/tss-lib）/ Safe 多签 Module 扩展
> >
> > **3 个核心开源 Demo（GitHub 公开）**：
> > 1. aave-health-monitor — 10 万用户级健康因子实时监控
> > 2. erc20-indexer — 任意 ERC20 合约链上 indexer
> > 3. mpc-keygen-grpc — 3-of-3 MPC 钱包 keygen gRPC 服务

---

## 简历更新的硬规则

| 规则 | 原因 |
|---|---|
| **每行必须有具体技术栈** | 招聘官扫简历是"找关键词"，不写技术 = 看不到 |
| **每行必须有数字** | 10 万用户 / 100ms 延迟 / 3 模块 / 200 行代码 |
| **不要重复 keyword** | 8 行里如果都写"go-ethereum"，等于一个都没写 |
| **最后一行必须最强** | W8 选定差异化方向，把它放最后压轴 |
