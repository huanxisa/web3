// Package service 是核心业务层。
//
// 命名习惯：每个 service 一个文件，对应一个 W1 Day 任务：
//   - health.go        Day 1：链连通性 + 区块号
//   - supply.go        Day 3：Aave supply（占位）
//   - borrow.go        Day 4：Aave borrow + getUserAccountData（占位）
//   - liquidation.go   Day 5：监听 LiquidationCall 事件（占位）
package service

import (
	"context"

	"github.com/piliepeng/w1-go-aave-adapter/internal/chain"
)

type HealthService struct {
	chain *chain.Client
}

func NewHealthService(c *chain.Client) *HealthService {
	return &HealthService{chain: c}
}

type HealthInfo struct {
	ChainID     uint64 `json:"chain_id"`
	BlockNumber uint64 `json:"block_number"`
	Address     string `json:"address,omitempty"`
	HasSigner   bool   `json:"has_signer"`
}

// Check 是 Day 1 验收点：能调通 RPC + 拿到 chainId + 最新块高。
//
// Sepolia 期望值：chain_id=11155111；block_number 应该是当前最新块。
func (s *HealthService) Check(ctx context.Context) (*HealthInfo, error) {
	bn, err := s.chain.Eth.BlockNumber(ctx)
	if err != nil {
		return nil, err
	}
	info := &HealthInfo{
		ChainID:     s.chain.ChainID,
		BlockNumber: bn,
		HasSigner:   s.chain.HasSigner(),
	}
	if s.chain.HasSigner() {
		info.Address = s.chain.Address().Hex()
	}
	return info, nil
}
