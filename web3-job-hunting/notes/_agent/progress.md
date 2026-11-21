# 进度追踪（Progress）

> **agent 每次开工前先读这里。每周收官时更新这里。**
>
> 这是整个项目唯一的"事实之源"（single source of truth），其他文档都不要重复进度信息。

---

## 当前状态（每周更新一次）

```yaml
当前周:        W1                          # W1 / W2 / ... / W8
当前 Stage:    Stage 1 (DeFi 基础)          # Stage 1 / 2 / 3
当前步骤:      D1 业务速读尚未开始            # D1 / D2 / D3 / D4 / D5 / D7
最近更新:      2026-05-12                  # 用户每次推进自己改
下一个里程碑:  W1 周日内化（D7）
```

> **agent 操作规则**：每次完成一个步骤，问用户"是否更新 progress.md 当前步骤为 ___ ？"再改。

---

## 8 周进度总表

| 周 | 项目 | 业务卡 | 系统设计 #1 | PoC #1 | 系统设计 #2 | PoC #2 | 简历段 | 状态 |
|---|---|---|---|---|---|---|---|---|
| **W1** | Uniswap V3 | ⬜ | ⬜ | ⬜ | ⬜ | ⬜ | ⬜ | 🟡 进行中 |
| **W2** | Aave V3 | ⬜ | ⬜⭐示范已写 | ⬜ | ⬜ | ⬜ | ⬜ | ⏸ 待开始 |
| **W3** | MakerDAO | ⬜ | ⬜ | ⬜ | ⬜ | ⬜ | ⬜ | ⏸ 待开始 |
| **W4** | Lido | ⬜ | ⬜ | ⬜ | ⬜ | ⬜ | ⬜ | ⏸ 待开始 |
| **W5** | dYdX V4 | ⬜ | ⬜ | ⬜⭐核心 Demo #2 | ⬜ | ⬜ | ⬜ | ⏸ 待开始 |
| **W6** | tss-lib | ⬜ | ⬜ | ⬜⭐核心 Demo #3 | ⬜ | ⬜ | ⬜ | ⏸ 待开始 |
| **W7** | Safe | ⬜ | ⬜ | ⬜ | ⬜ | ⬜ | ⬜ | ⏸ 待开始 |
| **W8** | 三选一 | ⬜ | ⬜ | ⬜ | ⬜ | ⬜ | ⬜ | ⏸ 待开始 |

> 标记说明：⬜ 未做 / 🟡 进行中 / ✅ 完成 / ❌ 跳过

---

## 核心 Demo 进度（简历重点项）

| Demo | 哪周 | GitHub 链接 | README 完成 | 主流程跑通 | 状态 |
|---|---|---|---|---|---|
| **#1 aave-health-monitor** | W2 | _____________ | ⬜ | ⬜ | ⏸ |
| **#2 erc20-indexer** | W5 | _____________ | ⬜ | ⬜ | ⏸ |
| **#3 mpc-keygen-grpc** | W6 | _____________ | ⬜ | ⬜ | ⏸ |

---

## Stage 收官检查（W4 / W7 / W8 末尾走一次）

### Stage 1（W1-W4 完成后，写于 ____）

- [ ] W1-W4 全部 8 套系统设计完成
- [ ] aave-health-monitor PoC 推到 GitHub
- [ ] resume_template.md 已填 Stage 1 内容
- [ ] interview_stories.md 已填 4 个项目的讲述脚本
- [ ] 镜子练习：能 5 分钟讲清任一题

### Stage 2（W5-W7 完成后，写于 ____）

- [ ] W5-W7 全部 6 套系统设计完成
- [ ] erc20-indexer + mpc-keygen-grpc 推到 GitHub
- [ ] resume_template.md 已填 Stage 2 内容
- [ ] interview_stories.md 已填 3 个项目的讲述脚本
- [ ] 镜子练习：能 5 分钟讲清任一题

### Stage 3（W8 完成后，写于 ____）

- [ ] W8 选定方向（① / ② / ③）= ____
- [ ] W8 全部 2 套系统设计完成
- [ ] 1 篇前沿叙事博客发布
- [ ] resume_template.md 已填 W8 内容
- [ ] **简历整体定稿**，可以海投

---

## 历史里程碑（用户每完成一周记一行）

