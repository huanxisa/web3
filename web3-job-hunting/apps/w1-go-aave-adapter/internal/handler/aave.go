// Package handler 是 HTTP 适配层；不写业务逻辑，只做参数转换 + 调 service。
package handler

import (
	"math/big"
	"net/http"

	"github.com/gin-gonic/gin"

	"github.com/piliepeng/w1-go-aave-adapter/internal/service"
)

type AaveHandler struct {
	health *service.HealthService
	supply *service.SupplyService
	borrow *service.BorrowService
}

func NewAaveHandler(h *service.HealthService, s *service.SupplyService, b *service.BorrowService) *AaveHandler {
	return &AaveHandler{health: h, supply: s, borrow: b}
}

func (h *AaveHandler) Register(r *gin.Engine) {
	api := r.Group("/api/v1")
	api.GET("/health", h.GetHealth)
	api.POST("/supply", h.PostSupply)
	api.POST("/borrow", h.PostBorrow)
	api.GET("/account/:user", h.GetAccountData)
}

func (h *AaveHandler) GetHealth(c *gin.Context) {
	info, err := h.health.Check(c.Request.Context())
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}
	c.JSON(http.StatusOK, info)
}

type supplyReq struct {
	Token  string `json:"token" binding:"required"`
	Amount string `json:"amount" binding:"required"` // 字符串保精度
}

func (h *AaveHandler) PostSupply(c *gin.Context) {
	var req supplyReq
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}
	amt, ok := new(big.Int).SetString(req.Amount, 10)
	if !ok {
		c.JSON(http.StatusBadRequest, gin.H{"error": "invalid amount"})
		return
	}
	tx, err := h.supply.Supply(c.Request.Context(), req.Token, amt)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error(), "tx": tx})
		return
	}
	c.JSON(http.StatusOK, gin.H{"tx": tx})
}

type borrowReq struct {
	Token  string `json:"token" binding:"required"`
	Amount string `json:"amount" binding:"required"`
}

func (h *AaveHandler) PostBorrow(c *gin.Context) {
	var req borrowReq
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}
	amt, ok := new(big.Int).SetString(req.Amount, 10)
	if !ok {
		c.JSON(http.StatusBadRequest, gin.H{"error": "invalid amount"})
		return
	}
	tx, err := h.borrow.Borrow(c.Request.Context(), req.Token, amt)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error(), "tx": tx})
		return
	}
	c.JSON(http.StatusOK, gin.H{"tx": tx})
}

func (h *AaveHandler) GetAccountData(c *gin.Context) {
	user := c.Param("user")
	data, err := h.borrow.GetUserAccountData(c.Request.Context(), user)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}
	c.JSON(http.StatusOK, data)
}
