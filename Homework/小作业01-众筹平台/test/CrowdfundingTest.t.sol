// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Test} from "forge-std/Test.sol";
import {CrowdfundingCampaign} from "../src/CrowdfundingCampaign.sol";
import {CrowdfundingFactory} from "../src/CrowdfundingFactory.sol";
import {ReentrancyAttacker} from "./ReentrancyAttacker.sol";

contract CrowdfundingTest is Test {
    CrowdfundingFactory factory;
    CrowdfundingCampaign campaign;

    // makeAddr: generate deterministic test addresses from a string label
    address owner = makeAddr("owner");
    address alice = makeAddr("alice");
    address bob = makeAddr("bob");

    uint256 constant GOAL = 10 ether;
    uint256 constant DURATION = 30;

    // setUp runs before each test_ function (like @BeforeEach in JUnit)
    function setUp() public {
        factory = new CrowdfundingFactory();

        // vm.prank: next call's msg.sender becomes the given address (one-shot)
        vm.prank(owner);
        address campaignAddr = factory.createCampaign(GOAL, DURATION);

        campaign = CrowdfundingCampaign(campaignAddr);

        // vm.deal: set ETH balance of an address
        vm.deal(alice, 20 ether);
        vm.deal(bob, 20 ether);
    }

    // ========== helpers ==========

    function _startCampaign() internal {
        vm.prank(owner);
        campaign.start();
    }

    function _makeFailed() internal {
        _startCampaign();
        vm.prank(alice);
        campaign.contribute{value: 1 ether}();
        // vm.warp: fast-forward block.timestamp
        vm.warp(block.timestamp + DURATION * 1 days + 1);
        campaign.finalize();
    }

    function _makeSuccess() internal {
        _startCampaign();
        vm.prank(alice);
        campaign.contribute{value: GOAL}();
    }

    // ========== deployment ==========

    function test_InitialState() public view {
        (
            address _owner,
            uint256 _goal,
            ,
            ,
            CrowdfundingCampaign.State _state,

        ) = campaign.getCampaignInfo();

        assertEq(_owner, owner);
        assertEq(_goal, GOAL);
        assertEq(
            uint256(_state),
            uint256(CrowdfundingCampaign.State.Preparing)
        );
    }

    // ========== state transitions ==========

    function test_StartCampaign() public {
        // vm.expectEmit: assert next call emits this event
        vm.expectEmit(true, true, false, false);
        emit CrowdfundingCampaign.StateChanged(
            CrowdfundingCampaign.State.Preparing,
            CrowdfundingCampaign.State.Active
        );

        _startCampaign();

        (, , , , CrowdfundingCampaign.State _state, ) = campaign
            .getCampaignInfo();
        assertEq(uint256(_state), uint256(CrowdfundingCampaign.State.Active));
    }

    function test_RevertWhen_NonOwnerStart() public {
        // vm.expectRevert: assert next call reverts
        vm.expectRevert();
        vm.prank(alice);
        campaign.start();
    }

    function test_RevertWhen_StartTwice() public {
        _startCampaign();
        vm.expectRevert("Invalid state");
        vm.prank(owner);
        campaign.start();
    }

    function test_AutoSuccessWhenGoalReached() public {
        _startCampaign();

        vm.prank(alice);
        campaign.contribute{value: GOAL}();

        (, , , , CrowdfundingCampaign.State _state, ) = campaign
            .getCampaignInfo();
        assertEq(uint256(_state), uint256(CrowdfundingCampaign.State.Success));
    }

    function test_FinalizeToFailed() public {
        _startCampaign();

        vm.prank(alice);
        campaign.contribute{value: 1 ether}();

        vm.warp(block.timestamp + DURATION * 1 days + 1);
        campaign.finalize();

        (, , , , CrowdfundingCampaign.State _state, ) = campaign
            .getCampaignInfo();
        assertEq(uint256(_state), uint256(CrowdfundingCampaign.State.Failed));
    }

    function test_RevertWhen_FinalizeBeforeDeadline() public {
        _startCampaign();
        vm.expectRevert("Campaign not ended");
        campaign.finalize();
    }

    // ========== funds ==========

    function test_ContributeAccumulates() public {
        _startCampaign();

        vm.prank(alice);
        campaign.contribute{value: 3 ether}();

        vm.prank(alice);
        campaign.contribute{value: 2 ether}();

        assertEq(campaign.getContribution(alice), 5 ether);

        (, , , uint256 totalRaised, , ) = campaign.getCampaignInfo();
        assertEq(totalRaised, 5 ether);
    }

    function test_WithdrawByOwner() public {
        _makeSuccess();

        uint256 ownerBalanceBefore = owner.balance;

        vm.prank(owner);
        campaign.withdraw();

        assertEq(owner.balance - ownerBalanceBefore, GOAL);

        (, , , , CrowdfundingCampaign.State _state, ) = campaign
            .getCampaignInfo();
        assertEq(uint256(_state), uint256(CrowdfundingCampaign.State.Closed));
    }

    function test_RevertWhen_WithdrawNotOwner() public {
        _makeSuccess();
        vm.expectRevert();
        vm.prank(alice);
        campaign.withdraw();
    }

    function test_RefundOnFailed() public {
        _makeFailed();

        uint256 aliceBalanceBefore = alice.balance;

        vm.prank(alice);
        campaign.refund();

        assertEq(alice.balance - aliceBalanceBefore, 1 ether);
        assertEq(campaign.getContribution(alice), 0);
    }

    function test_RevertWhen_RefundTwice() public {
        _makeFailed();

        vm.prank(alice);
        campaign.refund();

        vm.expectRevert("No contribution to refund");
        vm.prank(alice);
        campaign.refund();
    }

    function test_RevertWhen_RefundWithNoContribution() public {
        _makeFailed();
        vm.expectRevert("No contribution to refund");
        vm.prank(bob);
        campaign.refund();
    }

    // ========== factory ==========

    function test_FactoryCreateCampaign() public {
        vm.prank(alice);
        factory.createCampaign(5 ether, 7);

        assertEq(factory.getCampaignCount(), 2);
    }

    function test_FactoryUserCampaigns() public view {
        uint256[] memory ownerCampaigns = factory.getUserCampaigns(owner);
        assertEq(ownerCampaigns.length, 1);
        assertEq(ownerCampaigns[0], 0);
    }

    function test_FactoryGetAllCampaigns() public view {
        address[] memory all = factory.getAllCampaigns();
        assertEq(all.length, 1);
        assertEq(all[0], address(campaign));
    }

    function test_ReentrancyAttack() public {
        _startCampaign();

        ReentrancyAttacker attacker = new ReentrancyAttacker(address(campaign));
        vm.deal(address(attacker), 5 ether);

        vm.prank(address(attacker));
        campaign.contribute{value: 5 ether}();

        vm.warp(block.timestamp + DURATION * 1 days + 1);
        campaign.finalize();

        vm.expectRevert();
        vm.prank(address(attacker));
        attacker.attack();
        assertEq(address(campaign).balance, 5 ether);
        assertEq(address(attacker).balance, 0 ether);
        assertEq(campaign.getContribution(address(attacker)), 5 ether);
    }
}
