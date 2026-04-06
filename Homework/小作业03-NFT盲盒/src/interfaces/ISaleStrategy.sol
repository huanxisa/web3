// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {IERC165} from "@openzeppelin/contracts/utils/introspection/IERC165.sol";

/**
 * @title ISaleStrategy
 * @notice 销售策略的抽象接口，定义「谁能买、花多少钱」的契约
 * @dev 继承 IERC165，实现合约须实现 supportsInterface 以支持主合约的合规校验
 */
interface ISaleStrategy is IERC165 {
    function canPurchase(address buyer, uint256 payment) external view;
    function recordPurchase(address buyer) external;
}
