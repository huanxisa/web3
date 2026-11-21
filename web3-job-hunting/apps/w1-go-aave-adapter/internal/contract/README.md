# abigen 教程：从 Aave Pool ABI 生成 Go binding

## 一、安装 abigen

```bash
# 方法 1：用 go install
go install github.com/ethereum/go-ethereum/cmd/abigen@latest

# 方法 2：brew（macOS）
brew install ethereum
abigen --version
```

## 二、拉取 Aave Pool ABI

Aave V3 Pool 合约地址（Sepolia）：`0x6Ae43d3271ff6888e7Fc43Fd7321a503ff738951`

ABI 来源（任选）：

1. **Etherscan**（推荐）：
   ```bash
   curl -s "https://api-sepolia.etherscan.io/api?module=contract&action=getabi&address=0x6Ae43d3271ff6888e7Fc43Fd7321a503ff738951&apikey=YOUR_KEY" \
     | jq -r '.result' > ../../contract/abi/Pool.json
   ```
2. **Aave 官方仓库**：
   ```
   https://github.com/aave-dao/aave-v3-origin/blob/main/src/contracts/protocol/pool/Pool.sol
   ```
   编译后的 ABI 在 `out/Pool.sol/Pool.json`。

3. **Web3-interview-sharing/Web3综合资料库/Defi平台资料/Aave协议学习分析文档.pdf** 里有完整说明。

## 三、生成 Go binding

```bash
cd apps/w1-go-aave-adapter

abigen \
  --abi=contract/abi/Pool.json \
  --pkg=pool \
  --type=Pool \
  --out=contract/bindings/pool/pool.go
```

## 四、ERC20 binding

go-ethereum 没自带 ERC20 binding，自己生成：

```bash
# 用 OpenZeppelin 标准 ERC20 ABI
curl -s https://raw.githubusercontent.com/OpenZeppelin/openzeppelin-contracts/master/contracts/build/contracts/ERC20.json \
  | jq '.abi' > contract/abi/ERC20.json

abigen \
  --abi=contract/abi/ERC20.json \
  --pkg=erc20 \
  --type=ERC20 \
  --out=contract/bindings/erc20/erc20.go
```

## 五、在 Day 3+ 用法示例

```go
import (
    "github.com/ethereum/go-ethereum/common"
    "github.com/piliepeng/w1-go-aave-adapter/contract/bindings/pool"
    "github.com/piliepeng/w1-go-aave-adapter/contract/bindings/erc20"
)

// 1) 实例化
poolAddr := common.HexToAddress("0x6Ae...8951")
poolContract, _ := pool.NewPool(poolAddr, ethClient)
usdcAddr := common.HexToAddress("0x94a...4C8")
usdc, _ := erc20.NewERC20(usdcAddr, ethClient)

// 2) approve（写交易）
transactor, _ := chainClient.Transactor()
tx, _ := usdc.Approve(transactor, poolAddr, amount)
bind.WaitMined(ctx, ethClient, tx)

// 3) supply（写交易）
tx2, _ := poolContract.Supply(transactor, usdcAddr, amount, chainClient.Address(), big.NewInt(0))
receipt, _ := bind.WaitMined(ctx, ethClient, tx2)

// 4) read（只读，不要 transactor，用 bind.CallOpts{}）
data, _ := poolContract.GetUserAccountData(&bind.CallOpts{Context: ctx}, chainClient.Address())
```

## 六、Java vs Go binding 对比（学习用）

| 操作 | Java (web3j) | Go (abigen) |
|---|---|---|
| 加载合约 | `Pool.load(addr, web3j, credentials, gasProvider)` | `pool.NewPool(addr, ethClient)` |
| 调用写方法 | `pool.supply(...).send()` | `pool.Supply(transactor, ...)` |
| 调用读方法 | `pool.getUserAccountData(addr).send()` | `pool.GetUserAccountData(&bind.CallOpts{}, addr)` |
| 等待 receipt | `tx.getTransactionReceipt()` | `bind.WaitMined(ctx, client, tx)` |
| 监听事件 | `web3j.ethLogFlowable(filter).subscribe(...)` | `client.SubscribeFilterLogs(ctx, query, ch)` |

→ **几乎 1:1 镜像**，所以你将来要投 Binance 时，1 天内就能把 Go 版翻译为 Java 版。
