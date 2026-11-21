# Web3 后端工程师 4 周冲刺方案 v3（Go + Java 双语版）

> **画像锁死**：
>
> - Java 5+ 年（API 默写 + 底层熟）
> - Go 能写（IDE 辅助 + 代码补全后无门槛差距）
> - Solidity 只读不写
> - 4 周节奏 OK（每周 10-15 小时）
>
> **战略**：**Go 主 + Java 备**，跟着所学开源仓库的主语言走。
>
> | 仓库主语言 | Demo 用什么 | 为什么 |
> |---|---|---|
> | 协议合约（Sol/Vyper） | Go 优先 | go-ethereum 是行业基础，所有 indexer/bot 都用 |
> | 后端是 Python | Go 优先 | Go 性能好且符合 Web3 部署文化（单二进制） |
> | 后端是 Go（如 EigenDA、Chainlink）| **必须 Go** | 直接读源码 + 同语言改写 demo |
> | 投 Binance/Bitget/OKX 等大型 CEX | Java 翻译版 | web3j 几乎是 go-ethereum 的镜像 API，1 天可翻译 |

---

## 一、为什么 Go 主 Java 备（数据驱动）

### 实测数据：17 家公司 70 个匹配岗按语言分布（2026-05-12 最新）

| 语言 | 岗位数 | 占比 | 主要分布 |
|---|---|---|---|
| **Java** | 28 | 40% | Binance + **Bybit** + Gate（CEX）|
| **Golang** | 24 | 34% | **Coinbase + Uniswap + Bybit + Gate + Binance + OKX 多家分布** |
| **Rust** | 17 | 24% | Mantle / Aave / Bybit Principal Rust |
| Python | 16 | 23% | 全部公司辅助语言 |
| Solidity | 10 | 14% | 合约岗位 |
| TypeScript | 8 | 11% | Fireblocks / Uniswap |
| JavaScript | 7 | 10% | |
| Ruby | 1 | 1% | Coinbase（Web 老栈）|

**关键洞察**：
- **Bybit + Gate 加进来后，Go 24 已经追近 Java 28** —— 真正的双语并行。
- **Bybit 9 个工程岗几乎全部 Java + Golang 双标**（吉隆坡 / 维也纳 / 阿布扎比，全中文友好）
- **Gate 8 个工程岗 80% 含 Golang**，APAC-C1 杭州办公室
- **结论**：**Go + Java 双修必修**；写 demo 时按目标公司选语言。

### Web3 行业语言分布（按方向）

| 方向 | 主流语言 | 代表公司 |
|---|---|---|
| **L2 / 客户端** | **Go** 主导 | Optimism, Arbitrum, Polygon, Avalanche |
| **Oracle** | **Go** 主导 | Chainlink Labs（**全 Go**）|
| **MPC / 钱包托管** | **Go** 主导 | Fireblocks, BitGo, Cobo |
| **DeFi 协议方** | Go + TS | Aave, Lido, Pendle, Maker |
| **跨链桥** | Go + TS + Rust | LayerZero, Wormhole, Across |
| **Indexer** | Rust + Go | The Graph, Erigon |
| **大型 CEX** | **Java** 主导（少数）| Binance, Bitget, OKX 部分 |

→ **Go 覆盖 80% 的 Web3 后端岗位**，Java 主要是 Binance 系。

### 你目标公司池（已扩大到 17 家，但要分清「投递目标」vs「学习资料」）

| 主线 | 公司 | 用途 |
|---|---|---|
| **A：L2 基建** | Mantle, Scroll, Manta | 投递（Token 激励高）|
| **B：大型 CEX** | Binance, OKX, Bitget | 投递（HC 多，Java 主）|
| **C：强业务（部分投递）** | **Coinbase, Aave, Fireblocks, Magic Eden, Uniswap** | ✅ **投递**（Go 友好，业务标杆）|
| **C-学习用：仅学不投** | Circle, Lido, Ondo, Pendle | ⚠️ **仅学业务**（中文不友好，进不去）|
| **D：中文友好 CEX（新增）** | **Bybit, Gate.io** | ✅ **强烈投递**（华人创始 + Go/Java 双标 + APAC HC 多）|

