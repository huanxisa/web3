// Package config 加载 config/config.yml 与环境变量。
//
// 设计要点：
//   - viper 读 yml 后再让环境变量覆盖（${SEPOLIA_RPC_URL} 这类占位是给 docker 用的，
//     viper 不会自动解析 ${VAR}，所以这里再手动 expand 一次）
//   - 不暴露具体字段类型，只暴露 Get 函数；调用方用结构体拿
package config

import (
	"fmt"
	"os"
	"path/filepath"
	"strings"

	"github.com/spf13/viper"
)

type ServerCfg struct {
	Port int `mapstructure:"port"`
}

type AaveCfg struct {
	Network               string            `mapstructure:"network"`
	RPCURL                string            `mapstructure:"rpc_url"`
	PoolAddressesProvider string            `mapstructure:"pool_addresses_provider"`
	Pool                  string            `mapstructure:"pool"`
	UIPoolDataProvider    string            `mapstructure:"ui_pool_data_provider"`
	Tokens                map[string]string `mapstructure:"tokens"`
}

type WalletCfg struct {
	PrivateKey         string  `mapstructure:"private_key"`
	GasPriceMultiplier float64 `mapstructure:"gas_price_multiplier"`
}

type LiquidationListenerCfg struct {
	Enabled        bool   `mapstructure:"enabled"`
	StartBlock     string `mapstructure:"start_block"`
	PollIntervalMs int    `mapstructure:"poll_interval_ms"`
}

type LogCfg struct {
	Level string `mapstructure:"level"`
}

type Config struct {
	Server              ServerCfg              `mapstructure:"server"`
	Aave                AaveCfg                `mapstructure:"aave"`
	Wallet              WalletCfg              `mapstructure:"wallet"`
	LiquidationListener LiquidationListenerCfg `mapstructure:"liquidation_listener"`
	Log                 LogCfg                 `mapstructure:"log"`
}

// Load 从给定目录加载 config.yml；若 path 为空则按 ./config 查找。
func Load(path string) (*Config, error) {
	if path == "" {
		path = filepath.Join(".", "config")
	}
	v := viper.New()
	v.SetConfigName("config")
	v.SetConfigType("yaml")
	v.AddConfigPath(path)
	if err := v.ReadInConfig(); err != nil {
		return nil, fmt.Errorf("read config: %w", err)
	}

	// viper 不会自动 expand ${VAR}，这里手动展开 string 字段
	for _, k := range v.AllKeys() {
		if s, ok := v.Get(k).(string); ok {
			v.Set(k, expandEnv(s))
		}
	}

	var c Config
	if err := v.Unmarshal(&c); err != nil {
		return nil, fmt.Errorf("unmarshal config: %w", err)
	}
	return &c, nil
}

// expandEnv 支持 ${VAR:-default} 语法（viper 默认不支持）。
func expandEnv(s string) string {
	if !strings.Contains(s, "${") {
		return s
	}
	return os.Expand(s, func(key string) string {
		if i := strings.Index(key, ":-"); i >= 0 {
			name, def := key[:i], key[i+2:]
			if v, ok := os.LookupEnv(name); ok {
				return v
			}
			return def
		}
		return os.Getenv(key)
	})
}
