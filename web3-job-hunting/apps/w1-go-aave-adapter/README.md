# W1 Go Aave Adapter

> Web3 后端 4 周冲刺的第 1 周。**Go 版**（Java 版见 `apps/w1-aave-adapter/`）。
>
> 目标：用 Go + go-ethereum + Gin 实现 Aave V3 Sepolia 测试网的 supply / borrow / repay / withdraw + LiquidationCall 监听。

---

## 一、技术栈

| 层 | 选型 | 备注 |
|---|---|---|
| 语言 | Go 1.22 | |
| HTTP | Gin v1.10 | |
| 链交互 | go-ethereum v1.14 | abigen 生成 binding |
| 配置 | viper（自带 `${VAR:-default}` 展开） | |
| 日志 | zap | |
| 测试网 | Sepolia | Aave V3 官方部署 |

## 二、目录结构

```
w1-go-aave-adapter/
├── cmd/server/main.go            # 入口
├── config/config.yml             # Aave 地址 + RPC URL
├── internal/
│   ├── config/                   # viper 加载
│   ├── chain/                    # ethclient 包装 + transactor
│   ├── service/                  # 核心业务（D1-D5 任务）
│   │   ├── health.go             #   D1：链健康检查
│   │   ├── supply.go             #   D3：Aave supply（占位）
│   │   ├── borrow.go             #   D4：Aave borrow + getUserAccountData（占位）
│   │   └── liquidation.go        #   D5：监听 LiquidationCall（占位）
│   ├── handler/                  # HTTP 适配
│   └── contract/README.md        # abigen 生成 binding 的完整教程
├── contract/
│   ├── abi/                      # Pool.json / ERC20.json（待你下载）
│   └── bindings/                 # abigen 输出（gitignore，每次自己生成）
├── .env.example                  # 复制为 .env 填私钥
└── README.md                     # 本文件
```

## 三、7 天任务表（D1-D7）

| Day | 任务 | 验收 |
|---|---|---|
| **D1** | `go mod tidy` + `go run ./cmd/server` 启动 | `curl localhost:8080/api/v1/health` 看到 `chain_id=11155111` |
| **D2** | 看 `internal/contract/README.md`，跑通 abigen，生成 `contract/bindings/pool/pool.go` 和 `erc20/erc20.go` | `ls contract/bindings/` 有两个目录 |
| **D3** | 实现 `internal/service/supply.go` 的 `Supply()` 方法 | `curl -X POST -d '{"token":"usdc","amount":"100000000"}' localhost:8080/api/v1/supply` 在 Sepolia 上跑通 |
| **D4** | 实现 `borrow.go` 的 `Borrow()` + `GetUserAccountData()` | 能查到 `healthFactor` |
| **D5** | 实现 `liquidation.go` 用 `SubscribeFilterLogs` 监听 + 写 PostgreSQL | 测试网历史数据回放能落库 |
| **D6** | 单元测试 + 接 anvil 本地链做集成测试 | `go test ./...` 全绿 |
| **D7** | 写 README 演示动图 + push GitHub | repo 公开链接 |

## 四、Day 1 立刻可跑

```bash
cd apps/w1-go-aave-adapter
go mod tidy             # 下载依赖（约 2 分钟，go-ethereum 比较大）
go run ./cmd/server     # 启动
# 另起终端
curl http://localhost:8080/api/v1/health
# 期望返回：{"chain_id":11155111,"block_number":xxx,"has_signer":false}
```

⚠️ **首次跑 `go mod tidy` 会拉 ~150MB 依赖，记得网络 OK**。
⚠️ Day 1 不需要私钥，`has_signer: false` 也能跑通；后续 D3 才需要私钥。

## 五、为什么这一周用 Go 而不是 Java？

参考 [`reports/backend_engineer_4weeks.md`](../../reports/backend_engineer_4weeks.md) 的"语言决策树"：

- Aave 协议主仓库是 Sol；后端集成在 Web3 行业**主流是 Go**（go-ethereum 是行业基础）。
- 你 Java 8 → JDK 17 升级阻塞，Go 没有这种环境问题。
- 投 Binance 时再花 1 天把 Go 版翻译成 Java 版（API 1:1 镜像）。

## 六、对照 Java 版的核心差异

| 关注点 | Java 版（`apps/w1-aave-adapter/`） | Go 版（本项目） |
|---|---|---|
| 入口 | `AaveAdapterApplication.main()` | `cmd/server/main.go` |
| 配置 | `@ConfigurationProperties` + `application.yml` | `viper` + `config.yml` |
| 链客户端 | `Web3jConfig` Bean | `internal/chain/client.go` |
| 合约 binding | web3j-codegen 生成 `Pool.java` | abigen 生成 `pool.go` |
| supply 调用 | `pool.supply(...).send()` | `pool.Supply(transactor, ...)` |
| 监听事件 | `web3j.ethLogFlowable().subscribe()` | `client.SubscribeFilterLogs(ctx, q, ch)` |
| JDK 要求 | **JDK 17**（你卡在这）| Go 1.22（无升级负担）|

→ 选 Go 的核心动机：**没有任何环境阻塞，今天就能开干**。
