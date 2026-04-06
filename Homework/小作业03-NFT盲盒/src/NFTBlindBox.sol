// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {ERC721Upgradeable} from "@openzeppelin/contracts-upgradeable/token/ERC721/ERC721Upgradeable.sol";
import {OwnableUpgradeable} from "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import {UUPSUpgradeable} from "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import {Initializable} from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import {VRFConsumerBaseV2} from "@chainlink/contracts/src/v0.8/vrf/VRFConsumerBaseV2.sol";
import {VRFCoordinatorV2Interface} from "@chainlink/contracts/src/v0.8/vrf/interfaces/VRFCoordinatorV2Interface.sol";
import {ISaleStrategy} from "./interfaces/ISaleStrategy.sol";
import {IRarityStrategy} from "./interfaces/IRarityStrategy.sol";
import {IMetadataStrategy} from "./interfaces/IMetadataStrategy.sol";
import {BlindBoxTypes} from "./interfaces/IBlindBoxTypes.sol";

/**
 * @title NFTBlindBox
 * @notice 支持 Chainlink VRF 随机揭示 + UUPS 可升级的 NFT 盲盒合约
 *
 * 架构设计（职责分离）：
 *
 *   本合约只负责「编排」核心流程：
 *     1. mint NFT
 *     2. 请求 VRF 随机数
 *     3. 存储随机数
 *     4. 揭示（计算稀有度 + 更新 tokenURI）
 *
 *   三个可插拔策略模块（均通过接口持有，无需 UUPS 升级即可替换）：
 *     - ISaleStrategy saleStrategy       → 谁能买、花多少钱（多阶段销售编排）
 *     - IRarityStrategy rarityStrategy   → 随机数如何映射到稀有度
 *     - IMetadataStrategy metadataStrategy → tokenURI 如何生成（IPFS/Arweave/链上SVG）
 *
 *   替换方式（均无需 UUPS 升级）：
 *     - 换销售规则（白名单→荷兰拍）：部署新阶段合约 + saleStrategy.registerPhase/activatePhase()
 *     - 换稀有度算法（一维→多维）：部署新合约 + setRarityStrategy()
 *     - 换存储方案（IPFS→Arweave）：部署新合约 + setMetadataStrategy()
 *     - Chainlink Automation 自动揭示：V2 override revealBlindBox()
 *
 * 核心流程：
 *   purchaseBlindBox()
 *     → saleStrategy.canPurchase() 校验
 *     → _safeMint()
 *     → saleStrategy.recordPurchase()
 *     → VRF requestRandomWords()
 *   fulfillRandomWords() [VRF 回调]
 *     → 存入 pendingRandomness
 *   revealBlindBox()
 *     → rarityStrategy.assignRarity() 计算稀有度
 *     → 存储稀有度 + 标记已揭示
 */
