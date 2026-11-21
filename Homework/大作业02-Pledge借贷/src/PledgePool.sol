// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {ReentrancyGuard} from "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {AggregatorV3Interface} from "@chainlink/contracts/src/v0.8/shared/interfaces/AggregatorV3Interface.sol";

import {IPledgePool} from "./interfaces/IPledgePool.sol";
import {DebtToken} from "./tokens/DebtToken.sol";

/// @title PledgePool - 固定利率多池子借贷协议
/// @notice 参考 Pledge Finance 实现，支持多个独立借贷池
///
/// ## 核心设计
///
/// - 每个池子通过 pid（0-based 数组索引）唯一标识
/// - 贷款人存入 lendToken，获得 spCoin（贷款份额）
/// - 借款人抵押 borrowToken，获得 jpCoin（借款债务）
/// - 状态机：MATCH → EXECUTION → FINISH / LIQUIDATION / UNDONE
///
/// ## 利率计算（简化固定利率）
/// interest = principal × interestRate × duration / (365 days × 1e8)
///
contract PledgePool is IPledgePool, ReentrancyGuard, Ownable {
    using SafeERC20 for IERC20;

    // ─── 常量 ────────────────────────────────────────────────
    uint256 public constant CAL_DECIMAL = 1e18; // 计算精度
    uint256 public constant BASE_DECIMAL = 1e8; // 利率/抵押率基数
    uint256 public constant BASE_YEAR = 365 days;

    // ─── 全局参数 ────────────────────────────────────────────
    uint256 public minAmount = 100e18; // 最低存款金额
    uint256 public lendFee;            // 贷款手续费（BASE_DECIMAL）
    uint256 public borrowFee;          // 借款手续费（BASE_DECIMAL）
    address public feeAddress;         // 手续费接收地址
    bool public globalPaused;          // 全局暂停

    // ─── 池子数据（数组索引即 pid） ──────────────────────────
    PoolBaseInfo[] public poolBaseInfo;
    PoolDataInfo[] public poolDataInfo;

    // pid => user => info
    mapping(uint256 => mapping(address => LendInfo))   public userLendInfo;
    mapping(uint256 => mapping(address => BorrowInfo)) public userBorrowInfo;

    // ─── 价格预言机（pid => Chainlink feed） ─────────────────
    mapping(uint256 => address) public priceFeed;

    // ─── 错误 ────────────────────────────────────────────────
    error Paused();
    error InvalidState(PoolState current);
    error InvalidTime();
    error AmountTooSmall();
    error AmountTooLarge();
    error AlreadyClaimed();
    error NothingToClaim();
    error NotLiquidatable();
    error ZeroAddress();

    // ─── Modifier ────────────────────────────────────────────
    modifier notPaused() {
        if (globalPaused) revert Paused();
        _;
    }

    modifier onlyState(uint256 pid, PoolState required) {
        _checkState(pid, required);
        _;
    }

    function _checkState(uint256 pid, PoolState required) internal view {
        if (poolBaseInfo[pid].state != required) revert InvalidState(poolBaseInfo[pid].state);
    }

    // ─── 构造函数 ────────────────────────────────────────────
    constructor(address feeAddress_) Ownable(msg.sender) {
        if (feeAddress_ == address(0)) revert ZeroAddress();
        feeAddress = feeAddress_;
    }

    // ─── 管理员：创建借贷池 ──────────────────────────────────

    /// @inheritdoc IPledgePool
    /// @dev spToken 和 jpToken 需在池子创建前先部署（DebtToken），
    ///      部署时 owner 设为本合约地址
    function createPoolInfo(CreatePoolParams calldata p) external override onlyOwner {
        // TODO:
        // 1. 校验 p.endTime > p.settleTime > block.timestamp
        // 2. 校验 p.spToken != address(0) && p.jpToken != address(0)
        // 3. 校验 p.interestRate > 0, p.maxSupply > 0, p.martgageRate > 0
        // 4. 初始化 PoolBaseInfo 并 push 到 poolBaseInfo
        // 5. 初始化 PoolDataInfo 并 push 到 poolDataInfo
        // 6. emit PoolCreated

        uint256 pid = poolBaseInfo.length;
        emit PoolCreated(pid, p.lendToken, p.borrowToken, p.settleTime, p.endTime);
    }

    /// @notice 设置池子的 Chainlink 价格预言机地址
    function setPriceFeed(uint256 pid, address feed) external onlyOwner {
        // TODO: 校验 pid < poolLength(), feed != address(0)
        priceFeed[pid] = feed;
    }

    // ─── 贷款人操作 ──────────────────────────────────────────

    /// @inheritdoc IPledgePool
    /// @dev 前置条件：state == MATCH，block.timestamp < settleTime
    function depositLend(uint256 pid, uint256 stakeAmount)
        external
        override
        nonReentrant
        notPaused
        onlyState(pid, PoolState.MATCH)
    {
        // TODO:
        // 1. 校验 block.timestamp < poolBaseInfo[pid].settleTime（募集期内）
        // 2. 校验 stakeAmount >= minAmount
        // 3. 校验 lendSupply + stakeAmount <= maxSupply（不超额）
        // 4. IERC20(lendToken).safeTransferFrom(msg.sender, address(this), stakeAmount)
        // 5. 计算 mintAmount = stakeAmount（1:1 或按当前汇率）
        // 6. DebtToken(spCoin).mint(msg.sender, mintAmount)
        // 7. 更新 lendSupply 和 userLendInfo
        // 8. emit DepositLend
    }

    /// @inheritdoc IPledgePool
    /// @dev 取款：状态为 FINISH 或 LIQUIDATION 时，销毁 spCoin 换回本金+利息
    function withdrawLend(uint256 pid, uint256 spAmount)
        external
        override
        nonReentrant
        notPaused
    {
        // TODO:
        // 1. 校验 state == FINISH || state == LIQUIDATION
        // 2. 校验 spAmount > 0
        // 3. 计算应退金额（含利息或按清算价）
        // 4. DebtToken(spCoin).burn(msg.sender, spAmount)
        // 5. IERC20(lendToken).safeTransfer(msg.sender, returnAmount)
        // 6. emit WithdrawLend
    }

    /// @inheritdoc IPledgePool
    /// @dev 领取额外奖励（如果有）；若 UNDONE 则退款
    function claimLend(uint256 pid) external override nonReentrant notPaused {
        // TODO: 见 withdrawLend，两者可合并或分开
    }

    /// @inheritdoc IPledgePool
    /// @dev UNDONE 状态下退款
    function refundLend(uint256 pid) external override nonReentrant notPaused {
        // TODO:
        // 1. 校验 state == UNDONE
        // 2. 校验用户有未退款余额（!hasNoRefund）
        // 3. CEI：先标记 hasNoRefund = true
        // 4. 销毁 spCoin，退还 lendToken
        // 5. emit RefundLend
    }

    // ─── 借款人操作 ──────────────────────────────────────────

    /// @inheritdoc IPledgePool
    function depositBorrow(uint256 pid, uint256 stakeAmount)
        external
        override
        nonReentrant
        notPaused
        onlyState(pid, PoolState.MATCH)
    {
        // TODO:
        // 1. 校验 block.timestamp < settleTime（募集期内）
        // 2. 校验 stakeAmount >= minAmount
        // 3. safeTransferFrom borrowToken
        // 4. mint jpCoin（1:1）
        // 5. 更新 borrowSupply 和 userBorrowInfo
        // 6. emit DepositBorrow
    }

    /// @inheritdoc IPledgePool
    /// @dev FINISH 或 LIQUIDATION 状态，取回抵押品（或剩余抵押品）
    function withdrawBorrow(uint256 pid, uint256 jpAmount)
        external
        override
        nonReentrant
        notPaused
    {
        // TODO: 类似 withdrawLend，针对借款人侧
    }

    /// @inheritdoc IPledgePool
    /// @dev EXECUTION 阶段：借款人领取已借出的 lendToken
    function claimBorrow(uint256 pid)
        external
        override
        nonReentrant
        notPaused
        onlyState(pid, PoolState.EXECUTION)
    {
        // TODO:
        // 1. 校验用户有 jpCoin 且未认领（!hasNoClaim）
        // 2. 按抵押率计算可借出 lendToken 金额
        //    borrowAmount = stakeAmount × settleAmountLend / settleAmountBorrow（按比例）
        // 3. 标记 hasNoClaim = true
        // 4. safeTransfer lendToken 给 msg.sender
        // 5. emit ClaimBorrow
    }

    /// @inheritdoc IPledgePool
    /// @dev UNDONE 状态退款
    function refundBorrow(uint256 pid) external override nonReentrant notPaused {
        // TODO: 类似 refundLend，退还 borrowToken
    }

    /// @inheritdoc IPledgePool
    /// @dev 借款人还款：还本金+利息，取回抵押品
    function repay(uint256 pid) external override nonReentrant notPaused {
        // TODO:
        // 1. 校验 state == EXECUTION
        // 2. 计算应还金额：本金 + 利息
        //    interest = borrowAmount × interestRate × elapsed / (BASE_YEAR × BASE_DECIMAL)
        // 3. safeTransferFrom lendToken（还款）
        // 4. 退还 borrowToken（抵押品）
        // 5. burn jpCoin
        // 6. 若该池子所有借款人都已还款 → state = FINISH
        // 7. emit Repay
    }

    // ─── 清算 ────────────────────────────────────────────────

    /// @inheritdoc IPledgePool
    function checkoutLiquidate(uint256 pid) public view override returns (bool) {
        // TODO:
        // 1. 仅 EXECUTION 状态才能清算
        // 2. 获取抵押品当前价格
        // 3. 计算抵押率：borrowValue / lendValue × BASE_DECIMAL
        // 4. 若 < autoLiquidateThreshold → 返回 true
        return false;
    }

    /// @inheritdoc IPledgePool
    function liquidate(uint256 pid)
        external
        override
        nonReentrant
        notPaused
        onlyState(pid, PoolState.EXECUTION)
    {
        // TODO:
        // 1. 调用 checkoutLiquidate(pid)，若 false → revert NotLiquidatable
        // 2. _setState(pid, LIQUIDATION)
        // 3. 将抵押品通过 swap router 换成 lendToken 还给贷款人
        //    （简化版：按 Chainlink 价格直接计算，不走 swap）
        // 4. 更新 liquidationAmounLend / liquidationAmounBorrow
        // 5. emit Liquidate
    }

    // ─── 内部：状态机转换 ────────────────────────────────────

    function _setState(uint256 pid, PoolState newState) internal {
        emit StateChange(pid, poolBaseInfo[pid].state, newState);
        poolBaseInfo[pid].state = newState;
    }

    /// @notice 结算池子（settleTime 到期后调用）
    /// @dev 若 lendSupply 达到 maxSupply 要求 → EXECUTION；否则 → UNDONE
    function settle(uint256 pid) external notPaused {
        // TODO:
        // 1. 校验 state == MATCH && block.timestamp >= settleTime
        // 2. 若 lendSupply >= minAmount 且 borrowSupply > 0 → EXECUTION
        // 3. 否则 → UNDONE
        // 4. 记录 settleAmountLend / settleAmountBorrow
    }

    // ─── 视图函数 ────────────────────────────────────────────

    function poolLength() external view override returns (uint256) {
        return poolBaseInfo.length;
    }

    function getPoolBaseInfo(uint256 pid) external view override returns (PoolBaseInfo memory) {
        return poolBaseInfo[pid];
    }

    function getPoolDataInfo(uint256 pid) external view override returns (PoolDataInfo memory) {
        return poolDataInfo[pid];
    }

    function getUserLendInfo(uint256 pid, address user) external view override returns (LendInfo memory) {
        return userLendInfo[pid][user];
    }

    function getUserBorrowInfo(uint256 pid, address user) external view override returns (BorrowInfo memory) {
        return userBorrowInfo[pid][user];
    }

    /// @inheritdoc IPledgePool
    function getBorrowTokenPrice(uint256 pid) public view override returns (uint256) {
        // TODO: 调用 AggregatorV3Interface(priceFeed[pid]).latestRoundData()
        // 返回 uint256(price)，处理负价格 revert
        return 0;
    }

    // ─── Owner 管理 ──────────────────────────────────────────
    function setFee(uint256 lendFee_, uint256 borrowFee_) external onlyOwner {
        lendFee = lendFee_;
        borrowFee = borrowFee_;
    }

    function setFeeAddress(address feeAddress_) external onlyOwner {
        if (feeAddress_ == address(0)) revert ZeroAddress();
        feeAddress = feeAddress_;
    }

    function setMinAmount(uint256 minAmount_) external onlyOwner {
        minAmount = minAmount_;
    }

    function setPaused(bool paused_) external onlyOwner {
        globalPaused = paused_;
    }
}
