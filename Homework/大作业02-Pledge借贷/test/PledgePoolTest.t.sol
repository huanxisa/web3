// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Test} from "forge-std/Test.sol";
import {console} from "forge-std/console.sol";

import {PledgePool} from "../src/PledgePool.sol";
import {DebtToken} from "../src/tokens/DebtToken.sol";
import {MockERC20} from "../src/mocks/MockERC20.sol";
import {MockPriceFeed} from "../src/mocks/MockPriceFeed.sol";
import {IPledgePool} from "../src/interfaces/IPledgePool.sol";

contract PledgePoolTest is Test {
    // ─── 合约 ────────────────────────────────────────────────
    PledgePool public pool;
    MockERC20 public usdc;   // lendToken
    MockERC20 public wbtc;   // borrowToken
    MockPriceFeed public btcFeed;
    DebtToken public spToken; // 贷款人份额代币
    DebtToken public jpToken; // 借款人债务代币

    // ─── 账户 ────────────────────────────────────────────────
    address owner = makeAddr("owner");
    address lender1 = makeAddr("lender1");
    address lender2 = makeAddr("lender2");
    address borrower1 = makeAddr("borrower1");
    address liquidator = makeAddr("liquidator");
    address feeAddr = makeAddr("feeAddr");

    // ─── 常量 ────────────────────────────────────────────────
    uint256 constant BTC_PRICE = 40_000e8;   // $40,000/BTC（Chainlink 8 位）
    uint256 constant LEND_AMOUNT = 10_000e6; // 10,000 USDC
    uint256 constant COLLATERAL = 1e8;       // 1 WBTC（8 位精度）
    uint256 constant INTEREST_RATE = 5e6;    // 5%（精度 1e8）
    uint256 constant MARTGAGE_RATE = 2e8;    // 200% 抵押率（精度 1e8）
    uint256 constant AUTO_LIQ_THRESHOLD = 15e7; // 150% 触发清算

    uint256 public pid; // 测试用池子 ID

    function setUp() public {
        vm.startPrank(owner);

        // 部署 Mock 代币
        usdc = new MockERC20("USDC", "USDC", 6);
        wbtc = new MockERC20("Wrapped BTC", "WBTC", 8);

        // 部署 Mock 价格预言机（初始 $40,000/BTC）
        btcFeed = new MockPriceFeed(int256(BTC_PRICE), 8);

        // 部署 PledgePool（收费地址）
        pool = new PledgePool(feeAddr);

        // 部署 spToken / jpToken，owner 为 pool
        spToken = new DebtToken("SP USDC Pool1", "spUSDC-1", 6, address(pool));
        jpToken = new DebtToken("JP WBTC Pool1", "jpWBTC-1", 8, address(pool));

        // 创建池子（settleTime = 1天后，endTime = 31天后）
        pool.createPoolInfo(IPledgePool.CreatePoolParams({
            settleTime: block.timestamp + 1 days,
            endTime:    block.timestamp + 31 days,
            interestRate: INTEREST_RATE,
            maxSupply:  100_000e6,
            martgageRate: MARTGAGE_RATE,
            lendToken:  address(usdc),
            borrowToken: address(wbtc),
            spToken:    address(spToken),
            jpToken:    address(jpToken),
            autoLiquidateThreshold: AUTO_LIQ_THRESHOLD
        }));
        pid = 0; // 第一个池子

        // 设置价格预言机
        pool.setPriceFeed(pid, address(btcFeed));

        vm.stopPrank();

        // 给测试账户 mint 代币
        usdc.mint(lender1, 100_000e6);
        usdc.mint(lender2, 100_000e6);
        wbtc.mint(borrower1, 10e8);
        usdc.mint(liquidator, 1_000_000e6);
    }

    // ─── 1. 基础状态测试 ─────────────────────────────────────

    function test_InitialPoolState() public view {
        IPledgePool.PoolBaseInfo memory info = pool.getPoolBaseInfo(pid);
        assertEq(uint8(info.state), uint8(IPledgePool.PoolState.MATCH));
        assertEq(info.lendToken, address(usdc));
        assertEq(info.borrowToken, address(wbtc));
        assertEq(info.spCoin, address(spToken));
        assertEq(info.jpCoin, address(jpToken));
        assertEq(pool.poolLength(), 1);
    }

    // ─── 2. 贷款人存款测试 ───────────────────────────────────

    function test_DepositLend_Success() public {
        vm.startPrank(lender1);
        usdc.approve(address(pool), LEND_AMOUNT);
        pool.depositLend(pid, LEND_AMOUNT);
        vm.stopPrank();

        // TODO: 实现后取消注释
        // assertEq(spToken.balanceOf(lender1), LEND_AMOUNT);
        // assertEq(pool.getPoolBaseInfo(pid).lendSupply, LEND_AMOUNT);
    }

    function test_DepositLend_RevertAfterSettle() public {
        // 募集期过了之后不能再存款
        vm.warp(block.timestamp + 2 days);
        vm.startPrank(lender1);
        usdc.approve(address(pool), LEND_AMOUNT);
        // TODO: vm.expectRevert(...)
        // pool.depositLend(pid, LEND_AMOUNT);
        vm.stopPrank();
    }

    function testFuzz_DepositLend(uint256 amount) public {
        amount = bound(amount, 100e6, 50_000e6);
        vm.startPrank(lender1);
        usdc.approve(address(pool), amount);
        pool.depositLend(pid, amount);
        vm.stopPrank();
    }

    // ─── 3. 借款人抵押测试 ───────────────────────────────────

    function test_DepositBorrow_Success() public {
        vm.startPrank(borrower1);
        wbtc.approve(address(pool), COLLATERAL);
        pool.depositBorrow(pid, COLLATERAL);
        vm.stopPrank();

        // TODO: 实现后取消注释
        // assertEq(jpToken.balanceOf(borrower1), COLLATERAL);
    }

    // ─── 4. 完整流程测试（MATCH → EXECUTION → FINISH） ────────

    function test_FullFlow_LenderAndBorrower() public {
        // Step 1: 贷款人存款
        vm.startPrank(lender1);
        usdc.approve(address(pool), LEND_AMOUNT);
        pool.depositLend(pid, LEND_AMOUNT);
        vm.stopPrank();

        // Step 2: 借款人抵押
        vm.startPrank(borrower1);
        wbtc.approve(address(pool), COLLATERAL);
        pool.depositBorrow(pid, COLLATERAL);
        vm.stopPrank();

        // Step 3: 结算（settleTime 到期）
        vm.warp(block.timestamp + 1 days + 1);
        pool.settle(pid);
        // TODO: assertEq(uint8(pool.getPoolBaseInfo(pid).state), uint8(IPledgePool.PoolState.EXECUTION));

        // Step 4: 借款人领取资金
        vm.prank(borrower1);
        pool.claimBorrow(pid);

        // Step 5: 快进到期
        vm.warp(block.timestamp + 30 days);

        // Step 6: 借款人还款
        vm.startPrank(borrower1);
        usdc.approve(address(pool), type(uint256).max);
        pool.repay(pid);
        vm.stopPrank();

        // Step 7: 贷款人取款（本金+利息）
        // TODO: 取款并断言余额
    }

    // ─── 5. 退款测试（UNDONE 状态） ──────────────────────────

    function test_RefundLend_WhenUndone() public {
        // 存款后募集失败（只有贷款人，没有借款人）
        vm.startPrank(lender1);
        usdc.approve(address(pool), LEND_AMOUNT);
        pool.depositLend(pid, LEND_AMOUNT);
        vm.stopPrank();

        vm.warp(block.timestamp + 1 days + 1);
        pool.settle(pid); // 无借款人 → UNDONE

        vm.prank(lender1);
        pool.refundLend(pid);

        // TODO: assertEq(usdc.balanceOf(lender1), 100_000e6);
    }

    // ─── 6. 清算测试 ─────────────────────────────────────────

    function test_Liquidate_WhenPriceDrop() public {
        _setupExecution();

        // BTC 价格跌至 $15,000（低于清算阈值）
        btcFeed.setPrice(int256(15_000e8));
        assertTrue(pool.checkoutLiquidate(pid));

        pool.liquidate(pid);
        // TODO: assertEq(uint8(pool.getPoolBaseInfo(pid).state), uint8(IPledgePool.PoolState.LIQUIDATION));
    }

    function test_Liquidate_RevertWhenPriceNormal() public {
        _setupExecution();
        assertFalse(pool.checkoutLiquidate(pid));
        // TODO: vm.expectRevert(PledgePool.NotLiquidatable.selector);
        // pool.liquidate(pid);
    }

    // ─── 辅助函数 ────────────────────────────────────────────

    function _setupExecution() internal {
        vm.startPrank(lender1);
        usdc.approve(address(pool), LEND_AMOUNT);
        pool.depositLend(pid, LEND_AMOUNT);
        vm.stopPrank();

        vm.startPrank(borrower1);
        wbtc.approve(address(pool), COLLATERAL);
        pool.depositBorrow(pid, COLLATERAL);
        vm.stopPrank();

        vm.warp(block.timestamp + 1 days + 1);
        pool.settle(pid);

        vm.prank(borrower1);
        pool.claimBorrow(pid);
    }
}
