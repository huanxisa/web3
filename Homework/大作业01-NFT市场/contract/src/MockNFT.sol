// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {ERC721} from "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

/**
 * @title MockNFT
 * @notice 用于本地测试的简单 ERC721 合约
 */
contract MockNFT is ERC721, Ownable {
    uint256 private _nextTokenId;

    constructor(address owner) ERC721("MockNFT", "MNFT") Ownable(owner) {}

    /// @notice 任何人都可以 mint（测试用，生产环境需要权限控制）
    function mint(address to) external returns (uint256 tokenId) {
        tokenId = _nextTokenId++;
        _mint(to, tokenId);
    }

    function totalSupply() external view returns (uint256) {
        return _nextTokenId;
    }
}
