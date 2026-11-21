// cmd/schedule/main.go - 链上数据同步调度器入口
//
// 职责：
//   - 定时从链上读取池子数据、代币价格
//   - 写入 SQLite DB，供 API 服务读取
//
// 启动：
//
//	go run ./cmd/schedule
package main

import (
	"log"
	"os"
	"os/signal"
	"syscall"

	"pledge-backend/config"
	"pledge-backend/db"
	logger "pledge-backend/log"
	"pledge-backend/schedule/tasks"
)

func main() {
	// ── 初始化配置、日志、数据库 ──────────────────────────────
	config.Init()
	logger.Init(config.Config.Env.Mode)
	defer logger.Log.Sync() //nolint:errcheck
	db.Init()

	// ── 启动定时任务 ──────────────────────────────────────────
	tasks.Task()

	log.Println("[schedule] running, press Ctrl+C to stop")

	quit := make(chan os.Signal, 1)
	signal.Notify(quit, syscall.SIGINT, syscall.SIGTERM)
	<-quit
	log.Println("[schedule] stopped")
}
