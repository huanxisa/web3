package handler

import (
	"net/http"

	"github.com/gin-gonic/gin"

	"nft-auction-backend/internal/infra/db"
)

type StatsHandler struct {
	repo *db.Repo
}

func NewStatsHandler(repo *db.Repo) *StatsHandler {
	return &StatsHandler{repo: repo}
}

// GET /api/stats
// 平台统计数据
func (h *StatsHandler) GetStats(c *gin.Context) {
	// TODO: 调用 repo.GetStats
	stats, err := h.repo.GetStats()
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}
	c.JSON(http.StatusOK, stats)
}
