-include .env
export ETHERSCAN_API_KEY SEPOLIA_RPC_URL VRF_SUBSCRIPTION_ID DEPLOYER_ADDRESS \
       PROXY_ADDRESS NFT_IMPL_ADDRESS \
       SALE_STRATEGY_ADDRESS WHITELIST_PHASE_ADDRESS PUBLIC_PHASE_ADDRESS RARITY_STRATEGY_ADDRESS \
       METADATA_ADDRESS \
       IMAGE_FOLDER_CID JSON_FOLDER_CID

ANVIL_PRIVATE_KEY := 0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80
DEPLOY_SCRIPT     := script/Deploy.s.sol
CAST_ARGS         := --account deployer --rpc-url $(SEPOLIA_RPC_URL)
READ_ARGS         := --rpc-url $(SEPOLIA_RPC_URL)

# ── 帮助 ──────────────────────────────────────────────────────
help:
	@echo ""
	@echo "  ┌─────────────────────────────────────────────────────────────┐"
	@echo "  │                   NFT 盲盒项目命令列表                      │"
	@echo "  └─────────────────────────────────────────────────────────────┘"
	@echo ""
	@echo "  【编译 / 测试】"
	@echo "    make build             编译所有合约"
	@echo "    make test              运行测试套件"
	@echo "    make coverage          生成测试覆盖率报告"
	@echo "    make snapshot          生成 gas 快照"
	@echo "    make clean             清理编译产物"
	@echo ""
	@echo "  【VRF 配置】"
	@echo "    make set-gas-limit GAS=<n>  调整 VRF 回调 gas 上限（默认 100000，降低可减少 LINK 预估用量）"
	@echo ""
	@echo "  【查看状态（只读，不消耗 gas）】"
	@echo "    make status            查看所有合约当前配置"
	@echo "    make my-nfts           查看当前账户持有的 NFT tokenId"
	@echo "    make token-uri ID=<n>  查看指定 tokenId 的 URI（需填 ID=）"
	@echo "    make reveal ID=<n>     揭示指定 tokenId 的盲盒（需填 ID=）"
	@echo ""
	@echo "  【部署】"
	@echo "    make deploy-local      部署到本地 Anvil"
	@echo "    make deploy-sepolia    部署到 Sepolia 测试网"
	@echo "    make upgrade-sepolia   升级到 V2"
	@echo ""
	@echo "  【销售阶段管理】"
	@echo "    make activate-whitelist  开启白名单销售阶段"
	@echo "    make activate-public     切换到公开销售阶段"
	@echo ""
	@echo "  【元数据更新】"
	@echo "    make deploy-metadata     部署新版元数据合约（合约逻辑变更时）"
	@echo "    make set-metadata-strategy  通知 Proxy 使用新元数据合约"
	@echo "    make update-uris         用 .env 里的 CID 更新链上两个 URI"
	@echo "    make replace-cids        替换本地 JSON 文件里的占位 CID"
	@echo ""
	@echo "  【存储布局检查】"
	@echo "    make storage-layout    查看合约存储槽分布"
	@echo "    make check-storage     升级兼容性检查"
	@echo ""

# ── 查看状态（只读）──────────────────────────────────────────
status:
	@echo ""
	@echo "  ── 核心合约 ────────────────────────────────────────────"
	@echo "  Proxy:            $(PROXY_ADDRESS)"
	@echo "  Implementation:   $(NFT_IMPL_ADDRESS)"
	@echo ""
	@echo "  ── 策略合约 ────────────────────────────────────────────"
	@echo "  SaleStrategy:     $(SALE_STRATEGY_ADDRESS)"
	@echo "  WhitelistPhase:   $(WHITELIST_PHASE_ADDRESS)"
	@echo "  PublicPhase:      $(PUBLIC_PHASE_ADDRESS)"
	@echo "  RarityStrategy:   $(RARITY_STRATEGY_ADDRESS)"
	@echo "  MetadataStrategy: $(METADATA_ADDRESS)"
	@echo ""
	@echo "  ── 链上读取 ────────────────────────────────────────────"
	@printf "  metadataStrategy: " && \
		cast call $(PROXY_ADDRESS) "metadataStrategy()(address)" $(READ_ARGS)
	@printf "  blindBoxURI:      " && \
		cast call $(METADATA_ADDRESS) "blindBoxURI()(string)" $(READ_ARGS)
	@printf "  baseTokenURI:     " && \
		cast call $(METADATA_ADDRESS) "baseTokenURI()(string)" $(READ_ARGS)
	@printf "  currentPhase:     " && \
		cast call $(SALE_STRATEGY_ADDRESS) "currentPhaseIndex()(uint256)" $(READ_ARGS)
	@printf "  totalSupply:      " && \
		cast call $(PROXY_ADDRESS) "totalSupply()(uint256)" $(READ_ARGS)
	@echo ""

# 查看指定 token 的 URI，用法: make token-uri ID=1
token-uri:
	@cast call $(PROXY_ADDRESS) "tokenURI(uint256)(string)" $(ID) $(READ_ARGS)

