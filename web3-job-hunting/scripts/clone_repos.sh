#!/usr/bin/env bash
# clone_repos.sh
# 一键 clone 12 个强业务项目的合约 + 后端 repo
#
# 用法：
#   bash scripts/clone_repos.sh                # clone 全部（约 2 GB）
#   bash scripts/clone_repos.sh --essential    # 只 clone 4 周冲刺必读（约 800 MB）
#   bash scripts/clone_repos.sh --w1           # 只 clone W1 必读（Uniswap V3）
#   bash scripts/clone_repos.sh --w2           # 只 clone W2 必读（Aave V3）
#   bash scripts/clone_repos.sh --w3           # 只 clone W3 必读（Maker + Lido）
#   bash scripts/clone_repos.sh --w4-pendle    # W4 选 Pendle
#   bash scripts/clone_repos.sh --w4-eigen     # W4 选 EigenLayer
#   bash scripts/clone_repos.sh --w4-gmx       # W4 选 GMX V2
#   bash scripts/clone_repos.sh --safe         # 加分：Safe（钱包岗杀手锏）
#
# === v2 GAP 项目（基于 884 命中岗位反推，业务方向 GAP）===
#   bash scripts/clone_repos.sh --gap-trading   # GAP-1: dYdX V4 + LMAX Disruptor（撮合引擎）
#   bash scripts/clone_repos.sh --gap-mpc       # GAP-2: tss-lib + multi-party-ecdsa + WalletConnect（MPC 钱包）
#   bash scripts/clone_repos.sh --gap-bridge    # GAP-3: LayerZero V2 + Wormhole（通用跨链桥）
#   bash scripts/clone_repos.sh --gap-indexer   # GAP-4: Erigon（链上 Indexer）
#   bash scripts/clone_repos.sh --gap-essential # GAP P0+P1 必读（dYdX + tss-lib + LayerZero + LMAX）
#
# 所有 repo 会被 clone 到 repos/ 目录下（已加入 .gitignore）

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
REPOS_DIR="${ROOT_DIR}/repos"

# 颜色
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
RED='\033[0;31m'
NC='\033[0m'

mkdir -p "${REPOS_DIR}"/{dex,lending,stablecoin,derivatives,innovation,trading-engine,mpc-wallet,bridge,indexer}

# clone helper：跳过已存在的 repo
do_clone() {
    local url=$1
    local target=$2
    local full_path="${REPOS_DIR}/${target}"

    if [ -d "${full_path}/.git" ] || [ -d "${full_path}" -a -n "$(ls -A "${full_path}" 2>/dev/null)" ]; then
        echo -e "${YELLOW}[SKIP]${NC} ${target} already exists"
        return 0
    fi
    rm -rf "${full_path}"
    echo -e "${BLUE}[CLONE]${NC} ${url} -> ${target}"
    if git clone --depth=1 --quiet "${url}" "${full_path}" >/dev/null 2>&1; then
        local size
        size=$(du -sh "${full_path}" 2>/dev/null | awk '{print $1}')
        echo -e "${GREEN}[OK]${NC} ${target}  (${size})"
    else
        echo -e "${RED}[FAIL]${NC} ${target}"
        rm -rf "${full_path}"
    fi
    echo ""
}

clone_w1_uniswap() {
    echo -e "\n${GREEN}=== W1: Uniswap V3 ===${NC}"
    do_clone https://github.com/Uniswap/v3-core.git              dex/uniswap-v3-core
    do_clone https://github.com/Uniswap/v3-subgraph.git          dex/uniswap-v3-subgraph
}

clone_w1_uniswap_extra() {
    do_clone https://github.com/Uniswap/v3-periphery.git         dex/uniswap-v3-periphery
    do_clone https://github.com/Uniswap/v4-core.git              dex/uniswap-v4-core
}

clone_curve() {
    echo -e "\n${GREEN}=== Curve ===${NC}"
    do_clone https://github.com/curvefi/curve-contract.git       dex/curve-contract
    do_clone https://github.com/curvefi/stableswap-ng.git        dex/curve-stableswap-ng
}

