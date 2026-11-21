// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Test, console} from "forge-std/Test.sol";
import {NFTAuction} from "../src/NFTAuction.sol";
import {MockNFT} from "../src/MockNFT.sol";
import {INFTAuction} from "../src/interfaces/INFTAuction.sol";

contract NFTAuctionTest is Test {
    NFTAuction public auction;
    MockNFT    public nft;

    address constant SELLER  = address(0x1);
    address constant BIDDER1 = address(0x2);
    address constant BIDDER2 = address(0x3);

    uint256 constant START_PRICE = 1 ether;
    uint256 constant DURATION    = 1 days;

    uint256 tokenId;

    function setUp() public {
        auction = new NFTAuction();
        nft     = new MockNFT(address(this));

        vm.deal(SELLER,  10 ether);
        vm.deal(BIDDER1, 10 ether);
        vm.deal(BIDDER2, 10 ether);

        vm.prank(SELLER);
        tokenId = nft.mint(SELLER);
    }

    // ── 辅助函数 ───────────────────────────────────────────────

    function _createAuction() internal returns (uint256 id) {
        vm.startPrank(SELLER);
        nft.approve(address(auction), tokenId);
        id = auction.createAuction(
            address(nft), tokenId, START_PRICE,
            block.timestamp, DURATION
        );
        vm.stopPrank();
    }

    function _createAuctionFuture(uint256 delay) internal returns (uint256 id) {
        vm.startPrank(SELLER);
        nft.approve(address(auction), tokenId);
        id = auction.createAuction(
            address(nft), tokenId, START_PRICE,
            block.timestamp + delay, DURATION
        );
        vm.stopPrank();
    }

    // ── 创建拍卖 ───────────────────────────────────────────────

    function test_CreateAuction_Success() public {
        uint256 id = _createAuction();

        assertEq(id, 1);
        assertEq(nft.ownerOf(tokenId), address(auction));

        INFTAuction.Auction memory a = auction.getAuction(id);
        assertEq(a.seller, SELLER);
        assertEq(a.startPrice, START_PRICE);
        assertEq(a.endTime, a.startTime + DURATION);
        assertEq(uint8(a.status), uint8(INFTAuction.AuctionStatus.Pending));
        assertEq(auction.nftToken2AuctionId(address(nft), tokenId), id);
    }

    function test_CreateAuction_StartTime_Zero_MeansNow() public {
        vm.startPrank(SELLER);
        nft.approve(address(auction), tokenId);
        uint256 id = auction.createAuction(
            address(nft), tokenId, START_PRICE,
            0, DURATION
        );
        vm.stopPrank();

        INFTAuction.Auction memory a = auction.getAuction(id);
        assertEq(a.startTime, block.timestamp);
    }

    function test_CreateAuction_RevertIf_NFTAlreadyInAuction() public {
        _createAuction();

        uint256 tokenId2 = nft.mint(SELLER);
        vm.startPrank(SELLER);
        nft.approve(address(auction), tokenId2);
        // 同一个 tokenId 已有拍卖，不能再创建
        vm.expectRevert(
            abi.encodeWithSelector(
                NFTAuction.AuctionAlreadyExists.selector,
                address(nft), tokenId
            )
        );
        auction.createAuction(address(nft), tokenId, START_PRICE, 0, DURATION);
        vm.stopPrank();
    }

    function test_CreateAuction_RevertIf_DurationZero() public {
        vm.startPrank(SELLER);
        nft.approve(address(auction), tokenId);
        vm.expectRevert(NFTAuction.InvalidTimeParam.selector);
        auction.createAuction(address(nft), tokenId, START_PRICE, 0, 0);
        vm.stopPrank();
    }

    function test_CreateAuction_RevertIf_StartTimeInPast() public {
        vm.startPrank(SELLER);
        nft.approve(address(auction), tokenId);
        vm.expectRevert(NFTAuction.InvalidTimeParam.selector);
        auction.createAuction(
            address(nft), tokenId, START_PRICE,
            block.timestamp - 1, DURATION
        );
        vm.stopPrank();
    }

    // ── 出价 ───────────────────────────────────────────────────

    function test_PlaceBid_Success() public {
        uint256 id = _createAuction();

        vm.prank(BIDDER1);
        auction.placeBid{value: 2 ether}(id);

        INFTAuction.Auction memory a = auction.getAuction(id);
        assertEq(a.highestBid, 2 ether);
        assertEq(a.highestBidder, BIDDER1);
        assertEq(address(auction).balance, 2 ether);
    }

    function test_PlaceBid_RecordsPendingReturn_ForPreviousBidder() public {
        uint256 id = _createAuction();

        vm.prank(BIDDER1);
        auction.placeBid{value: 2 ether}(id);

        vm.prank(BIDDER2);
        auction.placeBid{value: 3 ether}(id);

        // BIDDER1 的 2 ether 应记入 pendingReturns，合约持有 5 ether
        assertEq(auction.pendingReturns(BIDDER1), 2 ether);
        assertEq(address(auction).balance, 5 ether);
    }

    function test_Withdraw_Success() public {
        uint256 id = _createAuction();

        vm.prank(BIDDER1);
        auction.placeBid{value: 2 ether}(id);

        vm.prank(BIDDER2);
        auction.placeBid{value: 3 ether}(id);

        uint256 balanceBefore = BIDDER1.balance;
        vm.prank(BIDDER1);
        auction.withdraw();

        assertEq(BIDDER1.balance, balanceBefore + 2 ether);
        assertEq(auction.pendingReturns(BIDDER1), 0);
    }

    function test_PlaceBid_RevertIf_BidTooLow() public {
        uint256 id = _createAuction();

        // 低于起拍价
        vm.prank(BIDDER1);
        vm.expectRevert(
            abi.encodeWithSelector(
                NFTAuction.BidTooLow.selector,
                START_PRICE, 0.5 ether
            )
        );
        auction.placeBid{value: 0.5 ether}(id);

        // 有人出过价后，等于最高价也不行
        vm.prank(BIDDER1);
        auction.placeBid{value: 2 ether}(id);

        vm.prank(BIDDER2);
        vm.expectRevert(
            abi.encodeWithSelector(
                NFTAuction.BidTooLow.selector,
                2 ether, 2 ether
            )
        );
        auction.placeBid{value: 2 ether}(id);
    }

    function test_PlaceBid_RevertIf_AuctionNotStarted() public {
        uint256 id = _createAuctionFuture(1 hours);

        vm.prank(BIDDER1);
        vm.expectRevert(
            abi.encodeWithSelector(NFTAuction.AuctionNotActive.selector, id)
        );
        auction.placeBid{value: 2 ether}(id);
    }

    function test_PlaceBid_RevertIf_AuctionExpired() public {
        uint256 id = _createAuction();

        vm.warp(block.timestamp + DURATION);

        vm.prank(BIDDER1);
        vm.expectRevert(
            abi.encodeWithSelector(NFTAuction.AuctionNotActive.selector, id)
        );
        auction.placeBid{value: 2 ether}(id);
    }

    // ── 结束拍卖 ───────────────────────────────────────────────

    function test_EndAuction_WithWinner() public {
        uint256 id = _createAuction();

        vm.prank(BIDDER1);
        auction.placeBid{value: 2 ether}(id);

        vm.warp(block.timestamp + DURATION);

        uint256 sellerBalanceBefore = SELLER.balance;
        auction.endAuction(id);

        // NFT 归 BIDDER1
        assertEq(nft.ownerOf(tokenId), BIDDER1);
        // ETH 归 SELLER
        assertEq(SELLER.balance, sellerBalanceBefore + 2 ether);
        // 状态变为 Ended
        assertEq(uint8(auction.getAuction(id).status), uint8(INFTAuction.AuctionStatus.Ended));
        // nftToken2AuctionId 已清理
        assertEq(auction.nftToken2AuctionId(address(nft), tokenId), 0);
    }

    function test_EndAuction_WithNoWinner() public {
        uint256 id = _createAuction();

        vm.warp(block.timestamp + DURATION);

        uint256 sellerNFTBefore = nft.balanceOf(SELLER);
        auction.endAuction(id);

        // NFT 退回 SELLER
        assertEq(nft.balanceOf(SELLER), sellerNFTBefore + 1);
        assertEq(nft.ownerOf(tokenId), SELLER);
        // 状态变为 Cancelled
        assertEq(uint8(auction.getAuction(id).status), uint8(INFTAuction.AuctionStatus.Cancelled));
    }

    function test_EndAuction_RevertIf_NotExpired() public {
        uint256 id = _createAuction();

        vm.expectRevert(
            abi.encodeWithSelector(NFTAuction.AuctionNotEnded.selector, id)
        );
        auction.endAuction(id);
    }

    function test_EndAuction_RevertIf_AlreadyEnded() public {
        uint256 id = _createAuction();
        vm.warp(block.timestamp + DURATION);
        auction.endAuction(id);

        vm.expectRevert(
            abi.encodeWithSelector(NFTAuction.AuctionNotActive.selector, id)
        );
        auction.endAuction(id);
    }

    // ── 取消拍卖 ───────────────────────────────────────────────

    function test_CancelAuction_Success() public {
        uint256 id = _createAuction();

        vm.prank(SELLER);
        auction.cancelAuction(id);

        // NFT 退回 SELLER
        assertEq(nft.ownerOf(tokenId), SELLER);
        assertEq(uint8(auction.getAuction(id).status), uint8(INFTAuction.AuctionStatus.Cancelled));
        assertEq(auction.nftToken2AuctionId(address(nft), tokenId), 0);
    }

    function test_CancelAuction_RevertIf_HasBidder() public {
        uint256 id = _createAuction();

        vm.prank(BIDDER1);
        auction.placeBid{value: 2 ether}(id);

        vm.prank(SELLER);
        vm.expectRevert(NFTAuction.HasBidder.selector);
        auction.cancelAuction(id);
    }

    function test_CancelAuction_RevertIf_NotSeller() public {
        uint256 id = _createAuction();

        vm.prank(BIDDER1);
        vm.expectRevert(
            abi.encodeWithSelector(NFTAuction.NotSeller.selector, BIDDER1)
        );
        auction.cancelAuction(id);
    }

    // ── 查询函数 ───────────────────────────────────────────────

    function test_TotalAuctions() public {
        assertEq(auction.totalAuctions(), 0);
        _createAuction();
        assertEq(auction.totalAuctions(), 1);
    }

    function test_GetAuctionIdByNFT() public {
        uint256 id = _createAuction();
        assertEq(auction.getAuctionIdByNFT(address(nft), tokenId), id);
    }

    // ── Fuzz 测试 ──────────────────────────────────────────────

    function testFuzz_PlaceBid_MustBeHigherThanPrevious(
        uint96 bid1,
        uint96 bid2
    ) public {
        // 限制 bid1 在 (START_PRICE, 5 ether]，保证第一笔能成功
        bid1 = uint96(bound(bid1, START_PRICE + 1, 5 ether));

        uint256 id = _createAuction();

        vm.deal(BIDDER1, uint256(bid1) + 1);
        vm.prank(BIDDER1);
        auction.placeBid{value: bid1}(id);

        // bid2 <= bid1 时必须 revert
        bid2 = uint96(bound(bid2, 0, bid1));
        vm.deal(BIDDER2, uint256(bid2) + 1);
        vm.prank(BIDDER2);
        vm.expectRevert(
            abi.encodeWithSelector(
                NFTAuction.BidTooLow.selector,
                uint256(bid1), uint256(bid2)
            )
        );
        auction.placeBid{value: bid2}(id);
    }
}
