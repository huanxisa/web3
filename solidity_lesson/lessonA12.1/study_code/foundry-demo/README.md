## Foundry

**Foundry is a blazing fast, portable and modular toolkit for Ethereum application development written in Rust.**

Foundry consists of:

-   **Forge**: Ethereum testing framework (like Truffle, Hardhat and DappTools).
-   **Cast**: Swiss army knife for interacting with EVM smart contracts, sending transactions and getting chain data.
-   **Anvil**: Local Ethereum node, akin to Ganache, Hardhat Network.
-   **Chisel**: Fast, utilitarian, and verbose solidity REPL.

## Documentation

https://book.getfoundry.sh/

## 推荐开发流程：先写 import，再一键同步依赖

不想打断思路时，可以**先在代码里写 import**，需要编译前跑一次脚本，自动按 import 安装缺失依赖：

```shell
# 1. 在 src/ script/ test/ 里直接写 import，例如：
#    import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
#    import "forge-std/Test.sol";

# 2. 同步依赖（会安装尚未存在的库）
./scripts/sync-deps.sh

# 3. 编译
forge build
```

- **remappings** 已在 `foundry.toml` 里配好（如 `@openzeppelin/`、`@forge-std/`），一般无需改。
- 若用到新前缀（如 `@solady/`），在 `scripts/sync-deps.sh` 的 `get_repo_for_import` 里加一条映射，并在 `foundry.toml` 的 `remappings` 里加一行即可。

## 从 GitHub 克隆后：依赖初始化

本项目使用 Git 子模块管理 `lib/` 下的依赖。克隆后需要先拉取依赖再编译：

```shell
# 方式一：标准 Git 子模块初始化（推荐）
git submodule update --init --recursive

# 然后即可构建
forge build
```

若仓库未提交子模块、仅提交了 `foundry.lock`，可运行同步脚本或手动安装：

```shell
./scripts/sync-deps.sh
# 或
forge install foundry-rs/forge-std
forge install OpenZeppelin/openzeppelin-contracts
```

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
