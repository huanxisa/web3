package config

import (
	"log"
	"os"
	"strconv"

	"github.com/joho/godotenv"
)

type Config struct {
	RPCURL                  string
	ChainID                 int64
	AuctionContractAddress  string
	ContractDeployBlock     uint64
	DBPath                  string // SQLite 文件路径，如 ./nft_auction.db
	ServerPort              string
	AlchemyAPIKey           string
}

func Load() *Config {
	// 加载 .env 文件（不存在时忽略，生产环境用环境变量）
	_ = godotenv.Load()

	cfg := &Config{
		RPCURL:                 mustEnv("RPC_URL"),
		ChainID:                parseInt64(getEnvOr("CHAIN_ID", "11155111")),
		AuctionContractAddress: mustEnv("AUCTION_CONTRACT_ADDRESS"),
		ContractDeployBlock:    parseUint64(getEnvOr("CONTRACT_DEPLOY_BLOCK", "0")),
		DBPath:                 getEnvOr("DB_PATH", "./nft_auction.db"),
		ServerPort:             getEnvOr("SERVER_PORT", "8080"),
		AlchemyAPIKey:          getEnvOr("ALCHEMY_API_KEY", ""),
	}

	return cfg
}

func mustEnv(key string) string {
	v := os.Getenv(key)
	if v == "" {
		log.Fatalf("required env var %s is not set", key)
	}
	return v
}

func getEnvOr(key, defaultVal string) string {
	if v := os.Getenv(key); v != "" {
		return v
	}
	return defaultVal
}

func parseInt64(s string) int64 {
	n, err := strconv.ParseInt(s, 10, 64)
	if err != nil {
		log.Fatalf("invalid int64 value: %s", s)
	}
	return n
}

func parseUint64(s string) uint64 {
	n, err := strconv.ParseUint(s, 10, 64)
	if err != nil {
		log.Fatalf("invalid uint64 value: %s", s)
	}
	return n
}
