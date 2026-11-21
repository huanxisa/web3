.PHONY: help tidy build run-api run-schedule

help:
	@echo "后端命令"
	@echo "  make tidy         - 安装/整理依赖"
	@echo "  make build        - 编译 api 和 schedule 二进制"
	@echo "  make run-api      - 启动 API 服务 (port 8080)"
	@echo "  make run-schedule - 启动链上数据同步调度器"

tidy:
	go mod tidy

build:
	go build -o bin/pledge-api     ./cmd/api
	go build -o bin/pledge-schedule ./cmd/schedule

run-api:
	go run ./cmd/api

run-schedule:
	go run ./cmd/schedule
