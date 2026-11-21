-include .env
export ETHERSCAN_API_KEY SEPOLIA_RPC_URL DEPLOYER_ADDRESS \
       MOCK_NFT_ADDRESS AUCTION_ADDRESS

DEPLOY_SCRIPT := script/Deploy.s.sol
CAST_ARGS     := --account deployer --rpc-url $(SEPOLIA_RPC_URL)
READ_ARGS     := --rpc-url $(SEPOLIA_RPC_URL)

# ── 帮助 ──────────────────────────────────────────────────────
help:
	@echo ""
	@echo "  【编译 / 测试】"
	@echo "    make build             编译合约"
	@echo "    make test              运行测试"
	@echo "    make coverage          生成覆盖率报告"
	@echo ""
	@echo "  【部署】"
	@echo "    make deploy-local      部署到本地 Anvil"
	@echo "    make deploy-sepolia    部署到 Sepolia"
	@echo ""
	@echo "  【合约操作】"
	@echo "    make status            查看合约当前状态"
	@echo ""

# ── 编译 / 测试 ──────────────────────────────────────────────
build:
	forge build

test:
	forge test -vv

coverage:
	forge coverage

snapshot:
	forge snapshot

clean:
	forge clean

# ── 部署 ─────────────────────────────────────────────────────
deploy-local:
	forge script $(DEPLOY_SCRIPT) \
		--tc DeployScript \
		--rpc-url http://localhost:8545 \
		--private-key 0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80 \
		--broadcast \
		-vvvv

deploy-sepolia:
	forge script $(DEPLOY_SCRIPT) \
		--tc DeployScript \
		--rpc-url $(SEPOLIA_RPC_URL) \
		--account deployer \
		--sender $(DEPLOYER_ADDRESS) \
		--broadcast \
		--verify \
		-vvvv

# ── 查看状态 ──────────────────────────────────────────────────
status:
	@echo "--- 合约地址 ---"
	@echo "MockNFT:    $(MOCK_NFT_ADDRESS)"
	@echo "Auction:    $(AUCTION_ADDRESS)"

.PHONY: help build test coverage snapshot clean \
        deploy-local deploy-sepolia status
