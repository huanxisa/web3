// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

interface INFTAuction {
    // ── 枚举 ──────────────────────────────────────────────────
    enum AuctionStatus {
        NotExist,  // 0: 不存在（哨兵值）
        Pending,   // 1: 进行中（含未开始和出价阶段，由时间窗口实时判断是否活跃）
        Ended,     // 2: 已结束（成交或无人出价到期）
        Cancelled  // 3: 已取消（卖家主动取消）
    }

    // ── 数据结构 ───────────────────────────────────────────────
    struct Auction {
        uint256 auctionId;
        address seller;
        address nftContract;
        uint256 tokenId;
        uint256 startPrice; // 起拍价（wei）
        uint256 startTime; // 开始时间（unix timestamp）
        uint256 endTime; // 结束时间（unix timestamp）
        uint256 highestBid; // 当前最高出价
        address highestBidder; // 当前最高出价者
        AuctionStatus status;
    }

    // ── 事件 ──────────────────────────────────────────────────
    event AuctionCreated(
        uint256 indexed auctionId,
        address indexed seller,
        address nftContract,
        uint256 tokenId,
        uint256 startPrice,
        uint256 startTime,
        uint256 endTime
    );
    event BidPlaced(
        uint256 indexed auctionId,
        address indexed bidder,
        uint256 amount
    );
    event AuctionEnded(
        uint256 indexed auctionId,
        address indexed winner,
        uint256 amount
    );
    event AuctionCancelled(uint256 indexed auctionId);
    event Withdrawn(address indexed bidder, uint256 amount);

    // ── 核心函数 ───────────────────────────────────────────────
    function createAuction(
        address nftContract,
        uint256 tokenId,
        uint256 startPrice,
        uint256 startTime,
        uint256 duration
    ) external returns (uint256 auctionId);

    function placeBid(uint256 auctionId) external payable;

    function endAuction(uint256 auctionId) external;

    function cancelAuction(uint256 auctionId) external;

    /// @notice 取回被超出价的 ETH（Pull Payment 模式）
    function withdraw() external;

    // ── 查询函数 ───────────────────────────────────────────────
    function getAuction(
        uint256 auctionId
    ) external view returns (Auction memory);

    function getAuctionIdByNFT(
        address nftContract,
        uint256 tokenId
    ) external view returns (uint256);
}
