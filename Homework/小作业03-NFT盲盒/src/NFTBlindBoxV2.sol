// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "./NFTBlindBox.sol";

/**
 * @title NFTBlindBoxV2
 * @notice NFTBlindBox 的升级版本，演示 UUPS 升级流程
 * 新增功能：版本号记录、用户购买次数统计、各稀有度铸造数量统计
 * @custom:oz-upgrades-from src/NFTBlindBox.sol:NFTBlindBox
 * @custom:oz-upgrades-unsafe-allow constructor state-variable-immutable
 */
contract NFTBlindBoxV2 is NFTBlindBox {
    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor(address vrfCoordinator) NFTBlindBox(vrfCoordinator) {}

    // ========== V2 新增状态变量 ==========
    // 注意：新变量必须追加在末尾，不能修改已有变量的顺序（否则破坏存储布局）

    uint256 public version;
    mapping(address => uint256) public userPurchaseCount; // 每个用户总购买次数统计
    mapping(uint256 => uint256) public rarityCount;       // 各稀有度铸造数量统计（枚举值作 key）

    // ========== V2 新增事件 ==========

    event VersionUpgraded(uint256 oldVersion, uint256 newVersion);
    event UserPurchaseCountUpdated(address indexed user, uint256 count);
    event RarityCountUpdated(BlindBoxTypes.Rarity rarity, uint256 count);

    // ========== V2 初始化（升级时调用） ==========

    /// @custom:oz-upgrades-validate-as-initializer
    function initializeV2(uint256 _version) external reinitializer(2) {
        emit VersionUpgraded(version, _version);
        version = _version;
    }

    // ========== V2 重写购买逻辑（增加统计） ==========

    /**
     * @dev override _doPurchase()，external purchaseBlindBox() 继承 V1 即可
     */
    function _doPurchase() internal override {
        super._doPurchase();
        userPurchaseCount[msg.sender]++;
        emit UserPurchaseCountUpdated(msg.sender, userPurchaseCount[msg.sender]);
    }

    // ========== V2 重写揭示逻辑（增加稀有度统计） ==========

    function revealBlindBox(uint256 tokenId) external override {
        _doReveal(tokenId);
        BlindBoxTypes.Rarity rarity = boxInfos[tokenId].rarity;
        rarityCount[uint256(rarity)]++;
        emit RarityCountUpdated(rarity, rarityCount[uint256(rarity)]);
    }

    // ========== V2 工具查询 ==========

    /// @notice 获取指定稀有度已铸造数量
    function getRarityCount(BlindBoxTypes.Rarity rarity) external view returns (uint256) {
        return rarityCount[uint256(rarity)];
    }

    /// @notice 一次性返回所有稀有度统计
    function getAllRarityCounts()
        external
        view
        returns (
            uint256 commonCount,
            uint256 uncommonCount,
            uint256 rareCount,
            uint256 epicCount,
            uint256 legendaryCount
        )
    {
        return (
            rarityCount[uint256(BlindBoxTypes.Rarity.Common)],
            rarityCount[uint256(BlindBoxTypes.Rarity.Uncommon)],
            rarityCount[uint256(BlindBoxTypes.Rarity.Rare)],
            rarityCount[uint256(BlindBoxTypes.Rarity.Epic)],
            rarityCount[uint256(BlindBoxTypes.Rarity.Legendary)]
        );
    }

    // ========== V2 存储间隙 ==========
    // V2 层新增了 3 个变量（version / userPurchaseCount / rarityCount），预留 47 个
    uint256[47] private __gap;
}
