// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {IERC165} from "@openzeppelin/contracts/utils/introspection/IERC165.sol";
import {BlindBoxTypes} from "./IBlindBoxTypes.sol";

/**
 * @title IRarityStrategy
 * @notice 稀有度算法的抽象接口
 * @dev 继承 IERC165，实现合约须实现 supportsInterface 以支持主合约的合规校验
 */
interface IRarityStrategy is IERC165 {
    function assignRarity(BlindBoxTypes.BoxInfo calldata box)
        external
        pure
        returns (BlindBoxTypes.Rarity rarity);
}
