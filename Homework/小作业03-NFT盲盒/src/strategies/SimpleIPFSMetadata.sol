// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {ERC165} from "@openzeppelin/contracts/utils/introspection/ERC165.sol";
import {IERC165} from "@openzeppelin/contracts/utils/introspection/IERC165.sol";
import {Strings} from "@openzeppelin/contracts/utils/Strings.sol";
import {IMetadataStrategy} from "../interfaces/IMetadataStrategy.sol";

contract SimpleIPFSMetadata is IMetadataStrategy, ERC165, Ownable {
    using Strings for uint256;

    // ========== 状态变量 ==========

    string private _blindBoxURI;  // 揭示前：所有 token 共用的占位图 URI
    string private _baseTokenURI; // 揭示后：IPFS 目录地址（末尾不含 "/"，此合约自动拼接）

    // 稀有度 ID → 文件名（不含 .json 后缀），由 owner 配置，与 Rarity enum 解耦
    mapping(uint8 => string) private _rarityNames;

    // ========== 事件 ==========

    event BlindBoxURIUpdated(string newURI);
    event BaseTokenURIUpdated(string newURI);
    event RarityNameUpdated(uint8 indexed rarityId, string name);

    // ========== 错误 ==========

    error UnknownRarity(uint8 rarityId);

    // ========== 构造 ==========

    constructor(address owner_, string memory blindBoxURI_, string memory baseTokenURI_)
        Ownable(owner_)
    {
        _blindBoxURI  = blindBoxURI_;
        _baseTokenURI = baseTokenURI_;

        // 默认名称与当前 Rarity enum 对齐，后续可通过 setRarityName 按需修改
        _rarityNames[0] = "common";
        _rarityNames[1] = "uncommon";
        _rarityNames[2] = "rare";
        _rarityNames[3] = "epic";
        _rarityNames[4] = "legendary";
    }

    // ========== IMetadataStrategy 实现 ==========

    /// @inheritdoc IMetadataStrategy
    function getTokenURI(uint256 /*tokenId*/, bool isRevealed, uint8 rarity)
        external
        view
        override
        returns (string memory)
    {
        if (!isRevealed) {
            return _blindBoxURI;
        }
        string memory name = _rarityNames[rarity];
        if (bytes(name).length == 0) revert UnknownRarity(rarity);
        // 揭示后：baseURI + "/" + rarityName + ".json"
        // 同一稀有度的所有 token 共享同一份元数据，无需为每个 tokenId 单独建文件
        return string.concat(_baseTokenURI, "/", name, ".json");
    }

    // ========== 管理函数（仅 owner） ==========

    /// @notice 更新揭示前占位 URI
    function setBlindBoxURI(string calldata uri) external onlyOwner {
        _blindBoxURI = uri;
        emit BlindBoxURIUpdated(uri);
    }

    /// @notice 更新揭示后 Base URI
    function setBaseTokenURI(string calldata uri) external onlyOwner {
        _baseTokenURI = uri;
        emit BaseTokenURIUpdated(uri);
    }

    /// @notice 新增或修改稀有度名称，与 Rarity enum 完全解耦
    /// @dev    新增稀有度时调用此函数即可，无需重新部署合约
    ///         例：setRarityName(5, "mythical") 支持第六种稀有度
    function setRarityName(uint8 rarityId, string calldata name) external onlyOwner {
        _rarityNames[rarityId] = name;
        emit RarityNameUpdated(rarityId, name);
    }

    // ========== 查询 ==========

    function blindBoxURI() external view returns (string memory) {
        return _blindBoxURI;
    }

    function baseTokenURI() external view returns (string memory) {
        return _baseTokenURI;
    }

    function rarityName(uint8 rarityId) external view returns (string memory) {
        return _rarityNames[rarityId];
    }

    function supportsInterface(bytes4 interfaceId)
        public view override(ERC165, IERC165)
        returns (bool)
    {
        return interfaceId == type(IMetadataStrategy).interfaceId
            || super.supportsInterface(interfaceId);
    }
}
