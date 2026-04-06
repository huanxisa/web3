# Solidity 学习笔记

---

## 一、Solidity 全局变量（EVM 运行时自动注入）

不需要声明，EVM 在每次交易执行时自动注入，直接使用。

### 1. 区块信息 `block.*`

| 变量 | 类型 | 含义 |
|------|------|------|
| `block.timestamp` | `uint256` | 当前区块的 Unix 时间戳（秒） |
| `block.number` | `uint256` | 当前区块号 |
| `block.chainid` | `uint256` | 当前链 ID（主网=1，Sepolia=11155111） |
| `block.basefee` | `uint256` | 当前区块基础 Gas 费（EIP-1559） |
| `block.coinbase` | `address` | 当前区块的验证者地址 |
| `block.gaslimit` | `uint256` | 当前区块的 Gas 上限 |

### 2. 交易/调用信息 `msg.*`

| 变量 | 类型 | 含义 |
|------|------|------|
| `msg.sender` | `address` | 当前调用者地址（直接调用方） |
| `msg.value` | `uint256` | 本次调用附带的 ETH 数量（wei） |
| `msg.data` | `bytes` | 完整的 calldata（函数选择器+参数） |
| `msg.sig` | `bytes4` | calldata 前 4 字节（函数选择器） |

### 3. 交易信息 `tx.*`

| 变量 | 类型 | 含义 |
|------|------|------|
| `tx.origin` | `address` | 交易的最初发起者（EOA） |
| `tx.gasprice` | `uint256` | 本次交易的 Gas 价格 |

> ⚠️ `msg.sender` vs `tx.origin`：合约 A 调用合约 B 时，在 B 里 `msg.sender` = 合约A地址，`tx.origin` = 最初的 EOA。**永远不要用 `tx.origin` 做权限验证**，有钓鱼攻击风险。

### 4. `this` — 当前合约自身

| 用法 | 含义 |
|------|------|
| `address(this)` | 当前合约的地址 |
| `address(this).balance` | 当前合约持有的 ETH 余额（wei） |
| `this.someFunction()` | 对自身发起外部调用（消耗额外 Gas，少用） |

> ⚠️ `this` 不能用来给状态变量赋值，状态变量直接写变量名即可。

### 5. Gas

| 变量 | 含义 |
|------|------|
| `gasleft()` | 当前剩余 Gas 数量（函数） |

---

## 二、import 写法

```solidity
// ✅ 具名导入（推荐）：只引入需要的符号，避免命名空间污染
import {ReentrancyGuard} from "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

// ⚠️ 普通导入（不推荐）：把目标文件所有内容倒入当前命名空间
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
```

---

## 三、immutable 关键字

- 只能在构造函数中赋值一次，之后永久锁定
- 编译时内嵌到字节码（PUSH 指令），读取约 3 gas
- 普通 storage 变量读取约 2100 gas（SLOAD）
- 适用于部署后不变的值（如 goal、owner）

```solidity
uint256 public immutable goal;   // ✅ 部署后不变
uint256 public totalRaised;      // ✅ 会变化，不能用 immutable
```

---

## 四、CEI 模式 vs nonReentrant

两者是独立的两道防线，必须同时使用，不能互相替代。

| | 防什么 | 怎么防 |
|--|--------|--------|
| **CEI 模式** | 任何形式的状态不一致攻击 | 先改状态（Effects），后转账（Interactions） |
| **`nonReentrant`** | 同一函数被重入调用 | 加锁，检测到重入直接 revert |

**`nonReentrant` 的局限**：只能防止调用"同一个函数"的重入。攻击者在回调里调用另一个函数，锁完全感知不到。

**CEI 的根本防御**：不管回调里调用什么函数，状态已经改了，所有依赖旧状态的操作都会失败，不依赖任何锁。

```solidity
// ✅ 正确：CEI + nonReentrant 双重保护
function withdraw() external nonReentrant {
    uint256 amount = address(this).balance;
    state = State.Closed;                        // Effects 先行
    (bool ok,) = owner.call{value: amount}("");  // Interactions 最后
    require(ok, "Transfer failed");
}
```

**实际选择建议：优先 CEI，按需加 `nonReentrant`**

| 场景 | 建议 | 理由 |
|------|------|------|
| 逻辑简单、状态改变完整覆盖攻击路径 | 只用 CEI | 节省 2000-5000 gas |
| 大额资金转移 | CEI + `nonReentrant` | 双保险，容错成本 > gas 成本 |
| 合约逻辑复杂，CEI 覆盖不确定 | CEI + `nonReentrant` | 安全优先 |
| 安全审计项目 | CEI + `nonReentrant` | 标准要求 |

真实项目参考：
- **Uniswap V2/V3**：只用 CEI，极致 gas 优化
- **OpenZeppelin ERC20**：只用 CEI
- **Gnosis Safe**：`nonReentrant`（涉及任意外部调用）
- **Aave / Compound**：CEI + `nonReentrant` 双保险（高价值资产）

---

## 五、ReentrancyGuard

**问题**：防止同一笔交易内的重入攻击（函数执行期间被恶意回调再次调用）。

**用法**：继承后在需要保护的函数上加 `nonReentrant` 修饰符。

```solidity
contract Foo is ReentrancyGuard {
    function withdraw() external nonReentrant {
        // 安全
    }
}
```

**原理**：合约内维护一个 `_status` 锁，进入函数时设为 ENTERED，退出时恢复，重入时检测到 ENTERED 直接 revert。

