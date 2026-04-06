// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Test} from "forge-std/Test.sol";
import {SimpleDiamond} from "../src/diamond-demo/SimpleDiamond.sol";
import {OwnerFacet} from "../src/diamond-demo/facets/OwnerFacet.sol";
import {CounterFacetV1} from "../src/diamond-demo/facets/CounterFacetV1.sol";
import {CounterFacetV2} from "../src/diamond-demo/facets/CounterFacetV2.sol";

/**
 * @notice Diamond 模式完整测试
 *
 * 重要：测试里我们把 diamond 的地址强制转换成各个 Facet 的接口类型来调用。
 *       例如：CounterFacetV1(address(diamond)).increment()
 *       这会向 diamond 发送 increment() 的 calldata，
 *       diamond 的 fallback 收到后查路由表，delegatecall 到对应 Facet。
 *       这就是 Diamond 对外表现为「一个合约」的原理。
 */
contract DiamondTest is Test {
    SimpleDiamond internal diamond;
    OwnerFacet internal ownerFacet;
    CounterFacetV1 internal counterV1;
    CounterFacetV2 internal counterV2;

    address internal owner = makeAddr("owner");
    address internal user  = makeAddr("user");

    function setUp() public {
        // 1. 部署各 Facet 实现合约（它们只是代码容器，自身没有任何存储意义）
        ownerFacet = new OwnerFacet();
        counterV1  = new CounterFacetV1();
        counterV2  = new CounterFacetV2();

        // 2. 构建初始路由表（Add 操作：注册函数 → Facet 的映射）
        SimpleDiamond.FacetCut[] memory cuts = new SimpleDiamond.FacetCut[](2);

        // OwnerFacet 管理的函数
        bytes4[] memory ownerSelectors = new bytes4[](2);
        ownerSelectors[0] = OwnerFacet.getOwner.selector;
        ownerSelectors[1] = OwnerFacet.transferOwnership.selector;
        cuts[0] = SimpleDiamond.FacetCut({
            facetAddress: address(ownerFacet),
            action: SimpleDiamond.FacetCutAction.Add,
            functionSelectors: ownerSelectors
        });

        // CounterFacetV1 管理的函数
        bytes4[] memory counterSelectors = new bytes4[](2);
        counterSelectors[0] = CounterFacetV1.increment.selector;
        counterSelectors[1] = CounterFacetV1.getCount.selector;
        cuts[1] = SimpleDiamond.FacetCut({
            facetAddress: address(counterV1),
            action: SimpleDiamond.FacetCutAction.Add,
            functionSelectors: counterSelectors
        });

        // 3. 部署 Diamond，同时完成初始注册
        vm.prank(owner);
        diamond = new SimpleDiamond(owner, cuts);
    }

    // ─── 验证初始路由 ──────────────────────────────────────────────────────────

    function test_RoutingTable_Initial() public view {
        // 验证每个选择器都正确指向对应 Facet
        assertEq(diamond.facetAddress(OwnerFacet.getOwner.selector),          address(ownerFacet));
        assertEq(diamond.facetAddress(OwnerFacet.transferOwnership.selector),  address(ownerFacet));
        assertEq(diamond.facetAddress(CounterFacetV1.increment.selector),      address(counterV1));
        assertEq(diamond.facetAddress(CounterFacetV1.getCount.selector),       address(counterV1));
    }

    // ─── V1 基础功能 ──────────────────────────────────────────────────────────

    function test_V1_GetOwner() public view {
        // 调用 diamond（不是 ownerFacet）的 getOwner
        // diamond 的 fallback 把这个调用路由到 ownerFacet
        address o = OwnerFacet(address(diamond)).getOwner();
        assertEq(o, owner);
    }

    function test_V1_Increment() public {
        CounterFacetV1 counter = CounterFacetV1(address(diamond));

        vm.prank(user);
        counter.increment();
        assertEq(counter.getCount(), 1);

        vm.prank(user);
        counter.increment();
        assertEq(counter.getCount(), 2);
    }

    function test_V1_Reverts_UnknownFunction() public {
        // 调用未注册的选择器，fallback 应该 revert
        (bool success,) = address(diamond).call(abi.encodeWithSignature("nonexistent()"));
        assertFalse(success);
    }

    // ─── 升级到 V2 ────────────────────────────────────────────────────────────

    function _upgradeToV2() internal {
        SimpleDiamond.FacetCut[] memory cuts = new SimpleDiamond.FacetCut[](2);

        // ① Replace：用 V2 的 increment 替换 V1 的 increment
        //    注意：选择器用 V1 的（函数签名没变，选择器相同），或直接写 V2 的都一样
        bytes4[] memory replaceSelectors = new bytes4[](1);
        replaceSelectors[0] = CounterFacetV1.increment.selector; // = CounterFacetV2.increment.selector
        cuts[0] = SimpleDiamond.FacetCut({
            facetAddress: address(counterV2),
            action: SimpleDiamond.FacetCutAction.Replace,
            functionSelectors: replaceSelectors
        });

        // ② Add：新增 setMaxCount（V1 没有这个函数）
        bytes4[] memory addSelectors = new bytes4[](1);
        addSelectors[0] = CounterFacetV2.setMaxCount.selector;
        cuts[1] = SimpleDiamond.FacetCut({
            facetAddress: address(counterV2),
            action: SimpleDiamond.FacetCutAction.Add,
            functionSelectors: addSelectors
        });

        vm.prank(owner);
        diamond.diamondCut(cuts);
    }

    function test_Upgrade_RoutingTableUpdated() public {
        _upgradeToV2();

        // increment 现在指向 V2
        assertEq(diamond.facetAddress(CounterFacetV1.increment.selector), address(counterV2));
        // getCount 没动，还是指向 V1
        assertEq(diamond.facetAddress(CounterFacetV1.getCount.selector),  address(counterV1));
        // setMaxCount 新增，指向 V2
        assertEq(diamond.facetAddress(CounterFacetV2.setMaxCount.selector), address(counterV2));
    }

    function test_Upgrade_HistoricalDataPreserved() public {
        // 升级前：count = 3
        CounterFacetV1 counter = CounterFacetV1(address(diamond));
        vm.startPrank(user);
        counter.increment();
        counter.increment();
        counter.increment();
        vm.stopPrank();
        assertEq(counter.getCount(), 3);

        // 升级到 V2
        _upgradeToV2();

        // 升级后：count 还是 3（AppStorage 里的数据没有变）
        assertEq(counter.getCount(), 3);
    }

    function test_Upgrade_V2_NoLimit_WorksLikeV1() public {
        _upgradeToV2();

        // maxCount 默认 0（无限制），行为和 V1 一样
        CounterFacetV1 counter = CounterFacetV1(address(diamond));
        vm.prank(user);
        counter.increment();
        assertEq(counter.getCount(), 1);
    }

    function test_Upgrade_V2_SetLimit_ThenBlock() public {
        _upgradeToV2();

        // 设置上限 = 2
        vm.prank(owner);
        CounterFacetV2(address(diamond)).setMaxCount(2);

        // 可以 increment 到 2
        CounterFacetV1 counter = CounterFacetV1(address(diamond));
        vm.prank(user);
        counter.increment(); // count = 1
        vm.prank(user);
        counter.increment(); // count = 2

        // 第 3 次应该被 V2 的上限检查阻止
        vm.prank(user);
        vm.expectRevert(abi.encodeWithSelector(CounterFacetV2.CountLimitReached.selector, 2, 2));
        counter.increment();
    }

    function test_Upgrade_OnlyOwner_CanDiamondCut() public {
        SimpleDiamond.FacetCut[] memory cuts = new SimpleDiamond.FacetCut[](0);
        vm.prank(user); // 非 owner
        vm.expectRevert(SimpleDiamond.NotOwner.selector);
        diamond.diamondCut(cuts);
    }

    // ─── 删除函数 ─────────────────────────────────────────────────────────────

    function test_Remove_Function() public {
        // 删除 getCount
        SimpleDiamond.FacetCut[] memory cuts = new SimpleDiamond.FacetCut[](1);
        bytes4[] memory sels = new bytes4[](1);
        sels[0] = CounterFacetV1.getCount.selector;
        cuts[0] = SimpleDiamond.FacetCut({
            facetAddress: address(0), // Remove 时填 address(0)
            action: SimpleDiamond.FacetCutAction.Remove,
            functionSelectors: sels
        });
        vm.prank(owner);
        diamond.diamondCut(cuts);

        // 删除后调用 getCount 应该 revert（路由表里没有这个选择器了）
        (bool success,) = address(diamond).call(abi.encodeWithSignature("getCount()"));
        assertFalse(success);
    }
}