/// @custom:oz-upgrades-unsafe-allow constructor state-variable-immutable
contract NFTBlindBox is
    Initializable,
    ERC721Upgradeable,
    OwnableUpgradeable,
    UUPSUpgradeable,
    VRFConsumerBaseV2
{
    // ========== 类型引入 ==========

    // 直接使用 BlindBoxTypes 中的共享类型，避免重复定义
    // BlindBoxTypes.Rarity / BlindBoxTypes.BoxInfo

    // ========== Chainlink VRF 配置 ==========

    /// @custom:oz-upgrades-unsafe-allow state-variable-immutable
    VRFCoordinatorV2Interface private immutable i_vrfCoordinator;
    bytes32 private s_keyHash;
    uint64 private s_subscriptionId;
    uint16 private constant REQUEST_CONFIRMATIONS = 3;
    uint32 private constant NUM_WORDS = 1;
    uint32 public callbackGasLimit; // 实际初始值在 initialize() 中赋值；可由 owner 调整，防止 override 后 out of gas

    // ========== 策略模块（核心可替换点） ==========

    ISaleStrategy public saleStrategy; // 销售规则策略
    IRarityStrategy public rarityStrategy; // 稀有度算法策略
    IMetadataStrategy public metadataStrategy; // 元数据 URI 生成策略

    // ========== NFT 核心状态 ==========

    uint256 public maxSupply;
    uint256 private _nextTokenId;

    mapping(uint256 => BlindBoxTypes.BoxInfo) public boxInfos; // tokenId => 盲盒信息
    mapping(uint256 => uint256) public vrfRequestToToken; // requestId => tokenId（反向索引，独立存储）

    // ========== 事件 ==========

    event BlindBoxPurchased(address indexed buyer, uint256 indexed tokenId);
    event BlindBoxRevealed(
        uint256 indexed tokenId,
        BlindBoxTypes.Rarity rarity
    );
    event VRFRequested(uint256 indexed requestId, uint256 indexed tokenId);
    event SaleStrategyUpdated(address indexed newStrategy);
    event RarityStrategyUpdated(address indexed newStrategy);
    event MetadataStrategyUpdated(address indexed newStrategy);
    event Withdrawn(address indexed to, uint256 amount);

    // ========== 错误 ==========

    error MaxSupplyReached();
    error AlreadyRevealed();
    error RandomnessNotReady();
    error NotTokenOwner();
    error WithdrawFailed();
    error InvalidStrategy();

    // ========== 构造函数（仅初始化 VRFConsumerBaseV2，不做业务初始化） ==========

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor(address vrfCoordinator) VRFConsumerBaseV2(vrfCoordinator) {
        i_vrfCoordinator = VRFCoordinatorV2Interface(vrfCoordinator);
        _disableInitializers();
    }

    // ========== 初始化（替代 constructor，只能调用一次） ==========

    function initialize(
        string memory name,
        string memory symbol,
        bytes32 keyHash,
        uint64 subscriptionId,
        uint256 _maxSupply,
        address _saleStrategy,
        address _rarityStrategy,
        address _metadataStrategy
    ) external initializer {
        __ERC721_init(name, symbol);
        __Ownable_init(msg.sender);

        s_keyHash = keyHash;
        s_subscriptionId = subscriptionId;
        maxSupply = _maxSupply;
        callbackGasLimit = 100_000; // 声明时的默认值在 upgradeable 合约中不生效，必须在 initialize 里显式赋值

        if (_saleStrategy == address(0)) revert InvalidStrategy();
        if (_rarityStrategy == address(0)) revert InvalidStrategy();
        if (_metadataStrategy == address(0)) revert InvalidStrategy();
        saleStrategy = ISaleStrategy(_saleStrategy);
        rarityStrategy = IRarityStrategy(_rarityStrategy);
        metadataStrategy = IMetadataStrategy(_metadataStrategy);
    }

    // ========== UUPS 升级授权 ==========

    function _authorizeUpgrade(
        address newImplementation
    ) internal override onlyOwner {}

    // ========== 策略替换（无需 UUPS 升级） ==========

    function setSaleStrategy(address _saleStrategy) external onlyOwner {
        if (_saleStrategy == address(0)) revert InvalidStrategy();
        if (
            !ISaleStrategy(_saleStrategy).supportsInterface(
                type(ISaleStrategy).interfaceId
            )
        ) revert InvalidStrategy();
        saleStrategy = ISaleStrategy(_saleStrategy);
        emit SaleStrategyUpdated(_saleStrategy);
    }

    function setRarityStrategy(address _rarityStrategy) external onlyOwner {
        if (_rarityStrategy == address(0)) revert InvalidStrategy();
        if (
            !IRarityStrategy(_rarityStrategy).supportsInterface(
                type(IRarityStrategy).interfaceId
            )
        ) revert InvalidStrategy();
        rarityStrategy = IRarityStrategy(_rarityStrategy);
        emit RarityStrategyUpdated(_rarityStrategy);
    }

    function setMetadataStrategy(address _metadataStrategy) external onlyOwner {
        if (_metadataStrategy == address(0)) revert InvalidStrategy();
        if (
            !IMetadataStrategy(_metadataStrategy).supportsInterface(
                type(IMetadataStrategy).interfaceId
            )
        ) revert InvalidStrategy();
        metadataStrategy = IMetadataStrategy(_metadataStrategy);
        emit MetadataStrategyUpdated(_metadataStrategy);
    }

    /// @notice 调整 VRF 回调 gas 上限（当 fulfillRandomWords 逻辑变重时需要提高）
    function setCallbackGasLimit(uint32 gasLimit) external onlyOwner {
        callbackGasLimit = gasLimit;
    }

    // ========== 核心业务：购买盲盒 ==========

    /**
     * @notice 购买盲盒
     * 流程：策略校验 → 供应量校验 → mint NFT → 记录购买 → 发起 VRF 请求
     *
     * 注意"记录购买"在 mint 之后：遵循 CEI（Check-Effects-Interactions）模式，
     * 先改本合约状态（mint），再和外部策略合约交互（recordPurchase）
     */
    function purchaseBlindBox() external payable virtual {
        _doPurchase();
    }

    /**
     * @dev 购买核心逻辑，提取为 internal 以允许子合约通过 _doPurchase() 复用
     * external 函数无法用 super 调用，因此通过 internal 函数传递逻辑
     */
    function _doPurchase() internal virtual {
        // Check：canPurchase 内部直接 revert，无需检查返回值
        saleStrategy.canPurchase(msg.sender, msg.value);
        if (_nextTokenId >= maxSupply) revert MaxSupplyReached();

        // Effect
        uint256 tokenId = _nextTokenId++;
        _mint(msg.sender, tokenId);

        // Interaction
        saleStrategy.recordPurchase(msg.sender);

        uint256 requestId = i_vrfCoordinator.requestRandomWords(
            s_keyHash,
            s_subscriptionId,
            REQUEST_CONFIRMATIONS,
            callbackGasLimit,
            NUM_WORDS
        );
        vrfRequestToToken[requestId] = tokenId;

        emit VRFRequested(requestId, tokenId);
        emit BlindBoxPurchased(msg.sender, tokenId);
    }

    // ========== Chainlink VRF 回调 ==========

    /**
     * @notice Chainlink 节点调用此函数返回随机数
     * @dev 只能被 VRFCoordinator 调用（VRFConsumerBaseV2 内部已校验），
     *      将随机数存入 pendingRandomness 等待用户/Automation 触发揭示
     */
    function fulfillRandomWords(
        uint256 requestId,
        uint256[] memory randomWords
    ) internal override {
        uint256 tokenId = vrfRequestToToken[requestId];
        // 防止 VRFCoordinator 对同一 requestId 重复回调（极少见但理论上可能）
        if (boxInfos[tokenId].vrfFulfilled) return;
        boxInfos[tokenId].pendingRandomness = randomWords[0];
        boxInfos[tokenId].vrfFulfilled = true;
    }

    // ========== 核心业务：揭示盲盒 ==========

    /**
     * @notice 揭示盲盒，根据随机数分配稀有度
     * @param tokenId 要揭示的 token
     * 流程：校验持有者 → 校验未揭示 → 校验随机数已到达 → 委托策略计算稀有度 → 标记已揭示
     *
     * 声明 virtual：V2 可 override 实现 Chainlink Automation 批量自动揭示
     */
    function revealBlindBox(uint256 tokenId) external virtual {
        _doReveal(tokenId);
    }

    function _doReveal(uint256 tokenId) internal virtual {
        // 校验当前持有者，支持 token 转让后由新 owner 揭示
        // 场景：A 购买盲盒 → VRF 回调 → A 转让给 B → B 调用 revealBlindBox → 正常揭示
        if (ownerOf(tokenId) != msg.sender) revert NotTokenOwner();
        BlindBoxTypes.BoxInfo storage box = boxInfos[tokenId];
        if (box.isRevealed) revert AlreadyRevealed();
        if (!box.vrfFulfilled) revert RandomnessNotReady();

        BlindBoxTypes.Rarity rarity = rarityStrategy.assignRarity(box);
        box.rarity = rarity;
        box.isRevealed = true;
        box.pendingRandomness = 0;

        emit BlindBoxRevealed(tokenId, rarity);
    }

    // ========== 元数据 ==========

    /**
     * @notice 动态返回 URI，完全委托给 metadataStrategy
     * @dev 主合约只负责传入 token 的当前状态（是否揭示、稀有度），
     *      具体的 URI 格式由策略合约决定，主合约不感知 IPFS/Arweave/链上SVG 的差异
     */
    function tokenURI(
        uint256 tokenId
    ) public view override returns (string memory) {
        _requireOwned(tokenId);
        BlindBoxTypes.BoxInfo storage box = boxInfos[tokenId];
        return
            metadataStrategy.getTokenURI(
                tokenId,
                box.isRevealed,
                uint8(box.rarity)
            );
    }

    // URI 管理（setBlindBoxURI / setBaseTokenURI）已移至各 MetadataStrategy 合约
    // 如需修改 URI，直接调用对应策略合约的管理函数

    // ========== 提款 ==========

    /// @notice owner 提取合约内 ETH 到指定地址
    /// @param to 接收地址，方便直接提款到多签或冷钱包，而无需二次转账
    function withdraw(address payable to) external onlyOwner {
        if (to == address(0)) revert WithdrawFailed();
        uint256 balance = address(this).balance;
        if (balance == 0) revert WithdrawFailed();
        (bool success, ) = to.call{value: balance}("");
        if (!success) revert WithdrawFailed();
        emit Withdrawn(to, balance);
    }

    // ========== 查询辅助 ==========

    function totalSupply() external view returns (uint256) {
        return _nextTokenId;
    }

    // ========== 存储间隙（UUPS 升级安全） ==========
    // 本合约层（NFTBlindBox）自身声明的变量（immutable 不占槽）：
    //   s_keyHash(1) + s_subscriptionId/callbackGasLimit pack(1) + saleStrategy(1)
    //   + rarityStrategy(1) + metadataStrategy(1) + maxSupply(1) + _nextTokenId(1)
    //   + boxInfos(1) + vrfRequestToToken(1) = 9 个槽
    // 注：boxInfos 的值（BoxInfo struct）已优化为 2 槽（Rarity+bool+bool 打包 + uint256），
    //     每次 mint 比旧版少一次 SSTORE，但 mapping 变量本身仍占 1 个状态槽。
    // 约定本层总槽数 = 50，__gap = 50 - 9 = 41
    // 每次在 V1 追加新状态变量，相应减少 __gap 长度
    uint256[41] private __gap;
}
