# 接口设计模式：如何处理具体与抽象的耦合

> 背景：策略模式中，调用方需要向策略合约传递数据。
> 核心矛盾：接口稳定性 vs 数据扩展性。
> 以稀有度策略（IRarityStrategy）为例展开讨论。

---

## 方案一：最小化接口（只传原子数据）

### 设计思路

接口只暴露最稳定的原始数据，不传复合对象，参数全部是基础类型。

### 代码示例

```solidity
interface IRarityStrategy {
    /// 只传最原始的数据，策略合约自己决定如何使用
    function assignRarity(
        uint256 randomness,
        uint256 tokenId,
        uint256 currentSupply
    ) external pure returns (uint8 rarity);
}

contract SimpleRarityStrategy is IRarityStrategy {
    function assignRarity(
        uint256 randomness,
        uint256 tokenId,
        uint256 currentSupply
    ) external pure override returns (uint8) {
        // 只用 randomness，其他参数忽略
        uint256 roll = randomness % 100;
        if (roll < 50) return 0; // Common
        if (roll < 75) return 1; // Uncommon
        if (roll < 90) return 2; // Rare
        if (roll < 98) return 3; // Epic
        return 4;                // Legendary
    }
}

// 动态稀有度策略：越晚 mint 越稀有，同时用到了 tokenId 和 currentSupply
contract DynamicRarityStrategy is IRarityStrategy {
    function assignRarity(
        uint256 randomness,
        uint256 tokenId,
        uint256 currentSupply
    ) external pure override returns (uint8) {
        // 越接近 maxSupply，Legendary 概率越高
        uint256 progress = (tokenId * 100) / currentSupply;
        uint256 legendaryThreshold = 2 + progress / 10; // 2% ~ 12%
        uint256 roll = randomness % 100;
        if (roll < legendaryThreshold) return 4;
        // ... 其他档位
        return 0;
    }
}
```

### 优点
- 接口极简，参数都是基础类型，几乎不会因业务变化而改接口
- 编译期类型安全
- 策略合约无需依赖任何外部类型定义

### 缺点
- 如果策略需要更多上下文，接口参数会越来越多（接口变胖）
- 参数顺序容易搞错，可读性差
- 无法传递复杂的关联数据（如历史购买记录）

### 适用场景
- 数据需求非常稳定，参数不超过 3-4 个
- 参考：Uniswap V2 的核心计算函数

---

## 方案二：Context 对象 + 版本号

### 设计思路

传一个带版本号的 struct，策略合约按版本号决定如何解析数据。
新版本追加字段，旧策略合约只读自己认识的字段，向后兼容。

### 代码示例

```solidity
// 共享的 Context 定义（只追加，不删改）
struct RarityContext {
    uint16 version;          // 版本号，策略合约按此决定解析逻辑
    uint256 randomness;      // V1: 基础随机数
    uint256 tokenId;         // V1: token 编号
    // ---- V2 追加 ----
    uint256 mintTimestamp;   // V2: 铸造时间戳（用于时间加权稀有度）
    // ---- V3 追加 ----
    address buyer;           // V3: 购买者地址（用于 VIP 加成）
}

interface IRarityStrategy {
    function assignRarity(RarityContext calldata ctx) external pure returns (uint8 rarity);
}

// V1 策略：只认识 version=1 的字段
contract V1RarityStrategy is IRarityStrategy {
    function assignRarity(RarityContext calldata ctx) external pure override returns (uint8) {
        // 只用 V1 字段，忽略 V2/V3 追加的字段
        uint256 roll = ctx.randomness % 100;
        if (roll < 50) return 0;
        if (roll < 75) return 1;
        if (roll < 90) return 2;
        if (roll < 98) return 3;
        return 4;
    }
}

// V2 策略：利用 mintTimestamp 做时间加权
contract V2RarityStrategy is IRarityStrategy {
    function assignRarity(RarityContext calldata ctx) external pure override returns (uint8) {
        require(ctx.version >= 2, "Context version too low");
        // 夜间铸造（0-6点）有额外稀有度加成
        uint256 hour = (ctx.mintTimestamp / 3600) % 24;
        uint256 bonus = (hour < 6) ? 5 : 0;
        uint256 roll = ctx.randomness % 100;
        if (roll < (2 + bonus)) return 4; // Legendary 概率提升
        // ...
        return 0;
    }
}
```

### 优点
- 接口签名稳定（只有一个 `RarityContext` 参数）
- 向后兼容：旧策略合约不需要重新部署
- 保留编译期类型安全
- 版本号让意图明确，便于调试

### 缺点
- `RarityContext` struct 本身需要严格维护（只追加，不删改）
- struct 字段增多后，calldata 体积增大，gas 消耗上升
- 版本校验逻辑需要每个策略合约自己实现，容易遗漏

### 适用场景
- 数据会扩展但有规律（追加字段）
- 参考：Chainlink VRF V2 → V2.5 的升级方式、EIP-712 结构化数据

---

## 方案三：`bytes` + ABI 编码

### 设计思路

接口签名永远不变，数据通过 `bytes` 传递。
调用方负责编码，策略合约负责解码，双方约定编码格式。

### 代码示例

