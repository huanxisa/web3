package api

import (
	"github.com/gin-gonic/gin"

	"nft-auction-backend/internal/api/handler"
	"nft-auction-backend/internal/infra/db"
)

func NewRouter(repo *db.Repo) *gin.Engine {
	r := gin.Default()

	auctionH := handler.NewAuctionHandler(repo)
	statsH   := handler.NewStatsHandler(repo)

	// 健康检查
	r.GET("/health", func(c *gin.Context) {
		c.JSON(200, gin.H{"status": "ok"})
	})

	api := r.Group("/api")
	{
		api.GET("/stats",                    statsH.GetStats)
		api.GET("/auctions",                 auctionH.ListAuctions)
		api.GET("/auctions/:id",             auctionH.GetAuction)
		api.GET("/auctions/:id/bids",        auctionH.ListBids)

		// TODO: 钱包 NFT 列表（调用 Alchemy NFT API）
		// api.GET("/wallet/:address/nfts",  walletH.ListNFTs)
	}

	return r
}
