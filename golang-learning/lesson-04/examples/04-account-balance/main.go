package main

import (
	"context"
	"flag"
	"fmt"
	"log"
	"math"
	"math/big"
	"os"
	"time"

	"github.com/ethereum/go-ethereum/common"
	"github.com/ethereum/go-ethereum/ethclient"
)

// 04-account-balance.go
// 1. 查询账户 ETH 余额（Wei 与 ETH）
// 2. 确认收款：--tx <hash> 时校验该笔支付已上链且成功，并可要求 N 个确认数
func main() {
	addrHex := flag.String("address", "", "account address (required)")
	blockNumber := flag.Int64("block", -1, "block number to query (-1 means latest)")
	txHashHex := flag.String("tx", "", "transaction hash: confirm this payment to me (use with --address)")
	minConfirmations := flag.Uint("confirmations", 1, "min block confirmations for --tx mode (0 = as soon as included)")
	flag.Parse()

	if *addrHex == "" {
		log.Fatal("missing --address flag")
	}

	rpcURL := os.Getenv("ETH_RPC_URL")
	if rpcURL == "" {
		log.Fatal("ETH_RPC_URL is not set")
	}

	ctx, cancel := context.WithTimeout(context.Background(), 15*time.Second)
	defer cancel()

	client, err := ethclient.DialContext(ctx, rpcURL)
	if err != nil {
		log.Fatalf("failed to connect to Ethereum node: %v", err)
	}
	defer client.Close()

	address := common.HexToAddress(*addrHex)

	// 模式：确认某笔交易是否已成功支付到本地址
	if *txHashHex != "" {
		confirmed, err := confirmPaymentToMe(ctx, client, *txHashHex, address, *minConfirmations)
		if err != nil {
			log.Fatalf("confirm payment: %v", err)
		}
		if confirmed {
			fmt.Println("Payment confirmed on-chain.")
		} else {
			log.Fatal("Payment not confirmed (pending, failed, or confirmations not met).")
		}
		return
	}

	// 模式：查询余额
	var blockNum *big.Int
	if *blockNumber >= 0 {
		blockNum = big.NewInt(*blockNumber)
	}

	balanceWei, err := client.BalanceAt(ctx, address, blockNum)
	if err != nil {
		log.Fatalf("failed to get balance: %v", err)
	}

	fmt.Println("=== Account Balance ===")
	fmt.Printf("Address     : %s\n", address.Hex())
	if blockNum == nil {
		fmt.Printf("Block       : latest\n")
	} else {
		fmt.Printf("Block       : %d\n", blockNum.Uint64())
	}
	fmt.Printf("Balance Wei : %s\n", balanceWei.String())

	balanceEth := weiToEth(balanceWei)
	fmt.Printf("Balance ETH : %s\n", balanceEth.Text('f', 6))
}

// confirmPaymentToMe 确认「这笔交易」已上链且成功，且收款方是 me，并满足最小确认数。
// 返回 true 表示可视为最终确认；false 表示尚未满足（pending / 失败 / 确认数不足）。
func confirmPaymentToMe(ctx context.Context, client *ethclient.Client, txHashHex string, me common.Address, minConfirmations uint) (bool, error) {
	txHash := common.HexToHash(txHashHex)

	// 1. 交易必须存在且已进块（非 pending）
	tx, isPending, err := client.TransactionByHash(ctx, txHash)
	if err != nil {
		return false, fmt.Errorf("transaction not found: %w", err)
	}
	if isPending {
		fmt.Println("Transaction is still pending (not yet in a block).")
		return false, nil
	}

	// 2. 必须有回执且执行成功（Status == 1）
	receipt, err := client.TransactionReceipt(ctx, txHash)
	if err != nil {
		return false, fmt.Errorf("receipt not available (tx may still be pending): %w", err)
	}
	if receipt.Status != 1 {
		fmt.Println("Transaction was included but reverted (Status != success).")
		return false, nil
	}

	// 3. 本笔为原生 ETH 转账时，收款方必须是 me（合约调用等需另解析 logs）
	if tx.To() != nil && *tx.To() != me {
		fmt.Printf("Transaction recipient is %s, not me %s.\n", tx.To().Hex(), me.Hex())
		return false, nil
	}
	if tx.To() == nil {
		fmt.Println("Transaction is contract creation, not a direct transfer to address.")
		return false, nil
	}

	// 4. 确认数：当前链头高度 - 交易所在块高度 >= minConfirmations
	if minConfirmations > 0 {
		header, err := client.HeaderByNumber(ctx, nil)
		if err != nil {
			return false, fmt.Errorf("failed to get latest block: %w", err)
		}
		confirmations := header.Number.Uint64() - receipt.BlockNumber.Uint64()
		if confirmations < uint64(minConfirmations) {
			fmt.Printf("Confirmations %d < required %d.\n", confirmations, minConfirmations)
			return false, nil
		}
	}

	// 全部通过：已上链、成功、收款方是我、确认数满足
	fmt.Printf("Tx %s: value %s wei to %s, block %d, confirmations met.\n",
		tx.Hash().Hex(), tx.Value().String(), tx.To().Hex(), receipt.BlockNumber.Uint64())
	return true, nil
}

func weiToEth(wei *big.Int) *big.Float {
	fWei := new(big.Float).SetInt(wei)
	ethValue := new(big.Float).Quo(fWei, big.NewFloat(math.Pow10(18)))
	return ethValue
}

