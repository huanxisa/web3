package indexer

import (
	"context"
	"log"
	"math/big"
	"time"

	"github.com/ethereum/go-ethereum"
	"github.com/ethereum/go-ethereum/common"
	"github.com/ethereum/go-ethereum/core/types"
	"github.com/ethereum/go-ethereum/ethclient"

	"nft-auction-backend/internal/config"
	"nft-auction-backend/internal/infra/db"
)

// 合约事件签名（keccak256 of event signature）
// 使用 cast sig-event "AuctionCreated(...)" 生成
var (
	topicAuctionCreated  = common.HexToHash("TODO: fill in event topic hash")
	topicBidPlaced       = common.HexToHash("TODO: fill in event topic hash")
	topicAuctionEnded    = common.HexToHash("TODO: fill in event topic hash")
	topicAuctionCancelled = common.HexToHash("TODO: fill in event topic hash")
)

type Indexer struct {
	client          *ethclient.Client
	contractAddress common.Address
	repo            *db.Repo
	cfg             *config.Config
}

func New(cfg *config.Config, repo *db.Repo) (*Indexer, error) {
	client, err := ethclient.Dial(cfg.RPCURL)
	if err != nil {
		return nil, err
	}
	return &Indexer{
		client:          client,
		contractAddress: common.HexToAddress(cfg.AuctionContractAddress),
		repo:            repo,
		cfg:             cfg,
	}, nil
}

// Run 启动索引器，持续监听链上事件
func (idx *Indexer) Run(ctx context.Context) {
	log.Println("[Indexer] Starting...")

	// 1. 先追赶历史区块（从上次断点到当前最新）
	if err := idx.catchUp(ctx); err != nil {
		log.Printf("[Indexer] catchUp error: %v", err)
	}

	// 2. 订阅新区块事件（持续监听）
	idx.subscribe(ctx)
}

// catchUp 从上次记录的区块开始扫描到最新区块
func (idx *Indexer) catchUp(ctx context.Context) error {
	lastBlock, err := idx.repo.GetLastBlock(idx.cfg.AuctionContractAddress)
	if err != nil {
		return err
	}
	if lastBlock == 0 {
		lastBlock = idx.cfg.ContractDeployBlock
	}

	latestBlock, err := idx.client.BlockNumber(ctx)
	if err != nil {
		return err
	}

	log.Printf("[Indexer] Catching up from block %d to %d", lastBlock, latestBlock)

	// TODO: 分批查询历史日志（每批 2000 个区块，避免节点限制）
	// 参考：idx.client.FilterLogs(ctx, ethereum.FilterQuery{...})

	return nil
}

// subscribe 订阅新区块的事件
func (idx *Indexer) subscribe(ctx context.Context) {
	query := ethereum.FilterQuery{
		Addresses: []common.Address{idx.contractAddress},
	}

	logs := make(chan types.Log)
	sub, err := idx.client.SubscribeFilterLogs(ctx, query, logs)
	if err != nil {
		// WebSocket 不可用时，降级为轮询
		log.Printf("[Indexer] Subscribe failed, falling back to polling: %v", err)
		idx.poll(ctx)
		return
	}

	log.Println("[Indexer] Subscribed to contract events")

	for {
		select {
		case err := <-sub.Err():
			log.Printf("[Indexer] Subscription error: %v, reconnecting...", err)
			time.Sleep(5 * time.Second)
			idx.subscribe(ctx) // 重连
			return
		case vLog := <-logs:
			idx.processLog(ctx, vLog)
		case <-ctx.Done():
			return
		}
	}
}

// poll 轮询模式（HTTP RPC 降级方案）
func (idx *Indexer) poll(ctx context.Context) {
	ticker := time.NewTicker(12 * time.Second) // ~以太坊出块时间
	defer ticker.Stop()

	for {
		select {
		case <-ticker.C:
			// TODO: 查询最新区块，处理新事件
		case <-ctx.Done():
			return
		}
	}
}

// processLog 解析并处理单条事件日志
func (idx *Indexer) processLog(ctx context.Context, vLog types.Log) {
	if len(vLog.Topics) == 0 {
		return
	}

	switch vLog.Topics[0] {
	case topicAuctionCreated:
		idx.handleAuctionCreated(ctx, vLog)
	case topicBidPlaced:
		idx.handleBidPlaced(ctx, vLog)
	case topicAuctionEnded:
		idx.handleAuctionEnded(ctx, vLog)
	case topicAuctionCancelled:
		idx.handleAuctionCancelled(ctx, vLog)
	}
}

func (idx *Indexer) handleAuctionCreated(ctx context.Context, vLog types.Log) {
	// TODO: 解析 AuctionCreated 事件，写入 auctions 表
	// 提示：indexed 参数在 Topics[1], Topics[2]...，non-indexed 参数在 Data 字段
	log.Printf("[Indexer] AuctionCreated tx=%s", vLog.TxHash.Hex())
}

func (idx *Indexer) handleBidPlaced(ctx context.Context, vLog types.Log) {
	// TODO: 解析 BidPlaced 事件，写入 bids 表，更新 auctions 的最高出价
	log.Printf("[Indexer] BidPlaced tx=%s", vLog.TxHash.Hex())
}

func (idx *Indexer) handleAuctionEnded(ctx context.Context, vLog types.Log) {
	// TODO: 解析 AuctionEnded 事件，更新 auctions 状态为 ended，记录 winner
	log.Printf("[Indexer] AuctionEnded tx=%s", vLog.TxHash.Hex())
}

func (idx *Indexer) handleAuctionCancelled(ctx context.Context, vLog types.Log) {
	// TODO: 解析 AuctionCancelled 事件，更新 auctions 状态为 cancelled
	log.Printf("[Indexer] AuctionCancelled tx=%s", vLog.TxHash.Hex())
}

// weiToString 将 big.Int wei 转为字符串（避免精度丢失）
func weiToString(wei *big.Int) string {
	if wei == nil {
		return "0"
	}
	return wei.String()
}
