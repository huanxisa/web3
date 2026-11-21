# 使命总览（Mission）

## 一、用户是谁

- 一名 Java 后端工程师（Java 主力 5+ 年，Go 能写，Solidity 只读不写）
- 想转 Web3 后端 senior 岗（薪资优先 + 纯远程优先 + 不要求英语母语）
- 已有的优势：传统后端深度足够（Spring/分布式/中间件熟）
- 需要补：**Web3 业务理解 + 链上集成工程能力**

## 二、目标岗位（已数据验证）

来源：本项目 `web3-job-hunting/reports/jd_summary.md` 抓取的 884 个命中岗位。

| 岗位类型 | 命中数 | 优先级 |
|---|---|---|
| Web3 后端 / Backend Engineer | 520+ | ⭐ 主投 |
| Java / Golang Web3 后端 | 81 个语言级强匹配 | ⭐ 主投 |
| CEX 钱包 / 风控 / 数据后端 | 高 | ⭐ 主投 |
| Smart Contract Engineer | 11 | 副投（合约篇 W8 之后再说） |

## 三、成功的定义

完成 **8 周后端篇**后，简历能拿出：

- **3 个开源 Go PoC** 推到 GitHub（公开链接）
  - aave-health-monitor — 健康因子实时监控（W2 产出）
  - erc20-indexer — 链上事件 indexer（W5 产出）
  - mpc-keygen-grpc — MPC 钱包 keygen（W6 产出）
- **16 套系统设计方案** Markdown（架构图 + Schema + Tradeoff + 监控）
- **8 篇业务故事卡** 300 字讲清每个协议
- **1 份完整简历**（[`../resume/resume_template.md`](../resume/resume_template.md)）

→ 满足这 4 条 = **可以开始海投**。

## 四、8 周地图（一图秒懂）

```
┌─ Stage 1：DeFi 业务理解 + 后端设计（W1-W4，4 周）═══════════════
│   W1  Uniswap V3      → AMM 业务流 + DEX 报价缓存 + LP 收益看板
│   W2  Aave V3         → 借贷业务流 + 健康因子监控 + 清算机器人 ⭐示范周
│   W3  MakerDAO        → 稳定币业务流 + CDP 风险盘 + 稳定费分发
│   W4  Lido            → LST 业务流 + stETH rebase 推送 + Operator 监控
│   📦 Stage 1 收官 → 8 套系统设计 + Aave 健康因子 PoC
│
├─ Stage 2：CEX/钱包后端深耕（W5-W7，3 周）═══════════════════════
│   W5  dYdX V4         → 链上撮合业务流 + ERC20 indexer + WS push
│   W6  Binance tss-lib → MPC 业务流 + keygen gRPC + 签名调度器
│   W7  Safe            → 多签业务流 + 提案聚合后端 + Module 扩展
│   📦 Stage 2 收官 → 6 套系统设计 + indexer PoC + MPC keygen PoC
│
└─ Stage 3：差异化（W8，1 周，3 选 1）═══════════════════════════
    ① EigenLayer  ② LayerZero  ③ Pendle
    📦 W8 收官 → 2 套系统设计 + 1 篇前沿叙事博客

总计 = 16 套系统设计 + 3 个 PoC + 8 篇业务故事 = 简历核心段
```

## 五、每周节奏（固定模板）

| 时段 | 时长 | 动作 | 产出 |
|---|---|---|---|
| **D1** | 4h | 业务速读：读 public function + events + 业务文档 | 业务故事卡 + 业务流程图 + event 清单 |
| **D2-D3** | 8-10h | 系统设计 #1 + Go PoC（100-200 行） | 1 份 7 段方案 + 1 个可跑 PoC |
| **D4** | 4-5h | 系统设计 #2 + Go PoC（100-200 行） | 1 份 7 段方案 + 1 个可跑 PoC |
| **D5-D6** | 机动 | 博客 / 答辩 / 简历更新 | 博客 + 简历段 |
| **D7** | 30 分钟 | 周日内化（镜子讲 + 自检表） | progress.md 勾选完成 |

## 六、不该做的事

- ❌ 不要现在啃合约源码细节（chi 累积器/RAY 数学/scaledBalance）—— 那是合约篇
- ❌ 不要追求每道系统设计题"生产级完美" —— 80% 颗粒度即可，重点是数量×多样性
- ❌ 不要重复研究"还有什么仓库可以加" —— 8 周 8 项目已锁定
- ❌ 不要在 W2 之前折腾框架/脚手架 —— W2 示范周直接用

## 七、配套文档（v4 体系）

| 文档 | 作用 |
|---|---|
| [`../../reports/learning_roadmap_v4_backend_first.md`](../../reports/learning_roadmap_v4_backend_first.md) | **核心地图**（v4，已锁定，不要改）|
| [`../weekly/backend/W{N}_*.md`](../weekly/backend/) | 8 周个人笔记（每周已预设题目和清单）|
| [`../weekly/backend/W2_sd1_health_monitor_solution.md`](../weekly/backend/W2_sd1_health_monitor_solution.md) | **标杆方案**（所有后续题对照它的颗粒度）|
| [`../_template/system_design.md`](../_template/system_design.md) | 系统设计 7 段模板 |
| [`../_template/business_card.md`](../_template/business_card.md) | 业务故事卡模板 |
| [`../_template/demo_readme.md`](../_template/demo_readme.md) | PoC 仓库 README 模板 |

## 八、Stage 收官自检

每个 Stage 末尾（W4 / W7 / W8），全部勾上才算合格：

- [ ] 该 Stage 所有系统设计题完成（架构图 + Schema + Tradeoff + PoC）
- [ ] 对应核心 Demo 推到 GitHub（公开链接）
- [ ] [`progress.md`](./progress.md) 完成度更新
- [ ] [`../resume/resume_template.md`](../resume/resume_template.md) 项目段已填该 Stage 内容
- [ ] 镜子练习：能 5 分钟讲清该 Stage 任一题

→ 任一不通过，回去补，**不许进入下一 Stage**。
