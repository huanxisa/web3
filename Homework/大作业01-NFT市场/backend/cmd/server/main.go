package main

import (
	"context"
	"log"
	"net/http"
	"os"
	"os/signal"
	"syscall"
	"time"

	"nft-auction-backend/internal/api"
	"nft-auction-backend/internal/config"
	"nft-auction-backend/internal/indexer"
	"nft-auction-backend/internal/infra/db"
)

func main() {
	// 1. 加载配置
	cfg := config.Load()

	// 2. 初始化数据库
	repo, err := db.NewRepo(cfg.DBPath)
	if err != nil {
		log.Fatalf("failed to init db: %v", err)
	}

	// 3. 启动 Indexer（后台 goroutine）
	ctx, cancel := context.WithCancel(context.Background())
	defer cancel()

	idx, err := indexer.New(cfg, repo)
	if err != nil {
		log.Fatalf("failed to init indexer: %v", err)
	}
	go idx.Run(ctx)

	// 4. 启动 HTTP API Server
	router := api.NewRouter(repo)
	srv := &http.Server{
		Addr:    ":" + cfg.ServerPort,
		Handler: router,
	}

	go func() {
		log.Printf("API server listening on :%s", cfg.ServerPort)
		if err := srv.ListenAndServe(); err != nil && err != http.ErrServerClosed {
			log.Fatalf("server error: %v", err)
		}
	}()

	// 5. 优雅关闭（等待 SIGINT/SIGTERM）
	quit := make(chan os.Signal, 1)
	signal.Notify(quit, syscall.SIGINT, syscall.SIGTERM)
	<-quit

	log.Println("Shutting down...")
	cancel() // 停止 Indexer

	shutdownCtx, shutdownCancel := context.WithTimeout(context.Background(), 5*time.Second)
	defer shutdownCancel()
	if err := srv.Shutdown(shutdownCtx); err != nil {
		log.Printf("server shutdown error: %v", err)
	}

	log.Println("Bye.")
}