**注意**：
- 锁粒度是「单笔交易」，不同地址的不同交易互不影响（以太坊单线程顺序执行）
- 两个 `nonReentrant` 函数不能互相调用（同一把锁）
- `nonReentrantView` 只能用于 `view` 函数，不改变锁状态

---

## 五、block.timestamp 使用注意

- 业界标准时间戳，以天/周为单位完全可靠
- 验证者可小幅操控（偏差几十秒内），秒级精确场景不适用
- `1 days` = 86400 秒，Solidity 时间单位字面量，推荐写法
- deadline 建议在 `start()` 时计算，而非构造函数，避免部署到启动的时间差

---

## 六、Ownable（OpenZeppelin）

继承后自动获得：
- `address public owner` 状态变量
- `onlyOwner` modifier（含零地址检查）
- `transferOwnership()` / `renounceOwnership()` 函数

```solidity
// OZ v5 构造函数需要显式传入 owner 地址
constructor(address _owner) Ownable(_owner) {}
```

手写练习时可自己实现，生产环境优先继承 Ownable。

---

## 七、EIP 体系

- **EIP**（Ethereum Improvement Proposal）：以太坊改进提案，任何人可提交
- **ERC** 是 EIP 的子集，专注应用层接口规范（如 ERC-20、ERC-721）
- **Core EIP**：修改 EVM 底层（如 EIP-1559 Gas 机制、EIP-1153 瞬态存储）

常用 EIP：

| EIP | 说明 |
|-----|------|
| EIP-20 (ERC-20) | 同质化代币标准 |
| EIP-721 (ERC-721) | NFT 标准 |
| EIP-1155 | 多代币标准 |
| EIP-1559 | Gas 费机制改革（基础费+小费） |
| EIP-1153 | 瞬态存储（TSTORE/TLOAD），交易结束自动清零，Gas 更低 |
| EIP-712 | 结构化数据签名标准 |
| EIP-2612 | ERC-20 Permit（签名授权，基于 EIP-712） |

---

## 八、Solidity 三种 ETH 转账方式

| | `transfer` | `send` | `call`（推荐） |
|--|-----------|--------|--------------|
| Gas 限制 | 固定 2300 | 固定 2300 | 转发所有剩余 gas（可指定上限） |
| 失败处理 | 自动 revert | 返回 bool，需手动处理 | 返回 bool，需手动处理 |
| 推荐程度 | ❌ 不推荐 | ❌ 不推荐 | ✅ 当前标准 |

**`transfer`**
```solidity
payable(receiver).transfer(amount);
// 失败自动 revert，2300 gas 限制
// 问题：2300 gas 不够目标合约执行任何逻辑，容易导致合法转账失败
```

**`send`**
```solidity
bool ok = payable(receiver).send(amount);
require(ok, "Transfer failed");
// 同样 2300 gas 限制，只是不自动 revert，需要手动 require
// 问题与 transfer 相同，已不推荐
```

**`call`（当前唯一推荐写法）**
```solidity
(bool ok, ) = receiver.call{value: amount}("");
require(ok, "Transfer failed");
// 转发所有剩余 gas，目标合约可以执行复杂逻辑
// 灵活，适应未来 gas 成本变化（EIP-1884 之后 transfer/send 问题更突出）
// 注意：call 之前必须做好 CEI，防重入
```

**为什么 `transfer`/`send` 被废弃：**
EIP-1884（伊斯坦布尔升级）提高了部分操作码的 gas 成本，导致目标合约的 `receive()`/`fallback()` 在 2300 gas 内无法完成基本操作，合法转账因此失败。`call` 没有这个限制。

---

## 九、Solidity 错误处理三种方式

### 对比总览

| | `require` | `revert` | `assert` |
|--|-----------|----------|----------|
| 用途 | 验证外部输入、前置条件 | 复杂条件判断、自定义错误 | 验证内部不变量（绝不应该发生的情况） |
| 退还剩余 gas | ✅ 是 | ✅ 是 | ❌ 否（消耗所有 gas） |
| 影响范围 | 回滚当前交易所有状态 | 回滚当前交易所有状态 | 回滚当前交易所有状态 |
| 错误类型 | `Error(string)` | `Error(string)` 或自定义 | `Panic(uint256)` |

---

### `require` — 最常用

**适用**：验证调用者输入、权限、状态前置条件，**可预期会发生**的失败。

```solidity
require(msg.value > 0, "Amount must be positive");       // 输入验证
require(msg.sender == owner, "Not owner");               // 权限验证
require(state == State.Active, "Wrong state");           // 状态验证
require(block.timestamp < deadline, "Campaign ended");   // 时间验证
```

失败时退还剩余 gas，用户只损失已消耗的部分。

---

### `revert` — 灵活版 require

**适用**：条件复杂不适合写在一行、或使用**自定义错误类型**（更省 gas）。

```solidity
// 写法一：等价于 require
if (msg.value == 0) {
    revert("Amount must be positive");
}

// 写法二：自定义错误（推荐，比字符串省 gas）
error InsufficientAmount(uint256 provided, uint256 required);

if (msg.value < minAmount) {
    revert InsufficientAmount(msg.value, minAmount);
}
```

自定义错误比字符串错误节省约 **50% 的部署和调用 gas**，Solidity 0.8.4+ 支持，新项目推荐使用。

---

### `assert` — 内部不变量守卫

