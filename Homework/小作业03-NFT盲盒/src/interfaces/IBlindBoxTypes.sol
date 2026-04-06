// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

/**
 * @title IBlindBoxTypes
 * @notice 盲盒核心数据类型定义，供主合约与各策略合约共享
 */
library BlindBoxTypes {
    enum Rarity {
        Common,   // 50%
        Uncommon, // 25%
        Rare,     // 15%
        Epic,     // 8%
        Legendary // 2%
    }

    /// @notice 每个 tokenId 对应的盲盒完整信息
    /// @dev 字段顺序按 slot packing 优化：小类型（Rarity 1字节 + bool 1字节 + bool 1字节）
    ///      打包进同一个槽，uint256 独占一槽，共 2 个槽。
    struct BoxInfo {
        Rarity rarity;             // 稀有度（揭示后有效）
        bool isRevealed;           // 是否已揭示
        bool vrfFulfilled;         // VRF 回调是否已到达（与 pendingRandomness==0 解耦）
        uint256 pendingRandomness; // VRF 随机数，揭示后清零以退还 gas
    }
}
