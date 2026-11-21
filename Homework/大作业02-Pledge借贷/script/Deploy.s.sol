// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Script, console} from "forge-std/Script.sol";
import {PledgePool} from "../src/PledgePool.sol";
import {IPledgePool} from "../src/interfaces/IPledgePool.sol";
import {DebtToken} from "../src/tokens/DebtToken.sol";
import {MockERC20} from "../src/mocks/MockERC20.sol";
import {MockPriceFeed} from "../src/mocks/MockPriceFeed.sol";
import {HelperConfig} from "./HelperConfig.s.sol";

/// @title DeployScript - 部署 Pledge 借贷协议
///
/// ## 部署流程
///
/// 1. 部署 PledgePool（传入手续费接收地址）
/// 2. 为每个池子单独部署 spToken + jpToken（DebtToken），owner = pool
/// 3. 调用 pool.createPoolInfo() 注册池子
/// 4. 调用 pool.setPriceFeed() 设置 Chainlink 价格预言机
///
/// ## 注意
/// spToken/jpToken 需先于 createPoolInfo 部署，因为地址要作为参数传入
///
contract DeployScript is Script {
    function run() external {
        HelperConfig helperConfig = new HelperConfig();
        HelperConfig.NetworkConfig memory net = helperConfig.getConfig();

        address deployer = net.deployer;
        address ethUsdFeed = net.ethUsdPriceFeed;
        address lendToken;
        address borrowToken;

        vm.startBroadcast(deployer);

        // ── 本地 Anvil：部署 Mock 代币和价格预言机 ─────────────
        if (block.chainid == 31337) {
            MockERC20 usdc = new MockERC20("USDC", "USDC", 6);
            MockERC20 wbtc = new MockERC20("Wrapped BTC", "WBTC", 8);
            MockPriceFeed mockFeed = new MockPriceFeed(40_000e8, 8); // $40,000/BTC

            usdc.mint(deployer, 10_000_000e6);
            wbtc.mint(deployer, 100e8);

            lendToken = address(usdc);
            borrowToken = address(wbtc);
            ethUsdFeed = address(mockFeed);

            console.log("MockUSDC:", lendToken);
            console.log("MockWBTC:", borrowToken);
            console.log("MockBTCFeed:", ethUsdFeed);
        } else {
            // Sepolia/Mainnet 使用真实代币地址（从 .env 读取）
            lendToken = vm.envAddress("LEND_TOKEN_ADDRESS");
            borrowToken = vm.envAddress("BORROW_TOKEN_ADDRESS");
        }

        // ── 部署 PledgePool ──────────────────────────────────────
        address feeAddress = vm.envOr("FEE_ADDRESS", deployer);
        PledgePool pledgePool = new PledgePool(feeAddress);

        // ── 为第一个池子部署 DebtToken ───────────────────────────
        uint256 settleTime = block.timestamp + 1 days;
        uint256 endTime    = block.timestamp + 31 days;

        DebtToken spToken = new DebtToken(
            "SP USDC Pool1", "spUSDC-1", 6, address(pledgePool)
        );
        DebtToken jpToken = new DebtToken(
            "JP WBTC Pool1", "jpWBTC-1", 8, address(pledgePool)
        );

        // ── 创建第一个借贷池 ─────────────────────────────────────
        pledgePool.createPoolInfo(IPledgePool.CreatePoolParams({
            settleTime:             settleTime,
            endTime:                endTime,
            interestRate:           5e6,
            maxSupply:              1_000_000e6,
            martgageRate:           2e8,
            lendToken:              lendToken,
            borrowToken:            borrowToken,
            spToken:                address(spToken),
            jpToken:                address(jpToken),
            autoLiquidateThreshold: 15e7
        }));

        // ── 设置价格预言机 ────────────────────────────────────────
        pledgePool.setPriceFeed(0, ethUsdFeed);

        vm.stopBroadcast();

        console.log("============= Deploy Complete =============");
        console.log("PledgePool:", address(pledgePool));
        console.log("spToken (Pool 0):", address(spToken));
        console.log("jpToken (Pool 0):", address(jpToken));
        console.log("Update PLEDGE_POOL_ADDRESS in .env");
    }
}
