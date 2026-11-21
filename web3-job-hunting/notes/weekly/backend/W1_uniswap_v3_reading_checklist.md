# W1 — Uniswap V3 逐文件导读清单（进度跟踪）

> 配套主笔记：[`W1_uniswap_v3.md`](./W1_uniswap_v3.md)  
> 配套路线：[`learning_roadmap_v4_backend_first.md`](../../../reports/learning_roadmap_v4_backend_first.md)  
> 仓库根：`repos/dex/`  
> 官方文档：<https://docs.uniswap.org/concepts/protocol/concentrated-liquidity>

**总原则**：只抠接口与数据流，不抠定点数证明。  
**读序**：事件从哪来 → 怎么入库 → 怎么定价 → 怎么选路。

---

## 进度总览

| 段 | 内容 | 预估 | 状态 |
|---|---|---|---|
| 第 0 段 | 建立地图 | 30 min | ⬜ 未开始 |
| 第 1 段 | 链上真相（core + periphery） | ~2h | ⬜ 未开始 |
| 第 2 段 | Indexer（subgraph + Revert） | ~3h | ⬜ 未开始 |
| 第 3 段 | 定价（pricing + SDK） | ~1.5h | ⬜ 未开始 |
| 第 4 段 | 选路（smart-order-router） | ~2h | ⬜ 未开始 |
| 周末内化 | 两道系统设计题口述 | — | ⬜ 未开始 |

> 状态建议：⬜ 未开始 / 🔄 进行中 / ✅ 已完成

**最近一次推进**：_（日期 + 读到哪）_

---

## 第 0 段（30 分钟）— 先建立地图

