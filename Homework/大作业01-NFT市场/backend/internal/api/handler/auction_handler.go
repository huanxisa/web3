package handler

import (
	"net/http"
	"strconv"

	"github.com/gin-gonic/gin"

	"nft-auction-backend/internal/infra/db"
)

type AuctionHandler struct {
	repo *db.Repo
}

func NewAuctionHandler(repo *db.Repo) *AuctionHandler {
	return &AuctionHandler{repo: repo}
}

// GET /api/auctions
// 查询拍卖列表，支持 status / order_by / limit / offset 过滤
func (h *AuctionHandler) ListAuctions(c *gin.Context) {
	filter := db.ListAuctionsFilter{
		Status:  c.Query("status"),
		OrderBy: c.DefaultQuery("order_by", "end_time_asc"),
		Limit:   parseIntOr(c.DefaultQuery("limit", "20"), 20),
		Offset:  parseIntOr(c.DefaultQuery("offset", "0"), 0),
	}

	// TODO: 调用 repo.ListAuctions，返回列表和总数
	auctions, total, err := h.repo.ListAuctions(filter)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}

	c.JSON(http.StatusOK, gin.H{
		"total": total,
		"data":  auctions,
	})
}

// GET /api/auctions/:id
// 查询单个拍卖详情
func (h *AuctionHandler) GetAuction(c *gin.Context) {
	auctionID, err := strconv.ParseUint(c.Param("id"), 10, 64)
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "invalid auction id"})
		return
	}

	// TODO: 调用 repo.GetAuction
	auction, err := h.repo.GetAuction(auctionID)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}
	if auction == nil {
		c.JSON(http.StatusNotFound, gin.H{"error": "auction not found"})
		return
	}

	c.JSON(http.StatusOK, auction)
}

// GET /api/auctions/:id/bids
// 查询某拍卖的出价历史
func (h *AuctionHandler) ListBids(c *gin.Context) {
	auctionID, err := strconv.ParseUint(c.Param("id"), 10, 64)
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "invalid auction id"})
		return
	}

	// TODO: 调用 repo.ListBids
	bids, err := h.repo.ListBids(auctionID)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}

	c.JSON(http.StatusOK, gin.H{"data": bids})
}

func parseIntOr(s string, defaultVal int) int {
	n, err := strconv.Atoi(s)
	if err != nil {
		return defaultVal
	}
	return n
}
