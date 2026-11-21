// 此文件由 abigen 命令生成，实际使用时执行：
//
//   abigen --abi=../abi/pledge_pool.abi --pkg=bindings --type=PledgePool --out=pledge_pool.go
//
// 骨架中提供手动封装版本，直接使用 go-ethereum 的 ABI 解析。

package bindings

import (
	"context"
	"math/big"
	"strings"

	"github.com/ethereum/go-ethereum"
	"github.com/ethereum/go-ethereum/accounts/abi"
	"github.com/ethereum/go-ethereum/common"
	"github.com/ethereum/go-ethereum/ethclient"
)

// ─── PledgePool 绑定 ──────────────────────────────────────────────────────────

const pledgePoolABIJSON = `[
  {"type":"function","name":"poolLength","inputs":[],"outputs":[{"name":"","type":"uint256"}],"stateMutability":"view"},
  {"type":"function","name":"poolBaseInfo","inputs":[{"name":"","type":"uint256"}],"outputs":[
    {"name":"settleTime","type":"uint256"},
    {"name":"endTime","type":"uint256"},
    {"name":"interestRate","type":"uint256"},
    {"name":"maxSupply","type":"uint256"},
    {"name":"lendSupply","type":"uint256"},
    {"name":"borrowSupply","type":"uint256"},
    {"name":"martgageRate","type":"uint256"},
    {"name":"lendToken","type":"address"},
    {"name":"borrowToken","type":"address"},
    {"name":"state","type":"uint8"},
    {"name":"spCoin","type":"address"},
    {"name":"jpCoin","type":"address"},
    {"name":"autoLiquidateThreshold","type":"uint256"}
  ],"stateMutability":"view"},
  {"type":"function","name":"poolDataInfo","inputs":[{"name":"","type":"uint256"}],"outputs":[
    {"name":"settleAmountLend","type":"uint256"},
    {"name":"settleAmountBorrow","type":"uint256"},
    {"name":"finishAmountLend","type":"uint256"},
    {"name":"finishAmountBorrow","type":"uint256"},
    {"name":"liquidationAmounLend","type":"uint256"},
    {"name":"liquidationAmounBorrow","type":"uint256"}
  ],"stateMutability":"view"}
]`

type PoolBaseInfo struct {
	SettleTime             *big.Int
	EndTime                *big.Int
	InterestRate           *big.Int
	MaxSupply              *big.Int
	LendSupply             *big.Int
	BorrowSupply           *big.Int
	MartgageRate           *big.Int
	LendToken              common.Address
	BorrowToken            common.Address
	State                  uint8
	SpCoin                 common.Address
	JpCoin                 common.Address
	AutoLiquidateThreshold *big.Int
}

type PoolDataInfo struct {
	SettleAmountLend       *big.Int
	SettleAmountBorrow     *big.Int
	FinishAmountLend       *big.Int
	FinishAmountBorrow     *big.Int
	LiquidationAmounLend   *big.Int
	LiquidationAmounBorrow *big.Int
}

type PledgePoolCaller struct {
	client  *ethclient.Client
	address common.Address
	abi     abi.ABI
}

func NewPledgePoolCaller(client *ethclient.Client, address common.Address) (*PledgePoolCaller, error) {
	parsedABI, err := abi.JSON(strings.NewReader(pledgePoolABIJSON))
	if err != nil {
		return nil, err
	}
	return &PledgePoolCaller{client: client, address: address, abi: parsedABI}, nil
}

// PoolLength 获取池子总数
func (c *PledgePoolCaller) PoolLength(ctx context.Context) (*big.Int, error) {
	// TODO:
	// 1. 用 c.abi.Pack("poolLength") 编码调用数据
	// 2. 用 c.client.CallContract 调用链上
	// 3. 用 c.abi.Unpack 解码结果
	// 4. 返回 *big.Int
	data, err := c.abi.Pack("poolLength")
	if err != nil {
		return nil, err
	}
	result, err := c.client.CallContract(ctx, ethereum.CallMsg{
		To:   &c.address,
		Data: data,
	}, nil)
	if err != nil {
		return nil, err
	}
	var length *big.Int
	if err := c.abi.UnpackIntoInterface(&length, "poolLength", result); err != nil {
		return nil, err
	}
	return length, nil
}

// PoolBaseInfo 获取单个池子基础信息
func (c *PledgePoolCaller) PoolBaseInfo(ctx context.Context, pid *big.Int) (*PoolBaseInfo, error) {
	// TODO: 与 PoolLength 类似，Pack("poolBaseInfo", pid) 然后解码
	return nil, nil
}

// PoolDataInfo 获取单个池子结算数据
func (c *PledgePoolCaller) PoolDataInfo(ctx context.Context, pid *big.Int) (*PoolDataInfo, error) {
	// TODO: Pack("poolDataInfo", pid) 然后解码
	return nil, nil
}
