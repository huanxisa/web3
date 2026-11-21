# 新 Agent 启动 Prompt 模板

> 用户开新 agent 会话时，**复制下面的某一段**直接发给 agent，避免重复历史对话。

---

## A. 通用启动（任何任务都先发这个）

```
请按顺序读这 5 个文件，然后告诉我：
1. 你理解的我的当前目标
2. 当前周 + 下一步建议
3. 你看到的防幻觉规则有哪些

文件清单（按顺序读）：
1. web3-job-hunting/notes/_agent/README.md
2. web3-job-hunting/notes/_agent/mission.md
3. web3-job-hunting/notes/_agent/progress.md
4. web3-job-hunting/notes/_agent/inventory.md
5. web3-job-hunting/notes/_agent/anti_hallucination.md

读完后等我下一条指令再动手，不要自作主张开始任何任务。
```

---

## B. 推进某周任务（已 onboarding 后用）

```
我准备做 W{N}（{project}），请：
1. Read web3-job-hunting/notes/weekly/backend/W{N}_{project}.md 看本周清单
2. 告诉我今天该做哪一段（D1 业务速读 / D2-D3 系统设计 #1 / D4 系统设计 #2）
3. 给我一个 30 分钟内可以完成的第一步小目标

注意防幻觉规则（_agent/anti_hallucination.md），任何代码引用必须 Read 后才能讲。
```

---

## C. 做系统设计题（已选定题目后用）

```
我开始 W{N} 的系统设计题 #{1 或 2}：{题目名}

请：
1. Read web3-job-hunting/notes/_template/system_design.md 看 7 段模板
2. Read web3-job-hunting/notes/weekly/backend/W2_sd1_health_monitor_solution.md 学习颗粒度
3. 跟我对话式产出：先问我"业务场景理解对不对" → "规模估算合理吗" → 一段一段做
4. 写完一段我确认后再进下一段，不要一次性产出全 7 段

最后帮我落地到 web3-job-hunting/notes/weekly/backend/W{N}_sd{1或2}_solution.md
```

---

## D. 写 PoC 代码（系统设计完成后用）

```
我要写 W{N} 系统设计 #{1或2} 的 Go PoC（{poc 名}）。

请：
1. Read web3-job-hunting/notes/weekly/backend/W{N}_sd{1或2}_solution.md 拿到方案
2. Read web3-job-hunting/notes/_template/demo_readme.md 看 PoC README 模板
3. 在 web3-job-hunting/repos/_demos/W{N}_{1或2}_{name}/ 下建项目骨架
4. 严格遵守 100-200 行约束，只覆盖核心模块的 happy path
5. 任何 go-ethereum / 第三方库 API，先 Read 验证再写（_agent/anti_hallucination.md 铁律 2）

完成后：
- README 写清"做什么 / 怎么跑 / 学到什么"
- 提示我在 _agent/progress.md 勾选完成
```

---

## E. 收官某周（D7 周日内化时用）

```
我完成了 W{N}。请帮我做 4 件事，每件做完都问我确认：

1. 在 web3-job-hunting/notes/_agent/progress.md 把 W{N} 行所有 ⬜ 改成 ✅，
   并把"当前周"推进到 W{N+1}
2. 在 web3-job-hunting/notes/resume/one_line_updates.md 末尾追加 1 行
   （格式：- W{N} {project}: 用一句话讲清这周做了什么）
3. 在 web3-job-hunting/notes/resume/interview_stories.md 找到 W{N} 段，
   帮我写 5 分钟讲述脚本（业务背景 1 分钟 / 系统设计 #1 2 分钟 / 系统设计 #2 2 分钟）
4. 在 web3-job-hunting/notes/resume/resume_template.md 项目经验段
   找到 W{N} 占位，填一段 3-5 行的简历项

每件做完贴给我看一眼，OK 我就说"OK"，不 OK 我会改。
```

---

## F. 简历定稿（W8 全部完成后用）

```
我完成了所有 8 周内化。请：

1. Read web3-job-hunting/notes/resume/resume_template.md 全文
2. Read web3-job-hunting/notes/resume/one_line_updates.md 全部 8 条
3. Read web3-job-hunting/notes/resume/interview_stories.md 全部 8 个项目
4. Read web3-job-hunting/notes/_agent/progress.md 看 3 个核心 Demo 的 GitHub 链接

做 3 件事：
- 把 resume_template.md 中所有 ___ 占位填完
- 检查整体项目段叙事是否连贯（DeFi → CEX/钱包 → 差异化）
- 给我一份纯 Markdown 的 1 页简历最终版（按"姓名/求职方向/技能/项目经验/工作经历"5 段）

之后我会拿去转 PDF 投递。
```

---

## G. 协助投递（简历完成后用）

```
我用完成的简历准备投递岗位。请：

1. Read web3-job-hunting/reports/jd_summary.md 全部命中岗位
2. 按"立即可投 + 远程 + 不强制英语 + 后端方向"过滤出 Top 30 岗位
3. 给我一份 markdown 投递清单（公司 / 岗位 / 投递入口 URL / 我简历的哪段最匹配）
4. 帮我起草一段通用的求职 cover letter（中英双版，300 字内）

投递记录我手工维护，不需要你管。
```

---

## H. 紧急救援（卡住 / 出错 / 困惑）

```
我现在卡住了：{描述具体卡点}。

请：
1. 先 Read web3-job-hunting/notes/_agent/progress.md 看我在哪一步
2. 不要给我加新任务，先帮我从当前卡点脱身
3. 如果是"完美主义陷阱"（追求生产级），提醒我"PoC 80% 颗粒度即可"
4. 如果是技术不确定（某个库怎么用），按 anti_hallucination.md 的求证流程做

直接给我下一个 30 分钟可执行的小动作。
```

---

## 使用建议

| 场景 | 用哪个模板 |
|---|---|
| 第一次开新 agent 会话 | A（通用启动） |
| 周一早上启动新一周 | A → B |
| 写系统设计 | C |
| 写 PoC 代码 | D |
| 周日晚上收官 | E |
| 完成 W8 后做简历 | F |
| 简历完成开始投递 | G |
| 任何时候卡住 | H |

> 💡 **小技巧**：每个新 agent 会话都先发 A，确保它进入状态。然后再发 B/C/D/E 中的某一个具体任务。
