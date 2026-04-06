// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Test} from "forge-std/Test.sol";
import {MultiSigWallet} from "../src/MultiSigWallet.sol";

// ============================================================
// 基础测试合约：setUp 只初始化空钱包
// 覆盖：部署、所有者管理、提案提交
// ============================================================
contract MultiSigWalletTest is Test {
    MultiSigWallet internal wallet;

    address internal owner1 = makeAddr("owner1");
    address internal owner2 = makeAddr("owner2");
    address internal owner3 = makeAddr("owner3");
    address internal nonOwner = makeAddr("nonOwner");
    address internal recipient = makeAddr("recipient");

    address[] internal owners;
    uint256 internal constant THRESHOLD = 2;

    function setUp() public virtual {
        owners.push(owner1);
        owners.push(owner2);
        owners.push(owner3);
        wallet = new MultiSigWallet(owners, THRESHOLD);
        vm.deal(address(wallet), 10 ether);
    }

    // ========== 辅助函数 ==========

    function _expectRevertIfNotOwner(bytes memory callData) internal {
        vm.prank(nonOwner);
        (bool success, ) = address(wallet).call(callData);
        assertFalse(success);
    }

    // ========== 部署测试 ==========

    function test_InitialState() public view {
        address[] memory _owners = wallet.getOwners();
        assertEq(_owners.length, owners.length);
        for (uint256 i = 0; i < _owners.length; i++) {
            assertEq(_owners[i], owners[i]);
        }
        assertEq(wallet.getThreshold(), THRESHOLD);
    }

    function test_RejectZeroAddress() public {
        address[] memory _owners = new address[](2);
        _owners[0] = address(0);
        _owners[1] = owner1;
        vm.expectRevert(MultiSigWallet.InvalidOwner.selector);
        new MultiSigWallet(_owners, THRESHOLD);
    }

    function test_RejectInvalidThreshold() public {
        address[] memory _owners = new address[](2);
        _owners[0] = owner1;
        _owners[1] = owner2;
        vm.expectRevert(MultiSigWallet.InvalidThreshold.selector);
        new MultiSigWallet(_owners, 0);
        vm.expectRevert(MultiSigWallet.InvalidThreshold.selector);
        new MultiSigWallet(_owners, 3);
    }

    // ========== 所有者管理测试 ==========

    function test_AddOwner() public {
        vm.prank(owner1);
        wallet.addOwner(nonOwner);
        assertEq(wallet.getOwners().length, owners.length + 1);
        assertEq(wallet.getOwners()[owners.length], nonOwner);
    }

    function test_AddOwner_RejectDuplicate() public {
        vm.prank(owner1);
        vm.expectRevert(MultiSigWallet.AlreadyOwner.selector);
        wallet.addOwner(owner2);
    }

    function test_AddOwner_RejectZeroAddress() public {
        vm.prank(owner1);
        vm.expectRevert(MultiSigWallet.InvalidOwner.selector);
        wallet.addOwner(address(0));
    }

    function test_RemoveOwner() public {
        vm.prank(owner1);
        wallet.removeOwner(owner2);
        assertEq(wallet.getOwners().length, owners.length - 1);
        assertFalse(wallet.isOwner(owner2));
    }

    function test_ChangeThreshold() public {
        vm.prank(owner1);
        wallet.changeThreshold(3);
        assertEq(wallet.getThreshold(), 3);
    }

    function test_OnlyOwnerCanManage() public {
        _expectRevertIfNotOwner(
            abi.encodeWithSelector(wallet.addOwner.selector, nonOwner)
        );
        _expectRevertIfNotOwner(
            abi.encodeWithSelector(wallet.removeOwner.selector, owner2)
        );
        _expectRevertIfNotOwner(
            abi.encodeWithSelector(wallet.changeThreshold.selector, 3)
        );
        _expectRevertIfNotOwner(
            abi.encodeWithSelector(
                wallet.submitTransaction.selector,
                recipient,
                1 ether,
                ""
            )
        );
        _expectRevertIfNotOwner(
            abi.encodeWithSelector(wallet.confirmTransaction.selector, 0)
        );
        _expectRevertIfNotOwner(
            abi.encodeWithSelector(wallet.revokeConfirmation.selector, 0)
        );
        _expectRevertIfNotOwner(
            abi.encodeWithSelector(wallet.executeTransaction.selector, 0)
        );
    }

    // ========== 提案功能测试 ==========

    function test_SubmitTransaction() public virtual {
        vm.prank(owner1);
        uint256 txIndex = wallet.submitTransaction(recipient, 1 ether, "");

        assertEq(txIndex, 0);
        assertEq(wallet.getTransactionCount(), 1);

        (
            address to,
            uint256 value,
            ,
            bool executed,
            uint256 confirmationCount
        ) = wallet.getTransaction(0);
        assertEq(to, recipient);
        assertEq(value, 1 ether);
        assertEq(executed, false);
        assertEq(confirmationCount, 0);
    }
}

