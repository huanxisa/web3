// 示例：同一把私钥的四种形态
// 运行：go run example_privatekey_formats.go（需在含 go-ethereum 的项目中）
package main

import (
	"fmt"
	"reflect"

	"github.com/ethereum/go-ethereum/crypto"
	"github.com/ethereum/go-ethereum/common/hexutil"
)

func main() {
	// 用一个固定的 hex 字符串，这样每次运行结果一致，方便对比
	hexStr := "ccec5314acec3d18eae81b6bd988b844fc4f7f7d3c828b351de6d0fede02d3f2"

	// ========== 1. privateKey：内存里的私钥对象 ==========
	privateKey, err := crypto.HexToECDSA(hexStr)
	if err != nil {
		panic(err)
	}

	fmt.Println("========== 同一把私钥的四种形态 ==========")
	fmt.Println()

	// 形态 1：*ecdsa.PrivateKey
	fmt.Println("【1】privateKey（私钥对象）")
	fmt.Printf("  类型: %v\n", reflect.TypeOf(privateKey))
	fmt.Printf("  内容: 结构体，包含曲线、D 等字段，不能直接打印\n")
	fmt.Printf("  用途: 签名、导出公钥/地址、转成 bytes\n")
	fmt.Println()

	// ========== 2. privateKeyBytes：字节切片 ==========
	privateKeyBytes := crypto.FromECDSA(privateKey)

	fmt.Println("【2】privateKeyBytes（私钥的字节形式）")
	fmt.Printf("  类型: %v\n", reflect.TypeOf(privateKeyBytes))
	fmt.Printf("  长度: %d 字节\n", len(privateKeyBytes))
	fmt.Printf("  内容: %v\n", privateKeyBytes)
	fmt.Printf("  用途: 二进制存储、哈希、再编码成 hex 等\n")
	fmt.Println()

	// ========== 3. hex 字符串（带 0x）==========
	hexWithPrefix := hexutil.Encode(privateKeyBytes)

	fmt.Println("【3】hexutil.Encode(privateKeyBytes)（带 0x 的 hex 字符串）")
	fmt.Printf("  类型: %v\n", reflect.TypeOf(hexWithPrefix))
	fmt.Printf("  内容: %q\n", hexWithPrefix)
	fmt.Printf("  用途: 以太坊里常见的「十六进制」写法，带 0x 前缀\n")
	fmt.Println()

	// ========== 4. hex 字符串（去掉 0x）==========
	hexNoPrefix := hexutil.Encode(privateKeyBytes)[2:]

	fmt.Println("【4】hexutil.Encode(privateKeyBytes)[2:]（去掉 0x 的 hex 字符串）")
	fmt.Printf("  类型: %v\n", reflect.TypeOf(hexNoPrefix))
	fmt.Printf("  内容: %q\n", hexNoPrefix)
	fmt.Printf("  用途: 配置/备份/粘贴用，也是 HexToECDSA 接受的格式\n")
	fmt.Println()

	// ========== 验证：从 hex 字符串恢复，得到同一个私钥 ==========
	recovered, _ := crypto.HexToECDSA(hexNoPrefix)
	recoveredBytes := crypto.FromECDSA(recovered)
	fmt.Println("========== 验证：用【4】恢复私钥再转 bytes，与【2】一致 ==========")
	fmt.Printf("  恢复后的 bytes 与 privateKeyBytes 相同: %v\n", string(recoveredBytes) == string(privateKeyBytes))
}
