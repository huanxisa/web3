// w1-go-aave-adapter / 命令入口。
//
// 启动顺序：
//  1. Load config（含 ${SEPOLIA_RPC_URL} / ${WALLET_PRIVATE_KEY} 展开）
//  2. New 链客户端（dial RPC + 解析私钥可选）
//  3. 注册 service（health / supply / borrow / liquidation）
//  4. 启动 LiquidationListener goroutine
//  5. 启动 Gin 监听
//
// Day 1 验收：跑起来后调 GET /api/v1/health → 应返回 chain_id=11155111。
package main

import (
	"context"
	"fmt"
	"log"
	"os/signal"
	"syscall"

	"github.com/gin-gonic/gin"
	"go.uber.org/zap"

	"github.com/piliepeng/w1-go-aave-adapter/internal/chain"
	"github.com/piliepeng/w1-go-aave-adapter/internal/config"
	"github.com/piliepeng/w1-go-aave-adapter/internal/handler"
	"github.com/piliepeng/w1-go-aave-adapter/internal/service"
)

func main() {
	cfg, err := config.Load("./config")
	if err != nil {
		log.Fatalf("load config: %v", err)
	}

	logger, _ := zap.NewProduction()
	defer logger.Sync() //nolint:errcheck
	logger.Info("config loaded",
		zap.String("network", cfg.Aave.Network),
		zap.String("rpc_url", cfg.Aave.RPCURL),
		zap.String("pool", cfg.Aave.Pool),
	)

	chainCli, err := chain.New(cfg.Aave.RPCURL, cfg.Wallet.PrivateKey)
	if err != nil {
		logger.Fatal("init chain client", zap.Error(err))
	}
	logger.Info("chain client ready",
		zap.Uint64("chain_id", chainCli.ChainID),
		zap.Bool("has_signer", chainCli.HasSigner()),
		zap.String("operator", chainCli.Address().Hex()),
	)

	healthSvc := service.NewHealthService(chainCli)
	supplySvc := service.NewSupplyService(chainCli, &cfg.Aave)
	borrowSvc := service.NewBorrowService(chainCli, &cfg.Aave)
	liqListener := service.NewLiquidationListener(chainCli, &cfg.LiquidationListener, cfg.Aave.Pool, logger)

	ctx, stop := signal.NotifyContext(context.Background(), syscall.SIGINT, syscall.SIGTERM)
	defer stop()
	go liqListener.Start(ctx)

	r := gin.Default()
	handler.NewAaveHandler(healthSvc, supplySvc, borrowSvc).Register(r)

	addr := fmt.Sprintf(":%d", cfg.Server.Port)
	logger.Info("starting HTTP server", zap.String("addr", addr))
	if err := r.Run(addr); err != nil {
		logger.Fatal("gin run", zap.Error(err))
	}
}
