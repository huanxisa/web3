// Day 5 待实现：监听 Aave V3 LiquidationCall 事件并落库。
//
// 事件签名（来自 Pool.sol）：
//
//	event LiquidationCall(
//	    address indexed collateralAsset,
//	    address indexed debtAsset,
//	    address indexed user,            // 被清算的人
//	    uint256 debtToCover,
//	    uint256 liquidatedCollateralAmount,
//	    address liquidator,
//	    bool    receiveAToken
//	);
//
// 实现路径（推荐 SubscribeFilterLogs 走 WS；HTTP 走 FilterLogs 轮询也行）：
//
//	query := ethereum.FilterQuery{
//	    Addresses: []common.Address{common.HexToAddress(cfg.Pool)},
//	    Topics:    [][]common.Hash{{poolABI.Events["LiquidationCall"].ID}},
//	}
//	logs := make(chan types.Log)
//	sub, err := chainClient.Eth.SubscribeFilterLogs(ctx, query, logs)
//	for { select { case l := <-logs: parseAndPersist(l) ... } }
//
// Day 5 任务：
//  1. 启动后从 cfg.LiquidationListener.StartBlock 开始（latest 或具体块号）
//  2. 解析 log → 入库 PostgreSQL（表名 liquidation_events，字段含 event 全部 + tx_hash + block_number）
//  3. 持久化已处理的 lastBlock，避免重启重复
//  4. 在测试网手动触发清算（或者读历史记录）验证落库
package service

import (
	"context"

	"go.uber.org/zap"

	"github.com/piliepeng/w1-go-aave-adapter/internal/chain"
	"github.com/piliepeng/w1-go-aave-adapter/internal/config"
)

type LiquidationListener struct {
	chain  *chain.Client
	cfg    *config.LiquidationListenerCfg
	pool   string // Pool 合约地址
	logger *zap.Logger
}

func NewLiquidationListener(c *chain.Client, cfg *config.LiquidationListenerCfg, poolAddr string, logger *zap.Logger) *LiquidationListener {
	return &LiquidationListener{chain: c, cfg: cfg, pool: poolAddr, logger: logger}
}

// Start 是 Day 5 占位：仅打印一行日志告诉你它没真跑。
func (l *LiquidationListener) Start(ctx context.Context) {
	if !l.cfg.Enabled {
		l.logger.Info("liquidation listener disabled by config")
		return
	}
	l.logger.Warn("[TODO Day 5] liquidation listener placeholder",
		zap.String("pool", l.pool),
		zap.String("start_block", l.cfg.StartBlock),
		zap.Int("poll_interval_ms", l.cfg.PollIntervalMs),
	)
	// 实现伪代码：
	//   poolAbi, _ := abi.JSON(strings.NewReader(string(poolABIJson)))
	//   topic := poolAbi.Events["LiquidationCall"].ID
	//   query := ethereum.FilterQuery{
	//       Addresses: []common.Address{common.HexToAddress(l.pool)},
	//       Topics:    [][]common.Hash{{topic}},
	//   }
	//   logsCh := make(chan types.Log)
	//   sub, _ := l.chain.Eth.SubscribeFilterLogs(ctx, query, logsCh)
	//   defer sub.Unsubscribe()
	//   for {
	//       select {
	//       case <-ctx.Done(): return
	//       case err := <-sub.Err(): l.logger.Error("sub err", zap.Error(err)); return
	//       case lg := <-logsCh: l.handle(ctx, lg)
	//       }
	//   }
}