**适用**：验证**理论上绝对不会发生**的情况，通常用于检测自身代码逻辑 bug。

```solidity
// 例：合约余额理论上永远 >= totalRaised（除非有 bug）
assert(address(this).balance >= totalRaised);

// 例：数学计算结果不应该溢出（0.8.x 已内置溢出检查，assert 更少用了）
assert(a + b >= a);
```

失败时**消耗所有剩余 gas**，不退还。这是故意的——`assert` 失败意味着合约内部出现了严重 bug，应该让调用者付出高昂代价，同时产生 `Panic` 类型错误方便链下监控告警。

**如果在生产合约里频繁触发 assert，说明合约有严重设计问题。**

---

### 使用场景速查

| 场景 | 用哪个 |
|------|--------|
| 验证 msg.value、参数合法性 | `require` |
| 权限检查（onlyOwner 等） | `require` |
| 状态机前置条件 | `require` |
| 条件复杂需要多行逻辑 | `revert` |
| 需要传递结构化错误信息给前端 | `revert` + 自定义错误 |
| 验证数学计算结果不会溢出 | `assert`（0.8+ 基本不需要了）|
| 验证合约内部不变量（防止自身 bug） | `assert` |

---

## 十、try-catch（与 Java 对比）

**Solidity try-catch 完整语法：**

```solidity
try externalContract.someFunction() returns (uint256 result) {
    // 成功
} catch Error(string memory reason) {
    // 捕获 require/revert("message") 字符串错误
} catch Panic(uint256 code) {
    // 捕获 assert 失败（code: 0x01=assert, 0x11=溢出, 0x12=除零）
} catch (bytes memory lowLevelData) {
    // 捕获自定义错误 + 其他所有情况，需手动解码
} catch {
    // 兜底
}
```

**与 Java 的核心差异：**

| | Java | Solidity |
|--|------|----------|
| 适用范围 | 任何函数调用 | **只能用于外部调用** |
| 按类型捕获 | ✅ `catch (MyException e)` | ❌ 自定义错误只能拿 bytes，手动比对 selector |
| 错误向上冒泡 | ✅ 自动，有 `throws` 声明 | revert 自动冒泡，但无 `throws` 声明机制 |
| 错误继承体系 | ✅ Exception 继承树 | ❌ 无，自定义错误是独立定义，无继承关系 |

**自定义错误手动识别方式：**
```solidity
} catch (bytes memory lowLevelData) {
    if (bytes4(lowLevelData) == InsufficientAmount.selector) {
        // 手动比对 4 字节选择器区分错误类型
    }
}
```

**根本原因：** EVM 的 revert 只传递一段裸 bytes，没有类型系统。自定义错误在 ABI 层只是 4 字节选择器 + 编码参数，类型识别需语言层手动处理。

**实际使用场景（try-catch 用得很少）：**
- 调用不可信的外部合约，防止对方 revert 拖垮自己
- 工厂合约部署子合约：`try new SubContract() returns (...)`
- 价格预言机查询，预言机可能 revert 需要降级处理

大多数合约直接用 `require`/`revert`，让错误自然冒泡，无需 try-catch。

**Solidity vs Java try-catch 结构差异：**

| | Java | Solidity |
|--|------|----------|
| try 块含义 | 被保护的代码段（可多行） | 不存在"try块"，只有单行外部调用 |
| 成功时执行 | try 块正常结束后继续往下 | `returns (...) { }` 块 |
| 失败时执行 | catch 块 | catch 块 |
| 收尾清理 | `finally` 块（必定执行） | **没有 finally** |
| 保护范围 | 任意多行代码 | **只能是单个外部调用** |

Java 里 `try {}` 是输入（放被保护的代码）；Solidity 里 `try` 后面的那行调用才是输入，`returns {}` 是成功的输出处理。两者语义完全不同。

---

## 十一、`this.` 把内部调用变成外部调用

`this.someFunction()` 让合约给**自己**发一笔 `CALL`，走完整外部调用流程。

**产生的影响：**

```solidity
function foo() external {
    // msg.sender = 外部调用者 A
    this.bar();  // 合约给自己发 CALL
}

function bar() external {
    // msg.sender = address(this)，不是 A！
}
```

| 影响点 | 说明 |
|--------|------|
| `msg.sender` 改变 | 变成 `address(this)`，会破坏权限逻辑 |
| gas 增加 | 多出 `CALL` 基础消耗（约 2600 gas） |
| 只能调用 public/external | private/internal 对外不可见，编译报错 |

**唯二合理使用场景：**
1. 在 try-catch 里包住内部逻辑（内部调用无法用 try-catch）
2. 强制走 ABI 编码路径

**日常不要用**，会引入隐蔽 bug。

---

## 十二、函数修饰符全览

### 维度一：访问控制
| 修饰符 | 说明 |
|--------|------|
| `public` | 内部 + 外部都能调用，自动生成 getter |
| `external` | 只能外部调用，参数用 calldata 更省 gas |
| `internal` | 内部 + 继承合约可调用 |
| `private` | 只有当前合约内部，继承合约也不行 |

### 维度二：状态可变性
| 修饰符 | 读 storage | 写 storage | 说明 |
|--------|-----------|-----------|------|
| 无 | ✅ | ✅ | 普通函数 |
| `view` | ✅ | ❌ | 只读，链下调用免 gas |
| `pure` | ❌ | ❌ | 纯计算，不接触任何状态，链下调用免 gas |

