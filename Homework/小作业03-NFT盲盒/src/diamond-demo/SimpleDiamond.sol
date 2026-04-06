// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {AppStorage} from "./storage/AppStorage.sol";

/**
 * @title SimpleDiamond
 * @notice Diamond 模式的代理合约，负责两件事：
 *   1. 路由：根据函数选择器把调用转发给对应的 Facet
 *   2. 升级：通过 diamondCut 增加/替换/删除函数→Facet 的映射
 *
 * ─── 和 UUPS Proxy 的区别 ────────────────────────────────────────────────
 *
 * UUPS Proxy：  所有函数 → 一个实现合约（整体替换）
 * Diamond：     每个函数 → 各自的 Facet 合约（逐函数替换）
 *
 * ─── 路由机制 ────────────────────────────────────────────────────────────
 *
 * 路由表 = mapping(bytes4 selector => address facet)
 *
 * 用户调用 increment()：
 *   1. calldata 的前 4 字节 = increment() 的选择器 = 0xd09de08a
 *   2. 查路由表：0xd09de08a → CounterFacetV1 地址
 *   3. delegatecall CounterFacetV1.increment()
 *      （用 CounterFacetV1 的代码，读写 Diamond Proxy 的存储）
 */
contract SimpleDiamond {
    // ─── 路由表 ───────────────────────────────────────────────────────────────
    // selector（函数签名的前4字节）→ Facet 合约地址
    mapping(bytes4 => address) private _facets;

    // ─── 事件 ─────────────────────────────────────────────────────────────────
    enum FacetCutAction { Add, Replace, Remove }

    struct FacetCut {
        address facetAddress;         // Facet 合约地址（Remove 时填 address(0)）
        FacetCutAction action;        // Add / Replace / Remove
        bytes4[] functionSelectors;   // 要操作的函数选择器列表
    }

    event DiamondCut(FacetCut[] cuts);

    // ─── 错误 ─────────────────────────────────────────────────────────────────
    error NotOwner();
    error FunctionNotFound(bytes4 selector);
    error SelectorAlreadyExists(bytes4 selector);
    error SelectorNotFound(bytes4 selector);
    error DelegateCallFailed();

    // ─── 构造 ─────────────────────────────────────────────────────────────────
    constructor(address owner_, FacetCut[] memory initialCuts) {
        // 初始化 owner（写入命名空间存储）
        AppStorage.get().owner = owner_;
        // 注册初始 Facet 函数
        _executeCuts(initialCuts);
    }

    // ─── 升级入口（仅 owner）─────────────────────────────────────────────────
    /**
     * @notice 增加/替换/删除函数到 Facet 的映射
     *
     * 典型用法——把 CounterFacetV1 的 increment 替换为 CounterFacetV2：
     *   FacetCut[] memory cuts = new FacetCut[](1);
     *   cuts[0] = FacetCut({
     *       facetAddress: address(counterV2),
     *       action: FacetCutAction.Replace,
     *       functionSelectors: [CounterFacetV1.increment.selector]
     *   });
     *   diamond.diamondCut(cuts);
     *
     * 关键点：只替换了 increment 这一个函数，其他函数（getCount 等）不受影响，
     * 仍然指向原来的 Facet。
     */
    function diamondCut(FacetCut[] calldata cuts) external {
        if (msg.sender != AppStorage.get().owner) revert NotOwner();
        _executeCuts(cuts);
        emit DiamondCut(cuts);
    }

    // ─── 查询路由表 ───────────────────────────────────────────────────────────
    function facetAddress(bytes4 selector) external view returns (address) {
        return _facets[selector];
    }

    // ─── 核心路由：fallback ───────────────────────────────────────────────────
    /**
     * @notice 所有非 diamondCut / facetAddress 的调用都走这里
     *
     * 执行步骤：
     *   1. 从 calldata 前 4 字节提取函数选择器
     *   2. 查路由表找到目标 Facet 地址
     *   3. delegatecall 到 Facet（Facet 的代码在 Diamond 的存储上运行）
     *   4. 把 Facet 的返回值原样返回给调用者
     *
     * 为什么用 assembly？
     *   Solidity 高层语法没有办法「透明转发任意 calldata 并原样返回任意结果」，
     *   必须用汇编直接操作内存。
     */
    fallback() external payable {
        // 1. 取选择器（calldata 前 4 字节）
        bytes4 selector = msg.sig;

        // 2. 查路由表
        address facet = _facets[selector];
        if (facet == address(0)) revert FunctionNotFound(selector);

        // 3. delegatecall + 透明转发
        assembly {
            // calldatacopy(destMem, srcCalldata, size)
            // 把完整 calldata 复制到内存 0 位置
            calldatacopy(0, 0, calldatasize())

            // delegatecall(gas, to, inOffset, inSize, outOffset, outSize)
            // outOffset=0, outSize=0：不预先知道返回值大小，后面用 returndatacopy 处理
            let result := delegatecall(gas(), facet, 0, calldatasize(), 0, 0)

            // 把 delegatecall 的返回数据复制到内存 0
            returndatacopy(0, 0, returndatasize())

            switch result
            case 0 {
                // delegatecall 失败：把错误信息 revert 出去
                revert(0, returndatasize())
            }
            default {
                // delegatecall 成功：把返回数据 return 出去
                return(0, returndatasize())
            }
        }
    }

    receive() external payable {}

    // ─── 内部：执行 cuts ──────────────────────────────────────────────────────
    function _executeCuts(FacetCut[] memory cuts) internal {
        for (uint256 i = 0; i < cuts.length; i++) {
            FacetCut memory cut = cuts[i];

            for (uint256 j = 0; j < cut.functionSelectors.length; j++) {
                bytes4 sel = cut.functionSelectors[j];

                if (cut.action == FacetCutAction.Add) {
                    // 新增：选择器不能已存在
                    if (_facets[sel] != address(0)) revert SelectorAlreadyExists(sel);
                    _facets[sel] = cut.facetAddress;

                } else if (cut.action == FacetCutAction.Replace) {
                    // 替换：选择器必须已存在
                    if (_facets[sel] == address(0)) revert SelectorNotFound(sel);
                    _facets[sel] = cut.facetAddress;

                } else {
                    // 删除：选择器必须已存在，设为 address(0) 即禁用
                    if (_facets[sel] == address(0)) revert SelectorNotFound(sel);
                    _facets[sel] = address(0);
                }
            }
        }
    }
}
