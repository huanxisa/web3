# 系统设计题：__题目名__

> v4 后端篇周笔记的核心产出。**7 段必填 + 1 段 PoC**，2-3 小时一题。
>
> 写作铁律：**用工程语言重新讲业务**，不要堆术语。每段 50-150 字。

---

## 1. 场景描述（50 字）

> 业务方是谁？要做什么？为什么需要这个系统？

**业务方**：

**核心需求**：

**为什么不用现成方案**：

---

## 2. 规模估算（必填，越具体越好）

> 面试官最爱问"你们 QPS 多少 / 数据量多大" → 自己先估算。

| 指标 | 数字 | 估算依据 |
|---|---|---|
| 用户数 | | （如：Aave V3 链上活跃 100 万钱包，取 10% = 10 万）|
| 写 QPS | | （触发频率 × 用户数）|
| 读 QPS | | （前端轮询 + 推送触发）|
| 数据量增长 | | （日 / 月 / 年）|
| 延迟 SLA | | （P50 / P99 各多少）|

---

## 3. 架构图（用 ASCII 或 mermaid）

```
┌─────────────────────────────────────────────────────────────────┐
│                                                                 │
│   [上游：链上 / API]                                              │
│         │                                                       │
│         ▼                                                       │
│   ┌─────────────┐    ┌─────────────┐    ┌─────────────┐         │
│   │ Listener    │───▶│ Worker /    │───▶│ Notifier /  │         │
│   │ (event sub) │    │ Calculator  │    │ Push        │         │
│   └─────────────┘    └─────────────┘    └─────────────┘         │
│         │                  │                  │                 │
│         ▼                  ▼                  ▼                 │
│   ┌─────────────────────────────────────────────────────┐       │
│   │              Database (Postgres / Redis)             │       │
│   └─────────────────────────────────────────────────────┘       │
│                            │                                    │
│                            ▼                                    │
│                       [下游：API / 前端 / 第三方]                  │
└─────────────────────────────────────────────────────────────────┘
```

**模块说明**（每个 30-50 字）：

- **Listener**：
- **Worker / Calculator**：
- **Notifier / Push**：
- **Database**：
- **API**：

---

## 4. 数据库 Schema

> 至少 2-3 张核心表，写出关键字段和索引。

```sql
CREATE TABLE __table_1__ (
    id BIGSERIAL PRIMARY KEY,
    -- 业务字段
    
    created_at TIMESTAMP DEFAULT NOW(),
    updated_at TIMESTAMP DEFAULT NOW()
);
CREATE INDEX __idx__ ON __table_1__(...);

CREATE TABLE __table_2__ (
    -- ...
);
```

**为什么这么 schema**（30-100 字）：
- 字段选型理由：
- 索引策略：
- 是否需要分表 / 分库：

---

## 5. API 接口

> 至少 3-5 个核心接口，REST 或 gRPC 都行。

| Method | Path | 入参 | 返回 | 用途 |
|---|---|---|---|---|
| GET | `/health/{address}` | - | `{healthFactor, status}` | 查单个用户健康因子 |
| GET | `/health/at-risk?threshold=1.1` | threshold | `[{address, hf}]` | 查所有低于阈值的用户 |
| POST | `/webhooks` | `{address, callback_url}` | - | 注册推送回调 |
| WS | `/ws/health/{address}` | - | stream | 实时订阅 |

---

## 6. Tradeoff 论述（**面试官最看重这段**）

> 至少写 3 个关键决策的"为什么这么选 / 不选另一种方案"。

### 决策 1：`__关键决策点__`

- **方案 A**：（描述）
- **方案 B**：（描述）
- **我选 A 因为**：__业务/规模/成本/团队_ 三个角度论证

### 决策 2：

### 决策 3：

---

## 7. 监控 + 异常处理 + 容灾

### 监控指标（Prometheus 视角）

| 指标 | 类型 | 告警阈值 |
|---|---|---|
| `xxx_event_processed_total` | Counter | 5 分钟无增长 |
| `xxx_lag_seconds` | Gauge | > 30s |
| `xxx_calculation_duration_p99` | Histogram | > 1s |

### 异常场景 + 应对

| 场景 | 应对 |
|---|---|
| RPC 节点宕机 | 多 RPC fallback + 健康检查 |
| Chain reorg（区块回滚）| 维护 N 块 buffer，回滚后重放 |
| 推送下游不可达 | 重试队列 + 死信队列 |
| Postgres 写入失败 | WAL + Redis 缓冲 |

---

## 8. PoC（**必填**，覆盖核心模块，100-200 行 Go）

> 不要全做，做最有信息量的 1 个模块（一般是 Listener + Calculator 那一段）。

**PoC 仓库位置**：`repos/_demos/__demo-name__/`

**核心代码片段**（贴 30-80 行最关键的）：

```go
// internal/calculator/health_factor.go

func (c *Calculator) Compute(ctx context.Context, addr common.Address) (decimal.Decimal, error) {
    // 1. 拉用户在 Aave V3 上的所有 reserve 持仓
    reserves, err := c.aave.GetUserReserves(ctx, addr)
    if err != nil {
        return decimal.Zero, fmt.Errorf("get reserves: %w", err)
    }
    
    // 2. 算 totalCollateralETH * avgLiquidationThreshold / totalDebtETH
    var totalCollateralETH, totalDebtETH, weightedThreshold decimal.Decimal
    for _, r := range reserves {
        ethValue := r.Amount.Mul(c.priceCache.Get(r.Token))
        if r.IsCollateral {
            totalCollateralETH = totalCollateralETH.Add(ethValue)
            weightedThreshold = weightedThreshold.Add(
                ethValue.Mul(c.aave.LiquidationThreshold(r.Token)),
            )
        }
        totalDebtETH = totalDebtETH.Add(ethValue)
    }
    
    if totalDebtETH.IsZero() {
        return decimal.NewFromInt(999), nil // safe
    }
    avgThreshold := weightedThreshold.Div(totalCollateralETH)
    return totalCollateralETH.Mul(avgThreshold).Div(totalDebtETH), nil
}
```

**怎么跑通**：
```bash
cd repos/_demos/aave-health-monitor
make migrate && make run
curl http://localhost:8080/health/0xabc...
```

**我学到了什么**（**这段写到博客 + 简历**）：
- 关键设计 1：__（如：用 decimal 而不是 big.Int 是因为 ___）__
- 关键设计 2：
- 我踩过的坑：
- 如果让我重新设计：

---

## 9. 自评

- [ ] 7 段全填完，每段不止 1 句话
- [ ] 规模估算给了具体数字（不是"很多"）
- [ ] 至少 3 个 tradeoff 论述
- [ ] PoC 能跑（不是伪代码）
- [ ] PoC 推到 GitHub 公开
- [ ] 我能用 5 分钟讲完这道题（不看资料）
- [ ] 我能回答 3 个面试官追问（如"如果用户从 10 万涨到 1000 万呢" / "RPC 节点慢 100ms 怎么办"）
