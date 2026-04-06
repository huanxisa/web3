# 加载 .env 文件中的环境变量，并导出为子进程环境变量
-include .env
export PRIVATE_KEY SEPOLIA_RPC_URL ETHERSCAN_API_KEY

# ============================================================
# 常量
# ============================================================

ANVIL_PRIVATE_KEY := 0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80
DEPLOY_SCRIPT     := script/Deploy.s.sol

# ============================================================
# 本地开发（Anvil）
# ============================================================

anvil:
	anvil

deploy-local:
	forge script $(DEPLOY_SCRIPT) \
		--rpc-url http://localhost:8545 \
		--private-key $(ANVIL_PRIVATE_KEY) \
		--broadcast \
		-vvvv

# ============================================================
# 测试网（Sepolia）
# ============================================================

deploy-sepolia:
	forge script $(DEPLOY_SCRIPT) \
		--rpc-url $(SEPOLIA_RPC_URL) \
		--account deployer \
		--broadcast \
		--verify \
		-vvvv

# ============================================================
# 常用命令
# ============================================================

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

.PHONY: anvil deploy-local deploy-sepolia build test coverage snapshot clean
