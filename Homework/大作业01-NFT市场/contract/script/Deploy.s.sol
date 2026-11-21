// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Script, console} from "forge-std/Script.sol";
import {HelperConfig} from "./HelperConfig.s.sol";
import {NFTAuction} from "../src/NFTAuction.sol";
import {MockNFT} from "../src/MockNFT.sol";

/**
 * @notice 部署脚本
 * 使用方法：
 *   make deploy-local    → Anvil
 *   make deploy-sepolia  → Sepolia
 */
contract DeployScript is Script {
    function run() external returns (address auctionAddr, address nftAddr) {
        HelperConfig config = new HelperConfig();
        (address deployer) = config.activeConfig();

        console.log("Deployer   :", deployer);
        console.log("Chain ID   :", block.chainid);

        vm.startBroadcast();

        // 1. 部署 MockNFT（测试用）
        MockNFT mockNFT = new MockNFT(deployer);
        console.log("MockNFT    :", address(mockNFT));

        // 2. 部署拍卖合约
        NFTAuction auction = new NFTAuction();
        console.log("NFTAuction :", address(auction));

        vm.stopBroadcast();

        // 提示后续操作
        console.log("");
        console.log("=== Update the following addresses in .env ===");
        console.log("MOCK_NFT_ADDRESS=", address(mockNFT));
        console.log("AUCTION_ADDRESS=",  address(auction));

        return (address(auction), address(mockNFT));
    }
}
