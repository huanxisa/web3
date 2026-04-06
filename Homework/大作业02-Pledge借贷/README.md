# 大作业02：Pledge 去中心化借贷协议

> 参考架构文档：`../README.md`
> 参考代码仓库：https://github.com/MetaNodeAcademy/ProjectBreakdown-Pledge

## 作业目标

实现一个固定利率去中心化借贷协议（DeFi Lending），包含借贷池管理、存款取款、自动清算等核心功能。

## 核心合约（contracts/）

### PledgePool.sol（核心借贷池合约）
- [ ] **借贷池创建与管理**
  - [ ] 创建借贷池（设置借贷参数、利率、期限）
  - [ ] 借贷池状态管理（募集中 → 运行中 → 到期 → 已清算）

- [ ] **贷款人（Lender）操作**
  - [ ] `depositLend()`：贷款人存入资金，获得 pToken
  - [ ] `refundLend()`：募集失败后退款
  - [ ] `claimLend()`：到期后领取本金 + 利息

- [ ] **借款人（Borrower）操作**
  - [ ] `depositBorrow()`：借款人抵押资产
  - [ ] `refundBorrow()`：抵押失败后退款
  - [ ] `claimBorrow()`：获取借出的资金
  - [ ] `repay()`：还款（本金 + 利息）

- [ ] **自动清算**
  - [ ] `liquidate()`：当抵押品价值低于阈值时触发清算
  - [ ] 清算阈值计算（基于 Chainlink 价格预言机）

- [ ] **费用管理**
  - [ ] 协议费收取与管理

### pToken / jToken
- [ ] pToken（ERC20）：代表贷款人的份额
- [ ] jToken（ERC20）：代表借款人的债务

### 事件定义
- [ ] `DepositLend` / `RefundLend` / `ClaimLend`
- [ ] `DepositBorrow` / `RefundBorrow` / `ClaimBorrow`
- [ ] `Liquidate`

## 测试覆盖（test/）
- [ ] 借贷池创建测试
- [ ] 贷款人存款 → 领取收益完整流程
- [ ] 借款人抵押 → 还款完整流程
- [ ] 自动清算测试（Chainlink Mock 价格下跌触发清算）
- [ ] 边界测试（募集不足退款、利率计算精度）

## 部署（scripts/）
- [ ] 部署 pToken / jToken
- [ ] 部署 PledgePool（配置 Chainlink 价格预言机地址）
- [ ] 部署到 Sepolia 测试网

## 技术栈
- Solidity 0.8.24
- OpenZeppelin Contracts（ERC20）
- Chainlink（价格预言机）
- Hardhat 3 + TypeScript
