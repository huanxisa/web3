// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Script} from "forge-std/Script.sol";
import {CrowdfundingFactory} from "../src/CrowdfundingFactory.sol";
import {console} from "forge-std/console.sol";

contract DeployScript is Script {
    function run() external {
        // TODO: 读取私钥（vm.envUint("PRIVATE_KEY")）
        uint256 privateKey = vm.envUint("PRIVATE_KEY");
        // TODO: vm.startBroadcast(privateKey)
        vm.startBroadcast(privateKey);
        // TODO: 部署 CrowdfundingFactory
        CrowdfundingFactory factory = new CrowdfundingFactory();
        // TODO: console.log 输出合约地址
        console.log("CrowdfundingFactory deployed at:", address(factory));
        // TODO: vm.stopBroadcast()
        vm.stopBroadcast();
    }
}
