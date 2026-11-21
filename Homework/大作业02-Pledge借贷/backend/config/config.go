package config

import (
	"log"
	"os"
	"strconv"

	"github.com/joho/godotenv"
)

// Config 全局配置（由 Init() 初始化）
var Config = &AppConfig{}

type AppConfig struct {
	Env      EnvConfig
	DB       DBConfig
	Chain    ChainConfig
}

type EnvConfig struct {
	Port    string
	Version string
	Mode    string // debug / release
}

type DBConfig struct {
	Path string // SQLite 文件路径
}

type ChainConfig struct {
	RPCURL          string
	ChainID         int64
	PledgePoolAddr  string
	DeployerPrivKey string // 仅本地测试使用，生产环境不配置
}

func Init() {
	// 加载 .env（忽略不存在的情况，使用系统环境变量）
	_ = godotenv.Load()

	chainID, _ := strconv.ParseInt(getEnv("CHAIN_ID", "31337"), 10, 64)

	Config = &AppConfig{
		Env: EnvConfig{
			Port:    getEnv("PORT", "8080"),
			Version: getEnv("API_VERSION", "2"),
			Mode:    getEnv("GIN_MODE", "debug"),
		},
		DB: DBConfig{
			Path: getEnv("DB_PATH", "./pledge.db"),
		},
		Chain: ChainConfig{
			RPCURL:          getEnv("RPC_URL", "http://localhost:8545"),
			ChainID:         chainID,
			PledgePoolAddr:  getEnv("PLEDGE_POOL_ADDRESS", ""),
			DeployerPrivKey: getEnv("DEPLOYER_PRIVATE_KEY", ""),
		},
	}

	if Config.Chain.PledgePoolAddr == "" {
		log.Println("[WARN] PLEDGE_POOL_ADDRESS is not set")
	}
}

func getEnv(key, fallback string) string {
	if v := os.Getenv(key); v != "" {
		return v
	}
	return fallback
}
