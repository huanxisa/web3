# __demo-name__

> 配套 Wn 内化的 Go Demo 工程脚手架。**不要写到完美**，写到"能跑通主流程 + README 能讲清"即可。

## 一句话讲它做什么

> 例：参考 dYdX V4 indexer 架构，用 Go 监听 Sepolia 上某 ERC20 的 Transfer 事件，写入 Postgres，并提供 REST API 查询任意地址的转账历史。

## 启动

```bash
# 1. 启动 Postgres
docker run -d --name pg -e POSTGRES_PASSWORD=demo -p 5432:5432 postgres:15

# 2. 配置 .env
cp .env.example .env
# RPC_URL=https://sepolia.infura.io/v3/<your-key>
# CONTRACT=0x...

# 3. 跑迁移 + 启动
make migrate && make run

# 4. 测试
curl http://localhost:8080/transfers/0xabc...
```

## 模块拆解

| 文件 | 职责 |
|---|---|
| `cmd/main.go` | 入口：启动 listener + http server |
| `internal/listener/` | 链上事件订阅（参考 dYdX `ender`）|
| `internal/repo/` | Postgres CRUD |
| `internal/api/` | REST handler |

## 我学到了什么（**这一段写到博客 + 简历**）

- 关键设计 1：例 — EventManager 模式怎么把"解析 + 持久化"解耦，便于单元测试
- 关键设计 2：…
- 我踩过的坑：…
- 如果让我重新设计：…

## 性能 / 限制

- 单 listener 单线程，TPS ___
- 不处理 chain reorg（生产级要补）
- 不处理 RPC 断线重连（生产级要补）

## License

MIT
