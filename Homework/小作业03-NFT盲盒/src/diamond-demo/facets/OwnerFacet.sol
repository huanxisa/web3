// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {AppStorage} from "../storage/AppStorage.sol";

/**
 * @title OwnerFacet
 * @notice 权限管理 Facet：读写 AppStorage 里的 owner 字段
 *
 * 注意：这个合约本身没有任何状态变量声明。
 * 它读写的数据全部来自 AppStorage.get()，也就是 Diamond Proxy 存储里的命名空间槽位。
 * 当用户通过 Diamond 的 fallback 调用这里的函数时，
 * delegatecall 保证 msg.sender、address(this) 都是相对于 Diamond Proxy 的。
 */
contract OwnerFacet {
    error NotOwner();
    error InvalidAddress();

    modifier onlyOwner() {
        if (msg.sender != AppStorage.get().owner) revert NotOwner();
        _;
    }

    function getOwner() external view returns (address) {
        return AppStorage.get().owner;
    }

    function transferOwnership(address newOwner) external onlyOwner {
        if (newOwner == address(0)) revert InvalidAddress();
        AppStorage.get().owner = newOwner;
    }
}
