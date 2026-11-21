.PHONY: help build test clean deploy-local deploy-sepolia \
        run-api run-schedule

# ══════════════════════════════════════════════════════════════
#  Pledge 借贷协议 - 一键命令
# ══════════════════════════════════════════════════════════════
help:
	@echo ""
	@echo "  ── 智能合约 ─────────────────────────────────"
	@echo "  make build            编译合约"
	@echo "  make test             运行所有测试"
	@echo "  make coverage         测试覆盖率"
	@echo "  make clean            清理编译缓存"
	@echo "  make deploy-local     部署到本地 Anvil"
	@echo "  make deploy-sepolia   部署到 Sepolia 测试网"
	@echo ""
	@echo "  ── Go 后端 ──────────────────────────────────"
	@echo "  make run-api          启动 HTTP API (port 8080)"
	@echo "  make run-schedule     启动链上数据同步调度器"
	@echo ""

# ─── 合约命令 ──────────────────────────────────────────────────
build:
	forge build

test:
	forge test -vv

coverage:
	forge coverage

clean:
	forge clean

deploy-local:
	@cp -n .env.example .env 2>/dev/null || true
	forge script script/Deploy.s.sol:DeployScript \
		--rpc-url localhost \
		--broadcast \
		--sender $(DEPLOYER_ADDRESS) \
		-vvv

deploy-sepolia:
	forge script script/Deploy.s.sol:DeployScript \
		--rpc-url sepolia \
		--broadcast \
		--verify \
		--sender $(DEPLOYER_ADDRESS) \
		-vvv

# ─── 后端命令 ──────────────────────────────────────────────────
run-api:
	@cd backend && cp -n .env.example .env 2>/dev/null || true
	cd backend && go run ./cmd/api

run-schedule:
	@cd backend && cp -n .env.example .env 2>/dev/null || true
	cd backend && go run ./cmd/schedule
