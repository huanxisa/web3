# Chainlink VRF V2 详解

## 什么是 VRF

VRF（Verifiable Random Function，可验证随机函数）是 Chainlink 提供的链上可验证随机数服务。

普通的链上随机数（如 `block.timestamp`、`blockhash`）可以被矿工/验证者操控，VRF 通过密码学证明解决了这个问题：
- 随机数由 Chainlink 节点用私钥生成
- 链上合约可以用对应公钥验证这个随机数确实是该节点生成的，且未被篡改
- 节点无法预知结果，合约无法控制结果

---

## 完整流程

```
用户合约                    VRFCoordinator              Chainlink 节点
    |                            |                           |
    |-- requestRandomWords() --> |                           |
    |   (支付 LINK 订阅费)        |                           |
    |                            |-- 发出随机数请求事件 -----> |
    |                            |                           | (等待指定区块确认数)
    |                            |                           | 生成随机数 + 密码学证明
    |                            | <-- 提交随机数 + 证明 ---- |
    |                            | 验证证明有效               |
    | <-- rawFulfillRandomWords()|                           |
    |     → fulfillRandomWords() |                           |
    | (处理随机数)                |                           |
```

**关键点：**
1. 请求和回调是**异步**的，中间隔几个区块（由 `requestConfirmations` 决定）
2. 回调由 Chainlink 节点发起，不是用户触发
3. 费用通过 Subscription 预付，不是每次请求时实时支付

---

## 两种付费模式

| 模式 | 说明 | 适用场景 |
|------|------|---------|
| Subscription | 预充值订阅账户，多个合约共享 | 生产环境，费用可控 |
| Direct Funding | 每次请求时直接支付 LINK | 简单场景，无需管理订阅 |

本合约使用 **Subscription 模式**。

---

## 核心合约和接口

### 1. VRFConsumerBaseV2（消费者基类）

你的合约需要继承这个基类：

```solidity
import {VRFConsumerBaseV2} from "@chainlink/contracts/src/v0.8/vrf/VRFConsumerBaseV2.sol";

contract MyContract is VRFConsumerBaseV2 {
    constructor(address vrfCoordinator) VRFConsumerBaseV2(vrfCoordinator) {}

    // 必须实现：VRF 回调函数
    function fulfillRandomWords(
        uint256 requestId,
        uint256[] memory randomWords
    ) internal override {
        // 处理随机数
    }
}
```

**基类做了什么：**
- 存储 `vrfCoordinator` 地址
- 提供 `rawFulfillRandomWords`（external），内部校验 `msg.sender == vrfCoordinator`
- 调用你实现的 `fulfillRandomWords`（internal）

### 2. VRFCoordinatorV2Interface（请求接口）

```solidity
import {VRFCoordinatorV2Interface} from "@chainlink/contracts/src/v0.8/vrf/interfaces/VRFCoordinatorV2Interface.sol";

VRFCoordinatorV2Interface coordinator = VRFCoordinatorV2Interface(coordinatorAddress);
```

#### requestRandomWords — 发起随机数请求

```solidity
function requestRandomWords(
    bytes32 keyHash,          // 指定使用哪个 Chainlink 节点（不同节点 gas 价格不同）
    uint64 subId,             // 订阅 ID（预充值的账户）
    uint16 requestConfirmations, // 等待多少个区块确认后才生成随机数（最小 3，越大越安全）
    uint32 callbackGasLimit,  // 回调函数 fulfillRandomWords 的 gas 上限
    uint32 numWords           // 需要几个随机数（每个都是独立的 uint256）
) external returns (uint256 requestId);
```

**参数说明：**

