# 合约 Java Binding 生成（Day 2-3 必读）

## 为什么要生成 binding

web3j 不喜欢直接 send raw transaction，它的最佳实践是：用 ABI 自动生成一个 Java 类（叫 binding），然后像调用普通 Java 方法那样调合约。

## 第 1 步：拿 Aave Pool 的 ABI

Aave V3 Pool 合约的 ABI 已经在我们 clone 的 repo 里：

```bash
# 找 Pool 的 ABI
ls /Users/piliepeng/cursor/go/web3-job-hunting/repos/lending/aave-v3-core/artifacts/contracts/protocol/pool/Pool.sol/

# Pool.json 文件里 .abi 字段就是 ABI
```

如果 Aave 还没编译过 artifacts，你需要先 compile 一次（不需要懂 hardhat，跑命令即可）：

```bash
cd /Users/piliepeng/cursor/go/web3-job-hunting/repos/lending/aave-v3-core
npm install --legacy-peer-deps   # ~5 分钟
npx hardhat compile               # ~2 分钟，生成 artifacts/
```

或者更快：直接从 Etherscan 下载已部署 Pool 合约的 ABI：
- Sepolia Pool: <https://sepolia.etherscan.io/address/0x6Ae43d3271ff6888e7Fc43Fd7321a503ff738951#code>

## 第 2 步：用 web3j-codegen 生成 Java 类

```bash
# 安装 web3j CLI（一次性）
brew install web3j

# 生成 Java binding
web3j generate solidity \
    -a /path/to/Pool.json \
    -o ./src/main/java \
    -p com.example.aaveadapter.contract
```

完成后你会得到：
```
src/main/java/com/example/aaveadapter/contract/Pool.java
```

后面在 service 里就可以这样用：

```java
Pool pool = Pool.load(poolAddress, web3j, credentials, gasProvider);
TransactionReceipt receipt = pool.supply(usdcAddress, amount, myAddress, BigInteger.ZERO).send();
```

## 第 3 步：常用 ERC20 binding

ERC20（USDC / DAI / WETH）的 binding 已经在 web3j-contracts 里现成的：

```java
import org.web3j.contracts.eip20.generated.ERC20;

ERC20 usdc = ERC20.load(usdcAddress, web3j, credentials, gasProvider);
usdc.approve(poolAddress, amount).send();
BigInteger balance = usdc.balanceOf(myAddress).send();
```

## 关键提示

- 测试网 USDC 可以从 Aave 官方 faucet 拿：<https://app.aave.com/faucet/>（先把网络切到 Sepolia）
- **不要把私钥写进 application.yml**，用 `.env` 或环境变量
- web3j 默认 polling 间隔 15 秒，要快可以传 `1000L`