clone_w2_aave() {
    echo -e "\n${GREEN}=== W2: Aave V3 ===${NC}"
    do_clone https://github.com/aave/aave-v3-core.git            lending/aave-v3-core
    do_clone https://github.com/aave/protocol-subgraphs.git      lending/aave-protocol-subgraphs
    do_clone https://github.com/aave/aave-utilities.git          lending/aave-utilities
}

clone_w3_maker() {
    echo -e "\n${GREEN}=== W3: MakerDAO ===${NC}"
    do_clone https://github.com/makerdao/dss.git                 stablecoin/makerdao-dss
    do_clone https://github.com/makerdao/dss-cdp-manager.git     stablecoin/makerdao-cdp-manager
    do_clone https://github.com/makerdao/auction-keeper.git      stablecoin/makerdao-auction-keeper
}

clone_w3_lido() {
    echo -e "\n${GREEN}=== W3: Lido ===${NC}"
    do_clone https://github.com/lidofinance/lido-dao.git         stablecoin/lido-dao
    do_clone https://github.com/lidofinance/lido-oracle.git      stablecoin/lido-oracle
    do_clone https://github.com/lidofinance/lido-subgraph.git    stablecoin/lido-subgraph
}

clone_ethena() {
    echo -e "\n${GREEN}=== Ethena USDe ===${NC}"
    do_clone https://github.com/ethena-labs/ethena.git           stablecoin/ethena
}

clone_w4_gmx() {
    echo -e "\n${GREEN}=== W4: GMX V2 ===${NC}"
    do_clone https://github.com/gmx-io/gmx-synthetics.git        derivatives/gmx-synthetics
    do_clone https://github.com/gmx-io/gmx-interface.git         derivatives/gmx-interface
}

clone_w4_pendle() {
    echo -e "\n${GREEN}=== W4: Pendle V2 ===${NC}"
    do_clone https://github.com/pendle-finance/pendle-core-v2-public.git  derivatives/pendle-core-v2
}

clone_w4_eigen() {
    echo -e "\n${GREEN}=== W4: EigenLayer ===${NC}"
    do_clone https://github.com/Layr-Labs/eigenlayer-contracts.git    innovation/eigenlayer-contracts
    do_clone https://github.com/Layr-Labs/eigenlayer-middleware.git   innovation/eigenlayer-middleware
    do_clone https://github.com/Layr-Labs/eigenda.git                 innovation/eigenda
    do_clone https://github.com/Layr-Labs/eigensdk-go.git             innovation/eigensdk-go
}

clone_safe() {
    echo -e "\n${GREEN}=== Safe（多签托管，钱包岗杀手锏） ===${NC}"
    do_clone https://github.com/safe-global/safe-smart-account.git      innovation/safe-smart-account
    do_clone https://github.com/safe-global/safe-modules.git            innovation/safe-modules
    do_clone https://github.com/safe-global/safe-transaction-service.git innovation/safe-transaction-service
    do_clone https://github.com/safe-global/safe-eth-py.git             innovation/safe-eth-py
}

clone_cctp() {
    echo -e "\n${GREEN}=== Circle CCTP ===${NC}"
    do_clone https://github.com/circlefin/evm-cctp-contracts.git    innovation/circle-evm-cctp
    do_clone https://github.com/circlefin/solana-cctp-contracts.git innovation/circle-solana-cctp
}

# ============== v2 GAP 项目 ==============
# GAP-1: 撮合引擎
clone_gap_trading() {
    echo -e "\n${GREEN}=== GAP-1: 撮合引擎（CEX Trading Engine）===${NC}"
    do_clone https://github.com/dydxprotocol/v4-chain.git           trading-engine/dydx-v4-chain
    do_clone https://github.com/LMAX-Exchange/disruptor.git         trading-engine/lmax-disruptor
}

