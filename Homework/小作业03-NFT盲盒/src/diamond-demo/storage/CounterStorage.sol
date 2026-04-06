// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

/**
 * @title CounterStorage
 * @notice CounterFacetV2 的「私有」命名空间存储
 *
 * ─── 为什么要单独一个 Storage？──────────────────────────────────────────────
 *
 * maxCount 只有 CounterFacetV2 用到，放进 AppStorage 的 Layout struct 会污染共享存储，
 * 而且 V1 的合约里根本不需要这个字段。
 *
 * 解决方案：给 CounterFacet 自己开一个独立的命名空间，
 * 哈希 "diamond.counter.storage" 和 "diamond.app.storage" 完全不重叠，
 * V2 的私有数据和共享数据互不干扰。
 *
 * ─── 类比 ────────────────────────────────────────────────────────────────────
 *
 * AppStorage     = 公司的共享数据库（所有部门都能读）
 * CounterStorage = 计数器部门的私有数据库（只有 CounterFacet 访问）
 * 两个数据库在同一台服务器（Diamond Proxy）上，但用不同的 schema 隔离。
 */
library CounterStorage {
    bytes32 private constant SLOT = keccak256("diamond.counter.storage");

    struct Layout {
        uint256 maxCount; // V2 新增：计数上限（0 表示无限制）
    }

    function get() internal pure returns (Layout storage s) {
        bytes32 slot = SLOT;
        assembly {
            s.slot := slot
        }
    }
}