| 日期 | 完成事项 | 备注 |
|---|---|---|
| 2026-05-12 | v4 学习地图锁定 + 8 周笔记占位 + W2 示范方案 | 由前一个 agent 完成 |
| 2026-05-12 | 创建 `_agent/` 工作手册 + `resume/` 简历构建区 | agent 交接 |
| 2026-05-17 | reporter.py 加完整中文 JD 展开块 + 修飞书段字段 bug | 用户硬要求 |
| 2026-05-17 | feishu_sync.py 加列错位检测（自动纠正 604 行被填表人填错列的数据） | 数据修复 |
| 2026-05-17 | translator.py 加 socket timeout + 分批 limit + ETA 心跳 + 失败保留英文不阻塞 | 防卡死 |
| 2026-05-17 | update.py 改成无条件跑翻译（不再"无新增就跳过"） | 防英文残留 |
| 2026-05-17 | ATS 70/70 ✅ + 飞书 356/356 ✅ 中文 JD 全完成；TG/web3career/GitHub 后台跑中 | 进度持续 |
| 2026-05-21 | **W1 sd2 数据层**：在本地 v3-subgraph 加 NonfungiblePositionManager 索引（B-2 路线，223 仓位 + 441 事件已验证），LP 收益看板数据完全可查；接手指南见 `repos/dex/uniswap-v3-subgraph/local-stack/B2_NPM_EXTENSION.md` | 为 sd2 系统设计扫清数据缺口 |
| 2026-05-21 | **W1 sd2 升级到生产级**：放弃自造 PoC，clone Revert Finance subgraph 本地部署（v2-coldstart-patch，IPFS Qm…oraM）。修了 4 个 handler 的 cold start bug（10 行 null check + early return），index 251 entity 跑通 healthy。识别出 Revert vs Uniswap 官方 schema 关键差异（Revert 在 PositionSnapshot 固化 derivedETH+ethPriceUSD），数据源用本地 + The Graph 官方双源；详见 `repos/dex/uniswap-v3-subgraph/local-stack/B_PATH_QUERIES.md` | 校准"不造玩具，引用生产实现"原则；待用户补 The Graph API key |
| 2026-05-21 | abigen v1.17.3 装好、pnpm 装好；扫了 W2-W7 各仓库依赖管理工具；停 graph-node stack 释放机器；W2-W7 环境就绪报告未生成（被 Revert 修 bug 这一线占用） | 后续 W2-W7 环境检查继续 |
| 2026-05-21 | **W1 + 双源数据对照完成**：本地 Revert v2-coldstart-patch 跑通 + The Graph 官方 V3 API key 配好；同一 Position id `1288697` 链上原生字段 7 个字节级一致；WLD/WETH 1% 池 $20-30K LP 仓位案例可用作 W1 周日内化素材；查询脚本 `repos/dex/uniswap-v3-subgraph/local-stack/B_PATH_QUERIES.md` | W1 数据层全部 ready |
| 2026-05-21 | **W2-W7 环境就绪度报告完成**：W1/W2/W5/W6 ✅ 完全就绪；W3 ⚠️ Python 3.13 不兼容 web3 5.12（需 pyenv 3.8 或仅读源码）；W4 ⚠️ 需补装 poetry；W7 ⏸️ Python 重型按需装。报告见 `notes/_agent/env_readiness.md` | 8 周环境进入"按周激活"阶段 |
| YYYY-MM-DD | W1 业务卡完成 | |
| YYYY-MM-DD | W1 系统设计 #1 完成 + PoC | |
| ...      |  | |

---

## 卡住时的求救表

| 症状 | 应对 |
|---|---|
| 业务速读读不懂某个机制 | 优先官方文档，再问 agent，**不要直接读源码细节** |
| 系统设计架构想不出来 | 对照 [`W2_sd1_health_monitor_solution.md`](../weekly/backend/W2_sd1_health_monitor_solution.md) 的 7 段结构套 |
| Go PoC 卡住 | 让 agent 先写 happy path 100 行（不要追求生产级），跑通再扩 |
| 时间不够 | 优先级：业务卡 > 系统设计 #1 + PoC > 系统设计 #2 PoC > 系统设计 #2 完整文档 |
| 一周没做完 | 不延期，直接进下周。落下的 PoC 后续 W5/W6/W8 后补 |

---

## 给 agent 的硬规则

1. **不要主动改"当前周"** — 等用户明确说"我这周做完了" 再改
2. **不要给用户加任务** — 8 周清单已锁定，加任务等于让用户做不完
3. **每完成一个产出**（业务卡 / 系统设计 / PoC），追问 4 件事是否做：
   - 进度表勾选
   - 简历 one-liner 追加
   - interview_stories 段填写
   - resume_template 段填写