```solidity
interface IRarityStrategy {
    /// context 的编码格式由调用方和策略合约约定，接口本身不感知
    function assignRarity(bytes calldata context) external pure returns (uint8 rarity);
}

// 调用方（主合约）编码数据
function _doReveal(uint256 tokenId) internal {
    BoxInfo storage box = boxInfos[tokenId];
    // V1 编码：只传 randomness + tokenId
    bytes memory ctx = abi.encode(box.pendingRandomness, tokenId);
    // V2 编码：追加 mintTimestamp
    // bytes memory ctx = abi.encode(box.pendingRandomness, tokenId, box.mintTimestamp);
    uint8 rarityIndex = rarityStrategy.assignRarity(ctx);
    // ...
}

// V1 策略：解码 V1 格式
contract V1RarityStrategy is IRarityStrategy {
    function assignRarity(bytes calldata context) external pure override returns (uint8) {
        (uint256 randomness, uint256 tokenId) = abi.decode(context, (uint256, uint256));
        uint256 roll = randomness % 100;
        if (roll < 50) return 0;
        // ...
        return 4;
    }
}

// V2 策略：解码 V2 格式（多了 mintTimestamp）
contract V2RarityStrategy is IRarityStrategy {
    function assignRarity(bytes calldata context) external pure override returns (uint8) {
        (uint256 randomness, uint256 tokenId, uint256 mintTimestamp) =
            abi.decode(context, (uint256, uint256, uint256));
        // 利用 mintTimestamp 计算稀有度
        // ...
        return 0;
    }
}
```

### 优点
- 接口签名永远不变，最高的接口稳定性
- 数据格式完全自由，无任何限制
- 不同策略合约可以约定完全不同的编码格式

### 缺点
- 完全失去编译期类型检查，decode 出错只能运行时发现
- 调用方和策略合约必须约定编码格式，文档要求高
- 调试困难，`bytes` 不可读
- 编解码本身有额外 gas 消耗

### 适用场景
- 数据变化完全不可预测，接口必须永远稳定
- 参考：Aave V3 的 `executeOperation`（闪贷回调）、ERC-1271 签名验证

---

## 方案四：注册表模式（策略合约主动查询）

### 设计思路

接口只传"在哪找数据"（合约地址 + tokenId），策略合约自己去主合约读取需要的字段。
调用方不需要知道策略需要什么数据，策略合约自己决定读什么。

### 代码示例

```solidity
// 主合约暴露查询接口
interface INFTBlindBox {
    function getBoxInfo(uint256 tokenId) external view returns (
        uint256 pendingRandomness,
        uint256 mintTimestamp,
        address originalBuyer
    );
    function totalSupply() external view returns (uint256);
}

interface IRarityStrategy {
    /// 只传"在哪找数据"，策略合约自己去读
    function assignRarity(
        address nftContract,
        uint256 tokenId
    ) external view returns (uint8 rarity);  // 注意：不再是 pure，因为需要读外部状态
}

// 策略合约主动查询所需数据
contract AdvancedRarityStrategy is IRarityStrategy {
    function assignRarity(
        address nftContract,
        uint256 tokenId
    ) external view override returns (uint8) {
        INFTBlindBox box = INFTBlindBox(nftContract);
        (uint256 randomness, uint256 mintTimestamp, address buyer) = box.getBoxInfo(tokenId);
        uint256 supply = box.totalSupply();

        // 策略合约可以自由组合任何数据
        uint256 roll = randomness % 100;
        // 根据 supply 动态调整概率...
        // 根据 mintTimestamp 加成...
        return uint8(roll < 50 ? 0 : 1);
    }
}

// 主合约调用时只传地址和 tokenId
function _doReveal(uint256 tokenId) internal {
    uint8 rarityIndex = rarityStrategy.assignRarity(address(this), tokenId);
    // ...
}
```

### 优点
- 接口签名最简洁且永远稳定（只有两个参数）
- 策略合约可以读取任何它需要的数据，扩展性最强
- 主合约不需要知道策略需要什么，职责分离最彻底

### 缺点
- 策略合约和主合约产生了**反向依赖**（策略依赖主合约接口）
- `pure` 变成 `view`，无法在某些场景下使用
- 测试复杂度上升（需要 mock 主合约）
- 策略合约升级时需要确保主合约的查询接口没有变化

### 适用场景
- 策略需要主动查询多个数据源
- 参考：The Graph 的 Subgraph 数据源模式、Chainlink 的 Data Feed 消费者模式

---

## 横向对比

| 维度 | 最小化接口 | Context+版本号 | bytes编码 | 注册表模式 |
|------|-----------|---------------|-----------|-----------|
| 接口稳定性 | 中（参数变胖） | 高 | 最高 | 最高 |
| 类型安全 | 高 | 高 | 无 | 高 |
| 扩展性 | 低 | 中 | 高 | 最高 |
| 实现复杂度 | 低 | 中 | 中 | 高 |
| 测试难度 | 低 | 低 | 中 | 高 |
| Gas 消耗 | 低 | 中 | 中 | 高（外部调用） |
| 参考项目 | Uniswap V2 | Chainlink VRF | Aave V3 | The Graph |

---

## 选型决策树

```
数据字段 <= 4 个且非常稳定？
    → 最小化接口

数据会扩展但有规律（只追加字段）？
    → Context + 版本号

接口必须永远不变，数据格式不可预测？
    → bytes + ABI 编码

策略需要主动查询多个数据源，或数据来源复杂？
    → 注册表模式
```

---

## 通用原则（不依赖具体方案）

1. **接口只暴露稳定的抽象**，不要把内部实现细节泄漏到接口层
2. **只追加，不删改**，无论是 struct 字段还是接口参数，向后兼容是底线
3. **版本号是廉价的保险**，在 struct 里加一个 `version` 字段几乎没有成本，但能在未来省很多麻烦
4. **接口越简单，寿命越长**，Uniswap V2 的核心接口 10 年没变过，因为它足够简单
