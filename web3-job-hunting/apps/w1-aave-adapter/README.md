# W1 · Aave V3 DeFi Adapter（Java + Spring Boot + web3j）

> 4 周冲刺第 1 周项目。学完后简历可以写：
> "DeFi Adapter Demo - Aave V3：用 Java 实现 supply/borrow/repay/withdraw + 监听 LiquidationCall"

---

## 一周日程（每日 1.5-2.5 小时）

| Day | 任务 | 校验 |
|---|---|---|
| **D1** | 项目跑通 + 看到 Sepolia 区块号 | 启动日志有 `✓ Connected. chainId=11155111 latestBlock=...` |
| **D2** | 读 Aave Pool.sol 4 个函数 + 生成 Java binding | `contract/Pool.java` 出现 |
| **D3** | 实现 `AaveSupplyService.supply()` | curl supply 接口，etherscan 看到 tx |
| **D4** | 实现 `AaveBorrowService.borrow()` + `getHealthFactor()` | health 接口返回真实数据 |
| **D5** | 实现 `LiquidationListener` 订阅 | 收到至少 1 个真实清算 event |
| **D6** | 加 H2/Postgres 持久化 + 单元测试 | 测试 80% 覆盖率 |
| **D7** | README + push GitHub | 简历段写入 |

---

## 准备工作（D0，30 分钟）

### 1. JDK 17 + Maven
```bash
java -version    # 应该 17+
mvn -version     # 应该 3.9+
```

### 2. 拿 Sepolia RPC（免费）
- 去 <https://alchemy.com> 注册
- Create App → Network = Ethereum / Sepolia
- 复制 HTTP URL

### 3. 准备测试钱包
- 用 MetaMask 创建一个**全新**钱包（**不要用主网钱包**）
- 切到 Sepolia 网络
- 去 <https://sepoliafaucet.com> 领 0.5 ETH 测试币
- 去 <https://app.aave.com/faucet/> 切 Sepolia 领 1000 USDC

### 4. 配置 .env
```bash
cp .env.example .env
# 编辑 .env 填入 RPC URL 和钱包私钥
```

---

## 启动（D1 验收）

```bash
# 加载环境变量
export $(grep -v '^#' .env | xargs)

# 启动
mvn spring-boot:run
```

启动日志应该看到：

```
✓ Connected. chainId=11155111 latestBlock=12345678 blockHash=0x...
```

→ 看到这行就证明 D1 完成了。

---

## D2 之后：跟着代码注释做

每个 Service 类的 javadoc 都标了 `[TODO Day X]`。
按照注释里的伪代码 + `contract/README.md` 的 binding 生成步骤一步步实现即可。

---

## 写完后的简历段

> **DeFi Adapter Demo · Aave V3（Java 17 + Spring Boot 3.2 + web3j 4.12）**
>
> 实现 Aave V3 借贷协议的 Java SDK 封装，覆盖 supply / borrow / repay / withdraw 全流程。
> 用 web3j EthFilter 订阅 LiquidationCall event 自动写入 PostgreSQL，含健康因子实时计算与告警。
> 在 Sepolia 测试网完整跑通，单元测试覆盖率 80%+。
> GitHub: github.com/your-handle/aave-adapter-demo

---

## 接下来 W2

完成 W1 后，复用本项目的 `Web3jConfig` + `AaveProperties` 模式，扩展为多协议：
- 加入 Uniswap V3 quote 计算
- 接入 Aave subgraph + Uniswap subgraph 做数据聚合
