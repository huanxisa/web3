package db

import (
	"gorm.io/driver/sqlite"
	"gorm.io/gorm"
)

type Repo struct {
	db *gorm.DB
}

func NewRepo(dbPath string) (*Repo, error) {
	db, err := gorm.Open(sqlite.Open(dbPath), &gorm.Config{})
	if err != nil {
		return nil, err
	}
	// 自动建表
	if err := db.AutoMigrate(&Auction{}, &Bid{}, &SyncCursor{}); err != nil {
		return nil, err
	}
	return &Repo{db: db}, nil
}

// ── 拍卖相关 ───────────────────────────────────────────────────

func (r *Repo) CreateAuction(a *Auction) error {
	// TODO: 实现创建拍卖记录
	return nil
}

func (r *Repo) UpdateAuction(a *Auction) error {
	// TODO: 实现更新拍卖（最高出价、状态等）
	return nil
}

func (r *Repo) GetAuction(auctionID uint64) (*Auction, error) {
	// TODO: 按链上拍卖 ID 查询
	return nil, nil
}

// ListAuctionsFilter 查询过滤条件
type ListAuctionsFilter struct {
	Status  string // pending/active/ended/cancelled/""（全部）
	OrderBy string // "end_time_asc" / "highest_bid_desc" 等
	Limit   int
	Offset  int
}

func (r *Repo) ListAuctions(filter ListAuctionsFilter) ([]Auction, int64, error) {
	// TODO: 实现带过滤、排序、分页的拍卖列表查询
	return nil, 0, nil
}

// ── 出价相关 ───────────────────────────────────────────────────

func (r *Repo) CreateBid(b *Bid) error {
	// TODO: 实现创建出价记录
	return nil
}

func (r *Repo) ListBids(auctionID uint64) ([]Bid, error) {
	// TODO: 查询某拍卖的全部出价历史，按时间排序
	return nil, nil
}

// ── 统计相关 ───────────────────────────────────────────────────

type Stats struct {
	TotalAuctions  int64
	ActiveAuctions int64
	EndedAuctions  int64
	TotalBids      int64
}

func (r *Repo) GetStats() (*Stats, error) {
	// TODO: 实现平台统计数据查询
	return nil, nil
}

// ── 游标相关（索引器断点续传）─────────────────────────────────

func (r *Repo) GetLastBlock(contractAddress string) (uint64, error) {
	// TODO: 查询已处理到的最新区块号
	return 0, nil
}

func (r *Repo) UpdateLastBlock(contractAddress string, blockNumber uint64) error {
	// TODO: 更新已处理到的最新区块号（upsert）
	return nil
}
