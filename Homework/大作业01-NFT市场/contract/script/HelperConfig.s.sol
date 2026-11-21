// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Script} from "forge-std/Script.sol";

/**
 * @notice 按 block.chainid 提供各网络差异化配置
 * 新增网络时只在此文件追加一个 else if 分支，部署脚本无需改动。
 */
contract HelperConfig is Script {
    struct NetworkConfig {
        address deployer;
    }

    NetworkConfig public activeConfig;

    constructor() {
        if (block.chainid == 31337) {
            activeConfig = _getAnvilConfig();
        } else if (block.chainid == 11155111) {
            activeConfig = _getSepoliaConfig();
        } else if (block.chainid == 1) {
            activeConfig = _getMainnetConfig();
        } else {
            revert(string.concat("Unsupported chainId: ", vm.toString(block.chainid)));
        }
    }

    function _getAnvilConfig() internal pure returns (NetworkConfig memory) {
        return NetworkConfig({
            deployer: 0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266 // Anvil 默认账户 #0
        });
    }

    function _getSepoliaConfig() internal view returns (NetworkConfig memory) {
        return NetworkConfig({
            deployer: vm.envAddress("DEPLOYER_ADDRESS")
        });
    }

    function _getMainnetConfig() internal view returns (NetworkConfig memory) {
        return NetworkConfig({
            deployer: vm.envAddress("DEPLOYER_ADDRESS")
        });
    }
}
