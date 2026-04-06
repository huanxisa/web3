
> 参考学习资料：`../../solidity_lesson/lessonA14.1/Solidity智能合约开发 - 众筹平台实战开发(学习资料).md`

## 作业目标

独立实现一个去中心化众筹平台，包含以下核心功能：

### CrowdfundingCampaign.sol（众筹项目合约）
- [ ] 状态机管理（Preparing → Active → Success/Failed → Closed）
- [ ] `contribute()` 函数：用户参与众筹，自动状态转换
- [ ] `withdraw()` 函数：项目成功后 owner 提取资金（CEI 模式）
- [ ] `refund()` 函数：项目失败后用户申请退款（防重入）
- [ ] `start()` / `finalize()` 函数：状态切换
- [ ] 事件定义：ContributionReceived / StateChanged / FundsWithdrawn

### CrowdfundingFactory.sol（工厂合约）
- [ ] `createCampaign()` 函数：部署新众筹合约
- [ ] `campaigns` 数组：记录所有项目地址
- [ ] `userCampaigns` mapping：记录用户创建的项目
- [ ] 事件定义：CampaignCreated

### 测试覆盖（test/）
- [ ] 部署测试：验证初始状态 Preparing
- [ ] 状态转换测试：start、达到目标自动 Success、超时 finalize → Failed
- [ ] 资金功能测试：contribute 累加、withdraw 提款、refund 退款
- [ ] 工厂合约测试：createCampaign 后数组长度、地址归属

### 部署（script/）
- [ ] Foundry Script 部署脚本
- [ ] 部署到 Sepolia 测试网并验证合约

---

## Foundry

**Foundry is a blazing fast, portable and modular toolkit for Ethereum application development written in Rust.**

Foundry consists of:

- **Forge**: Ethereum testing framework (like Truffle, Hardhat and DappTools).
- **Cast**: Swiss army knife for interacting with EVM smart contracts, sending transactions and getting chain data.
- **Anvil**: Local Ethereum node, akin to Ganache, Hardhat Network.
- **Chisel**: Fast, utilitarian, and verbose solidity REPL.

## Documentation

https://book.getfoundry.sh/

## Usage

### Build

```shell
$ forge build
```

### Test

```shell
$ forge test
```

### Format

```shell
$ forge fmt
```

### Gas Snapshots

```shell
$ forge snapshot
```

### Anvil

```shell
$ anvil
```

### Deploy

```shell
$ forge script script/Counter.s.sol:CounterScript --rpc-url <your_rpc_url> --private-key <your_private_key>
```

### Cast

```shell
$ cast <subcommand>
```

### Help

```shell
$ forge --help
$ anvil --help
$ cast --help
```
