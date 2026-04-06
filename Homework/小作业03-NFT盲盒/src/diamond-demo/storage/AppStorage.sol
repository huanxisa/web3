// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

/**
 * @title AppStorage
 * @notice Diamond 模式的「共享命名空间存储」
 *
 * ─── 为什么要用命名空间存储？ ───────────────────────────────────────────────
 *
 * 普通合约的变量按声明顺序分配槽位（槽0、槽1…），多个 Facet 各自声明变量会冲突。
 *
 * 命名空间存储的解决方案：
 *   把所有共享变量打包成一个 struct，
 *   然后通过 keccak256 哈希值确定这个 struct 在存储里的起始位置。
 *   两个不同 library 的哈希值在 2^256 的空间里几乎不可能碰撞，
 *   因此每个 Facet 的存储空间天然隔离。
 *
 * ─── 哪些变量放这里？ ──────────────────────────────────────────────────────
 *
 * 放「多个 Facet 都需要访问」的共享状态：
 *   - owner          →  OwnerFacet 写入，CounterFacet 读取做权限校验
 *   - count          →  CounterFacet 读写，外部查询 Facet 读取
 *
 * 只有一个 Facet 用的私有变量，放在该 Facet 自己的 Storage library 里。
 */
library AppStorage {
    // ─── 命名空间槽位 ────────────────────────────────────────────────────────
    //
    // 公式：keccak256(abi.encode(uint256(keccak256("diamond.app.storage")) - 1)) & ~bytes32(uint256(0xff))
    //
    // 这个公式来自 ERC-7201 标准，目的是：
    //   1. keccak256("diamond.app.storage") → 得到一个哈希
    //   2. - 1                              → 防止和某些特殊值碰撞
    //   3. & ~bytes32(0xff)                 → 末尾 32 位清零，为 struct 内的字段留连续空间
    //
    // 实际项目里这个值用工具预先计算好，硬编码进来（避免运行时计算 gas）
    bytes32 private constant SLOT = keccak256("diamond.app.storage.v1");

    // ─── 共享数据结构 ─────────────────────────────────────────────────────────
    struct Layout {
        address owner;   // 合约所有者，由 OwnerFacet 管理
        uint256 count;   // 计数器，由 CounterFacet 管理
    }

    // ─── 核心魔法：把 struct 定位到哈希槽 ────────────────────────────────────
    //
    // 返回一个指向 Layout 的 storage 引用，起始位置是 SLOT。
    //
    // 普通写法：  storage s = Layout(...)  → Solidity 自动分配槽 0、1…
    // 这里的写法：手动用汇编把 s.slot 设置为我们的哈希值
    //
    // 之后对 s.owner、s.count 的读写，
    // 实际操作的是 SLOT+0、SLOT+1 这两个槽，而不是槽 0、槽 1。
    function get() internal pure returns (Layout storage s) {
        bytes32 slot = SLOT;
        assembly {
            // slot 是我们的目标槽位
            // s.slot 是 storage 指针的槽位字段
            // 这行汇编 = "把 s 这个 storage 引用指向 slot 这个槽位"
            s.slot := slot
        }
    }
}
