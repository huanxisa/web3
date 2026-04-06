// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Script} from "forge-std/Script.sol";
import {console} from "forge-std/console.sol";
import {MultiSigWallet} from "../src/MultiSigWallet.sol";

contract DeployScript is Script {
    function run() external returns (MultiSigWallet) {
        address deployer = msg.sender;

        console.log("Deployer:", deployer);
        console.log("Chain ID:", block.chainid);

        // TODO：配置初始 owners 和 threshold
        address[] memory owners = new address[](1);
        owners[0] = deployer;
        uint256 threshold = 1;

        vm.startBroadcast();
        MultiSigWallet wallet = new MultiSigWallet(owners, threshold);
        vm.stopBroadcast();

        console.log("MultiSigWallet deployed at:", address(wallet));
        return wallet;
    }
}