- `keyHash`：每条链、每个 gas 通道对应一个 keyHash，从 [Chainlink 文档](https://docs.chain.link/vrf/v2/subscription/supported-networks) 获取
- `requestConfirmations`：Sepolia 最小值为 3，主网建议 5-20
- `callbackGasLimit`：回调函数消耗的 gas 上限，超出则回调失败且**不会重试**，需要根据 `fulfillRandomWords` 的逻辑估算
- `numWords`：最多 500 个，但每个都消耗更多 gas

**返回值 `requestId`：**
- 全局唯一，用于关联请求和回调
- 需要存储 `requestId → tokenId` 的映射，回调时才能知道是哪个 token 的请求

---

## Subscription 管理 API

### 创建和管理订阅

```solidity
// 创建订阅，返回 subscriptionId
uint64 subId = coordinator.createSubscription();

// 充值（需要先 approve LINK token）
// 实际上通过 LINK token 的 transferAndCall 充值，不是直接调用 coordinator
LinkTokenInterface(linkAddress).transferAndCall(
    address(coordinator),
    amount,
    abi.encode(subId)
);

// 添加消费者合约（只有白名单内的合约才能使用这个订阅）
coordinator.addConsumer(subId, consumerAddress);

// 移除消费者
coordinator.removeConsumer(subId, consumerAddress);

// 取消订阅，退还剩余 LINK
coordinator.cancelSubscription(subId, receivingAddress);

// 查询订阅余额和消费者列表
(uint96 balance, uint64 reqCount, address owner, address[] memory consumers)
    = coordinator.getSubscription(subId);
```

---

## 本地测试：VRFCoordinatorV2Mock

测试环境不能真正调用 Chainlink 节点，使用官方提供的 Mock：

```solidity
import {VRFCoordinatorV2Mock} from "@chainlink/contracts/src/v0.8/vrf/mocks/VRFCoordinatorV2Mock.sol";

// 部署 Mock
VRFCoordinatorV2Mock mock = new VRFCoordinatorV2Mock(
    0.1 ether,  // baseFee（LINK）
    1e9         // gasPriceLink
);

// 创建订阅并充值
uint64 subId = mock.createSubscription();
mock.fundSubscription(subId, 1000 ether); // 测试用，直接充值不需要真实 LINK

// 注册消费者
mock.addConsumer(subId, address(myContract));

// 模拟 Chainlink 节点回调（手动触发）
// requestId 是 requestRandomWords 返回的值
mock.fulfillRandomWords(requestId, address(myContract));

// 也可以指定具体的随机数值（用于测试特定稀有度）
mock.fulfillRandomWordsWithOverride(
    requestId,
    address(myContract),
    new uint256[](1) // [0] 会触发 Common 稀有度（0 % 100 = 0 < 50）
);
```

---

## 本合约中的 VRF 使用

```solidity
// 1. 购买时发起请求
uint256 requestId = i_vrfCoordinator.requestRandomWords(
    s_keyHash,
    s_subscriptionId,
    REQUEST_CONFIRMATIONS,  // 3
    callbackGasLimit,       // 默认 100_000，可调整
    NUM_WORDS               // 1
);
vrfRequestToToken[requestId] = tokenId; // 记录 requestId → tokenId 映射

// 2. VRF 回调（由 Chainlink 节点触发）
function fulfillRandomWords(uint256 requestId, uint256[] memory randomWords) internal override {
    uint256 tokenId = vrfRequestToToken[requestId];
    boxInfos[tokenId].pendingRandomness = randomWords[0]; // 存储随机数
}

// 3. 用户揭示（读取存储的随机数计算稀有度）
function revealBlindBox(uint256 tokenId) external {
    // 检查 pendingRandomness != 0（VRF 已回调）
    // 调用 rarityStrategy.assignRarity(box) 计算稀有度
}
```

---

## 常见问题

**Q: callbackGasLimit 设多少合适？**

根据 `fulfillRandomWords` 里的操作估算：
- 只做 1 次 SSTORE：约 20,000 gas，设 100,000 有足够余量
- 如果回调里做更多操作（如自动揭示），需要相应提高
- 超出 gas 上限时回调失败，且**不会重试**，随机数永久丢失

**Q: requestConfirmations 设多少？**

- 最小值：3（Sepolia）/ 3（主网）
- 推荐：主网用 5-20，区块确认越多越难被操控
- 越大用户等待时间越长

**Q: 随机数可以预测吗？**

不能。VRF 的密码学保证：
- 节点在提交前无法知道结果（因为结果依赖未来的区块哈希）
- 合约无法影响结果
- 任何人可以用公钥验证结果的真实性

**Q: 测试时如何模拟特定稀有度？**

```solidity
// 想测试 Legendary（需要 randomness % 100 >= 98）
uint256[] memory words = new uint256[](1);
words[0] = 98; // 98 % 100 = 98，触发 Legendary
mock.fulfillRandomWordsWithOverride(requestId, address(nft), words);
```

---

## Sepolia 测试网配置

```
VRF Coordinator: 0x8103B0A8A00be2DDC778e6e7eaa21791Cd364625
Key Hash (500 gwei): 0x474e34a077df58807dbe9c96d3c009b23b3c6d0cce433e59bbf5b34f823bc56c
LINK Token: 0x779877A7B0D9E8603169DdbD7836e478b4624789
最小确认数: 3
```

部署后需要在 [vrf.chain.link](https://vrf.chain.link) 把代理合约地址添加为 Consumer。
