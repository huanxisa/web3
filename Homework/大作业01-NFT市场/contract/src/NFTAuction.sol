// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {IERC721} from "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import {ReentrancyGuard} from "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import {INFTAuction} from "./interfaces/INFTAuction.sol";

/**
 * @title NFTAuction
 * @notice 一个合约管理所有 NFT 拍卖
 *
 * 核心流程：
 *   卖家调用 createAuction → NFT 转入合约锁定
 *   买家调用 placeBid      → ETH 转入合约，旧出价记入 pendingReturns
 *   任何人调用 endAuction  → 到期后交割（NFT→买家，ETH→卖家）
 *   卖家调用 cancelAuction → 无人出价时取消，NFT 退回
 *   出价者调用 withdraw    → 取回被更高出价替换的 ETH（Pull Payment）
 */
contract NFTAuction is INFTAuction, ReentrancyGuard {
    // ── 状态变量 ───────────────────────────────────────────────

    // 0 保留为哨兵值，表示"不存在"，有效 ID 从 1 开始
    uint256 private _nextAuctionId = 1;

    // NFT 合约地址 + tokenId → 拍卖 ID（防止同一 NFT 重复拍卖）
    mapping(address => mapping(uint256 => uint256)) public nftToken2AuctionId;
    // 拍卖 ID → 拍卖数据
    mapping(uint256 => Auction) private _auctions;
    // Pull Payment：记录每个地址待取回的 ETH
    mapping(address => uint256) public pendingReturns;

    // ── 错误定义 ───────────────────────────────────────────────

    error AuctionNotExist(uint256 auctionId);
    error AuctionNotActive(uint256 auctionId);
    error AuctionNotEnded(uint256 auctionId);
    error AuctionAlreadyExists(address nftContract, uint256 tokenId);
    error BidTooLow(uint256 required, uint256 provided);
    error NotSeller(address caller);
    error HasBidder();
    error InvalidTimeParam();
    error WithdrawFailed();

    // ── 修饰符 ────────────────────────────────────────────────

    modifier auctionExists(uint256 auctionId) {
        if (_auctions[auctionId].status == AuctionStatus.NotExist)
            revert AuctionNotExist(auctionId);
        _;
    }

    // ── 核心业务函数 ──────────────────────────────────────────

    /**
     * @notice 创建拍卖
     * @param nftContract NFT 合约地址
     * @param tokenId     NFT Token ID
     * @param startPrice  起拍价（wei）
     * @param startTime   开始时间（unix timestamp），传 0 表示立即开始
     * @param duration    持续时长（秒）
     */
    function createAuction(
        address nftContract,
        uint256 tokenId,
        uint256 startPrice,
        uint256 startTime,
        uint256 duration
    ) external returns (uint256 auctionId) {
        if (duration == 0) revert InvalidTimeParam();

        // startTime 为 0 表示立即开始；否则不能早于当前区块时间
        uint256 start = startTime == 0 ? block.timestamp : startTime;
        if (start < block.timestamp) revert InvalidTimeParam();

        if (nftToken2AuctionId[nftContract][tokenId] != 0)
            revert AuctionAlreadyExists(nftContract, tokenId);

        // 将 NFT 转入本合约（caller 须提前 approve）
        IERC721(nftContract).transferFrom(msg.sender, address(this), tokenId);

        auctionId = _nextAuctionId++;
        uint256 endTime = start + duration;
        _auctions[auctionId] = Auction({
            auctionId:     auctionId,
            seller:        msg.sender,
            nftContract:   nftContract,
            tokenId:       tokenId,
            startPrice:    startPrice,
            startTime:     start,
            endTime:       endTime,
            highestBid:    0,
            highestBidder: address(0),
            status:        AuctionStatus.Pending
        });
        nftToken2AuctionId[nftContract][tokenId] = auctionId;

        emit AuctionCreated(auctionId, msg.sender, nftContract, tokenId, startPrice, start, endTime);
    }

    /**
     * @notice 出价（CEI + Pull Payment 双重保护）
     * @param auctionId 拍卖 ID
     */
    function placeBid(
        uint256 auctionId
    ) external payable nonReentrant auctionExists(auctionId) {
        Auction storage a = _auctions[auctionId];

        if (!_isActive(a)) revert AuctionNotActive(auctionId);

        // 首次出价须高于起拍价；后续出价须高于当前最高价
        uint256 minRequired = a.highestBidder == address(0) ? a.startPrice : a.highestBid;
        if (msg.value <= minRequired) revert BidTooLow(minRequired, msg.value);

        // 记录旧出价信息（后续记账用）
        address oldBidder = a.highestBidder;
        uint256 oldBid    = a.highestBid;

        // Effects：先更新状态
        a.highestBidder = msg.sender;
        a.highestBid    = msg.value;

        // 记录旧出价者待退金额，不发起外部调用（防止 Griefing 攻击）
        if (oldBidder != address(0)) {
            pendingReturns[oldBidder] += oldBid;
        }

        emit BidPlaced(auctionId, msg.sender, msg.value);
    }

    /**
     * @notice 结束拍卖（到期后任何人可调用）
     * @param auctionId 拍卖 ID
     */
    function endAuction(
        uint256 auctionId
    ) external nonReentrant auctionExists(auctionId) {
        Auction storage a = _auctions[auctionId];

        if (block.timestamp < a.endTime) revert AuctionNotEnded(auctionId);
        if (a.status != AuctionStatus.Pending) revert AuctionNotActive(auctionId);

        // 清理映射，防止同一 NFT 无法再次拍卖
        delete nftToken2AuctionId[a.nftContract][a.tokenId];

        if (a.highestBidder != address(0)) {
            // 有成交：NFT → 最高出价者，ETH → 卖家
            a.status = AuctionStatus.Ended;
            IERC721(a.nftContract).transferFrom(address(this), a.highestBidder, a.tokenId);
            _transfer(a.seller, a.highestBid);
            emit AuctionEnded(auctionId, a.highestBidder, a.highestBid);
        } else {
            // 无出价：NFT 退回卖家
            a.status = AuctionStatus.Cancelled;
            IERC721(a.nftContract).transferFrom(address(this), a.seller, a.tokenId);
            emit AuctionCancelled(auctionId);
        }
    }

    /**
     * @notice 取消拍卖（卖家在无出价时可随时取消）
     * @param auctionId 拍卖 ID
     */
    function cancelAuction(
        uint256 auctionId
    ) external nonReentrant auctionExists(auctionId) {
        Auction storage a = _auctions[auctionId];

        if (msg.sender != a.seller) revert NotSeller(msg.sender);
        if (a.highestBidder != address(0)) revert HasBidder();
        if (a.status != AuctionStatus.Pending) revert AuctionNotActive(auctionId);

        a.status = AuctionStatus.Cancelled;
        delete nftToken2AuctionId[a.nftContract][a.tokenId];

        IERC721(a.nftContract).transferFrom(address(this), a.seller, a.tokenId);
        emit AuctionCancelled(auctionId);
    }

    /**
     * @notice 取回被更高出价替换后的 ETH（Pull Payment 模式）
     */
    function withdraw() external nonReentrant {
        uint256 amount = pendingReturns[msg.sender];
        if (amount == 0) return;
        // Effects 先清零，防止重入
        pendingReturns[msg.sender] = 0;
        // Interactions 再转账
        _transfer(msg.sender, amount);
        emit Withdrawn(msg.sender, amount);
    }

    // ── 查询函数 ───────────────────────────────────────────────

    function getAuction(
        uint256 auctionId
    ) external view returns (Auction memory) {
        return _auctions[auctionId];
    }

    function getAuctionIdByNFT(
        address nftContract,
        uint256 tokenId
    ) external view returns (uint256) {
        return nftToken2AuctionId[nftContract][tokenId];
    }

    function totalAuctions() external view returns (uint256) {
        return _nextAuctionId - 1;
    }

    // ── 内部辅助函数 ──────────────────────────────────────────

    /// @dev 向地址转 ETH，失败则 revert
    function _transfer(address to, uint256 amount) internal {
        if (amount == 0) return;
        (bool success, ) = to.call{value: amount}("");
        if (!success) revert WithdrawFailed();
    }

    /// @dev Pending 状态 + 时间窗口内 = 逻辑上的"进行中"
    function _isActive(Auction storage auction) internal view returns (bool) {
        return
            auction.status == AuctionStatus.Pending &&
            block.timestamp >= auction.startTime &&
            block.timestamp < auction.endTime;
    }
}