#### 待考虑加入的中文友好公司（下一轮）

| 公司 | 业务 | 中文友好度 | 投递价值 |
|---|---|---|---|
| **HTX（火币）** | 老牌华人 CEX | ⭐⭐⭐⭐⭐ | 高（自建 ATS，需手动看 LinkedIn）|
| **KuCoin** | "人民交易所" | ⭐⭐⭐⭐⭐ | 中（自建 ATS）|
| **MEXC（抹茶）** | 新币上线龙头 | ⭐⭐⭐⭐⭐ | 中（用飞书招聘）|
| **CoinEx** | 杨海坡矿池系 | ⭐⭐⭐⭐⭐ | 中（自建）|
| **Cobo Global** | 神鱼机构托管 | ⭐⭐⭐⭐⭐ | 高（MPC 钱包业务）|
| **Babylon** | BTC Restaking | ⭐⭐⭐⭐ | 高（中国 BD 团队）|
| **Particle Network** | 钱包抽象 AA | ⭐⭐⭐⭐⭐ | 中（小但有 token）|
| **Mask Network** | Web3 社交 | ⭐⭐⭐⭐⭐ | 中（中国团队）|

→ 这些公司都用**自建系统或 LinkedIn**，不写抓取器，**直接 LinkedIn 关注 + 中文招聘群**。

### Circle/Lido/Ondo/Pendle 仅作"业务学习"用途

| 公司 | 学什么 | 学完写到简历哪一段 |
|---|---|---|
| **Circle** | USDC mint / burn / CCTP 跨链 | "研究过 Circle 跨链稳定币 CCTP 协议设计" |
| **Lido** | LST 模型（stETH 与 ETH 1:1 重平衡）| W3 项目 demo 段："基于 Lido 设计的 LST adapter" |
| **Ondo** | RWA 代币化（USDY 收益分发）| "理解 RWA 链下抵押 + 链上分红的会计模型" |
| **Pendle** | YT/PT 收益拆分（DeFi 衍生品）| "学习了 Pendle YT/PT 利率拆分模型"（高级面试加分）|

→ **不投递这 4 家，但所学知识 100% 复用到投 Aave/Uniswap/Binance 的面试中**。

---

## 二、技术栈双轨锁死

| 层 | Go 主版 | Java 备版（投 Binance 时翻译用）|
|---|---|---|
| 链上交互 | **go-ethereum** (`github.com/ethereum/go-ethereum`) | web3j 4.12 |
| 框架 | **Gin** + zap log | Spring Boot 3.2 + Lombok |
| 配置 | **viper** | application.yml |
| ORM | **gorm** + PostgreSQL | Spring Data JPA |
| 缓存 | go-redis | Redis Template |
| Binding 生成 | **abigen** | web3j-codegen |
| 测试 | testify | JUnit 5 |
| 部署 | 单二进制 + Dockerfile | Spring Boot fat jar |

→ 两套栈在概念上 1:1 对应，**学一遍不必学两遍**。

---

## 三、4 周计划（每周一个 Demo，Go 主 Java 备）

### W1：Aave V3 DeFi Adapter

**目标**：实现 supply / borrow / repay / withdraw + 监听 LiquidationCall。

| Day | 任务 | Go 实现 | Java 实现（可选） |
|---|---|---|---|
| D1 | 项目骨架 + 连 Sepolia + 打印区块号 | `go run main.go` 看到 chainId=11155111 | `mvn spring-boot:run` |
| D2 | 用 abigen 生成 Aave Pool Go binding | `abigen --abi Pool.json --pkg aave -o pool.go` | `web3j generate solidity` |
| D3 | 实现 SupplyService.Supply(token, amount) | `pool.Supply(opts, asset, amount, addr, 0)` | `pool.supply(...).send()` |
| D4 | 实现 BorrowService + GetUserAccountData | 同上 | 同上 |
| D5 | EthFilter 订阅 LiquidationCall + 落 Postgres | `client.SubscribeFilterLogs()` | `web3j.ethLogFlowable()` |
| D6 | 单元测试 + 接 anvil 本地链快测 | `go test -race ./...` | JUnit |
| D7 | README + push GitHub | | |

