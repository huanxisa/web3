# 大作业01：NFT 交易市场（拍卖市场）

> 参考架构文档：`../NFTMartket.md`
> 参考额外作业要求：`../../LearningRoadmap/contract/homework03.md`
>
> **说明**：`LearningRoadmap/contract/homework03.md` 中的 NFT 拍卖市场任务与本大作业高度重叠，合并为同一个项目完成。

## 作业目标

实现一个基于订单簿模型的去中心化 NFT 交易市场，集成 Chainlink 预言机价格喂价，支持 UUPS 合约升级。

## 核心合约（contracts/）

### NFT 合约
- [ ] `MockNFT.sol`：ERC721 标准，支持铸造和转移

### 核心交易合约
- [ ] `OrderBookExchange.sol`：完整订单簿交易逻辑
  - [ ] `OrderStorage`：订单存储模块
  - [ ] `OrderValidator`：订单逻辑验证模块
  - [ ] `ProtocolManager`：协议费管理模块
- [ ] `OrderVault.sol`：独立存储订单相关资产

### 订单功能
- [ ] **Limit Sell Order**：限价挂卖 NFT
- [ ] **Limit Buy Order**：限价出价购买 NFT
- [ ] **Market Sell Order**：市价卖出 NFT
- [ ] **Market Buy Order**：市价买入 NFT
- [ ] **Edit / Cancel Order**：修改或取消订单

### Chainlink 预言机集成
- [ ] 获取 ETH/USD 价格喂价（`AggregatorV3Interface`）
- [ ] 获取 ERC20/USD 价格，统一换算为美元比较出价

### 合约升级（UUPS / 透明代理）
- [ ] 使用 UUPS 或透明代理模式部署核心合约
- [ ] 实现 V2 升级版本

## 测试覆盖（test/）
- [ ] NFT 铸造和授权测试
- [ ] 挂卖、出价、成交完整流程测试
- [ ] 取消订单测试
- [ ] Chainlink Mock 预言机价格测试
- [ ] 代理升级测试（V1 → V2）

## 部署（scripts/ 或 ignition/）
- [ ] 部署 NFT 合约
- [ ] 部署 OrderVault
- [ ] 部署 OrderBookExchange（代理模式）
- [ ] 配置 Chainlink 价格预言机
- [ ] 部署到 Sepolia 测试网

## 提交内容
- [ ] 完整合约代码
- [ ] 测试报告（覆盖率 + 测试结果）
- [ ] 测试网合约地址
- [ ] 项目文档

## 技术栈
- Solidity 0.8.24
- OpenZeppelin Contracts（ERC721 + UUPS）
- Chainlink（AggregatorV3Interface）
- Hardhat 3 + TypeScript
- hardhat-deploy / Hardhat Ignition