### 维度三：是否可接收 ETH
| 修饰符 | 说明 |
|--------|------|
| `payable` | 可接收 ETH |
| 无 | 收到 ETH 直接 revert |

### 维度四：继承相关
| 修饰符 | 说明 |
|--------|------|
| `virtual` | 声明此函数可被子合约重写 |
| `override` | 声明此函数重写了父合约同名函数 |
| `override(A, B)` | 多继承时同时重写多个父合约的同名函数 |

### 书写顺序约定
```solidity
function foo()
    external        // 1. 访问控制
    payable         // 2. payable / view / pure
    virtual         // 3. virtual / override
    onlyOwner       // 4. 自定义 modifier
    nonReentrant
    returns (uint256)
{ ... }
```

---

## 十三、合约间调用上下文对比

三种调用方式，每种产生不同的执行上下文：

| 上下文变量 | 普通 `call` | `delegatecall` | `staticcall` |
|-----------|------------|----------------|--------------|
| `msg.sender` | 变为调用方合约地址 | 保持原始调用者 | 变为调用方合约地址 |
| `msg.value` | 可以传新的 value | 保持原始 value | 必须为 0 |
| `address(this)` | 变为被调用合约地址 | 保持调用方合约地址 | 变为被调用合约地址 |
| 读写的 storage | 被调用合约自己的 | **调用方合约的 storage** | 只读，不能写 |
| 能否改变状态 | ✅ | ✅ | ❌ |

**永远不变的变量（与调用上下文无关）：**
- `tx.origin`：永远是交易最初发起的 EOA
- `block.*` 系列：区块信息全局一致
- `tx.gasprice`：交易级别属性

**`delegatecall` 的核心用途——代理合约：**
```
用户 → 代理合约 → delegatecall → 实现合约的代码
                  ↑ storage 和 address(this) 都是代理合约的
                  ↑ 代码逻辑来自实现合约
```
升级时只换实现合约地址，storage 数据和合约地址对用户完全透明，这是 UUPS/透明代理的核心原理。

---

## 十四、mapping 默认值

Solidity 的 mapping 不存在"key 不存在"的概念，所有未赋值的 key 都返回 value 类型的零值：

| value 类型 | 默认值 |
|-----------|--------|
| `uint256` | `0` |
| `bool` | `false` |
| `address` | `address(0)` |
| `bytes` | `""` |

```solidity
// 用 == 0 判断是否首次贡献，完全可靠
if (contributions[msg.sender] == 0) {
    contributors.push(msg.sender);
}
```

---

## 九、fallback() 与自定义函数的区别

| | `fallback()` | 自定义函数（如 `finalize()`） |
|--|-------------|-------------|
| 来源 | Solidity 内置特殊函数 | 开发者自己定义 |
| 触发时机 | 调用合约时找不到匹配的函数签名，或直接发送 ETH 且无 `receive()` | 主动调用 |
| 命名 | 固定必须叫 `fallback` | 随意命名 |

```solidity
// fallback：兜底函数，无函数匹配时触发
fallback() external payable { ... }

// receive：专门接收纯 ETH 转账（calldata 为空时触发）
receive() external payable { ... }
```

触发优先级：
```
收到调用
  ├─ calldata 为空 + 有 ETH → receive()（没有则走 fallback）
  └─ 找不到匹配函数         → fallback()
```

常见使用场景：
1. **接收 ETH**：合约需要接受转账时定义 `receive()`
2. **代理合约**：UUPS/透明代理用 `fallback` 把所有未知调用转发给实现合约（小作业03会用到）
3. **多签钱包**：两个都定义，接收 ETH 存款并支持任意调用转发

众筹合约建议：
```solidity
// 拒绝直接转账，强制走 contribute() 流程
receive() external payable {
    revert("Please use contribute()");
}
```

---

## 十、Foundry 工具链：forge / anvil / cast

Foundry 包含三个核心命令行工具：

| 工具 | 用途 |
|------|------|
| `forge` | 编译、测试、部署合约 |
| `anvil` | 本地测试链（类似 Hardhat Network） |
| `cast` | 与链交互（读写合约、查询数据） |

---

### 10.1 forge 常用命令

```bash
# 编译
forge build

# 运行所有测试
forge test

# 带详细输出（v/vv/vvv/vvvv 详细程度递增）
forge test -vv
forge test -vvvv

# 运行指定测试
forge test --match-test test_WithdrawByOwner
forge test --match-contract CrowdfundingTest

# 调试某个测试（TUI 调试器）
forge test --match-test test_WithdrawByOwner --debug

# 覆盖率报告
forge coverage
forge coverage --report lcov   # 生成 lcov 格式，可用 genhtml 生成 HTML

# Gas 报告
forge test --gas-report

# Gas 快照（生成基准，用于对比优化效果）
forge snapshot
forge snapshot --diff           # 和上次快照对比差异

# 部署脚本（模拟，不上链）
forge script script/Deploy.s.sol --rpc-url http://127.0.0.1:8545

# 部署脚本（真实上链）
forge script script/Deploy.s.sol \
  --rpc-url $SEPOLIA_RPC_URL \
  --broadcast \
  --verify                      # 同时在 Etherscan 验证源码

# 安装依赖
forge install OpenZeppelin/openzeppelin-contracts --no-git
forge install OpenZeppelin/openzeppelin-contracts-upgradeable --no-git
forge install smartcontractkit/chainlink --no-git
forge install smartcontractkit/chainlink-brownie-contracts --no-git

# 生成 remappings
forge remappings > remappings.txt

# 查看合约 ABI
forge inspect CrowdfundingFactory abi

# 查看合约存储布局（slot 分布）
forge inspect CrowdfundingCampaign storage-layout
```

