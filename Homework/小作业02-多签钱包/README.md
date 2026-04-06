# 小作业02：多签钱包项目实战

> 参考学习资料：`../Solidity智能合约开发 - 多签钱包项目实战(学习资料).md`

## 作业目标

独立实现一个功能完备的多签钱包合约（Multi-Signature Wallet）。

## 核心合约

### MultiSigWallet.sol

#### 数据结构
- [ ] `address[] owners` + `mapping(address => bool) isOwner`
- [ ] `uint256 numConfirmationsRequired`（确认阈值）
- [ ] `Transaction[] transactions`（提案列表）
- [ ] `mapping(uint256 => mapping(address => bool)) isConfirmed`（确认状态）

#### 修饰符
- [ ] `onlyOwner` / `txExists` / `notExecuted` / `notConfirmed`

#### 所有者管理
- [ ] `addOwner()` / `removeOwner()`（Gas 优化：交换后删除）
- [ ] `changeThreshold()`

#### 交易提案
- [ ] `submitTransaction(to, value, data)`

#### 确认机制
- [ ] `confirmTransaction()` / `revokeConfirmation()`

#### 执行交易
- [ ] `executeTransaction()`（CEI 模式，防重入）

#### 接收 ETH
- [ ] `receive()` / `fallback()` + `Deposit` 事件

#### 查询辅助函数
- [ ] `getOwners()` / `getThreshold()` / `getBalance()`
- [ ] `isTransactionConfirmed()` / `getConfirmationCount()` / `canExecute()`

## 测试覆盖（test/）
- [ ] 部署测试（正确初始化、拒绝零地址、拒绝无效阈值）
- [ ] 所有者管理测试（添加、删除、阈值约束、权限拒绝）
- [ ] 提案功能测试（提交、查询）
- [ ] 确认机制测试（确认、撤销、防重复确认）
- [ ] 执行交易测试（ETH 转账、防重复执行、确认数不足）
- [ ] 边界测试

## 技术栈
- Solidity 0.8.24
- Hardhat 3 + TypeScript
- Chai（测试）