# 查询账户持有的 NFT 数量以及前 10 个 tokenId 的归属
my-nfts:
	@echo "--- $(DEPLOYER_ADDRESS) 持有数量 ---"
	@cast call $(PROXY_ADDRESS) "balanceOf(address)(uint256)" $(DEPLOYER_ADDRESS) $(READ_ARGS)
	@echo "--- 扫描 tokenId 0~9 的 owner ---"
	@for id in 0 1 2 3 4 5 6 7 8 9; do \
		owner=$$(cast call $(PROXY_ADDRESS) "ownerOf(uint256)(address)" $$id $(READ_ARGS) 2>/dev/null) && \
		echo "  tokenId $$id → $$owner" || true; \
	done

# 揭示盲盒，用法: make reveal ID=0
reveal:
	cast send $(PROXY_ADDRESS) \
		"revealBlindBox(uint256)" $(ID) \
		$(CAST_ARGS)

# ── VRF 配置 ─────────────────────────────────────────────────

# 调整回调 gas 上限（降低可减少 LINK 预估消耗，用法: make set-gas-limit GAS=50000）
set-gas-limit:
	cast send $(PROXY_ADDRESS) \
		"setCallbackGasLimit(uint32)" $(GAS) \
		$(CAST_ARGS)

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
		--private-key $(ANVIL_PRIVATE_KEY) \
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
		--ffi \
		-vvvv

upgrade-sepolia:
	forge script $(DEPLOY_SCRIPT) \
		--tc UpgradeToV2Script \
		--rpc-url $(SEPOLIA_RPC_URL) \
		--account deployer \
		--sender $(DEPLOYER_ADDRESS) \
		--broadcast \
		--verify \
		--ffi \
		-vvvv

# ── 元数据策略（修复 / 更新）────────────────────────────────

# 部署新版 SimpleIPFSMetadata（合约逻辑变更时使用）
# 部署完成后将输出的地址填入 .env 的 METADATA_ADDRESS，再执行 set-metadata-strategy
deploy-metadata:
	forge create src/strategies/SimpleIPFSMetadata.sol:SimpleIPFSMetadata \
		$(CAST_ARGS) \
		--broadcast \
		--verify \
		--constructor-args \
			$(DEPLOYER_ADDRESS) \
			"ipfs://$(JSON_FOLDER_CID)/blindbox.json" \
			"ipfs://$(JSON_FOLDER_CID)"

# 通知 Proxy 切换到新 MetadataStrategy（deploy-metadata 后执行）
set-metadata-strategy:
	cast send $(PROXY_ADDRESS) \
		"setMetadataStrategy(address)" $(METADATA_ADDRESS) \
		$(CAST_ARGS)

# ── IPFS URI 更新（上传 Pinata 后执行）──────────────────────

# 更新盲盒占位 URI（揭示前显示）
set-blindbox-uri:
	cast send $(METADATA_ADDRESS) \
		"setBlindBoxURI(string)" "ipfs://$(JSON_FOLDER_CID)/blindbox.json" \
		$(CAST_ARGS)

# 更新揭示后 Base URI
set-base-uri:
	cast send $(METADATA_ADDRESS) \
		"setBaseTokenURI(string)" "ipfs://$(JSON_FOLDER_CID)" \
		$(CAST_ARGS)

# 一键更新两个 URI（上传完 IPFS 后的标准操作）
update-uris: set-blindbox-uri set-base-uri

# 替换 metadata/json/ 中的占位 CID（sed 本地替换，不上链）
replace-cids:
	sed -i '' 's/IMAGE_FOLDER_CID/$(IMAGE_FOLDER_CID)/g' metadata/json/*.json

# ── 销售阶段管理 ─────────────────────────────────────────────

# 激活白名单阶段（部署后手动操作）
activate-whitelist:
	cast send $(SALE_STRATEGY_ADDRESS) \
		"activatePhase(uint256)" 1 \
		$(CAST_ARGS)

# 切换到公售阶段
activate-public:
	cast send $(SALE_STRATEGY_ADDRESS) \
		"activatePhase(uint256)" 2 \
		$(CAST_ARGS)

# ── 存储布局检查 ─────────────────────────────────────────────

storage-layout:
	@echo "=== NFTBlindBox ===" && forge inspect src/NFTBlindBox.sol:NFTBlindBox storage-layout --pretty
	@echo "=== NFTBlindBoxV2 ===" && forge inspect src/NFTBlindBoxV2.sol:NFTBlindBoxV2 storage-layout --pretty

# 升级前兼容性检查（FROM=NFTBlindBox TO=NFTBlindBoxV3 make check-storage）
check-storage:
	forge script script/CheckStorageLayout.s.sol:CheckStorageLayoutScript -vv

.PHONY: help status token-uri my-nfts reveal set-gas-limit \
        build test coverage snapshot clean \
        deploy-local deploy-sepolia upgrade-sepolia \
        deploy-metadata set-metadata-strategy \
        set-blindbox-uri set-base-uri update-uris replace-cids \
        activate-whitelist activate-public \
        storage-layout check-storage
