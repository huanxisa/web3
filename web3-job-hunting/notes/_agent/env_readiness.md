# 各周环境就绪度报告（Env Readiness）

> 8 周项目所需的工具链 / 仓库 / 依赖的就绪状态。
> 每周开始前先看对应行，知道有什么坑要先填。
>
> 生成时间：2026-05-21
> 验证策略：**轻量化 — 不预装重依赖、不创建 PoC 脚手架、不动业务代码**

---

## 工具链总览

| 工具 | 版本 | 用途 | 状态 |
|---|---|---|---|
| **go** | 1.24.3 | W2 abigen 生 binding / W5 dydx / W6 tss-lib | ✅ |
| **abigen** | 1.17.3 | 合约 ABI → Go binding（W2-W8 所有 PoC 都用） | ✅ 装在 `~/go/bin/abigen` |
| **node** | 23.11.0 | W1 subgraph / W2 aave-utilities / W4 lido / W7 safe | ✅ |
| **npm** | 10.9.2 | 装合约项目 npm 包 | ✅ |
| **yarn** | 1.22.22 | W1 subgraph（Revert 用 yarn.lock） | ✅ |
| **pnpm** | latest | W5 dYdX indexer 用 pnpm workspaces | ✅ |
| **python3** | 3.13.3 | W3 / W4 / W7 Python 项目 | ✅ 主版本；W3 需补 3.8 |
| **pyenv** | ❌ 未装 | W3 auction-keeper 必须 Python 3.8 | ⚠️ **W3 前需装** |
| **poetry** | ❌ 未装 | W4 lido-oracle 用 poetry | ⚠️ **W4 前需装**（brew install poetry）|
| **docker** | 29.4.3 | W1 graph-node / W2 PoC 用的 PG+Redis+Kafka / W4 oracle | ✅ |
| **forge** | 1.5.1 | W3 makerdao-dss / W4 lido-dao foundry 部分 | ✅ |
| **jq** | 1.7.1 | ABI 抽取 + GraphQL 查询解析 | ✅ |

---

## 各周仓库 + 就绪度

### W1 — Uniswap V3 ✅✅ 完全就绪（已实战）

| 仓库 | 状态 | 说明 |
|---|---|---|
| `repos/dex/uniswap-v3-core/` | ✅ 源码可读 | 业务速读用，不需要 npm install |
| `repos/dex/uniswap-v3-subgraph/` | ✅ 本地索引完整可跑 | local-stack docker-compose 已调好，data volume 529MB 保留 |
| `repos/dex/uniswap-v3-subgraph-revert/` | ✅ **生产级模板，已 deploy 通过** | cold start patch 修了 4 个 handler；synced + healthy + 251 entities |
| The Graph 官方 Uniswap V3 端点 | ✅ API key 已配 | 用户 Free Plan 100K/月配额；查询脚本见 `local-stack/B_PATH_QUERIES.md` |

**W1 已交付**：
- 本地 Revert subgraph + 官方 Uniswap V3 **双源数据对照**完成
- 同一 Position id `1288697` 链上原生字段 7 个**字节级一致**
- WLD/WETH 1% 池 $20-30K LP 仓位案例可用

**下一步预热**：W1 周日内化时读 `repos/dex/uniswap-v3-subgraph-revert/src/mappings/` 的 4 个 handler 源码，对照已经跑出来的数据看 schema 设计取舍。

---

### W2 — Aave V3 ✅✅ 完全就绪

| 仓库 | 状态 | 说明 |
|---|---|---|
| `repos/lending/aave-v3-core/` | ✅ 源码可读 | hardhat 项目，**不必 npm install**（ABI 走 npm @aave/core-v3 拉）|
| `repos/lending/aave-protocol-subgraphs/` | ✅ 源码可读 | 学 indexer 处理 supply/borrow/liquidation 事件思路 |
| `repos/lending/aave-utilities/` | ✅ 源码可读 | `packages/math-utils/` 是 healthFactor 链下计算的 TS 实现，**翻译成 Go** = PoC #1 核心 |

**已验证**：
- `npm install @aave/core-v3@latest` 1 秒拿到完整 Pool.json artifacts
- Pool 合约 46 个函数 + 16 个 event 全有
- `abigen` 已生成 3910 行 Go binding（含 `GetUserAccountData / Supply / Borrow / Repay / Withdraw / LiquidationCall` 全部 W2 关键函数）

**W2 启动指令**（用户拿来就能跑）：
```bash
mkdir -p /tmp/w2-aave-probe && cd /tmp/w2-aave-probe
echo '{"name":"probe"}' > package.json
npm install @aave/core-v3@latest
jq '.abi' node_modules/@aave/core-v3/artifacts/contracts/protocol/pool/Pool.sol/Pool.json > Pool.abi.json
abigen --abi=Pool.abi.json --pkg=aavev3 --type=AaveV3Pool --out=AaveV3Pool.go
```

---

### W3 — MakerDAO ⚠️ Python 3.13 不兼容（需补 pyenv）

| 仓库 | 状态 | 说明 |
|---|---|---|
| `repos/stablecoin/makerdao-dss/` | ✅ 源码可读 | dapp.tools 老项目，源码学习就行 |
| `repos/stablecoin/makerdao-cdp-manager/` | ✅ 源码可读 | 同上 |
| `repos/stablecoin/makerdao-auction-keeper/` | ⚠️ **Python 不兼容** | requirements.txt 锁死 `web3==5.12.0`（2020-06 老版本，最高支持 Python 3.8） |

**问题**：本机 Python 3.13.3 装不上 `web3==5.12.0`（依赖链断），auction-keeper 跑不起来。

