# 大作业01：NFT 拍卖市场

## 项目概述

实现一个完整的 NFT 拍卖 DApp，包含链上智能合约和链下 Go 后端两部分。

**架构图**：
```
前端 (JS)                后端 (Go)               以太坊节点
   │                        │                        │
   │── createAuction ──────►│                        │
   │── placeBid ───────────►│     合约 ABI           │
   │── endAuction ─────────►│◄── 事件订阅 ──────────►│
   │                        │       │                │
   │◄── REST API ───────────│    MySQL               │
                            │    Redis               │
```

- **前端**：直接调用合约（用户签名交易），无需经过后端
- **后端**：监听链上事件 → 解析入库 → 提供 REST API 供前端查询

---

## Part 1：智能合约

### 合约功能

#### 核心数据结构
```solidity
// NFT Token → 拍卖 ID 的映射（避免同一 NFT 重复拍卖）
mapping(address => mapping(uint256 => uint256)) public nftToken2AuctionId;
// 拍卖 ID → 拍卖数据
mapping(uint256 => Auction) public auctionData;
```

#### 拍卖生命周期
| 状态 | 说明 |
|---|---|
| 未开始 | 创建后等待开始时间到达 |
| 进行中 | 接受出价，每次出价必须高于当前最高价 |
| 已结束 | 时间到期，可调用 endAuction 完成交割 |
| 已取消 | 无人出价时卖家可取消，取回 NFT |

#### 合约函数
- [ ] `createAuction(nftContract, tokenId, startPrice, startTime, duration)`
  - NFT 转入合约锁定
  - 配置起拍价、开始时间、持续时长
- [ ] `placeBid(auctionId)`
  - ETH 转入合约锁定
  - 前一个出价者的 ETH 自动退回
  - 出价必须高于当前最高价
- [ ] `endAuction(auctionId)`
  - 拍卖时间到期后可调用
  - 买家获得 NFT，卖家获得 ETH
- [ ] `cancelAuction(auctionId)`
  - 无人出价时卖家可取消
  - NFT 退回卖家

#### 合约事件（后端监听的入口）
```solidity
event AuctionCreated(uint256 indexed auctionId, address indexed seller, address nftContract, uint256 tokenId, uint256 startPrice, uint256 startTime, uint256 endTime);
event BidPlaced(uint256 indexed auctionId, address indexed bidder, uint256 amount);
event AuctionEnded(uint256 indexed auctionId, address indexed winner, uint256 amount);
event AuctionCancelled(uint256 indexed auctionId);
```

### 合约测试覆盖
- [ ] 创建拍卖、NFT 锁定验证
- [ ] 出价流程（正常出价、低价被拒、前置出价退款）
- [ ] 时间边界（未开始不能出价、未到期不能结束）
- [ ] 结束拍卖（NFT 转移 + ETH 转移）
- [ ] 取消拍卖（有出价时不能取消）

### 合约部署
- [ ] 部署 MockNFT（ERC721）
- [ ] 部署 NFTAuction 合约
- [ ] 部署到 Sepolia 测试网

---

## Part 2：Go 后端

参考实现：
- [YuLengsen/nft-auction-dapp/backend](https://github.com/YuLengsen/nft-auction-dapp/tree/main/backend)
- [j66609083/NftAutionMarketBackend](https://github.com/j66609083/NftAutionMarketBackend)
- [okzhp/MetaNodeMissions/auctionBackEnd](https://github.com/okzhp/MetaNodeMissions/tree/main/backend/auctionBackEnd)

### 技术栈
- **语言**：Go
- **HTTP 框架**：Gin
- **ORM**：GORM
- **数据库**：MySQL
- **缓存**：Redis（可选）
- **链上交互**：go-ethereum + abigen
- **节点 RPC**：Alchemy（Sepolia）

### 数据库表设计
```sql
-- 拍卖主表
auctions (id, auction_id, seller, nft_contract, token_id, start_price,
          start_time, end_time, status, highest_bid, winner, tx_hash, block_number)

-- 出价历史表
bids (id, auction_id, bidder, amount, tx_hash, block_number, created_at)

-- 索引进度游标（保证重启可恢复）
sync_cursors (contract_address, last_block)
```

### Indexer（链上事件同步）
- [ ] 订阅 / 轮询合约事件（AuctionCreated / BidPlaced / AuctionEnded / AuctionCancelled）
- [ ] 解析事件写入 MySQL
- [ ] 游标机制：记录已处理到的区块号，服务重启后从断点继续
- [ ] 异常重连：网络中断后自动重试

### REST API
| 方法 | 路径 | 说明 |
|---|---|---|
| GET | `/health` | 健康检查 |
| GET | `/api/stats` | 平台统计（拍卖总数、出价总数、进行中数量）|
| GET | `/api/auctions` | 拍卖列表（支持状态过滤、排序）|
| GET | `/api/auctions/:id` | 拍卖详情（NFT 信息、最高价、获胜者）|
| GET | `/api/auctions/:id/bids` | 某拍卖的出价历史记录 |
| GET | `/api/wallet/:address/nfts` | 查询钱包持有的所有 NFT |

### 第三方 API 集成
- [ ] **Alchemy NFT API**：查询钱包地址持有的 NFT 列表
  - 参考：https://www.alchemy.com/docs/reference/nft-api-overview
- [ ] **OpenSea API**（可选）：查询 NFT 集合地板价
  - 参考：https://docs.opensea.io/reference/api-overview

### 项目结构
```
backend/
├── cmd/server/main.go          # 入口：同时启动 Indexer 和 API Server
├── internal/
│   ├── indexer/                # 链上事件监听与解析
│   ├── api/                    # HTTP Handler + 路由
│   ├── infra/db/               # 数据模型 + Repository 层
│   └── config/                 # 环境变量配置
├── abi/                        # 合约 ABI JSON（abigen 生成 Go 绑定）
└── docker-compose.yml          # MySQL + Redis 本地环境
```

---

## 可选扩展

### 积分空投系统
- 每季度统计用户参与积分：
  - 创建拍卖：+1000 积分
  - 每次出价：+2000 积分
  - 获胜者：+5000 积分
- 按积分比例分配季度空投代币

---

## 提交内容
- [ ] 合约代码 + 测试报告（覆盖率）
- [ ] Sepolia 合约地址
- [ ] Go 后端代码
- [ ] API 接口文档（或 Postman Collection）
- [ ] README（本地运行说明）
