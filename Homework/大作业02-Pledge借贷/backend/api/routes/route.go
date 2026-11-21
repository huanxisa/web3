package routes

import (
	"github.com/gin-gonic/gin"
	"pledge-backend/api/controllers"
	"pledge-backend/api/middlewares"
	"pledge-backend/config"
)

func InitRoute(e *gin.Engine) *gin.Engine {
	e.Use(middlewares.CORS())

	// /api/v{version}/...
	v := e.Group("/api/v" + config.Config.Env.Version)

	// ── 公开接口（不需要 token） ──────────────────────────────
	poolCtrl := controllers.PoolController{}
	v.GET("/poolBaseInfo", poolCtrl.PoolBaseInfo) // 池子列表
	v.GET("/poolDataInfo", poolCtrl.PoolDataInfo) // 池子结算数据
	v.GET("/token", poolCtrl.TokenList)            // 代币列表

	userCtrl := controllers.UserController{}
	v.POST("/user/login", userCtrl.Login) // 管理员登录

	// ── 需要 JWT 的管理员接口 ────────────────────────────────
	auth := v.Group("/", middlewares.CheckToken())
	auth.POST("/user/logout", userCtrl.Logout)

	// TODO: 添加更多管理员接口
	// auth.POST("/pool/create", adminPoolCtrl.Create)

	return e
}
