package services

import (
	"context"
	"fmt"
	"log"
	"math/big"
	"time"

	"github.com/ethereum/go-ethereum/common"
	"github.com/ethereum/go-ethereum/ethclient"
	"pledge-backend/config"
	"pledge-backend/contract/bindings"
	"pledge-backend/db"
)

// SyncPoolData 从链上读取所有池子数据并写入 DB
//
// 此函数由 cron 定时调用（如每 30 秒一次）
//
// 流程：
//  1. 连接 RPC 节点
//  2. 调用 poolLength() 获取池子数量
//  3. 遍历每个 pid，读取 poolBaseInfo / poolDataInfo
//  4. upsert（按 chain_id + pool_id）到 DB
func SyncPoolData() {
	ctx, cancel := context.WithTimeout(context.Background(), 30*time.Second)
	defer cancel()

	client, err := ethclient.DialContext(ctx, config.Config.Chain.RPCURL)
	if err != nil {
		log.Printf("[SyncPool] dial error: %v", err)
		return
	}
	defer client.Close()

	if config.Config.Chain.PledgePoolAddr == "" {
		log.Println("[SyncPool] PLEDGE_POOL_ADDRESS not configured, skip")
		return
	}

	caller, err := bindings.NewPledgePoolCaller(
		client,
		common.HexToAddress(config.Config.Chain.PledgePoolAddr),
	)
	if err != nil {
		log.Printf("[SyncPool] init caller error: %v", err)
		return
	}

	// ── 获取池子数量 ──────────────────────────────────────────
	length, err := caller.PoolLength(ctx)
	if err != nil {
		log.Printf("[SyncPool] poolLength error: %v", err)
		return
	}
	log.Printf("[SyncPool] found %s pools on chain %d", length.String(), config.Config.Chain.ChainID)

	chainIDStr := fmt.Sprintf("%d", config.Config.Chain.ChainID)

	// ── 遍历每个池子 ──────────────────────────────────────────
	for i := int64(0); i < length.Int64(); i++ {
		pid := big.NewInt(i)

		// TODO: 调用 caller.PoolBaseInfo(ctx, pid) 获取基础信息
		baseInfo, err := caller.PoolBaseInfo(ctx, pid)
		if err != nil {
			log.Printf("[SyncPool] pid=%d PoolBaseInfo error: %v", i, err)
			continue
		}
		if baseInfo == nil {
			continue // 骨架中跳过（待实现）
		}

		// TODO: 调用 caller.PoolDataInfo(ctx, pid) 获取结算数据
		dataInfo, err := caller.PoolDataInfo(ctx, pid)
		if err != nil {
			log.Printf("[SyncPool] pid=%d PoolDataInfo error: %v", i, err)
			continue
		}
		if dataInfo == nil {
			continue
		}

		// ── upsert PoolBase ───────────────────────────────────
		poolBase := db.PoolBase{
			PoolID:  int(i),
			ChainID: chainIDStr,
			// TODO: 从 baseInfo 填充各字段
			// SettleTime: baseInfo.SettleTime.String(),
			// ...
			UpdatedAt: time.Now(),
		}
		db.DB.Where("chain_id = ? AND pool_id = ?", chainIDStr, i).
			Assign(poolBase).
			FirstOrCreate(&poolBase)

		// ── upsert PoolData ───────────────────────────────────
		poolData := db.PoolData{
			PoolID:  fmt.Sprintf("%d", i),
			ChainID: chainIDStr,
			// TODO: 从 dataInfo 填充
			UpdatedAt: time.Now(),
		}
		db.DB.Where("chain_id = ? AND pool_id = ?", chainIDStr, fmt.Sprintf("%d", i)).
			Assign(poolData).
			FirstOrCreate(&poolData)
	}

	log.Printf("[SyncPool] sync done, %d pools processed", length.Int64())
}
