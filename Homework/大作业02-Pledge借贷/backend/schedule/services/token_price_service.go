package services

import (
	"log"
	"time"

	"pledge-backend/db"
)

// SyncTokenPrice 更新 DB 中所有代币的实时价格
//
// 数据来源：
//   - 方案A（当前）：直接读链上 Chainlink price feed（推荐，无中心化依赖）
//   - 方案B（参考项目）：调用 KuCoin 等 CEX API
//
// 此函数由 cron 定时调用（如每 60 秒一次）
func SyncTokenPrice() {
	// TODO:
	// 1. 查询 DB 中所有需要更新价格的代币（token_info 表）
	// 2. 对每个代币，调用对应的 Chainlink feed 合约 latestRoundData()
	//    或调用外部 API（如 CoinGecko）
	// 3. 更新 token_info.price 和 updated_at

	var tokens []db.TokenInfo
	db.DB.Find(&tokens)

	for _, t := range tokens {
		newPrice := fetchPrice(t.Symbol, t.Token)
		if newPrice == "" {
			continue
		}
		db.DB.Model(&t).Updates(map[string]interface{}{
			"price":      newPrice,
			"updated_at": time.Now(),
		})
		log.Printf("[TokenPrice] %s(%s) updated to %s", t.Symbol, t.Token, newPrice)
	}
}

// fetchPrice 从链上或外部 API 获取代币价格（精度 1e8）
func fetchPrice(symbol, tokenAddr string) string {
	// TODO:
	// 实现具体价格获取逻辑
	// 示例（Chainlink）：
	//   client, _ := ethclient.Dial(rpcURL)
	//   feed, _ := chainlink.NewAggregatorV3Interface(feedAddr, client)
	//   _, price, _, _, _ := feed.LatestRoundData(ctx)
	//   return price.String()
	return ""
}
