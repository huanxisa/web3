// Package chain 包装 go-ethereum 的 ethclient 与签名账户。
//
// 这一层只做 3 件事：
//  1. Dial RPC（HTTP 或 WS 都支持）
//  2. 解析私钥 → *ecdsa.PrivateKey + transactor (*bind.TransactOpts)
//  3. 暴露 *ethclient.Client 给上层 service 用
//
// 之所以放在独立包里：未来要支持多链时，只需要在这里加一个 multi-chain 池，
// 上层 service 不感知。这是 go-ethereum 项目的常见分层。
package chain

import (
	"context"
	"crypto/ecdsa"
	"fmt"

	"github.com/ethereum/go-ethereum/accounts/abi/bind"
	"github.com/ethereum/go-ethereum/common"
	"github.com/ethereum/go-ethereum/crypto"
	"github.com/ethereum/go-ethereum/ethclient"
)

type Client struct {
	Eth     *ethclient.Client
	ChainID uint64

	// 签名相关；如果 privateKey 为空，则只读模式
	priv       *ecdsa.PrivateKey
	addr       common.Address
	hasSigner  bool
}

func New(rpcURL, privateKey string) (*Client, error) {
	cli, err := ethclient.Dial(rpcURL)
	if err != nil {
		return nil, fmt.Errorf("dial rpc %s: %w", rpcURL, err)
	}
	chainID, err := cli.ChainID(context.Background())
	if err != nil {
		return nil, fmt.Errorf("get chainID: %w", err)
	}
	c := &Client{Eth: cli, ChainID: chainID.Uint64()}

	if privateKey != "" {
		priv, err := crypto.HexToECDSA(stripHex(privateKey))
		if err != nil {
			return nil, fmt.Errorf("parse private key: %w", err)
		}
		pub, ok := priv.Public().(*ecdsa.PublicKey)
		if !ok {
			return nil, fmt.Errorf("invalid public key cast")
		}
		c.priv = priv
		c.addr = crypto.PubkeyToAddress(*pub)
		c.hasSigner = true
	}
	return c, nil
}

// Address 返回当前签名账户地址；只读模式返回零地址。
func (c *Client) Address() common.Address { return c.addr }

// HasSigner 是否注入了私钥。
func (c *Client) HasSigner() bool { return c.hasSigner }

// Transactor 生成一个用于发交易的 TransactOpts（线程不安全；建议每次发送新建一个）。
//
// 注意：调用方应当后续手动设置 Nonce / GasLimit / Value / Context 等字段。
// 这里只完成最关键的签名器初始化。
func (c *Client) Transactor() (*bind.TransactOpts, error) {
	if !c.hasSigner {
		return nil, fmt.Errorf("client is read-only (no private key)")
	}
	opts, err := bind.NewKeyedTransactorWithChainID(c.priv, bigIntFromUint64(c.ChainID))
	if err != nil {
		return nil, fmt.Errorf("new keyed transactor: %w", err)
	}
	return opts, nil
}

// stripHex 去掉 0x 前缀
func stripHex(s string) string {
	if len(s) >= 2 && (s[:2] == "0x" || s[:2] == "0X") {
		return s[2:]
	}
	return s
}
