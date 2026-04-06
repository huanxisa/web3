// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {IPhaseStrategy} from "../../interfaces/IPhaseStrategy.sol";

/**
 * @title PublicPhase
 * @notice IPhaseStrategy 的公开销售阶段实现
 *
 * 规则：
 *   - 任何地址均可购买（无白名单限制）
 *   - 固定公开价格
 *   - 无 per-wallet 限购（全局供应量限制由 NFTBlindBox 主合约负责）
 *
 * 扩展提示：
 *   如果需要公售也有 per-wallet 限购，只需在此合约加 maxPerWallet + mintedPerWallet 即可，
 *   不需要修改编排器或主合约。
 */
contract PublicPhase is IPhaseStrategy, Ownable {
    // ========== 状态变量 ==========

    address public immutable coordinator;
    uint256 public price;

    // ========== 事件 ==========

    event PriceUpdated(uint256 newPrice);

    // ========== 错误 ==========

    error UnauthorizedCaller();
    error InsufficientPayment(uint256 required, uint256 provided);

    // ========== 构造 ==========

    constructor(address owner_, address coordinator_, uint256 _price) Ownable(owner_) {
        coordinator = coordinator_;
        price = _price;
    }

    // ========== IPhaseStrategy 实现 ==========

    /// @inheritdoc IPhaseStrategy
    function canBuyInPhase(address /*buyer*/, uint256 payment) external view override {
        if (payment < price) revert InsufficientPayment(price, payment);
    }

    /// @inheritdoc IPhaseStrategy
    function recordPurchaseInPhase(address /*buyer*/) external override {
        if (msg.sender != coordinator) revert UnauthorizedCaller();
        // 公售阶段无 per-wallet 计数，无操作
    }

    /// @inheritdoc IPhaseStrategy
    function minPrice() external view override returns (uint256) {
        return price;
    }

    /// @inheritdoc IPhaseStrategy
    function phaseName() external pure override returns (string memory) {
        return "Public";
    }

    // ========== 管理函数（仅 owner） ==========

    function setPrice(uint256 _price) external onlyOwner {
        price = _price;
        emit PriceUpdated(_price);
    }
}