**简历段（W1 完成后）**：

> **DeFi Adapter Demo · Aave V3（Go + Gin + go-ethereum）**
> 实现 Aave V3 借贷协议的 Go SDK 封装，覆盖 supply/borrow/repay/withdraw。用 ethclient 订阅 LiquidationCall event 落地 PostgreSQL，含健康因子实时计算。Sepolia 完整跑通。
> （**投 Binance 时简历换成**：Java 17 + Spring Boot + web3j 同等实现，1 天翻译完成）

### W2：Aave + Uniswap Subgraph 多协议数据聚合 API

**目标**：写一个数据聚合服务，查任意用户在 Aave + Uniswap V3 的所有头寸 + 实时 quote。

| Day | 任务 | Go | Java |
|---|---|---|---|
| D1-2 | 本地 docker 起 graph-node，跑通 Aave subgraph | `docker compose up -d graph-node` | 同 |
| D3 | Go GraphQL client（graphql-go）调 Aave subgraph | `client.Query(...)` | Apollo Client |
| D4 | 同样接 Uniswap V3 subgraph | | |
| D5 | go-redis 缓存（5s TTL）+ Prometheus | `redis.Get/SetEX` | RedisTemplate |
| D6 | REST `GET /api/portfolio/{addr}` 返回跨协议总资产 | Gin handler | Spring Controller |
| D7 | 测试 + push | | |

**简历段**：

> **多协议 DeFi 数据聚合 API（Go + Gin + GraphQL）**
> 集成 Aave / Uniswap V3 两个 subgraph，提供用户跨协议总资产查询 + Uniswap 实时 quote 计算。
> Redis 缓存 + Prometheus 监控，QPS 500+。

### W3：Lido + MakerDAO ETH 自动复投策略 Bot

**目标**：用 Go 写一个定时 bot，存 ETH→Lido 拿 stETH→在 Maker 借 DAI→存 sDAI 拿 DSR。

| Day | 任务 | Go | Java |
|---|---|---|---|
| D1 | abigen Lido + Maker binding | | |
| D2 | LidoService.Stake(amount) | `lido.Submit(opts, addr)` | |
| D3 | MakerService.OpenCdp(stETHAmount, daiAmount) | | |
| D4 | 自动复投策略 + Go cron | `cron.AddFunc("@every 1h", ...)` | `@Scheduled` |
| D5 | Slack/Telegram 告警 + 失败重试 | | |
| D6 | 端到端测试网跑通 + 截图收益曲线 | | |
| D7 | push | | |

**重点**：W3 涉及 Lido 的 **Python lido-oracle**，建议**只读懂架构图**（看 README + 关键 module），**不重写**。你的 demo 用 Go 模拟 Oracle 简化版即可。

**简历段**：

> **ETH 收益自动复投策略 Bot（Go）**
> Lido 质押 → MakerDAO CDP 借 DAI → sDAI 拿 DSR，年化叠加 8%+。
> 含 Slack 告警 + 失败重试 + Prometheus 监控。

### W4：Safe（多签托管）+ EigenLayer Go SDK 实战

**目标**：写企业级多签托管服务，**直接基于 EigenLayer Go SDK 二次开发**。

| Day | 任务 | 技术 |
|---|---|---|
| D1 | 读 Safe Smart Account 关键合约（execTransaction）| Sol 只读 |
| D2 | **直接调用 Safe transaction-service 的 REST API**（你不需要部署 Python 后端） | go-resty |
| D3 | SafeService.ProposeTx() + ConfirmTx() | Go |
| D4 | 把 W1 的 Aave supply 包一层 Safe 多签 | |
| D5 | **读 EigenLayer Go SDK 源码**（eigensdk-go），写一个最小 Operator demo | Go 读 Go，舒适 |
| D6 | 把 W1-W4 整合成 monorepo | |
| D7 | 总 README + 简历最终版 | |

**简历总段**：