- [ ] 读 [`W1_uniswap_v3.md`](./W1_uniswap_v3.md) 的 A–E 段（本周打哪 / 不打哪 / 两道题）
- [ ] 读 [Concentrated Liquidity](https://docs.uniswap.org/concepts/protocol/concentrated-liquidity)（业务概念，不跟源码对行）

**读完自检**

- [ ] 能用一句话说清 Alice swap / Bob LP 分别碰哪些层

**本段备注**

> 

---

## 第 1 段（约 2h）— 链上真相：事件从哪来

路径根：`repos/dex/uniswap-v3-core/`

### 1.1 🔴 必读 `contracts/UniswapV3Pool.sol`

- [ ] 状态字段：`slot0` / `liquidity` / `feeGrowthGlobal*` / `ticks` / `positions`（对照 DB / 缓存 schema）
- [ ] `initialize`（~308）— 池子出生
- [ ] `mint`（~499）— LP 加仓 → `Mint`
- [ ] `burn`（~570）— LP 减仓 → `Burn`
- [ ] `collect`（~537）— 收手续费 → `Collect`
- [ ] `swap`（~659）— 交易核心 → `Swap`（**最重要**）

**读法**：只记 public 签名 + emit 的 event 字段；`swap` 内部循环、Q64.96 证明先跳过。

**读完能讲**

- [ ] Indexer 至少要订阅哪 5 个 event？
- [ ] 每个 event 更新哪张表？

### 1.2 🟡 速览（各 10–15 分钟）

- [ ] `contracts/UniswapV3Factory.sol` — `createPool` + `PoolCreated`（跳过部署细节）
- [ ] `contracts/libraries/Position.sol` — Position key / feeGrowth 字段
- [ ] `contracts/libraries/TickMath.sol` — 只看签名：`getSqrtRatioAtTick` / `getTickAtSqrtRatio`
- [ ] `contracts/libraries/SqrtPriceMath.sol` — 只看签名：给 amount 算价格变化
- [ ] `contracts/libraries/SwapMath.sol` — 只看签名：单步 swap 输入输出

### 1.3 🟡 外围入口（用户不直接调 Pool）

路径：`repos/dex/uniswap-v3-periphery/`

- [ ] `contracts/NonfungiblePositionManager.sol` — `mint` / `increaseLiquidity` / `decreaseLiquidity` / `collect` / `Transfer`
- [ ] `contracts/SwapRouter.sol` — 扫一遍：用户意图如何转成对 Pool 的 `swap`

**读完能讲**

- [ ] Bob 的 LP 仓位为什么是 NFT？
- [ ] Indexer 该盯 Pool 还是盯 NPM？

**本段备注**

> 

---

## 第 2 段（约 3h）— Indexer：事件怎么变成可查数据

路径根：`repos/dex/uniswap-v3-subgraph/`  
**严格按序读，不要并行乱跳。**

### 2.1 官方 subgraph 主线

- [ ] 1. `src/v3/schema.graphql` — `Pool` / `Token` / `Swap` / `Tick` / `Position`（Postgres DDL 草稿）
- [ ] 2. `src/v3/mappings/factory.ts` — `PoolCreated` → 建 Pool/Token
- [ ] 3. `src/v3/mappings/initialize.ts` — 池子首次定价
- [ ] 4. 🔴 `src/v3/mappings/swap.ts` — **整文件**：更新 pool 价格、volume、tick（报价缓存失效入口）
- [ ] 5. `src/v3/mappings/mint.ts` — 加流动性
- [ ] 6. `src/v3/mappings/burn.ts` — 减流动性
- [ ] 7. `src/v3/mappings/collect.ts` — 收 fee
- [ ] 8. `src/v3/mappings/intervalUpdates.ts` — Hour/Day 聚合（时序表设计）
- [ ] 9. `src/common/position.ts` — Position 实体怎么组装
- [ ] 10. `src/v3/mappings/position-manager.ts`（若有）— NPM 事件 → Position（LP 看板主路径）

### 2.2 Revert 对照（同一业务，不同 schema 取舍）

路径根：`repos/dex/uniswap-v3-subgraph-revert/`

- [ ] `schema.graphql` — Position / PositionSnapshot 字段差异
- [ ] `src/mappings/position-manager.ts` — cold start / null check 的生产级写法
- [ ] `src/mappings/core.ts` — Pool 事件处理对照官方

**读完能讲**

- [ ] 一条 `Swap` 进 subgraph 后，改了哪些 entity？
- [ ] 官方 vs Revert：LP 看板该抄谁的 schema？

**本段备注**

> 

---

## 第 3 段（约 1.5h）— 定价：报价公式从哪来

### 3.1 🔴🔴 王炸 `src/common/pricing.ts`

路径：`repos/dex/uniswap-v3-subgraph/src/common/pricing.ts`

- [ ] `sqrtPriceX96ToTokenPrices`（~11）— `sqrtPriceX96` → token0/token1 价格
- [ ] `getEthPriceInUSD`（~23）— ETH 锚定 USD
- [ ] `findEthPerToken`（~39）— 任意 token → ETH（再转 USD）
- [ ] `getTrackedAmountUSD`（~98）— 成交额如何计入 TVL/volume

**读法**：把这 4 个函数当成「要翻译成 Go 的规格书」；每函数画一张输入→输出表。

**读完练习**

- [ ] 手算：已知某池 `sqrtPriceX96` + 两边 decimals → token1/token0 价格

### 3.2 🟡 SDK 对照（链下官方实现）

路径：`repos/dex/uniswap-v3-sdk/src/`

- [ ] `entities/pool.ts` — `getOutputAmount` / `getInputAmount`
- [ ] `entities/route.ts` — 多跳路径怎么串池子
- [ ] `entities/trade.ts` — Trade 对象怎么表达一笔交易
- [ ] `quoter.ts` — 与链上 Quoter 的关系（扫一眼）

**读完能讲**

- [ ] `pricing.ts` vs SDK `Pool.getOutputAmount`：各自服务谁（索引聚合 vs 精确报价）？

**本段备注**

> 

---

## 第 4 段（约 2h）— 选路：聚合器怎么找最优路径

路径根：`repos/dex/smart-order-router/src/`  
**只读 Alpha Router 主链，不要钻进 100+ provider 文件。**

- [ ] 1. `routers/router.ts` — Router 接口：输入/输出长什么样
- [ ] 2. `routers/alpha-router/alpha-router.ts` — `route()` 主流程：候选池 → 算路 → 报价 → 选优
- [ ] 3. `routers/alpha-router/functions/get-candidate-pools.ts` — 候选池从哪来
- [ ] 4. `routers/alpha-router/functions/compute-all-routes.ts` — 如何枚举多跳
- [ ] 5. `routers/alpha-router/quoters/v3-quoter.ts` — V3 报价怎么算
- [ ] 6. `routers/alpha-router/functions/best-swap-route.ts` — 多条 route 里选最优（含 split）
- [ ] 7. `providers/v3/pool-provider.ts` — 池状态怎么拉取/缓存（后端缓存设计对照）

**读完能讲**

- [ ] 「百万 QPS 报价」里，什么必须缓存？什么必须实时？
- [ ] 新 `Swap` event 来了，哪一层缓存要失效？

**本段备注**

> 

---

## 推荐日程（对齐 W1）

| 天 | 读哪段 | 当天产出 | 完成 |
|---|---|---|---|
| D1 | 第 0 + 第 1 段 | 业务故事卡 + event 清单 | [ ] |
| D2 | 第 2 段（factory→swap→interval） | 画出「event → entity」表 | [ ] |
| D3 | 第 2 段（mint/burn/collect/position）+ Revert | LP 看板 schema 草稿 | [ ] |
| D4 | 第 3 + 第 4 段 | 报价公式手算 + Alpha Router 流程图 | [ ] |
| 周末 | 对着两道系统设计题口述 | 不看笔记讲 3 分钟 | [ ] |

---

## 周末内化 — 镜子口述模板

每段结束用这 4 问自检；周末串起来讲两道系统设计题。

1. **信号**：链上哪个合约、哪个 event？
2. **落库**：改了哪些字段/表？
3. **消费**：报价 API / LP 看板怎么用这些字段？
4. **坑**：reorg、cold start、缓存脏读会出什么问题？

### 题 #1 — DEX 聚合器报价缓存系统

- [ ] 能讲 Listener / Cache / Quoter API 三模块
- [ ] 能讲 reorg 12 块 buffer + 缓存原子更新

### 题 #2 — LP 收益看板

- [ ] 能讲 Indexer / Aggregator / Time-series / API 四模块
- [ ] 能讲 `feeGrowthInside*LastX128` 差值跟踪思路

---

## 明确不要读（省时间）

- [ ] ~~`SqrtPriceMath` / `TickMath` 的证明与汇编优化~~（已刻意跳过）
- [ ] ~~`interface` 前端、`universal-router` 全量编译细节~~
- [ ] ~~`smart-order-router` 里 V2/V4/mixed 全部 quoter~~（先吃透 V3）
- [ ] ~~subgraph 的 `v3-tokens/` 旁路~~（先主线 `v3/`）

---

## 变更记录

| 日期 | 动作 |
|---|---|
| 2026-08-25 | 初版：四段导读 + 勾选进度 + 日程对齐 W1 |
