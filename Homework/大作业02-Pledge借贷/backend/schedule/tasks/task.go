package tasks

import (
	"log"

	"github.com/robfig/cron/v3"
	"pledge-backend/schedule/services"
)

// Task 注册并启动所有定时任务
//
// 任务清单：
//   - 每 30 秒：同步链上池子数据 → DB
//   - 每 60 秒：同步代币价格
//
// cron 表达式参考：https://pkg.go.dev/github.com/robfig/cron/v3
func Task() {
	c := cron.New(cron.WithSeconds())

	// ── 池子数据同步（每 30 秒）────────────────────────────────
	if _, err := c.AddFunc("@every 30s", func() {
		log.Println("[cron] SyncPoolData start")
		services.SyncPoolData()
	}); err != nil {
		log.Fatalf("[cron] AddFunc SyncPoolData error: %v", err)
	}

	// ── 代币价格同步（每 60 秒）────────────────────────────────
	if _, err := c.AddFunc("@every 60s", func() {
		log.Println("[cron] SyncTokenPrice start")
		services.SyncTokenPrice()
	}); err != nil {
		log.Fatalf("[cron] AddFunc SyncTokenPrice error: %v", err)
	}

	c.Start()
	log.Println("[cron] scheduler started")

	// 首次立即执行（不等定时器）
	go services.SyncPoolData()
	go services.SyncTokenPrice()
}
