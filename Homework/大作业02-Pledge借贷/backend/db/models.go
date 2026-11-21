package db

import "time"

// PoolBase 对应链上 PoolBaseInfo（按 chain_id + pool_id 唯一）
// 由 schedule 服务定时从链上同步
type PoolBase struct {
	ID                     uint      `gorm:"primaryKey;autoIncrement" json:"id"`
	PoolID                 int       `gorm:"index;not null" json:"pool_id"`      // 链上 pid
	ChainID                string    `gorm:"index;not null;default:'31337'" json:"chain_id"`
	SettleTime             string    `json:"settle_time"`
	EndTime                string    `json:"end_time"`
	InterestRate           string    `json:"interest_rate"`
	MaxSupply              string    `json:"max_supply"`
	LendSupply             string    `json:"lend_supply"`
	BorrowSupply           string    `json:"borrow_supply"`
	MartgageRate           string    `json:"martgage_rate"`
	LendToken              string    `json:"lend_token"`
	BorrowToken            string    `json:"borrow_token"`
	State                  string    `json:"state"`    // 0=MATCH 1=EXECUTION 2=FINISH 3=LIQUIDATION 4=UNDONE
	SpCoin                 string    `json:"sp_coin"`  // spToken 地址
	JpCoin                 string    `json:"jp_coin"`  // jpToken 地址
	AutoLiquidateThreshold string    `json:"auto_liquidate_threshold"`
	// 冗余字段（前端展示用）
	LendTokenSymbol        string    `json:"lend_token_symbol"`
	BorrowTokenSymbol      string    `json:"borrow_token_symbol"`
	LendTokenInfo          string    `gorm:"type:text" json:"lend_token_info"`   // JSON
	BorrowTokenInfo        string    `gorm:"type:text" json:"borrow_token_info"` // JSON
	CreatedAt              time.Time `json:"created_at"`
	UpdatedAt              time.Time `json:"updated_at"`
}

// PoolData 对应链上 PoolDataInfo（结算/清算数据）
type PoolData struct {
	ID                    uint      `gorm:"primaryKey;autoIncrement" json:"id"`
	PoolID                string    `gorm:"index;not null" json:"pool_id"`
	ChainID               string    `gorm:"index;not null;default:'31337'" json:"chain_id"`
	SettleAmountLend      string    `json:"settle_amount_lend"`
	SettleAmountBorrow    string    `json:"settle_amount_borrow"`
	FinishAmountLend      string    `json:"finish_amount_lend"`
	FinishAmountBorrow    string    `json:"finish_amount_borrow"`
	LiquidationAmounLend  string    `json:"liquidation_amoun_lend"`
	LiquidationAmounBorrow string   `json:"liquidation_amoun_borrow"`
	CreatedAt             time.Time `json:"created_at"`
	UpdatedAt             time.Time `json:"updated_at"`
}

// TokenInfo 代币基础信息（价格、logo 等）
type TokenInfo struct {
	ID          uint      `gorm:"primaryKey;autoIncrement" json:"id"`
	Symbol      string    `gorm:"index" json:"symbol"`
	Logo        string    `json:"logo"`
	Price       string    `json:"price"` // 精度 1e8，Chainlink 格式
	Token       string    `gorm:"index" json:"token"` // 合约地址
	ChainID     string    `gorm:"index;default:'31337'" json:"chain_id"`
	Decimals    int       `json:"decimals"`
	CreatedAt   time.Time `json:"created_at"`
	UpdatedAt   time.Time `json:"updated_at"`
}

// Admin 后台管理员账号
type Admin struct {
	UserID   uint   `gorm:"primaryKey;autoIncrement" json:"user_id"`
	Name     string `gorm:"unique;not null" json:"name"`
	Password string `gorm:"not null" json:"-"` // bcrypt hash
}