**两条路（W3 开始前先选）**：
- **A：装 pyenv + Python 3.8.18 专门给 W3**：
  ```bash
  brew install pyenv
  pyenv install 3.8.18
  cd repos/stablecoin/makerdao-auction-keeper
  pyenv local 3.8.18
  python -m venv .venv && source .venv/bin/activate
  pip install -r requirements.txt
  ```
- **B：跳过运行，只读源码 `auction_keeper/main.py`**：清算 keeper 业务逻辑 200 行读完，不必跑（W3 不是核心 Demo 周）

→ **推荐 B**（节省一上午时间）

---

### W4 — Lido ⚠️ 需装 poetry

| 仓库 | 状态 | 说明 |
|---|---|---|
| `repos/stablecoin/lido-dao/` | ✅ 源码可读 | hardhat + foundry mix，源码学习够用 |
| `repos/stablecoin/lido-oracle/` | ⚠️ **需 poetry** | pyproject.toml + python ^3.12（Python 3.13 兼容）|
| `repos/stablecoin/lido-subgraph/` | ✅ 源码可读 | TypeScript subgraph |

**W4 开始前装 poetry**：
```bash
brew install poetry
cd repos/stablecoin/lido-oracle
poetry install
```

**lido-oracle 依赖看点**：
- `web3 ^7.8.0`（新版）+ `prometheus-client`（监控）
- `oz-merkle-tree`（OpenZeppelin Merkle Tree，from git）
- `multiformats / dag-cbor / ipld-dag-pb`（IPFS 相关，oracle 用 IPFS 存验证者数据）

---

### W5 — dYdX V4 ✅ Go 部分就绪

| 仓库 | 状态 | 说明 |
|---|---|---|
| `repos/trading-engine/dydx-v4-chain/protocol/` | ✅ **Go deps 已下载（674MB）** | `x/clob/keeper` package build 通 |
| `repos/trading-engine/dydx-v4-chain/indexer/` | ⏸️ pnpm workspaces 未装 | 等 W5 进入时跑 `pnpm install` |
| `repos/trading-engine/lmax-disruptor/` | ✅ 源码可读 | Java 撮合参考，源码学就行 |

**W5 验证过的事**：
- Go 1.24.3 ≥ 要求 go 1.23.1 ✅
- `go mod download` 完成（GOMODCACHE 累积 674MB）
- `go build ./x/clob/keeper/` 通（撮合引擎核心 package）
- **没跑 `go build ./...`**（dydx 是 monorepo，全 build 会很久且没必要）

---

### W6 — Binance tss-lib ✅✅ 完全就绪

| 仓库 | 状态 | 说明 |
|---|---|---|
| `repos/mpc-wallet/binance-tss-lib/` | ✅ **go build ./... 全过** | 7 个 package（common/crypto/ecdsa/eddsa/protob/test/tss）都 build 通 |

**W6 直接可上手**：`go test ./ecdsa/keygen/ -v` 跑 MPC keygen 例子。

---

### W7 — Safe ⏸️ Python 重型，按需装

| 仓库 | 状态 | 说明 |
|---|---|---|
| `repos/innovation/safe-smart-account/` | ✅ 源码可读 | hardhat 项目，源码学就行 |
| `repos/innovation/safe-modules/` | ✅ 源码可读 | 同上 |
| `repos/innovation/safe-transaction-service/` | ⏸️ **超重型** | Python 3.13 ✅ 兼容，但依赖 30+ 包（Django + Celery + Redis + Postgres + S3） |
| `repos/innovation/safe-eth-py/` | ✅ Python 3.10+ + 轻量 | 只 5 个核心依赖，可装 |

**W7 推荐路径**：
- **safe-eth-py**（轻量）：进入 W7 时 `pip install -e .` 看 `gnosis/safe/` 核心 SDK
- **safe-transaction-service**（重型）：建议**只读源码** `safe_transaction_service/history/` 学 indexer 设计，**不在本地跑整个 web service**（生产级 Django + Celery + Redis 占资源大）

---

### W8 — 三选一（待决定）

| 方向 | 仓库 | 状态 |
|---|---|---|
| ① EigenLayer | `repos/innovation/eigenlayer-contracts/` + `eigensdk-go/` + `eigenda/` | 源码可读，go 项目可 build |
| ② LayerZero | `repos/bridge/layerzero-v2/` | 源码可读 |
| ③ Pendle | `repos/derivatives/pendle-core-v2/` | 源码可读 |

W8 进入前再做就绪度评估。

---

## 当前已知未决项

| 项 | 何时处理 | 难度 |
|---|---|---|
| `brew install poetry` | W4 开始前 | 低（5 分钟） |
| `brew install pyenv && pyenv install 3.8.18` | W3 开始前（如选 A 路径） | 中（10-15 分钟）|
| Aave/Safe 的 npm install 整库 | 各周开始前（若需 hardhat 编译） | 中-重 |
| dydx indexer `pnpm install` | W5 开始前（若做 indexer PoC） | 重（几百 MB）|

---

## Agent 后续可做（不需用户介入）

- ⏳ **梳理 Revert 4 个关键文件的设计取舍对比**（schema.graphql + factory.ts + core.ts + position-manager.ts）→ 产出《Revert vs Uniswap 官方 vs Messari subgraph 代码差异设计对比》
- ⏳ W8 三个方向的 stretch 仓库就绪度评估
- ⏳ W2 aave-utilities healthFactor 算法的 TS 源码定位（为翻译成 Go 做准备）

→ **以上都是"知识准备"性质，不预先创建任何 PoC 脚手架 / 不动业务代码**。