// ============================================================
// 扩展测试合约：setUp 在空钱包基础上预提交一笔交易
// 覆盖：确认机制、执行交易
// ============================================================
contract MultiSigWalletWithTxTest is MultiSigWalletTest {
    function setUp() public override {
        super.setUp(); // 初始化空钱包
        vm.prank(owner1);
        wallet.submitTransaction(recipient, 1 ether, ""); // 预提交一笔交易（index=0）
    }

    // ========== 确认机制测试 ==========

    function test_ConfirmTransaction() public {
        vm.prank(owner1);
        wallet.confirmTransaction(0);

        assertEq(wallet.getConfirmationCount(0), 1);
        assertFalse(wallet.canExecute(0)); // 还差一个确认
    }

    function test_RevokeConfirmation() public {
        vm.prank(owner1);
        wallet.confirmTransaction(0);
        vm.prank(owner1);
        wallet.revokeConfirmation(0);

        assertEq(wallet.getConfirmationCount(0), 0);
    }

    function test_PreventDoubleConfirm() public {
        vm.prank(owner1);
        wallet.confirmTransaction(0);
        vm.prank(owner1);
        vm.expectRevert(MultiSigWallet.AlreadyConfirmed.selector);
        wallet.confirmTransaction(0);
    }

    // ========== 执行交易测试 ==========

    function test_ExecuteTransaction() public {
        vm.prank(owner1);
        wallet.confirmTransaction(0);
        vm.prank(owner2);
        wallet.confirmTransaction(0);

        uint256 balanceBefore = recipient.balance;
        vm.prank(owner1);
        wallet.executeTransaction(0);

        assertEq(recipient.balance, balanceBefore + 1 ether);
        (, , , bool executed, ) = wallet.getTransaction(0);
        assertTrue(executed);
    }

    function test_PreventDoubleExecution() public {
        vm.prank(owner1);
        wallet.confirmTransaction(0);
        vm.prank(owner2);
        wallet.confirmTransaction(0);
        vm.prank(owner1);
        wallet.executeTransaction(0);

        vm.prank(owner1);
        vm.expectRevert(MultiSigWallet.AlreadyExecuted.selector);
        wallet.executeTransaction(0);
    }

    function test_InsufficientConfirmations() public {
        vm.prank(owner1);
        wallet.confirmTransaction(0); // 只有1个，需要2个

        vm.prank(owner1);
        vm.expectRevert(MultiSigWallet.NotEnoughConfirmations.selector);
        wallet.executeTransaction(0);
    }

    // ========== 边界测试 ==========

    function test_ReceiveETH() public {
        uint256 balanceBefore = wallet.getBalance();
        vm.deal(address(this), 1 ether);
        (bool ok, ) = address(wallet).call{value: 1 ether}("");
        assertTrue(ok);
        assertEq(wallet.getBalance(), balanceBefore + 1 ether);
    }

    // setUp 里已预提交一笔交易，此测试在子类里不适用
    function test_SubmitTransaction() public override {}
}
