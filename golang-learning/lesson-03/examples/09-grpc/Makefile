# 09-grpc 示例：构建与运行
# 使用 make 或 make help 查看目标

BINARY := grpc-demo
ADDR   := :50051

.PHONY: help build run-server run-client proto clean

help:
	@echo "用法:"
	@echo "  make build       - 编译为可执行文件 $(BINARY)"
	@echo "  make run-server - 直接运行服务端 (go run .)"
	@echo "  make run-client - 直接运行客户端 (go run .)"
	@echo "  make proto      - 根据 user.proto 重新生成 pb 代码"
	@echo "  make clean      - 删除生成的可执行文件"

# 编译为可执行文件（当前目录下所有参与构建的 .go 会一起编译）
build:
	go build -o $(BINARY) .

# 运行服务端（不指定文件时用 go run . 表示当前包）
run-server:
	go run . -mode=server -addr=$(ADDR)

# 运行客户端
run-client:
	go run . -mode=client -addr=localhost:50051

# 重新生成 gRPC/Protobuf 代码
proto:
	protoc --go_out=. --go_opt=paths=source_relative \
	       --go-grpc_out=. --go-grpc_opt=paths=source_relative \
	       user.proto

clean:
	rm -f $(BINARY)
