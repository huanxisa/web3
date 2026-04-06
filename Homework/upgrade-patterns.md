# 合约升级模式：ERC-7201 vs Diamond

## 核心区别

| 维度 | ERC-7201 Namespaced Storage | Diamond (EIP-2535) |
|------|-----------------------------|--------------------|
| 解决的问题 | 存储槽冲突 / 取消 `__gap` | 合约体积限制 / 模块化升级 |
| 代理结构 | 单代理 + 单实现 | 单代理 + 多实现（Facet） |
| 升级粒度 | 整个实现合约一起换 | 可以只换某个功能模块 |
| 复杂度 | 低，改造成本小 | 高，需要维护函数选择器路由表 |
| 适用场景 | 大多数 UUPS/透明代理项目 | 超大合约、需要精细化模块升级 |

---

## ERC-7201 Namespaced Storage

### 原理

把所有状态变量放进一个 struct，用 `keccak256` 派生一个固定的存储槽地址来存放这个 struct。
不同合约用不同的命名空间，槽地址天然隔离，彻底消除继承链中的槽位冲突，不再需要 `__gap`。

槽地址计算公式：
```
slot = keccak256(abi.encode(uint256(keccak256("命名空间字符串")) - 1)) & ~bytes32(uint256(0xff))
```
末尾 `& ~0xff` 是为了让 struct 从一个对齐的槽开始，避免 struct 内部的 slot 和其他变量碰撞。

### 完整代码

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {ERC721Upgradeable} from "@openzeppelin/contracts-upgradeable/token/ERC721/ERC721Upgradeable.sol";
import {OwnableUpgradeable} from "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import {UUPSUpgradeable} from "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import {Initializable} from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

contract NFTBlindBoxNS is
    Initializable,
    ERC721Upgradeable,
    OwnableUpgradeable,
    UUPSUpgradeable
{
    // ── 1. 定义命名空间存储结构 ──────────────────────────────────────────
    //
    // @custom:storage-location erc7201:nftblindbox.main
    // 这个注解告诉 OZ Upgrades Plugin 用 ERC-7201 规则校验此 struct 的存储位置
    struct MainStorage {
        uint256 maxSupply;
        uint256 nextTokenId;
        mapping(uint256 => uint8) tokenRarity;
        mapping(uint256 => bool) isRevealed;
    }

    // ── 2. 计算固定槽地址 ────────────────────────────────────────────────
    //
    // keccak256("nftblindbox.main") = 0x...（编译期常量）
    // 减 1 再 & ~0xff 是 ERC-7201 规范要求的对齐操作
    bytes32 private constant MAIN_STORAGE_SLOT =
        0x8a3e4c2f1d6b5a9e7c0f3d2b1a4e8c6f9d0b3a2e5c8f1d4b7a0e3c6f9d2b5a800;
    //  ↑ 实际值用下面的方式生成，这里仅示意

    // 生成方式（可在测试或脚本中验证）：
    // bytes32 slot = keccak256(
    //     abi.encode(uint256(keccak256("nftblindbox.main")) - 1)
    // ) & ~bytes32(uint256(0xff));

    // ── 3. 存储访问器（internal pure，零 gas 开销）────────────────────────
    //
    // 用 assembly 直接把 slot 地址赋给 storage pointer
    // 这是 ERC-7201 的标准访问模式
    function _getMainStorage() private pure returns (MainStorage storage $) {
        assembly {
            $.slot := MAIN_STORAGE_SLOT
        }
    }

    // ── 4. 初始化 ────────────────────────────────────────────────────────
    function initialize(
        string memory name,
        string memory symbol,
        uint256 maxSupply_
    ) external initializer {
        __ERC721_init(name, symbol);
        __Ownable_init(msg.sender);

        // 通过访问器读写，不直接操作状态变量
        MainStorage storage $ = _getMainStorage();
        $.maxSupply = maxSupply_;
    }

    // ── 5. 业务函数 ──────────────────────────────────────────────────────
    function mint() external {
        MainStorage storage $ = _getMainStorage();
        require($.nextTokenId < $.maxSupply, "Max supply reached");
        uint256 tokenId = $.nextTokenId++;
        _mint(msg.sender, tokenId);
    }

    function _authorizeUpgrade(address) internal override onlyOwner {}

    // ── 6. 升级到 V2 时，直接在 struct 末尾追加新字段 ────────────────────
    //
    // struct MainStorage {
    //     uint256 maxSupply;
    //     uint256 nextTokenId;
    //     mapping(uint256 => uint8) tokenRarity;
    //     mapping(uint256 => bool) isRevealed;
    //     uint256 newFieldInV2;   // ← 直接追加，不需要动 __gap
    // }
    //
    // 已有字段的槽位不变，新字段追加在后面，天然安全
}
```

### 关键点总结

- `_getMainStorage()` 是唯一访问入口，所有读写都通过它
- struct 内追加字段 = V2 升级，不需要 `__gap`，不需要手动计算槽位
- OZ v5 的 `ERC721Upgradeable` 等合约内部已全部采用此模式

---

## Diamond 模式（EIP-2535）

### 原理

一个 Diamond 代理合约持有一张**函数选择器 → Facet 合约地址**的路由表。
调用任意函数时，代理查表找到对应的 Facet，用 `delegatecall` 转发执行。
升级时只需要替换某个 Facet，其他模块不受影响。

```
用户调用 diamond.transfer()
    ↓
