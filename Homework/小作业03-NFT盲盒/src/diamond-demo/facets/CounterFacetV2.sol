// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {AppStorage} from "../storage/AppStorage.sol";
import {CounterStorage} from "../storage/CounterStorage.sol";

/**
 * @title CounterFacetV2
 * @notice 计数器 V2：在 V1 基础上增加「计数上限」功能
 *
 * ─── 升级方式 ─────────────────────────────────────────────────────────────
 *
 * 升级时调用 diamond.diamondCut()，只替换 increment 函数：
 *   cuts[0] = FacetCut({
 *       facetAddress: address(counterV2),
 *       action: Replace,
 *       functionSelectors: [CounterFacetV1.increment.selector]
 *                           ↑ 注意：用 V1 的选择器！
 *                             因为函数签名没变（increment()），选择器相同。
 *   })
 *
 * 同时，新增 setMaxCount 函数（V1 没有，需要 Add 操作）：
 *   cuts[1] = FacetCut({
 *       facetAddress: address(counterV2),
 *       action: Add,
 *       functionSelectors: [CounterFacetV2.setMaxCount.selector]
 *   })
 *
 * 升级后：
 *   increment.selector → CounterFacetV2（新代码，有上限检查）
 *   getCount.selector  → CounterFacetV1（没动，仍然有效）
 *   setMaxCount.selector → CounterFacetV2（新增）
 *   getOwner.selector  → OwnerFacet（没动，仍然有效）
 *
 * ─── 存储兼容性 ───────────────────────────────────────────────────────────
 *
 * V2 的 increment 读写的还是 AppStorage 里的 count 字段（同一个命名空间槽），
 * 所以升级前 count = 5，升级后 count 还是 5，历史数据完全保留。
 *
 * V2 新增的 maxCount 放在 CounterStorage（独立命名空间），不影响 AppStorage。
 */
contract CounterFacetV2 {
    error CountLimitReached(uint256 current, uint256 max);
    error NotOwner();

    event Incremented(address indexed by, uint256 newCount);
    event MaxCountSet(uint256 maxCount);

    function increment() external {
        AppStorage.Layout storage app = AppStorage.get();
        CounterStorage.Layout storage cs = CounterStorage.get();

        // V2 新增：上限检查（maxCount == 0 表示无限制，兼容 V1 的行为）
        if (cs.maxCount > 0 && app.count >= cs.maxCount) {
            revert CountLimitReached(app.count, cs.maxCount);
        }

        app.count++;
        emit Incremented(msg.sender, app.count);
    }

    // V2 新增函数：设置计数上限（仅 owner）
    function setMaxCount(uint256 max) external {
        if (msg.sender != AppStorage.get().owner) revert NotOwner();
        CounterStorage.get().maxCount = max;
        emit MaxCountSet(max);
    }

    // getCount 没有变化，保留在 CounterFacetV1 里即可，不需要重复定义
}
