// Day 3 待实现：Aave V3 supply（存抵押品）。
//
// Aave Pool.sol 的核心函数签名（你只读不写，但要看懂）：
//
//	function supply(
//	    address asset,        // 要存的 token，如 USDC
//	    uint256 amount,       // 数量（注意精度，USDC 是 6 位）
//	    address onBehalfOf,   // 受益人地址（一般 = msg.sender）
//	    uint16  referralCode  // 通常传 0
//	) external;
//
// 调用前必须：
//  1. token.approve(poolAddress, amount)  ← 授权 Pool 合约扣你的 token
//  2. Pool.supply(...)
//
// Day 3 任务步骤（参考 internal/contract/README.md 的 abigen 教程）：
//  1. 用 abigen 从 Pool ABI 生成 contract/bindings/pool/pool.go
//  2. 用 ERC20 标准 binding 调用 token.Approve()
//  3. 调用 pool.Supply(transactor, asset, amount, onBehalfOf, big.NewInt(0))
//  4. 等待 receipt: bind.WaitMined(ctx, client, tx)
//  5. 在测试网用 100 USDC 跑通整个流程，校验你的 aUSDC 余额上涨
package service

import (
	"context"
	"fmt"
	"math/big"

	"github.com/piliepeng/w1-go-aave-adapter/internal/chain"
	"github.com/piliepeng/w1-go-aave-adapter/internal/config"
)

type SupplyService struct {
	chain *chain.Client
	cfg   *config.AaveCfg
}

func NewSupplyService(c *chain.Client, cfg *config.AaveCfg) *SupplyService {
	return &SupplyService{chain: c, cfg: cfg}
}

// Supply 是 Day 3 占位实现。验证 token 是否在 config 中即返回 TODO。
func (s *SupplyService) Supply(ctx context.Context, tokenSymbol string, amount *big.Int) (string, error) {
	tokenAddr, ok := s.cfg.Tokens[tokenSymbol]
	if !ok {
		return "", fmt.Errorf("unknown token: %s", tokenSymbol)
	}

	// 实现伪代码（Day 3 自己补完）：
	//   erc20, _ := bindings.NewERC20(common.HexToAddress(tokenAddr), s.chain.Eth)
	//   transactor, _ := s.chain.Transactor()
	//   _, err := erc20.Approve(transactor, common.HexToAddress(s.cfg.Pool), amount)
	//   ... 等 approve 上链 ...
	//   pool, _ := pool.NewPool(common.HexToAddress(s.cfg.Pool), s.chain.Eth)
	//   tx, err := pool.Supply(transactor, common.HexToAddress(tokenAddr), amount, s.chain.Address(), big.NewInt(0))
	//   receipt, _ := bind.WaitMined(ctx, s.chain.Eth, tx)
	//   return tx.Hash().Hex(), nil

	return "TODO_DAY3", fmt.Errorf("not implemented yet: supply(%s, %s) on Pool %s, tokenAddr=%s",
		tokenSymbol, amount.String(), s.cfg.Pool, tokenAddr)
}