---

### 10.2 anvil 常用命令

anvil 是本地测试链，启动后提供 10 个测试账户（每个 10000 ETH）和对应私钥。

```bash
# 启动本地链（默认端口 8545）
anvil

# 指定 chain ID（默认 31337）
anvil --chain-id 1337

# 指定账户数量和初始余额
anvil --accounts 20 --balance 1000

# 指定区块时间（默认不自动出块，有交易才出块）
anvil --block-time 2       # 每 2 秒自动出一个区块

# fork 主网/测试网（在真实链状态上测试）
anvil --fork-url https://mainnet.infura.io/v3/YOUR_KEY
anvil --fork-url $SEPOLIA_RPC_URL --fork-block-number 5000000

# 持久化状态（关闭时保存，重启时加载）
anvil --dump-state state.json
anvil --load-state state.json

# 设置 gas limit
anvil --gas-limit 30000000

# 无 gas 限制（方便测试大型合约）
anvil --disable-block-gas-limit
```

anvil 启动后输出的默认私钥（本地测试专用，切勿用于真实网络）：
```
Account 0: 0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266
Private Key: 0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80
```

---

### 10.3 cast 常用命令

cast 是链交互工具，可以读写合约、查询数据、编解码 ABI 等。

#### 查询（读操作，不消耗 Gas）

```bash
# 调用 view 函数
cast call <合约地址> "函数签名(参数类型)(返回类型)" [参数值] --rpc-url <RPC>

# 示例：查询众筹项目数量
cast call 0x5FbDB... "getCampaignCount()(uint256)" --rpc-url http://127.0.0.1:8545

# 查询账户 ETH 余额
cast balance 0xf39Fd6... --rpc-url http://127.0.0.1:8545

# 查询合约代码（是否有代码 = 是否是合约）
cast code 0x5FbDB... --rpc-url http://127.0.0.1:8545

# 查询某个 storage slot 的值
cast storage 0x5FbDB... 0 --rpc-url http://127.0.0.1:8545

# 查询交易详情
cast tx 0x7e162fe... --rpc-url http://127.0.0.1:8545

# 查询交易收据
cast receipt 0x7e162fe... --rpc-url http://127.0.0.1:8545

# 查询当前区块号
cast block-number --rpc-url http://127.0.0.1:8545

# 查询当前 Gas 价格
cast gas-price --rpc-url http://127.0.0.1:8545
```

#### 发送交易（写操作，消耗 Gas）

```bash
# 调用写函数
cast send <合约地址> "函数签名(参数类型)" [参数值] \
  --private-key <私钥> \
  --rpc-url <RPC>

# 示例：创建众筹项目（10 ETH 目标，30天）
cast send 0x5FbDB... "createCampaign(uint256,uint256)" \
  10000000000000000000 30 \
  --private-key 0xac0974... \
  --rpc-url http://127.0.0.1:8545

# 附带 ETH 调用 payable 函数
cast send 0x5FbDB... "contribute()" \
  --value 1ether \
  --private-key 0xac0974... \
  --rpc-url http://127.0.0.1:8545

# 纯 ETH 转账
cast send 0xRecipient... \
  --value 1ether \
  --private-key 0xac0974... \
  --rpc-url http://127.0.0.1:8545
```

#### ABI 编解码工具

```bash
# 编码函数调用（生成 calldata）
cast calldata "createCampaign(uint256,uint256)" 10000000000000000000 30

# 解码 calldata
cast calldata-decode "createCampaign(uint256,uint256)" 0x...

# 计算函数选择器（前4字节）
cast sig "createCampaign(uint256,uint256)"
# 输出：0x7b3a3c8b

# 计算 keccak256 哈希
cast keccak "hello"

# 单位换算
cast to-wei 1               # 1 ETH → wei
cast from-wei 1000000000000000000  # wei → ETH
cast to-unit 1gwei wei      # gwei → wei
```

#### 账户工具

```bash
# 私钥 → 地址
cast wallet address --private-key 0xac0974...

# 生成新钱包
cast wallet new

# 查看 ENS 域名对应的地址
cast resolve-name vitalik.eth --rpc-url https://mainnet.infura.io/v3/KEY
```

---

### 10.4 部署脚本 API 速查（Script 合约专用）

| API | 作用 |
|-----|------|
| `vm.startBroadcast()` | 开始广播，使用命令行 `--private-key` |
| `vm.startBroadcast(privateKey)` | 开始广播，使用指定私钥 |
| `vm.stopBroadcast()` | 结束广播 |
| `vm.envUint("KEY")` | 读取环境变量为 uint256 |
| `vm.envAddress("KEY")` | 读取环境变量为 address |
| `vm.envString("KEY")` | 读取环境变量为 string |
| `vm.envOr("KEY", defaultVal)` | 读取环境变量，不存在时用默认值 |
| `vm.addr(privateKey)` | 私钥 → 对应的钱包地址 |
| `block.chainid` | 当前链 ID（用于多环境判断） |

**部署脚本最佳实践：**

