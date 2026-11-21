package controllers

import (
	"net/http"
	"strconv"

	"github.com/gin-gonic/gin"
	"pledge-backend/db"
)

type PoolController struct{}

// PoolBaseInfo GET /api/v2/poolBaseInfo?chainId=31337&page=1&pageSize=10
//
// 返回所有借贷池的基础信息列表（从 DB 读取，由 schedule 服务定时同步）
func (p *PoolController) PoolBaseInfo(c *gin.Context) {
	chainID := c.DefaultQuery("chainId", "31337")
	page, _ := strconv.Atoi(c.DefaultQuery("page", "1"))
	pageSize, _ := strconv.Atoi(c.DefaultQuery("pageSize", "10"))
	if page < 1 {
		page = 1
	}
	offset := (page - 1) * pageSize

	// TODO:
	// 1. 从 db.DB 查询 PoolBase 列表（按 chain_id 过滤，分页）
	// 2. 查询对应的 PoolData
	// 3. 组合成前端需要的格式返回

	var pools []db.PoolBase
	result := db.DB.Where("chain_id = ?", chainID).
		Order("pool_id asc").
		Offset(offset).Limit(pageSize).
		Find(&pools)
	if result.Error != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"code": 500, "msg": result.Error.Error()})
		return
	}

	var total int64
	db.DB.Model(&db.PoolBase{}).Where("chain_id = ?", chainID).Count(&total)

	c.JSON(http.StatusOK, gin.H{
		"code":  200,
		"msg":   "ok",
		"total": total,
		"data":  pools,
	})
}

// PoolDataInfo GET /api/v2/poolDataInfo?chainId=31337&poolId=0
//
// 返回单个池子的结算数据
func (p *PoolController) PoolDataInfo(c *gin.Context) {
	chainID := c.DefaultQuery("chainId", "31337")
	poolID := c.DefaultQuery("poolId", "")

	if poolID == "" {
		c.JSON(http.StatusBadRequest, gin.H{"code": 400, "msg": "poolId required"})
		return
	}

	// TODO:
	// 1. 查询 PoolData（chain_id + pool_id）
	// 2. 同时查 PoolBase 基础信息一起返回

	var data db.PoolData
	result := db.DB.Where("chain_id = ? AND pool_id = ?", chainID, poolID).First(&data)
	if result.Error != nil {
		c.JSON(http.StatusNotFound, gin.H{"code": 404, "msg": "pool not found"})
		return
	}

	c.JSON(http.StatusOK, gin.H{"code": 200, "msg": "ok", "data": data})
}

// TokenList GET /api/v2/token?chainId=31337
//
// 返回支持的代币列表（含价格、logo）
func (p *PoolController) TokenList(c *gin.Context) {
	chainID := c.DefaultQuery("chainId", "31337")

	// TODO:
	// 1. 查询 TokenInfo 列表
	// 2. 按价格排序

	var tokens []db.TokenInfo
	db.DB.Where("chain_id = ?", chainID).Find(&tokens)

	c.JSON(http.StatusOK, gin.H{"code": 200, "msg": "ok", "data": tokens})
}