# GAP-2: MPC 钱包后端
clone_gap_mpc() {
    echo -e "\n${GREEN}=== GAP-2: MPC 钱包后端（Custody / TSS）===${NC}"
    do_clone https://github.com/bnb-chain/tss-lib.git               mpc-wallet/binance-tss-lib
    do_clone https://github.com/ZenGo-X/multi-party-ecdsa.git       mpc-wallet/zengo-multi-party-ecdsa
    do_clone https://github.com/WalletConnect/walletconnect-monorepo.git  mpc-wallet/walletconnect-monorepo
    do_clone https://github.com/reown-com/reown-go.git              mpc-wallet/walletconnect-go-sdk
}

# GAP-3: 通用跨链桥
clone_gap_bridge() {
    echo -e "\n${GREEN}=== GAP-3: 通用跨链桥（LayerZero / Wormhole）===${NC}"
    do_clone https://github.com/LayerZero-Labs/LayerZero-v2.git     bridge/layerzero-v2
    do_clone https://github.com/wormhole-foundation/wormhole.git    bridge/wormhole
}

# GAP-4: 链上 Indexer 真后端
clone_gap_indexer() {
    echo -e "\n${GREEN}=== GAP-4: 链上 Indexer 真后端（Erigon）===${NC}"
    do_clone https://github.com/ledgerwatch/erigon.git              indexer/erigon
    # dYdX indexer 已含在 trading-engine/dydx-v4-chain 里
}

# GAP P0+P1 一键必读
clone_gap_essential() {
    echo -e "\n${GREEN}=== GAP 必读：dYdX V4 + tss-lib + LayerZero + LMAX ===${NC}"
    do_clone https://github.com/dydxprotocol/v4-chain.git           trading-engine/dydx-v4-chain
    do_clone https://github.com/bnb-chain/tss-lib.git               mpc-wallet/binance-tss-lib
    do_clone https://github.com/LayerZero-Labs/LayerZero-v2.git     bridge/layerzero-v2
    do_clone https://github.com/LMAX-Exchange/disruptor.git         trading-engine/lmax-disruptor
}

print_done() {
    echo -e "\n${GREEN}=========================================${NC}"
    echo -e "${GREEN}    Done. All repos under repos/${NC}"
    echo -e "${GREEN}=========================================${NC}"
    du -sh "${REPOS_DIR}" 2>/dev/null || true
}

# 入口
case "${1:-all}" in
    --w1)
        clone_w1_uniswap
        ;;
    --w2)
        clone_w2_aave
        ;;
    --w3)
        clone_w3_maker
        clone_w3_lido
        ;;
    --w4-pendle)
        clone_w4_pendle
        ;;
    --w4-eigen)
        clone_w4_eigen
        ;;
    --w4-gmx)
        clone_w4_gmx
        ;;
    --safe)
        clone_safe
        ;;
    --essential)
        clone_w1_uniswap
        clone_w2_aave
        clone_w3_maker
        clone_w3_lido
        clone_w4_pendle
        ;;
    --gap-trading)
        clone_gap_trading
        ;;
    --gap-mpc)
        clone_gap_mpc
        ;;
    --gap-bridge)
        clone_gap_bridge
        ;;
    --gap-indexer)
        clone_gap_indexer
        ;;
    --gap-essential)
        clone_gap_essential
        ;;
    all|--all|"")
        clone_w1_uniswap
        clone_w1_uniswap_extra
        clone_curve
        clone_w2_aave
        clone_w3_maker
        clone_w3_lido
        clone_ethena
        clone_w4_gmx
        clone_w4_pendle
        clone_w4_eigen
        clone_safe
        clone_cctp
        # v2 GAP
        clone_gap_trading
        clone_gap_mpc
        clone_gap_bridge
        clone_gap_indexer
        ;;
    *)
        echo "用法: $0 [--essential|--w1|--w2|--w3|--w4-pendle|--w4-eigen|--w4-gmx|--safe|--all]"
        echo "      [--gap-essential|--gap-trading|--gap-mpc|--gap-bridge|--gap-indexer]"
        exit 1
        ;;
esac

print_done
