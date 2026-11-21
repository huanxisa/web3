package db

import "time"

// Auction 拍卖主表
type Auction struct {
	ID            uint      `gorm:"primaryKey"`
	AuctionID     uint64    `gorm:"uniqueIndex;not null"` // 链上拍卖 ID
	Seller        string    `gorm:"size:42;not null"`
	NFTContract   string    `gorm:"size:42;not null"`
	TokenID       uint64    `gorm:"not null"`
	StartPrice    string    `gorm:"not null"` // wei，用 string 避免精度丢失
	StartTime     time.Time `gorm:"not null"`
	EndTime       time.Time `gorm:"not null"`
	Status        string    `gorm:"size:20;not null;default:'pending'"` // pending/active/ended/cancelled
	HighestBid    string    `gorm:"default:'0'"`
	HighestBidder string    `gorm:"size:42"`
	Winner        string    `gorm:"size:42"`
	TxHash        string    `gorm:"size:66"`
	BlockNumber   uint64
	CreatedAt     time.Time
	UpdatedAt     time.Time
}

// Bid 出价历史表
type Bid struct {
	ID          uint   `gorm:"primaryKey"`
	AuctionID   uint64 `gorm:"index;not null"`
	Bidder      string `gorm:"size:42;not null"`
	Amount      string `gorm:"not null"` // wei
	TxHash      string `gorm:"size:66"`
	BlockNumber uint64
	CreatedAt   time.Time
}

// SyncCursor 索引进度游标表（保证重启可恢复）
type SyncCursor struct {
	ID              uint   `gorm:"primaryKey"`
	ContractAddress string `gorm:"size:42;uniqueIndex"`
	LastBlock       uint64 `gorm:"not null;default:0"`
}
