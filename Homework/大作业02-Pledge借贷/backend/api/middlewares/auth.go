package middlewares

import (
	"net/http"
	"strings"

	"github.com/gin-gonic/gin"
	"github.com/golang-jwt/jwt/v5"
)

// CheckToken 验证 JWT（管理员接口使用）
func CheckToken() gin.HandlerFunc {
	return func(c *gin.Context) {
		// TODO:
		// 1. 从 Authorization: Bearer <token> 头提取 token
		// 2. 用 jwt.Parse 解析并验证签名
		// 3. 将 claims 写入 context，供后续 handler 使用
		// 4. 验证失败 → 401

		authHeader := c.GetHeader("Authorization")
		if authHeader == "" {
			c.AbortWithStatusJSON(http.StatusUnauthorized, gin.H{"error": "missing token"})
			return
		}
		tokenStr := strings.TrimPrefix(authHeader, "Bearer ")
		_ = tokenStr
		_ = jwt.ParseWithClaims // 占位，避免 import 被删除

		// TODO: 实现具体解析逻辑
		c.Next()
	}
}