> **Web3 DeFi Adapter Suite（个人项目，Go + Gin + go-ethereum）**
> 自主设计实现的 Go DeFi 集成框架，封装 Aave V3 / Uniswap V3 / Lido / MakerDAO / Safe / EigenLayer 6 个协议的统一 Adapter 层。覆盖借贷、swap、质押、稳定币、多签托管、Restaking 全场景。Sepolia 测试网完整 demo，含 PostgreSQL 持久化、Redis 缓存、Prometheus 监控、Docker 部署。
> （**投 Binance/Bitget 时**：替换为 Java + Spring Boot 实现，核心代码已 1:1 适配 web3j）

---

## 四、用 4 周成果对应到 13 家投递公司岗位

> Circle / Lido / Ondo / Pendle 已剔除（仅作业务学习），下表只列**投递目标**。

| 公司 | W1 Aave | W2 Subgraph | W3 LST/Maker | W4 Safe/EigenLayer | 简历版本 |
|---|---|---|---|---|---|
| **Coinbase** | ✓ | ✓ | ✓ | ✓ Restaking | **Go 版** |
| **Aave Companies** | ✓✓ | ✓ | | | **Go 版** |
| **Fireblocks** | ✓ | | | ✓✓ Safe | **Go 版** |
| **Magic Eden** | ✓ | | | ✓ Safe | Go 版 |
| **Uniswap Labs** | | ✓✓ | | | Go 版 |
| **Mantle** | | | | ✓✓ EigenDA | Go 版 |
| **Scroll** | (协议读) | | | | Go 版 |
| **Manta** | (协议读) | | | | Go 版 |
| **Bybit** ⭐ 新 | ✓ Go/Java | ✓ | | | **Go + Java 双修** |
| **Gate.io** ⭐ 新 | ✓ Go | ✓ | | | **Go 版** |
| **Binance Wallet Java** | ✓ Java 翻译 | | | ✓ Safe Java | **Java 翻译版** |
| **Binance DeFi Java** | ✓✓ Java | ✓ Java | | | **Java 翻译版** |
| **Binance Stablecoin Java** | | | ✓✓ Java | | **Java 翻译版** |
| **Bitget Wallet** | ✓ Java | | | ✓ Java | **Java 翻译版** |
| **OKX** | ✓ | | | | Java 或 Go |

→ **13 家投递公司里 60% Go + 40% Java**，跟实测语言分布（Java 28 / Go 24）完全吻合。

---

## 五、Go 还是 Java 怎么选（每周开始前的简单决策树）

```
即将开始这一周的项目 →
    ├─ 该项目主开源仓库是 Go？ → Go 主版（直接读源码 + 改写）
    ├─ 该项目主开源仓库是 Sol/Vyper（合约）？ → 先 Go 实现 Adapter
    ├─ 该项目主开源仓库是 Python（如 lido-oracle）？ → Go 简化版重写
    └─ 你这周想投的目标公司清一色 Java（Binance）？ → 加做 Java 翻译版（1 天）
```

→ **结论**：**主开发用 Go，Java 在投 Binance/Bitget/OKX 当周临时翻译**。

---

## 六、当前 Go 阻塞：0（你已经能写）

| 之前的阻塞 | 是否还在 |
|---|---|
| Java 8 → JDK 17 升级 | ⚠️ 仍在，但 **W1 用 Go 不阻塞** |
| 不熟 Spring Boot 3.x | ⚠️ 仍在，**Go 不需要** |
| go-ethereum 不熟 | ✗ 你能写 + 用 IDE 补全 |
| go.mod / go module | ✗ 你已经在 cursor/go 工作区，环境天然就绪 |

→ **W1 立刻可以开干**。

---

## 七、下一步

| 选项 | 说明 |
|---|---|
| **A** | 抓取完成后我立刻汇报新增了多少 Go 岗位 |
| **B** | 我搭 **Go 版 W1 项目骨架**：`apps/w1-go-aave-adapter/`（Gin + go-ethereum + abigen + Sepolia 配置 + supply 模板代码）|
| **C** | A + B |

我推荐 **C**：等抓取完看新岗位数据 + 立刻搭 Go 项目骨架（不阻塞，10 分钟）。
