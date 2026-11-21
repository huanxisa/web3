package controllers

import (
	"net/http"
	"time"

	"github.com/gin-gonic/gin"
	"github.com/golang-jwt/jwt/v5"
	"pledge-backend/db"
)

type UserController struct{}

type LoginRequest struct {
	Name     string `json:"name" binding:"required"`
	Password string `json:"password" binding:"required"`
}

// Login POST /api/v2/user/login
//
// 管理员登录，返回 JWT token
func (u *UserController) Login(c *gin.Context) {
	var req LoginRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"code": 400, "msg": err.Error()})
		return
	}

	// TODO:
	// 1. 查询 db.DB 找到 Admin（按 name）
	// 2. bcrypt.CompareHashAndPassword 验证密码
	// 3. 签发 JWT（24h 过期）
	// 4. 返回 token

	var admin db.Admin
	if err := db.DB.Where("name = ?", req.Name).First(&admin).Error; err != nil {
		c.JSON(http.StatusUnauthorized, gin.H{"code": 401, "msg": "invalid credentials"})
		return
	}

	// TODO: 校验 bcrypt 密码（骨架中跳过）
	_ = admin

	claims := jwt.MapClaims{
		"user_id": admin.UserID,
		"name":    admin.Name,
		"exp":     time.Now().Add(24 * time.Hour).Unix(),
	}
	token := jwt.NewWithClaims(jwt.SigningMethodHS256, claims)
	tokenStr, err := token.SignedString([]byte("your-secret-key")) // TODO: 从配置读取
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"code": 500, "msg": err.Error()})
		return
	}

	c.JSON(http.StatusOK, gin.H{"code": 200, "msg": "ok", "token": tokenStr})
}

// Logout POST /api/v2/user/logout （需要 CheckToken 中间件）
func (u *UserController) Logout(c *gin.Context) {
	// TODO: JWT 无状态，可在 Redis 维护 token 黑名单（骨架中直接返回成功）
	c.JSON(http.StatusOK, gin.H{"code": 200, "msg": "logged out"})
}
