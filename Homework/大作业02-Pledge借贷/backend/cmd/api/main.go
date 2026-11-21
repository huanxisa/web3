// cmd/api/main.go - HTTP API 服务入口
//
// 职责：
//   - 接收前端/外部请求，查询 DB 返回数据
//   - 不直接读链，所有链上数据由 schedule 服务同步到 DB
//
// 启动：
//
//	go run ./cmd/api
package main

import (
	"context"
	"log"
	"net/http"
	"os"
	"os/signal"
	"syscall"
	"time"

	"github.com/gin-gonic/gin"
	"pledge-backend/api/routes"
	"pledge-backend/config"
	"pledge-backend/db"
	logger "pledge-backend/log"
)

func main() {
	// ── 初始化配置 ────────────────────────────────────────────
	config.Init()

	// ── 初始化日志 ────────────────────────────────────────────
	logger.Init(config.Config.Env.Mode)
	defer logger.Log.Sync() //nolint:errcheck

	// ── 初始化数据库 ──────────────────────────────────────────
	db.Init()

	// ── 启动 Gin ──────────────────────────────────────────────
	gin.SetMode(config.Config.Env.Mode)
	engine := gin.Default()
	routes.InitRoute(engine)

	srv := &http.Server{
		Addr:    ":" + config.Config.Env.Port,
		Handler: engine,
	}

	go func() {
		log.Printf("[API] listening on :%s", config.Config.Env.Port)
		if err := srv.ListenAndServe(); err != nil && err != http.ErrServerClosed {
			log.Fatalf("[API] ListenAndServe error: %v", err)
		}
	}()

	// ── 优雅关闭 ──────────────────────────────────────────────
	quit := make(chan os.Signal, 1)
	signal.Notify(quit, syscall.SIGINT, syscall.SIGTERM)
	<-quit

	log.Println("[API] shutting down...")
	ctx, cancel := context.WithTimeout(context.Background(), 5*time.Second)
	defer cancel()
	if err := srv.Shutdown(ctx); err != nil {
		log.Fatalf("[API] Shutdown error: %v", err)
	}
	log.Println("[API] stopped")
}