```solidity
function run() external returns (CrowdfundingFactory) {
    // 1. 安全检查：防止误部署到主网
    require(block.chainid != 1, "Do not deploy to mainnet");

    uint256 privateKey  = vm.envUint("PRIVATE_KEY");
    address deployerAddr = vm.addr(privateKey);

    // 2. 部署前信息确认
    console.log("Chain ID:        ", block.chainid);
    console.log("Deployer:        ", deployerAddr);
    console.log("Deployer balance:", deployerAddr.balance);

    vm.startBroadcast(privateKey);

    // 3. 按依赖顺序部署
    CrowdfundingFactory factory = new CrowdfundingFactory();

    // 4. 部署后初始化（如果需要）
    // factory.initialize(...);

    vm.stopBroadcast();

    // 5. 部署后验证
    console.log("=== Deployment Summary ===");
    console.log("CrowdfundingFactory:", address(factory));

    // 6. 返回合约实例（方便测试和其他脚本复用）
    return factory;
}
```

**部署到测试网完整命令：**

```bash
# 配置 .env 文件
PRIVATE_KEY=0x...
SEPOLIA_RPC_URL=https://sepolia.infura.io/v3/YOUR_KEY
ETHERSCAN_API_KEY=YOUR_KEY

# 加载环境变量
source .env

# 部署并验证
forge script script/Deploy.s.sol \
  --rpc-url $SEPOLIA_RPC_URL \
  --broadcast \
  --verify \
  -vvvv
```

---

## 十一、Web3 常用网址

### 11.1 行情与数据

