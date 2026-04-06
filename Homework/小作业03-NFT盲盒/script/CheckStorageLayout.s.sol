// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Script} from "forge-std/Script.sol";
import {console} from "forge-std/console.sol";
import {Upgrades, Options} from "openzeppelin-foundry-upgrades/Upgrades.sol";

/**
 * @notice 存储布局兼容性检查脚本（无需 broadcast，无需网络）
 *
 * 用途：
 *   - 升级前验证新版本与当前版本的存储布局是否兼容
 *   - 多人协作时，任何人提交新版本合约都应先跑此脚本
 *   - 不部署任何合约，纯静态分析，本地即可运行
 *
 * 使用方法：
 *   # 检查 V1 → V2 兼容性
 *   make check-storage
 *
 *   # 检查任意版本（通过环境变量指定）
 *   FROM=NFTBlindBox TO=NFTBlindBoxV2 make check-storage
 */
contract CheckStorageLayoutScript is Script {
    function run() external {
        string memory from = vm.envOr("FROM", string("NFTBlindBox"));
        string memory to   = vm.envOr("TO",   string("NFTBlindBoxV2"));

        string memory fromContract = string.concat("src/", from, ".sol:", from);
        string memory toContract   = string.concat("src/", to,   ".sol:", to);

        console.log("=== Storage Layout Compatibility Check ===");
        console.log("From :", fromContract);
        console.log("To   :", toContract);
        console.log("");

        // validateUpgrade 是纯静态分析：
        //   - 检查新合约存储布局是否与旧合约兼容
        //   - 检查是否有 selfdestruct / delegatecall 等危险操作
        //   - 不发送任何交易，不需要 RPC 连接
        Options memory opts;
        opts.referenceContract = fromContract;
        Upgrades.validateUpgrade(toContract, opts);

        console.log("[PASS] Storage layout is compatible.");
        console.log("       Safe to upgrade", from, "->", to);
    }
}
