// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {IERC165} from "@openzeppelin/contracts/utils/introspection/IERC165.sol";

/**
 * @title IMetadataStrategy
 * @notice NFT 元数据 URI 的策略接口
 * @dev 继承 IERC165，实现合约须实现 supportsInterface 以支持主合约的合规校验
 */
interface IMetadataStrategy is IERC165 {
    function getTokenURI(uint256 tokenId, bool isRevealed, uint8 rarity)
        external
        view
        returns (string memory);
}
