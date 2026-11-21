package db

import (
	"log"
	"pledge-backend/config"

	"gorm.io/driver/sqlite"
	"gorm.io/gorm"
	"gorm.io/gorm/logger"
)

var DB *gorm.DB

// Init 初始化 SQLite 数据库并自动迁移表结构
func Init() {
	var err error
	DB, err = gorm.Open(sqlite.Open(config.Config.DB.Path), &gorm.Config{
		Logger: logger.Default.LogMode(logger.Warn),
	})
	if err != nil {
		log.Fatalf("failed to open database: %v", err)
	}

	// 自动建表
	err = DB.AutoMigrate(
		&Admin{},
		&PoolBase{},
		&PoolData{},
		&TokenInfo{},
	)
	if err != nil {
		log.Fatalf("auto migrate failed: %v", err)
	}

	log.Println("[DB] SQLite connected:", config.Config.DB.Path)
}
