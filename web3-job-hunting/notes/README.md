# 内化笔记区

> 配套 [`reports/learning_roadmap_v3_universal.md`](../reports/learning_roadmap_v3_universal.md) 的产出脚手架。
>
> **目的**：每周读完一个项目，把"读过"沉淀成"能讲 + 能写 + 能写在简历"。
>
> **铁律**：**没写笔记 = 没读过**。下周不许开新项目。

---

## 目录结构

```
notes/
├─ _template/              ← 模板（每周 copy 一份）
│  ├─ business_card.md      业务故事卡（300 字，1 段话讲清协议）
│  ├─ weekly_qa.md          5 题答案（每题 200 字，含 tradeoff 论述）
│  └─ demo_readme.md        Demo 仓库 README 模板
├─ weekly/                 ← 8 周笔记沉淀（W1-W8）
│  ├─ W1_uniswap_v3.md
│  ├─ W2_aave_v3.md
│  ├─ W3_makerdao.md
│  ├─ W4_lido.md
│  ├─ W5_dydx_v4.md
│  ├─ W6_binance_tss_lib.md
│  ├─ W7_safe.md
│  └─ W8_选1_eigenlayer_or_layerzero_or_pendle.md
└─ demos/                  ← 3 个 Demo 工程的 README + 复盘
   ├─ aave-demo.md           W2 产出（Go + go-ethereum）
   ├─ erc20-indexer-demo.md  W5 产出（Go + Postgres）
   └─ mpc-keygen-demo.md     W6 产出（Go + tss-lib）
```

---

## 每周日内化流程（30 分钟固定动作）

```
1. 把 _template/ 三个文件复制到 weekly/Wn_xxx.md
2. 读这周的代码笔记，填写：
   - 业务故事卡（5 分钟）
   - 5 题答案（15 分钟）
   - Demo README（5 分钟，仅 W2/W5/W6 周）
3. 对镜子讲 3 分钟（不看资料）
4. 简历"项目经验"末尾加一句（5 分钟）
```

---

## 自检通过线

每个 Stage 末尾（W4 / W7 / W8 末），对照 `reports/learning_roadmap_v3_universal.md` 第四节的"自检表"。任一项不通过 → **回去补，不许进下一 Stage**。
