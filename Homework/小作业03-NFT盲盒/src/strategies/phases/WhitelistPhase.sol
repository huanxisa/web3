// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {IPhaseStrategy} from "../../interfaces/IPhaseStrategy.sol";

/**
 * @title WhitelistPhase
 * @notice IPhaseStrategy 的白名单预售阶段实现
 *
 * 规则：
 *   - 只有白名单地址可以购买
 *   - 每个地址最多购买 maxPerWallet 个
 *   - 固定白名单价格
 */
contract WhitelistPhase is IPhaseStrategy, Ownable {
    // ========== 状态变量 ==========

    address public immutable coordinator; // MultiPhaseSaleStrategy，唯一可调用 recordPurchaseInPhase
    uint256 public price;
    uint256 public maxPerWallet;

    mapping(address => bool) public whitelist;
    mapping(address => uint256) public mintedPerWallet;

    // ========== 事件 ==========

    event PriceUpdated(uint256 newPrice);
    event MaxPerWalletUpdated(uint256 newMax);
    event WhitelistUpdated(address indexed account, bool status);

    // ========== 错误 ==========

    error UnauthorizedCaller();
    error InvalidAddress();
    error NotWhitelisted();
    error InsufficientPayment(uint256 required, uint256 provided);
    error WalletLimitReached(uint256 limit);

    // ========== 构造 ==========

    constructor(
        address owner_,
        address coordinator_,
        uint256 _price,
        uint256 _maxPerWallet
    ) Ownable(owner_) {
        coordinator = coordinator_;
        price = _price;
        maxPerWallet = _maxPerWallet;
    }

    // ========== IPhaseStrategy 实现 ==========

    /// @inheritdoc IPhaseStrategy
    function canBuyInPhase(address buyer, uint256 payment) external view override {
        if (!whitelist[buyer]) revert NotWhitelisted();
        if (payment < price) revert InsufficientPayment(price, payment);
        if (mintedPerWallet[buyer] >= maxPerWallet) revert WalletLimitReached(maxPerWallet);
    }

    /// @inheritdoc IPhaseStrategy
    function recordPurchaseInPhase(address buyer) external override {
        if (msg.sender != coordinator) revert UnauthorizedCaller();
        mintedPerWallet[buyer]++;
    }

    /// @inheritdoc IPhaseStrategy
    function minPrice() external view override returns (uint256) {
        return price;
    }

    /// @inheritdoc IPhaseStrategy
    function phaseName() external pure override returns (string memory) {
        return "Whitelist";
    }

    // ========== 管理函数（仅 owner） ==========

    function setPrice(uint256 _price) external onlyOwner {
        price = _price;
        emit PriceUpdated(_price);
    }

    function setMaxPerWallet(uint256 _max) external onlyOwner {
        maxPerWallet = _max;
        emit MaxPerWalletUpdated(_max);
    }

    function addToWhitelist(address[] calldata accounts) external onlyOwner {
        for (uint256 i = 0; i < accounts.length; i++) {
            if (accounts[i] == address(0)) revert InvalidAddress();
            whitelist[accounts[i]] = true;
            emit WhitelistUpdated(accounts[i], true);
        }
    }

    function removeFromWhitelist(address[] calldata accounts) external onlyOwner {
        for (uint256 i = 0; i < accounts.length; i++) {
            whitelist[accounts[i]] = false;
            emit WhitelistUpdated(accounts[i], false);
        }
    }
}
