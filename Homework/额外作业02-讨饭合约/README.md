# 额外作业02：讨饭合约（BeggingContract）

> 作业要求：`../homework02.md`

## 作业说明

与 lessonA14.1 众筹平台**概念相近**（都涉及收款与提款），但本任务更简单，属于**独立的合约练习**，分开完成。

区别：众筹平台有状态机、工厂模式、目标金额、退款机制；讨饭合约仅是简单捐款记录 + owner 提款。

## 合约需求

### BeggingContract.sol
- [ ] `mapping(address => uint256) donations`：记录每个捐赠者的金额
- [ ] `donate()` 函数（`payable`）：接收 ETH，记录捐赠信息
- [ ] `withdraw()` 函数：owner 提取所有资金（`onlyOwner`）
- [ ] `getDonation(address)` 函数：查询某地址的捐赠金额

### 额外挑战（可选）
- [ ] `Donation` 事件：记录每次捐赠的地址和金额
- [ ] 捐赠排行榜：显示捐赠金额最多的前 3 个地址
- [ ] 时间限制：只有在特定时间段内才能捐赠

## 部署要求
- [ ] 在 Remix IDE 中编译合约
- [ ] 部署到 Sepolia 测试网
- [ ] 使用 MetaMask 测试 donate、withdraw、getDonation 功能

## 提交内容
- [ ] `BeggingContract.sol` 合约文件
- [ ] 部署到测试网的合约地址
- [ ] Remix 或 Etherscan 测试截图

## 文件结构
```
homework02-code/
└── contracts/
    └── BeggingContract.sol
```
