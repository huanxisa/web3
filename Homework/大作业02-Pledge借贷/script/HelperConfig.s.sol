// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Script} from "forge-std/Script.sol";

/// @notice 网络配置，根据 block.chainid 返回不同的 Chainlink 地址
contract HelperConfig is Script {
    struct NetworkConfig {
        address ethUsdPriceFeed;
        address deployer;
    }

    uint256 constant ANVIL_CHAIN_ID = 31337;
    uint256 constant SEPOLIA_CHAIN_ID = 11155111;
    uint256 constant MAINNET_CHAIN_ID = 1;

    function getConfig() external returns (NetworkConfig memory) {
        if (block.chainid == ANVIL_CHAIN_ID) {
            return _getAnvilConfig();
        } else if (block.chainid == SEPOLIA_CHAIN_ID) {
            return _getSepoliaConfig();
        } else if (block.chainid == MAINNET_CHAIN_ID) {
            return _getMainnetConfig();
        }
        revert("Unsupported network");
    }

    function _getSepoliaConfig() internal view returns (NetworkConfig memory) {
        return NetworkConfig({
            // https://docs.chain.link/data-feeds/price-feeds/addresses?network=ethereum&page=1
            ethUsdPriceFeed: 0x694AA1769357215DE4FAC081bf1f309aDC325306,
            deployer: vm.envAddress("DEPLOYER_ADDRESS")
        });
    }

    function _getMainnetConfig() internal view returns (NetworkConfig memory) {
        return NetworkConfig({
            ethUsdPriceFeed: 0x5f4eC3Df9cbd43714FE2740f5E3616155c5b8419,
            deployer: vm.envAddress("DEPLOYER_ADDRESS")
        });
    }

    function _getAnvilConfig() internal returns (NetworkConfig memory) {
        // 本地 Anvil 使用 Mock 价格预言机（在 Deploy 脚本中部署）
        return NetworkConfig({
            ethUsdPriceFeed: address(0), // 由 Deploy 脚本替换
            deployer: vm.rememberKey(vm.envUint("PRIVATE_KEY"))
        });
    }
}
