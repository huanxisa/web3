// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

/// @title IPledgePool - 多池子固定利率借贷协议接口
/// @notice 每个池子独立配置，通过 pool ID (pid) 区分
///
/// ## 池子生命周期（状态机）
///
///   MATCH ─────────────────────────────────► UNDONE（募集期结束但资金不足）
///     │
///     │ 触发条件：settleTime 到期且资金充足
///     ▼
///   EXECUTION ─────────────────────────────► LIQUIDATION（抵押价值跌破阈值）
///     │
///     │ 触发条件：endTime 到期，借款人还款
///     ▼
///   FINISH
///
interface IPledgePool {
    // ─── 状态枚举 ────────────────────────────────────────────
    enum PoolState {
        MATCH,       // 募集中：接受存款/抵押
        EXECUTION,   // 运行中：借款人已获取资金
        FINISH,      // 已完成：正常到期还款
        LIQUIDATION, // 已清算：抵押品价值跌破阈值
        UNDONE       // 已取消：募集失败
    }

    // ─── 池子基本信息 ────────────────────────────────────────
    struct PoolBaseInfo {
        uint256 settleTime;          // 结算时间（募集截止，超过则可能 UNDONE）
        uint256 endTime;             // 到期时间（还款截止）
        uint256 interestRate;        // 固定利率（精度 1e8，如 1e7 = 10%）
        uint256 maxSupply;           // 借出方最大募集额（lendToken 单位）
        uint256 lendSupply;          // 当前贷款人已存入总量
        uint256 borrowSupply;        // 当前借款人已抵押总量
        uint256 martgageRate;        // 抵押率（精度 1e8，如 2e8 = 200%）
        address lendToken;           // 贷款代币（如 USDC）
        address borrowToken;         // 抵押代币（如 WBTC）
        PoolState state;
        address spCoin;              // 贷款人份额代币 DebtToken 地址
        address jpCoin;              // 借款人债务代币 DebtToken 地址
        uint256 autoLiquidateThreshold; // 自动清算阈值（精度 1e8）
    }

    // ─── 池子结算数据 ────────────────────────────────────────
    struct PoolDataInfo {
        uint256 settleAmountLend;    // 结算时实际出借金额
        uint256 settleAmountBorrow;  // 结算时实际抵押金额
        uint256 finishAmountLend;    // 完成时出借侧金额
        uint256 finishAmountBorrow;  // 完成时借款侧金额
        uint256 liquidationAmounLend;   // 清算时出借侧金额
        uint256 liquidationAmounBorrow; // 清算时借款侧金额
    }

    // ─── 用户信息 ────────────────────────────────────────────
    struct LendInfo {
        uint256 stakeAmount;  // 存入金额
        uint256 refundAmount; // 可退款金额
        bool hasNoRefund;     // false=未退款，true=已退款
        bool hasNoClaim;      // false=未领取，true=已领取
    }

    struct BorrowInfo {
        uint256 stakeAmount;  // 抵押金额
        uint256 refundAmount; // 可退款金额
        bool hasNoRefund;
        bool hasNoClaim;
    }

    // ─── 事件 ────────────────────────────────────────────────
    event PoolCreated(uint256 indexed pid, address lendToken, address borrowToken, uint256 settleTime, uint256 endTime);
    event StateChange(uint256 indexed pid, PoolState oldState, PoolState newState);

    event DepositLend(address indexed user, uint256 indexed pid, address token, uint256 amount, uint256 mintAmount);
    event RefundLend(address indexed user, uint256 indexed pid, address token, uint256 amount);
    event ClaimLend(address indexed user, uint256 indexed pid, address token, uint256 amount);
    event WithdrawLend(address indexed user, uint256 indexed pid, address token, uint256 amount);

    event DepositBorrow(address indexed user, uint256 indexed pid, address token, uint256 amount, uint256 mintAmount);
    event RefundBorrow(address indexed user, uint256 indexed pid, address token, uint256 amount);
    event ClaimBorrow(address indexed user, uint256 indexed pid, address token, uint256 amount);
    event WithdrawBorrow(address indexed user, uint256 indexed pid, address token, uint256 amount);
    event Repay(address indexed user, uint256 indexed pid, address token, uint256 amount);

    event Liquidate(uint256 indexed pid, address token, uint256 collateralAmount, uint256 debtAmount);

    // ─── 管理员操作 ──────────────────────────────────────────
    struct CreatePoolParams {
        uint256 settleTime;
        uint256 endTime;
        uint256 interestRate;
        uint256 maxSupply;
        uint256 martgageRate;
        address lendToken;
        address borrowToken;
        address spToken;
        address jpToken;
        uint256 autoLiquidateThreshold;
    }

    function createPoolInfo(CreatePoolParams calldata params) external;

    // ─── 贷款人操作 ──────────────────────────────────────────
    function depositLend(uint256 pid, uint256 stakeAmount) external;
    function withdrawLend(uint256 pid, uint256 spAmount) external;
    function claimLend(uint256 pid) external;
    function refundLend(uint256 pid) external;

    // ─── 借款人操作 ──────────────────────────────────────────
    function depositBorrow(uint256 pid, uint256 stakeAmount) external;
    function withdrawBorrow(uint256 pid, uint256 jpAmount) external;
    function claimBorrow(uint256 pid) external;
    function refundBorrow(uint256 pid) external;
    function repay(uint256 pid) external;

    // ─── 清算 ────────────────────────────────────────────────
    function checkoutLiquidate(uint256 pid) external returns (bool);
    function liquidate(uint256 pid) external;

    // ─── 视图 ────────────────────────────────────────────────
    function poolLength() external view returns (uint256);
    function getPoolBaseInfo(uint256 pid) external view returns (PoolBaseInfo memory);
    function getPoolDataInfo(uint256 pid) external view returns (PoolDataInfo memory);
    function getUserLendInfo(uint256 pid, address user) external view returns (LendInfo memory);
    function getUserBorrowInfo(uint256 pid, address user) external view returns (BorrowInfo memory);
    function getBorrowTokenPrice(uint256 pid) external view returns (uint256);
}
