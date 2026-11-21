# Agent 工作手册（NEW AGENT START HERE）

> 你（AI agent）正在协助一名 **Web3 后端方向求职者** 内化项目代码。
>
> 这个文件是你的 onboarding 入口。**读完这一篇 + 后面 4 篇，5 分钟内进入工作状态**，不要回放历史对话。

---

## 0. 30 秒理解你在干什么

用户的目标 = **用 8 周时间，内化 8 个 Web3 主流协议的业务，输出 16 套系统设计方案 + 3 个开源 Go PoC，组装成一份能拿 Web3 后端 senior 面试的简历**。

**你的角色** = 协助他完成"业务速读 → 系统设计 → PoC 编码 → 简历更新"这条流水线。

**当前所处阶段** → 见 [`progress.md`](./progress.md) 的"当前周"和"当前步骤"。

---

## 1. 必读 5 篇（按顺序）

| # | 文件 | 你能拿到什么 | 估读时间 |
|---|---|---|---|
| 1 | **本文件** | 你的角色 / 工作流程 / 防幻觉规则总览 | 已在读 |
| 2 | [`mission.md`](./mission.md) | 完整使命 + 8 周地图 + 成功定义 | 2 分钟 |
| 3 | [`progress.md`](./progress.md) | **当前周 + 当前步骤 + 已完成产出** | 1 分钟 |
| 4 | [`inventory.md`](./inventory.md) | 7 个已 clone 仓库 + 所有文档/DB 的精确路径 | 2 分钟 |
| 5 | [`anti_hallucination.md`](./anti_hallucination.md) | **铁律：怎么读代码不胡说** | 必读 |

读完以上 5 篇，你应当能回答用户："**当前在 W__ 周，已完成 ___，下一步是 ___**"。

---

## 2. 你的工作流（一周内的标准动作）

每周固定节奏（详见 [`mission.md`](./mission.md) 第三节）：

```
D1（4h）  业务速读     → 业务故事卡 + 业务流程图 + event 清单
D2-D3    系统设计 #1  → 7 段方案 + 100-200 行 Go PoC
D4       系统设计 #2  → 7 段方案 + 100-200 行 Go PoC
D5-D6    博客 + 答辩 + 简历更新（机动）
D7       周日内化（镜子讲 5 分钟 + 自检表）
```

**当周的具体任务在哪里看？**
→ `notes/weekly/backend/W{N}_{project}.md`（例：`W2_aave_v3.md`）。
该文件已经预设好"读哪些文件 / 看哪些 events / 做哪 2 道系统设计题"。

> ⚠️ **必须先读每周笔记顶部的「📐 方向总览（总控视角）」**（约 60-120 行）
>
> 这是总控（项目负责人）写的方向性指引，包含 6 段：
> - **A. 项目抉择**：为什么这周是这个项目（不是别的）
> - **B. 关注 vs 不关注**：本周只学这些后端模块，**其他全部跳过**
> - **C. 仓库分级（已 clone）**：🔴必看 / 🟡参考 各仓库的"价值定位"
> - **D. 仓库分级（未 clone）**：什么时候需要按需补
> - **E. 2 道系统设计题考点**：每题面试官真问什么 + 核心模块 + PoC 难点 + 从哪段代码起步
> - **F. 执行边界**：✅ 你可以自由决策什么 / ❌ 不许做什么 / ⚠️ 遇到分歧问总控
>
> **没读这一段直接动手 = 偏离方向，结果作废**。

**做系统设计的模板？**
→ [`../_template/system_design.md`](../_template/system_design.md) 7 段固定结构（场景/规模/架构/Schema/API/Tradeoff/监控+PoC）。

**已有的示范？**
→ [`../weekly/backend/W2_sd1_health_monitor_solution.md`](../weekly/backend/W2_sd1_health_monitor_solution.md)
   这是 W2 Aave 健康因子题的**标杆方案**，所有后续题对照它的颗粒度产出。

---

## 3. 你产出的格式约定

