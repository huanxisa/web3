package chain

import "math/big"

// bigIntFromUint64 是一个内部小工具，避免每次写 new(big.Int).SetUint64(x)
func bigIntFromUint64(x uint64) *big.Int { return new(big.Int).SetUint64(x) }