| 网址 | 作用 |
|------|------|
| [coinmarketcap.com](https://coinmarketcap.com) | 查看所有代币的实时价格、市值、交易量排行，是最常用的行情网站 |
| [etherscan.io](https://etherscan.io) | 以太坊主网区块浏览器，查交易、合约、地址余额、事件日志 |
| [sepolia.etherscan.io](https://sepolia.etherscan.io) | Sepolia 测试网区块浏览器 |

### 11.2 开发基础设施

| 网址 | 作用 |
|------|------|
| [chainlist.org](https://chainlist.org) | 所有 EVM 兼容链的 Chain ID 和 RPC 地址汇总，点击即可一键添加到 MetaMask |
| [alchemy.com](https://alchemy.com) | 提供以太坊/各链的 RPC 节点服务，开发者常用，有免费额度 |
| [infura.io](https://infura.io) | 同上，另一家主流 RPC 节点服务提供商 |

### 11.3 钱包

| 网址 | 作用 |
|------|------|
| MetaMask（浏览器插件） | 最主流的以太坊钱包，连接 DApp 的标准入口 |
| [web3.okx.com](https://web3.okx.com) | OKX Web3 钱包，支持 130+ 条链，可在浏览器直接使用，功能比 MetaMask 更丰富（内置 DEX 聚合、跨链等） |

### 11.4 DeFi 协议

| 网址 | 作用 |
|------|------|
| [app.uniswap.org](https://app.uniswap.org) | 最大的去中心化交易所（DEX），可在链上直接兑换代币，无需中间人，基于自动做市商（AMM）模型 |
| [aave.com](https://aave.com) | 去中心化借贷协议，可存币赚利息或抵押借款，课件中 DeFi 借贷案例参考的就是 Aave |

### 11.5 合约开发资源

| 网址 | 作用 |
|------|------|
| [docs.openzeppelin.com](https://docs.openzeppelin.com) | OpenZeppelin 官方文档，Solidity 安全合约库，本项目用到的 Ownable/ReentrancyGuard 均来自此 |
| [book.getfoundry.sh](https://book.getfoundry.sh) | Foundry 官方文档，forge/anvil/cast 所有命令的权威参考 |
| [remix.ethereum.org](https://remix.ethereum.org) | 浏览器在线 Solidity IDE，适合快速验证和调试小合约 |
| [docs.soliditylang.org](https://docs.soliditylang.org) | Solidity 官方文档 |

### 11.6 测试币水龙头

| 网址 | 作用 |
|------|------|
| [cloud.google.com/…/sepolia](https://cloud.google.com/application/web3/faucet/ethereum/sepolia) | Google 水龙头，只需 Google 账号，每天 0.05 ETH，无需主网余额 |
| [faucets.chain.link/sepolia](https://faucets.chain.link/sepolia) | Chainlink 水龙头，需 GitHub 账号 |
| [sepoliafaucet.com](https://sepoliafaucet.com) | Alchemy 水龙头，需注册 Alchemy 账号 |

---

## 12. Web3 生态重要实体

Web3 生态不只有技术层面的角色，还有在市场、流动性、基础设施、标准制定等层面扮演核心角色的实体。

### 12.1 NFT 市场层

NFT 市场负责撮合买卖双方，类似于传统世界的淘宝/亚马逊，但运行在链上。

| 实体 | 定位 | 核心作用 |
|------|------|----------|
| **OpenSea** | 最大综合 NFT 市场 | 读取合约 `tokenURI()` 展示元数据；提供二级市场交易；长期占据最大市场份额 |
| **Blur** | 面向专业交易者的 NFT 市场 | 以零手续费和高速聚合抢占市场，2023 年交易量超过 OpenSea；引入积分/空投机制改变了 NFT 市场竞争格局 |
| **LooksRare** | 社区驱动 NFT 市场 | 用代币奖励激励交易，是第一个以"吸血鬼攻击"策略挑战 OpenSea 的对手 |
| **Foundation** | 策展型艺术 NFT 平台 | 面向艺术家，需邀请制，定位高端艺术品，更接近画廊模式 |
| **Magic Eden** | Solana 最大 NFT 市场 | 后扩张到多链，是跨链 NFT 市场的重要玩家 |

**OpenSea 在生态中的角色（不止是技术）：**
- **市场定价权**：OpenSea 的流量决定了大多数 NFT 项目的可见度和流动性
- **标准影响力**：OpenSea 制定了 NFT 元数据展示标准（JSON 格式、属性字段命名），事实上成为了行业标准
- **版税争议**：2022 年 OpenSea 与 Blur 的版税战（是否强制执行创作者版税）影响了整个 NFT 行业的商业模式

---

### 12.2 DeFi 协议层

DeFi（去中心化金融）协议是 Web3 中流动性和金融基础设施的核心。

| 实体 | 定位 | 核心作用 |
|------|------|----------|
| **Uniswap** | 最大去中心化交易所（DEX） | 发明 AMM（自动做市商）模型，取代传统订单簿；V3 引入集中流动性，成为 DeFi 基础设施 |
| **Aave** | 最大借贷协议 | 用户存入资产赚利息，或抵押借出其他资产；引入闪电贷（Flash Loan） |
| **Compound** | 早期借贷协议 | 率先发明流动性挖矿（借贷即挖矿），引发 2020 年 DeFi Summer |
| **Curve** | 稳定币专用 DEX | 专注于稳定币之间的低滑点兑换，是稳定币流动性的核心基础设施 |
| **MakerDAO / Sky** | 去中心化稳定币 DAI 的发行方 | 通过超额抵押 ETH 铸造 DAI，是最早也是最重要的去中心化稳定币 |
| **Lido** | 流动性质押协议 | 用户质押 ETH 获得 stETH，可继续参与 DeFi，是以太坊质押量最大的协议 |

---

### 12.3 基础设施层

| 实体 | 定位 | 核心作用 |
|------|------|----------|
| **Chainlink** | 去中心化预言机网络 | 为合约提供链外数据（价格、随机数、跨链消息等），详见第 12.4 节 |
| **The Graph** | 链上数据索引协议 | 区块链数据查询极慢，The Graph 对链上事件建立索引，提供类似 GraphQL 的查询接口；绝大多数 DeFi 前端使用它来读取历史数据 |
| **IPFS / Filecoin** | 去中心化存储 | IPFS 是协议层（内容寻址），Filecoin 是激励层（付费存储），NFT 图片/元数据存储的主要方案 |
| **Arweave** | 永久存储网络 | 一次付费永久存储，比 IPFS（需要节点持续 pin）更彻底；Solana NFT 项目大量使用 |
| **Safe (Gnosis Safe)** | 多签钱包基础设施 | 几乎所有 DeFi 协议的国库和合约升级都用 Safe 多签管理，是 Web3 最重要的安全基础设施之一 |
| **OpenZeppelin** | 智能合约安全标准库 | 提供经过审计的合约模板（ERC20、ERC721、UUPS 等），绝大多数合约项目都基于它构建 |

---

### 12.4 常用链上服务（Chainlink 系列）

Chainlink 提供多种链上服务，合约可以像调用接口一样使用这些服务。

#### Price Feed（价格预言机）
```
场景：借贷协议需要知道 ETH 的实时价格来计算抵押率
用法：直接读取 Chainlink 维护的链上价格合约（无需订阅）
```
```solidity
AggregatorV3Interface priceFeed = AggregatorV3Interface(0x694AA1...);
(, int256 price,,,) = priceFeed.latestRoundData();
// price = 200000000000  → 即 $2000.00（8位小数）
```
**使用它的知名项目：** Aave、Compound、MakerDAO

#### VRF（可验证随机数）
```
场景：NFT 盲盒、链上游戏、彩票需要不可预测的随机数
流程：合约请求 → Chainlink 节点生成 + 密码学证明 → 回调合约
需要：创建 Subscription，充值 LINK 代币（每次请求消耗少量 LINK）
```
**使用它的知名项目：** PoolTogether（链上彩票）、各种 NFT 项目

#### Automation（自动化执行）
```
场景：当某条件满足时自动执行合约函数（如清算、定时分红）
原理：Chainlink 节点持续监控条件，条件满足时自动调用你的合约
无需：用户手动触发，类似链上 Cron Job
```
**使用它的知名项目：** Aave（自动清算触发）、各种收益聚合器

#### CCIP（跨链互操作协议）
```
场景：把代币或消息从 Ethereum 发送到 Polygon/Arbitrum 等其他链
```
**使用它的知名项目：** Synthetix 跨链部署

---

### 12.5 为什么透明代理先于 UUPS 出现

透明代理（Transparent Proxy）在 2019-2020 年被广泛采用，UUPS 在 2021 年才由 EIP-1822 标准化并被 OZ 推广。原因在于两者解决的是同一个问题，但各自揭示了不同阶段的工程认知。

**透明代理的核心设计问题（Selector Clash，函数选择器冲突）：**

```
问题：
  Proxy 合约有一个 upgradeTo(address) 方法（用于升级）
  Implementation 合约恰好也有一个 upgradeTo(address) 方法（业务逻辑）
  
  当用户调用 proxy.upgradeTo(x) 时，到底执行哪个？
```

透明代理的解法是"区分调用者"：

```solidity
// 透明代理的 fallback 伪码
fallback() {
    if (msg.sender == admin) {
        // 管理员调用 → 直接执行 Proxy 自身的方法（upgradeTo 等）
        // 不转发给 Implementation
    } else {
        // 普通用户 → delegatecall 到 Implementation
        delegatecall(implementation, msg.data)
    }
}
```

这个方案能用，但有两个代价：
1. 每笔交易都要读一次 `admin` 地址做比较（额外 SLOAD）
2. 需要单独部署 ProxyAdmin 合约来隔离管理员权限

UUPS 的解法是"把升级逻辑放进 Implementation"：

```solidity
// UUPS 的 Proxy 伪码（极简）
fallback() {
    delegatecall(implementation, msg.data)  // 无条件转发，不判断任何东西
}

// Implementation 里的升级函数
function upgradeTo(address newImpl) external onlyOwner {
    // 选择器冲突？不存在，因为 Proxy 自身没有任何业务函数
    // 这个函数本身就是通过 delegatecall 在 Proxy 的存储上执行的
    _upgradeToAndCall(newImpl)
}
```

UUPS 更优雅，但它要求开发者理解"升级函数在 Implementation 里，如果升级到没有升级函数的合约，代理就永久锁死"。这对 2019 年的开发者认知要求更高，透明代理更直觉、更安全（最坏情况是浪费 gas，不会锁死合约）。

**结论：透明代理是"先能跑"的工程解，UUPS 是"跑得更好"的优化解，技术演进的正常路径。**

---

### 12.6 开源学习项目推荐

#### NFT 相关
| 项目 | 地址 | 学习点 |
|------|------|--------|
| OpenZeppelin Contracts | [github.com/OpenZeppelin/openzeppelin-contracts](https://github.com/OpenZeppelin/openzeppelin-contracts) | ERC721、ERC20、UUPS 等标准实现的权威参考 |
| Azuki NFT | [github.com/chiru-labs/ERC721A](https://github.com/chiru-labs/ERC721A) | ERC721 的 Gas 优化版（批量 mint 大幅降低 gas），Azuki、BAYC 系列使用 |
| Art Gobblers | [github.com/artgobblers/art-gobblers](https://github.com/artgobblers/art-gobblers) | a16z 出品，链上随机生成艺术 NFT，VRF + 可升级的优秀实践 |

#### DeFi 相关
| 项目 | 地址 | 学习点 |
|------|------|--------|
| Uniswap V2 | [github.com/Uniswap/v2-core](https://github.com/Uniswap/v2-core) | AMM 最经典的实现，代码量少，是读懂 DeFi 的必读材料 |
| Uniswap V3 | [github.com/Uniswap/v3-core](https://github.com/Uniswap/v3-core) | 集中流动性，数学较复杂，进阶读物 |
| Aave V3 | [github.com/aave/aave-v3-core](https://github.com/aave/aave-v3-core) | 借贷协议最完整的工业级实现 |

#### 学习型项目（专为学习设计，代码更易读）
| 项目 | 地址 | 学习点 |
|------|------|--------|
| Damn Vulnerable DeFi | [github.com/tinchoabbate/damn-vulnerable-defi](https://github.com/tinchoabbate/damn-vulnerable-defi) | 专门设计的 DeFi 漏洞练习题，学安全必做 |
| Foundry 官方示例 | [github.com/foundry-rs/foundry-starter-kit](https://github.com/foundry-rs/foundry-starter-kit) | Foundry 项目最佳实践模板 |
| Patrick Collins 课程代码 | [github.com/Cyfrin/foundry-full-course-f23](https://github.com/Cyfrin/foundry-full-course-f23) | 最系统的 Foundry 全栈课程配套代码，涵盖 NFT/DeFi/UUPS/VRF |

---

## 十、生产安全：信任模型与逃生出口

### 核心原则

> **每引入一个外部依赖，就问：如果它永远不响应，用户的资金会被永久锁死吗？**
> 如果答案是"会"，必须设计逃生出口。

### 可信 vs 不可信

| 可信 | 不可信 |
|------|--------|
| 自己的合约代码（部署后不可篡改） | 外部用户（`msg.sender`）——恶意输入、重入、MEV |
| OpenZeppelin 库（经审计、亿级资金验证） | Chainlink VRF——LINK 耗尽、节点延迟、回调永不到达 |
| `onlyOwner` 调用路径 | 外部策略/协议合约——可能被升级成恶意逻辑 |
| 合约内部函数调用 | IPFS 链接——内容可被删除，网关可失效 |
| | 预言机价格——可被闪贷操纵 |
| | 跨链桥——消息丢失或延迟 |

### 逃生出口设计模式

| 不可信依赖 | 逃生出口函数 |
|-----------|------------|
| Chainlink VRF 回调失败 | `retryVRF()` 重新发起 + `refund()` 退款销毁 |
| 策略合约出 bug | `setSaleStrategy()` / `setRarityStrategy()` / `setMetadataStrategy()` |
| IPFS 链接失效 | `setBaseTokenURI()` / `setBlindBoxURI()` |
| ETH 意外锁死 | `withdraw()` |
| 合约逻辑严重 bug | UUPS `upgradeTo()` |

### 后门本身的权限管理

逃生出口是双刃剑，`onlyOwner` 本身是中心化风险：

```
低风险操作（改 URI）      → onlyOwner 直接调用
中风险操作（换策略合约）  → 多签钱包（Gnosis Safe，需要 M/N 签名确认）
高风险操作（升级合约）    → 时间锁（TimeLock，48h 延迟，给社区反应时间）
```