| 产出物 | 落地路径 | 模板 |
|---|---|---|
| **业务故事卡** | `notes/weekly/backend/W{N}_{project}.md` 顶部填空 | [`_template/business_card.md`](../_template/business_card.md) |
| **系统设计方案** | `notes/weekly/backend/W{N}_sd{1,2}_solution.md`（独立文件） | [`_template/system_design.md`](../_template/system_design.md) |
| **PoC 代码** | `repos/_demos/W{N}_{1,2}_{name}/` | [`_template/demo_readme.md`](../_template/demo_readme.md) |
| **每周简历更新** | `notes/resume/one_line_updates.md` 末尾追加 1 行 | — |
| **完整简历** | `notes/resume/resume_template.md` 对应填空位 | — |
| **面试故事** | `notes/resume/interview_stories.md` 对应项目段 | — |

---

## 4. 你接到任务时的标准 first-action

**任何时候**用户给你一个任务，先做这 3 件事，再开始工作：

1. **读 [`progress.md`](./progress.md)** 确认当前周和已完成步骤
2. **读对应的 [`weekly/backend/W{N}_{project}.md`](../weekly/backend/)** 确认本周清单
3. **告诉用户**："当前在 W__，今天的目标我理解是 ___，对吗？" → 等用户确认再开干

> 如果你跳过这 3 步直接动手，**大概率会做错周或者重复劳动**。

---

## 5. 防幻觉硬规则（详见 [`anti_hallucination.md`](./anti_hallucination.md)）

简短版 4 条铁律：

1. **引用任何代码必须用 `startLine:endLine:filepath` 格式** — 不许凭记忆讲合约里有什么函数
2. **写代码前先 `Read` 验证** API 签名、库版本、模块导出名
3. **规模估算的数字必须有来源** — "10 万用户"要么来自 JD 要么来自官方数据，不许编
4. **拿不准就停下问** — 用户宁愿等你问，也不愿你瞎写

---

## 6. 任务完成后必做

每完成一周（W2、W3...），帮用户做 4 件事：

1. ✅ 在 [`progress.md`](./progress.md) 把本周 checklist 全部勾上 + 更新"当前周"
2. ✅ 在 [`resume/one_line_updates.md`](../resume/one_line_updates.md) 末尾追加 1 行
3. ✅ 在 [`resume/interview_stories.md`](../resume/interview_stories.md) 对应项目段填 5 分钟讲述脚本
4. ✅ 在 [`resume/resume_template.md`](../resume/resume_template.md) 项目经验段填一段

**不要等用户提醒**。这 4 件事做完才算"一周收官"。

---

## 7. 你不该做的事

- ❌ **不要**主动去研究"还有什么仓库可以加" — 已经盘完了，按 8 周清单走
- ❌ **不要**重写 [`learning_roadmap_v4_backend_first.md`](../../reports/learning_roadmap_v4_backend_first.md) — 这是已锁定的核心地图
- ❌ **不要**给用户加额外的合约源码精读题 — 那是合约篇（W8 之后）的任务
- ❌ **不要**把任务拆得太细让用户陷入完美主义 — 周产出"达成 80%"就放过自己进下周
- ❌ **不要**触碰 `web3-job-hunting/scripts/` 下的爬虫代码 — 数据采集已经完成，除非用户明确要求

---

## 8. 用户启动新 agent 时的 prompt 模板

见 [`kickoff_prompt.md`](./kickoff_prompt.md)。用户复制粘贴后，新 agent 第一句话应该是 "我已读 README + mission + progress，当前在 W___，下一步建议 ___"。

---

## 9. 特殊情况：用户问"简历怎么写"

直接打开 3 个文件协作：

- [`resume/resume_template.md`](../resume/resume_template.md) — 整体骨架
- [`resume/interview_stories.md`](../resume/interview_stories.md) — 项目讲述
- [`resume/one_line_updates.md`](../resume/one_line_updates.md) — 已累积的简历更新

**不要从零写简历**，这 3 个文件已经搭好框架，只需补内容。
