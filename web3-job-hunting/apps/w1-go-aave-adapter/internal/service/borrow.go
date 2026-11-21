// Day 4 待实现：Aave V3 borrow + getUserAccountData。
//
// Aave Pool.sol 关键函数：
//
//	function borrow(
//	    address asset,
//	    uint256 amount,
//	    uint256 interestRateMode,   // 1=Stable, 2=Variable（V3 默认 Variable）
//	    uint16  referralCode,
//	    address onBehalfOf
//	) external;
//
//	function getUserAccountData(address user) external view returns (
//	    uint256 totalCollateralBase,
//	    uint256 totalDebtBase,
//	    uint256 availableBorrowsBase,
//	    uint256 currentLiquidationThreshold,
//	    uint256 ltv,
//	    uint256 healthFactor       // 1e18，<1e18 即可被清算
//	);
//
// Day 4 任务：
//  1. 复用 Day 3 生成的 pool binding
//  2. 实现 GetUserAccountData(user) → 返回上述 6 个字段
//  3. 实现 Borrow(token, amount) → mode=2（Variable）
//  4. 在测试网验证：先 supply 100 USDC，再 borrow 30 DAI，看 healthFactor 变化
package service

import (
	"context"
	"fmt"
	"math/big"

	"github.com/piliepeng/w1-go-aave-adapter/internal/chain"
	"github.com/piliepeng/w1-go-aave-adapter/internal/config"
)

type BorrowService struct {
	chain *chain.Client
	cfg   *config.AaveCfg
}

func NewBorrowService(c *chain.Client, cfg *config.AaveCfg) *BorrowService {
	return &BorrowService{chain: c, cfg: cfg}
}

type UserAccountData struct {
	TotalCollateralBase         *big.Int `json:"total_collateral_base"`
	TotalDebtBase               *big.Int `json:"total_debt_base"`
	AvailableBorrowsBase        *big.Int `json:"available_borrows_base"`
	CurrentLiquidationThreshold *big.Int `json:"current_liquidation_threshold"`
	LTV                         *big.Int `json:"ltv"`
	HealthFactor                *big.Int `json:"health_factor"`
}

func (s *BorrowService) Borrow(ctx context.Context, tokenSymbol string, amount *big.Int) (string, error) {
	tokenAddr, ok := s.cfg.Tokens[tokenSymbol]
	if !ok {
		return "", fmt.Errorf("unknown token: %s", tokenSymbol)
	}
	return "TODO_DAY4", fmt.Errorf("not implemented yet: borrow(%s, %s), tokenAddr=%s",
		tokenSymbol, amount.String(), tokenAddr)
}

func (s *BorrowService) GetUserAccountData(ctx context.Context, user string) (*UserAccountData, error) {
	return nil, fmt.Errorf("not implemented yet: getUserAccountData(%s)", user)
}
