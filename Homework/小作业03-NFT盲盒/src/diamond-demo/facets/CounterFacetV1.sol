// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {AppStorage} from "../storage/AppStorage.sol";

/**
 * @title CounterFacetV1
 * @notice 计数器 V1：任何人可以 increment，没有上限限制
 *
 * ─── 存储访问模式 ─────────────────────────────────────────────────────────
 *
 * AppStorage.get().count 读写的是 Diamond Proxy 存储里命名空间槽位的 count 字段。
 * OwnerFacet.getOwner() 读的是同一个命名空间的 owner 字段。
 * 两个 Facet 共享同一块 AppStorage，数据是同步的。
 *
 * ─── 这个 Facet 有哪些函数？─────────────────────────────────────────────────
 *
 * 部署后，需要通过 diamondCut 把这两个选择器注册进 Diamond：
 *   CounterFacetV1.increment.selector → CounterFacetV1 地址
 *   CounterFacetV1.getCount.selector  → CounterFacetV1 地址
 */
contract CounterFacetV1 {
    event Incremented(address indexed by, uint256 newCount);

    function increment() external {
        AppStorage.Layout storage s = AppStorage.get();
        s.count++;
        emit Incremented(msg.sender, s.count);
    }

    function getCount() external view returns (uint256) {
        return AppStorage.get().count;
    }
}
