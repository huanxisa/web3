// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

/**
 * @title IPhaseStrategy
 * @notice 单个销售阶段的策略接口
 *
 * 设计原则：
 *   每个阶段是一个独立合约，负责该阶段的所有规则：
 *   - 谁有资格买（白名单检查 / 无限制 / OG 资格）
 *   - 最低价格（固定价 / 荷兰拍动态价 / 折扣价）
 *   - 本阶段限购（per-wallet 计数）
 *
 *   全局规则（总供应量、全局暂停）由 MultiPhaseSaleStrategy 负责，不下放到阶段。
 *
 * 调用约定：
 *   - canBuyInPhase / minPrice：view，任何人可查
 *   - recordPurchaseInPhase：只有注册的 MultiPhaseSaleStrategy（coordinator）可调用
 */
interface IPhaseStrategy {
    /**
     * @notice 检查 buyer 在本阶段是否有资格购买
     * @dev 不满足条件时直接 revert，调用方无需检查返回值
     * @param buyer   购买者地址
     * @param payment 本次支付的 ETH
     */
    function canBuyInPhase(address buyer, uint256 payment) external view;

    /**
     * @notice 购买成功后记录本次购买（更新本阶段的计数器等状态）
     * @dev 只能被 MultiPhaseSaleStrategy（coordinator）调用
     * @param buyer 购买者地址
     */
    function recordPurchaseInPhase(address buyer) external;

    /**
     * @notice 本阶段购买的最低 ETH 价格（用于前端展示和快速校验）
     */
    function minPrice() external view returns (uint256);

    /**
     * @notice 阶段名称（用于事件和前端展示）
     */
    function phaseName() external pure returns (string memory);
}