Diamond 查路由表：transfer.selector → TokenFacet 地址
    ↓
delegatecall TokenFacet.transfer()（在 Diamond 的存储上执行）
```

### 完整代码

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

// ── 1. 存储布局（所有 Facet 共享同一个 Diamond 的存储）────────────────────

library DiamondStorage {
    // 每个功能模块用独立命名空间，避免 Facet 之间槽位冲突
    // 这里 Diamond 本身的路由表用一个固定槽
    bytes32 constant DIAMOND_STORAGE_SLOT =
        keccak256("diamond.standard.diamond.storage");

    struct FacetAddressAndPosition {
        address facetAddress;
        uint96 functionSelectorPosition; // Facet 内的函数选择器索引
    }

    struct DiamondStorageData {
        // 函数选择器 → Facet 地址+位置
        mapping(bytes4 => FacetAddressAndPosition) selectorToFacetAndPosition;
        // 所有已注册的函数选择器列表
        bytes4[] selectors;
        // owner
        address contractOwner;
    }

    function getStorage() internal pure returns (DiamondStorageData storage ds) {
        bytes32 slot = DIAMOND_STORAGE_SLOT;
        assembly {
            ds.slot := slot
        }
    }
}

// ── 2. Diamond 代理合约 ──────────────────────────────────────────────────

contract Diamond {
    constructor(address owner_) {
        DiamondStorage.getStorage().contractOwner = owner_;
    }

    // 核心：fallback 查路由表，delegatecall 对应 Facet
    fallback() external payable {
        DiamondStorage.DiamondStorageData storage ds = DiamondStorage.getStorage();
        address facet = ds.selectorToFacetAndPosition[msg.sig].facetAddress;
        require(facet != address(0), "Diamond: function not found");

        assembly {
            // 把调用数据复制到内存，delegatecall 到 Facet
            calldatacopy(0, 0, calldatasize())
            let result := delegatecall(gas(), facet, 0, calldatasize(), 0, 0)
            returndatacopy(0, 0, returndatasize())
            switch result
            case 0 { revert(0, returndatasize()) }
            default { return(0, returndatasize()) }
        }
    }

    receive() external payable {}
}

// ── 3. DiamondCut Facet（管理路由表的特殊 Facet）────────────────────────

interface IDiamondCut {
    enum FacetCutAction { Add, Replace, Remove }

    struct FacetCut {
        address facetAddress;
        FacetCutAction action;
        bytes4[] functionSelectors;
    }

    function diamondCut(FacetCut[] calldata cuts, address init, bytes calldata data) external;
}

contract DiamondCutFacet is IDiamondCut {
    // 只有 owner 可以修改路由表
    modifier onlyOwner() {
        require(
            msg.sender == DiamondStorage.getStorage().contractOwner,
            "DiamondCut: not owner"
        );
        _;
    }

    // 升级入口：增加/替换/删除函数选择器
    function diamondCut(
        FacetCut[] calldata cuts,
        address init,
        bytes calldata data
    ) external override onlyOwner {
        DiamondStorage.DiamondStorageData storage ds = DiamondStorage.getStorage();

        for (uint256 i = 0; i < cuts.length; i++) {
            FacetCut calldata cut = cuts[i];

            if (cut.action == FacetCutAction.Add) {
                // 注册新函数选择器 → Facet 地址
                for (uint256 j = 0; j < cut.functionSelectors.length; j++) {
                    bytes4 sel = cut.functionSelectors[j];
                    require(
                        ds.selectorToFacetAndPosition[sel].facetAddress == address(0),
                        "DiamondCut: selector already exists"
                    );
                    ds.selectorToFacetAndPosition[sel].facetAddress = cut.facetAddress;
                    ds.selectors.push(sel);
                }
            } else if (cut.action == FacetCutAction.Replace) {
                // 替换已有选择器指向的 Facet（= 升级某个模块）
                for (uint256 j = 0; j < cut.functionSelectors.length; j++) {
                    bytes4 sel = cut.functionSelectors[j];
                    require(
                        ds.selectorToFacetAndPosition[sel].facetAddress != address(0),
                        "DiamondCut: selector not found"
                    );
                    ds.selectorToFacetAndPosition[sel].facetAddress = cut.facetAddress;
                }
            } else {
                // 删除选择器
                for (uint256 j = 0; j < cut.functionSelectors.length; j++) {
                    delete ds.selectorToFacetAndPosition[cut.functionSelectors[j]];
                }
            }
        }

        // 可选：升级后执行初始化逻辑
        if (init != address(0)) {
            (bool ok,) = init.delegatecall(data);
            require(ok, "DiamondCut: init failed");
        }
    }
}

// ── 4. 业务 Facet 示例（NFT 铸造模块）──────────────────────────────────

// 每个 Facet 用自己的命名空间存储，不和其他 Facet 冲突
library NFTFacetStorage {
    bytes32 constant SLOT = keccak256("nftblindbox.facet.nft");

    struct Data {
        uint256 maxSupply;
        uint256 nextTokenId;
        mapping(uint256 => address) owners; // 简化示意
    }

    function getStorage() internal pure returns (Data storage $) {
        bytes32 slot = SLOT;
        assembly { $.slot := slot }
    }
}

contract NFTFacet {
    function initialize(uint256 maxSupply_) external {
        NFTFacetStorage.getStorage().maxSupply = maxSupply_;
    }

    function mint() external {
        NFTFacetStorage.Data storage $ = NFTFacetStorage.getStorage();
        require($.nextTokenId < $.maxSupply, "Max supply reached");
        uint256 tokenId = $.nextTokenId++;
        $.owners[tokenId] = msg.sender;
    }

    function ownerOf(uint256 tokenId) external view returns (address) {
        return NFTFacetStorage.getStorage().owners[tokenId];
    }
}

// ── 5. 升级示例：只替换 NFTFacet，其他模块不受影响 ──────────────────────
//
// NFTFacetV2 是新版本，只需要把 mint() 的选择器指向新地址
//
// IDiamondCut.FacetCut[] memory cuts = new IDiamondCut.FacetCut[](1);
// cuts[0] = IDiamondCut.FacetCut({
//     facetAddress: address(new NFTFacetV2()),
//     action: IDiamondCut.FacetCutAction.Replace,
//     functionSelectors: [NFTFacet.mint.selector, NFTFacet.ownerOf.selector]
// });
// IDiamondCut(diamondAddress).diamondCut(cuts, address(0), "");
```

### 关键点总结

- Diamond 代理本身不含业务逻辑，只有一个 `fallback` 做路由
- 每个 Facet 必须用命名空间存储（否则多个 Facet 会互相覆盖存储槽）
- 升级某个模块只需 `diamondCut` 替换对应选择器，其他模块零影响
- 复杂度高：需要维护选择器路由表，调试难度大

---

## 选型建议

```
合约 < 24KB，功能相对集中
    → UUPS + ERC-7201（简单、够用、OZ 原生支持）

合约 > 24KB，或需要独立升级不同功能模块
    → Diamond（复杂但灵活，适合大型协议）
```

实际项目中 Uniswap、AAVE 等大型协议用 Diamond，
大多数 NFT / 中小型 DeFi 项目用 UUPS + ERC-7201 就足够了。
