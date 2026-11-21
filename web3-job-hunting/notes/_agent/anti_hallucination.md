# 防幻觉铁律（Anti-Hallucination）

> agent 的最大风险 = 凭"训练记忆"瞎讲合约里的函数 / 编造规模数字 / 假设库 API。
>
> 本文是 4 条不可破的铁律 + 高频陷阱清单。**任何工作开始前都要刷一遍。**

---

## 铁律 1：引用代码必须带 `startLine:endLine:filepath`

❌ **禁止**：

> Aave 的 `getUserAccountData` 返回了健康因子，逻辑大致是 `totalCollateralBase * liquidationThreshold / totalDebtBase`...

✅ **正确**：

先 Read 实际文件，再用代码引用块：

```123:140:web3-job-hunting/repos/lending/aave-v3-core/contracts/protocol/pool/Pool.sol
function getUserAccountData(address user) ...
// 真实代码贴在这里
```

→ **如果你没 Read 过文件，就不要讲文件里有什么。** 一律先 Read 再说。

---

## 铁律 2：写代码前必须 Read 验证

写 Go PoC 时，3 类东西**必须先验证**再写：

| 类别 | 验证方式 |
|---|---|
| **第三方库 API 签名** | `Read` 该库的源码 / `WebFetch` godoc / `mcp_context7` 拉文档 |
| **合约 ABI 函数签名** | `Read` ABI JSON 文件 或 直接 Read `.sol` 接口文件 |
| **Go 包模块路径** | `Read` 用户项目的 `go.mod` 或 `go.sum` 确认版本 |

❌ **禁止**：

> 用 `client.SubscribeFilterLogs(ctx, query, ch)` 订阅事件...（凭记忆写）

✅ **正确**：

先 Read `repos/.../go-ethereum/ethclient/ethclient.go` 找到该方法的真实签名，再写。

> 特别注意：**go-ethereum / web3.js / ethers.js 的 API 在不同大版本之间会重命名**。不许靠记忆。

---

## 铁律 3：规模估算的数字必须有来源

写"系统设计 — 规模估算"段时：

❌ **禁止**：

> 假设 10 万用户 / QPS 5000 / 每天 1TB 数据...

✅ **正确**：

每个数字都要标明出处：

> - **10 万用户** — 来源：Aave 官方 dashboard，2024 Q3 active borrower 约 8 万（往上保守估）
> - **QPS 5000** — 来源：取参照系 Etherscan 公开 QPS（约 3000）×1.7 缓冲
> - **1TB/天** — 推导：100 个 Pool × 平均 5000 events/天 × 200 字节 ≈ 100MB/天，10x 索引膨胀 ≈ 1GB（**这里我之前的"1TB"高估了，已修正**）

→ 重点：**承认推导来源 + 主动检查推导是否离谱**。允许范围估算（`5k-10k QPS`），不允许凭空数字。

---

## 铁律 4：拿不准就停下问

任何时候发现：

- 用户的指令有歧义（"做下 W3" — 是业务速读还是系统设计？）
- 你需要做一个**架构决策**（"用 Postgres 还是 ClickHouse？"）
- 用户的仓库里**找不到你预期的文件**（可能版本对不上）
- 你**不确定某个 Web3 概念**（"liquidation bonus 跟 close factor 是同一个东西吗？"）

**立刻停下，问用户**。绝对不要"先写了再说"。

> 用户原话："**宁愿等你问，也不愿你瞎写**"

---

## 高频陷阱清单（已踩过 / 容易踩）

### Web3 概念陷阱

| 陷阱 | 正确做法 |
|---|---|
| 把 Aave V2 的机制当 V3 讲（V3 引入 eMode / Isolation 等新概念）| 明确指明版本，参考 V3 文档 |
| 把 Uniswap V2 的恒定乘积公式当 V3 讲（V3 是 concentrated liquidity）| 永远区分 V2/V3/V4 |
| 把"健康因子 < 1 触发清算"简化为"价格跌就清算" | 健康因子涉及 LTV / Liquidation Threshold / Liquidation Bonus 多个参数 |
| MakerDAO 的 DAI 被混称为"算法稳定币" | DAI 是 CDP 超额抵押稳定币，与 UST 等算稳是两码事 |
| 把 stETH 的"rebase"理解成"代币数量变" | stETH 是 rebase token，余额每天变；wstETH 是包装版，余额不变价格变 |
| MPC 跟多签混为一谈 | MPC 是单一私钥分片签名（链上看到单签），多签是多个独立私钥（链上看到 N-of-M）|

### 工程陷阱

| 陷阱 | 正确做法 |
|---|---|
| 直接用 `eth_subscribe` 假设 RPC 一定支持 WS | 公开 RPC 大多只给 HTTP，要么自建节点要么用 Alchemy/QuickNode |
| 假设事件按区块顺序到达 | reorg 会让旧区块事件"消失/重发"，必须 reorg 处理 |
| 假设一个 RPC 永远活着 | 必须 multi-RPC fallback + 超时 + 降级 |
| 用 `time.Now()` 当事件时间 | 必须用 `block.timestamp`（链上时间），不然时区问题 + 误差 |
| 用 `int64` 存 wei | 24 小时内必爆，必须 `*big.Int` 或 `decimal.Decimal` |
| Postgres 用单表存所有事件 | 千万级以上必须分区（按区块号 / 按合约地址）|

### Go 工程陷阱

| 陷阱 | 正确做法 |
|---|---|
| 凭记忆用 `go-ethereum` 旧版 API（`bind.NewKeyedTransactor` 已 deprecated）| Read `accounts/abi/bind/auth.go` 用 `NewKeyedTransactorWithChainID` |
| `decimal.Decimal` 直接用 `float64` 转 | 必须 `decimal.NewFromBigInt(weiBigInt, -18)` |
| context 不传超时 | RPC 调用 100% 必须 `context.WithTimeout` |
| goroutine 泄漏 | 任何 goroutine 必须有退出条件（ctx.Done / channel close） |

---

## 不确定时的求证流程

```
1. Read 相关文件 → 拿到真实签名 / 真实参数
   ↓ 还是不确定
2. WebFetch 官方文档 → 找权威说法
   ↓ 还是不确定
3. 跟用户说："我对 X 不确定，三个候选答案是 A/B/C，倾向 A 因为 ___，你选哪个？"
   ↓
4. 等用户拍板后再写
```

---

## 触发"危险信号"的关键词（你说出这些词时立刻警觉）

- "**大致**" / "**应该**" / "**好像**" / "**记得是**" → 你正在凭记忆，立刻 Read 验证
- "**假设规模**" / "**估计**" → 标注来源，否则改成区间
- "**通常这样实现**" → 这是模式而非事实，但要明确是"我建议"还是"该项目实际"

---

## 如果用户挑战你"这个对吗？"

**正确反应**：

1. 立刻承认不确定
2. Read 真实文件 / WebFetch 官方文档
3. 给出修正后的答案

❌ **错误反应**：

- 嘴硬辩护
- 编更多细节"加固"原答案
- 转移话题

---

## 最后一条：知识截止

你的训练数据有截止日期。Web3 协议升级很快：

- Uniswap **V4** 已经发布（2025），但社区仍在用 V3
- Aave **V3.2** 引入了 eMode 修订
- dYdX 从 V3（StarkEx）迁到 **V4**（Cosmos SDK）—— 完全两套架构！
- LayerZero **V2** 与 V1 编程模型不同
- Pendle **V2** 与 V1 数学模型不同

→ **本项目用的版本以 [`inventory.md`](./inventory.md) 列出的仓库为准**，不要假设。
