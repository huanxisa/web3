// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Test, Vm} from "forge-std/Test.sol";
import {console} from "forge-std/console.sol";
import {NFTBlindBox} from "../src/NFTBlindBox.sol";
import {NFTBlindBoxV2} from "../src/NFTBlindBoxV2.sol";
import {MultiPhaseSaleStrategy} from "../src/strategies/MultiPhaseSaleStrategy.sol";
import {WhitelistPhase} from "../src/strategies/phases/WhitelistPhase.sol";
import {PublicPhase} from "../src/strategies/phases/PublicPhase.sol";
import {SimpleRarityStrategy} from "../src/strategies/SimpleRarityStrategy.sol";
import {SimpleIPFSMetadata} from "../src/strategies/SimpleIPFSMetadata.sol";
import {BlindBoxTypes} from "../src/interfaces/IBlindBoxTypes.sol";
import {ERC1967Proxy} from "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";
import {VRFCoordinatorV2Mock} from "@chainlink/contracts/src/v0.8/vrf/mocks/VRFCoordinatorV2Mock.sol";

// ============================================================
// 测试基类：部署完整的合约体系
// ============================================================
contract NFTBlindBoxTest is Test {
    // 合约
    NFTBlindBox internal nft;
    VRFCoordinatorV2Mock internal vrfCoordinator;
    MultiPhaseSaleStrategy internal saleStrategy;
    WhitelistPhase internal whitelistPhase;
    PublicPhase internal publicPhase;
    SimpleRarityStrategy internal rarityStrategy;
    SimpleIPFSMetadata internal metadataStrategy;

    // 阶段 ID
    uint256 internal whitelistPhaseId;
    uint256 internal publicPhaseId;

    // 账户
    address internal owner  = makeAddr("owner");
    address internal user1  = makeAddr("user1");
    address internal user2  = makeAddr("user2");

    // VRF 参数
    bytes32 internal constant KEY_HASH      = bytes32(uint256(1));
    uint96  internal constant BASE_FEE      = 0.1 ether;
    uint96  internal constant GAS_PRICE_LINK = 1e9;
    uint64  internal subscriptionId;

    // 价格
    uint256 internal constant WHITELIST_PRICE = 0.01 ether;
    uint256 internal constant PUBLIC_PRICE    = 0.02 ether;

    // URI
    string internal constant BLIND_URI   = "ipfs://blind/";
    string internal constant REVEAL_BASE = "ipfs://revealed";

    function setUp() public virtual {
        // 1. VRF Mock
        vrfCoordinator = new VRFCoordinatorV2Mock(BASE_FEE, GAS_PRICE_LINK);
        subscriptionId = vrfCoordinator.createSubscription();
        vrfCoordinator.fundSubscription(subscriptionId, 1000 ether);

        vm.startPrank(owner);

        // 2. 无状态策略
        rarityStrategy  = new SimpleRarityStrategy();
        metadataStrategy = new SimpleIPFSMetadata(owner, BLIND_URI, REVEAL_BASE);

        // 3. 销售编排器（nftContract 占位）
        saleStrategy = new MultiPhaseSaleStrategy(owner, address(0));

        // 4. 阶段合约 + 注册
        whitelistPhase  = new WhitelistPhase(owner, address(saleStrategy), WHITELIST_PRICE, 3);
        publicPhase     = new PublicPhase(owner, address(saleStrategy), PUBLIC_PRICE);
        whitelistPhaseId = saleStrategy.registerPhase(address(whitelistPhase));
        publicPhaseId    = saleStrategy.registerPhase(address(publicPhase));

        // 5. 部署 NFTBlindBox 实现 + 代理
        NFTBlindBox impl = new NFTBlindBox(address(vrfCoordinator));
        bytes memory initData = abi.encodeWithSelector(
            NFTBlindBox.initialize.selector,
            "NFT Blind Box", "NBB",
            KEY_HASH, subscriptionId,
            1000,
            address(saleStrategy),
            address(rarityStrategy),
            address(metadataStrategy)
        );
        ERC1967Proxy proxy = new ERC1967Proxy(address(impl), initData);
        nft = NFTBlindBox(address(proxy));

        // 6. 修正 nftContract
        saleStrategy.setNftContract(address(nft));

        vm.stopPrank();

        // 7. 注册 VRF 消费者 + 充值
        vrfCoordinator.addConsumer(subscriptionId, address(nft));
        vm.deal(user1, 10 ether);
        vm.deal(user2, 10 ether);
    }

    // ─── 辅助：激活白名单阶段 + 将 user 加入白名单 ─────────────────────
    function _activateWhitelist(address user) internal {
        vm.startPrank(owner);
        saleStrategy.activatePhase(whitelistPhaseId);
        address[] memory accounts = new address[](1);
        accounts[0] = user;
        whitelistPhase.addToWhitelist(accounts);
        vm.stopPrank();
    }

    // ─── 辅助：激活公售阶段 ─────────────────────────────────────────────
    function _activatePublic() internal {
        vm.prank(owner);
        saleStrategy.activatePhase(publicPhaseId);
    }

    // ─── 辅助：完整购买流程（user 在公售阶段购买，返回 requestId）─────────
    function _buyPublic(address user) internal returns (uint256 requestId) {
        _activatePublic();
        vm.recordLogs();
        vm.prank(user);
        nft.purchaseBlindBox{value: PUBLIC_PRICE}();
        // 从 VRFRequested 事件里取 requestId（topic[1]）
        Vm.Log[] memory logs = vm.getRecordedLogs();
        for (uint256 i = 0; i < logs.length; i++) {
            if (logs[i].topics[0] == NFTBlindBox.VRFRequested.selector) {
                requestId = uint256(logs[i].topics[1]);
                break;
            }
        }
    }

    // ─── 辅助：完整揭示流程 ─────────────────────────────────────────────
    function _revealToken(uint256 tokenId, uint256 requestId, address user) internal {
        vrfCoordinator.fulfillRandomWords(requestId, address(nft));
        vm.prank(user);
        nft.revealBlindBox(tokenId);
    }

    // ==================================================================
    // 初始状态
    // ==================================================================

    function test_InitialState() public view {
        assertEq(nft.name(), "NFT Blind Box");
        assertEq(nft.symbol(), "NBB");
        assertEq(nft.totalSupply(), 0);
        assertEq(nft.maxSupply(), 1000);
        assertEq(address(nft.saleStrategy()), address(saleStrategy));
        assertEq(address(nft.rarityStrategy()), address(rarityStrategy));
        assertEq(address(nft.metadataStrategy()), address(metadataStrategy));
        assertEq(saleStrategy.activePhaseId(), 0);
        assertEq(saleStrategy.phaseCount(), 2);
    }

    // ==================================================================
    // 白名单管理
    // ==================================================================

    function test_AddToWhitelist() public {
        address[] memory accounts = new address[](1);
        accounts[0] = user1;
        vm.prank(owner);
        whitelistPhase.addToWhitelist(accounts);
        assertTrue(whitelistPhase.whitelist(user1));
    }

    function test_RemoveFromWhitelist() public {
        address[] memory accounts = new address[](1);
        accounts[0] = user1;
        vm.startPrank(owner);
        whitelistPhase.addToWhitelist(accounts);
        whitelistPhase.removeFromWhitelist(accounts);
        vm.stopPrank();
        assertFalse(whitelistPhase.whitelist(user1));
    }

    // ==================================================================
    // 销售阶段管理
    // ==================================================================

    function test_ActivatePhase() public {
        vm.prank(owner);
        saleStrategy.activatePhase(whitelistPhaseId);
        assertEq(saleStrategy.activePhaseId(), whitelistPhaseId);
        assertEq(saleStrategy.activePhase(), address(whitelistPhase));
    }

    function test_SwitchPhase() public {
        vm.startPrank(owner);
        saleStrategy.activatePhase(whitelistPhaseId);
        saleStrategy.activatePhase(publicPhaseId);
        vm.stopPrank();
        assertEq(saleStrategy.activePhase(), address(publicPhase));
    }

    // ==================================================================
    // 购买失败场景
    // ==================================================================

    function test_PurchaseReverts_WhenNoActivePhase() public {
        vm.prank(user1);
        vm.expectRevert(MultiPhaseSaleStrategy.NoActivePhase.selector);
        nft.purchaseBlindBox{value: PUBLIC_PRICE}();
    }

    function test_PurchaseReverts_WhenGloballyPaused() public {
        vm.startPrank(owner);
        saleStrategy.activatePhase(publicPhaseId);
        saleStrategy.setPaused(true);
        vm.stopPrank();
        vm.prank(user1);
        vm.expectRevert(MultiPhaseSaleStrategy.SaleGloballyPaused.selector);
        nft.purchaseBlindBox{value: PUBLIC_PRICE}();
    }

    function test_PurchaseReverts_WhenNotWhitelisted() public {
        vm.prank(owner);
        saleStrategy.activatePhase(whitelistPhaseId);
        vm.prank(user1);
        vm.expectRevert(WhitelistPhase.NotWhitelisted.selector);
        nft.purchaseBlindBox{value: WHITELIST_PRICE}();
    }

    function test_PurchaseReverts_InsufficientPayment() public {
        _activateWhitelist(user1);
        vm.prank(user1);
        vm.expectRevert(
            abi.encodeWithSelector(WhitelistPhase.InsufficientPayment.selector, WHITELIST_PRICE, WHITELIST_PRICE - 1)
        );
        nft.purchaseBlindBox{value: WHITELIST_PRICE - 1}();
    }

    function test_PurchaseReverts_WalletLimitReached() public {
        _activateWhitelist(user1);
        vm.startPrank(user1);
        nft.purchaseBlindBox{value: WHITELIST_PRICE}();
        nft.purchaseBlindBox{value: WHITELIST_PRICE}();
        nft.purchaseBlindBox{value: WHITELIST_PRICE}(); // 达到上限 3
        vm.expectRevert(abi.encodeWithSelector(WhitelistPhase.WalletLimitReached.selector, uint256(3)));
        nft.purchaseBlindBox{value: WHITELIST_PRICE}();
        vm.stopPrank();
    }

    function test_PurchaseReverts_MaxSupply() public {
        // 用一个 maxSupply=2 的合约测试
        vm.startPrank(owner);
        NFTBlindBox impl2 = new NFTBlindBox(address(vrfCoordinator));
        MultiPhaseSaleStrategy sale2 = new MultiPhaseSaleStrategy(owner, address(0));
        PublicPhase pub2 = new PublicPhase(owner, address(sale2), PUBLIC_PRICE);
        sale2.registerPhase(address(pub2));
        bytes memory d = abi.encodeWithSelector(
            NFTBlindBox.initialize.selector,
            "T","T", KEY_HASH, subscriptionId, 2,
            address(sale2), address(rarityStrategy), address(metadataStrategy)
        );
        address p2 = address(new ERC1967Proxy(address(impl2), d));
        sale2.setNftContract(p2);
        sale2.activatePhase(1);
        vm.stopPrank();

        vrfCoordinator.addConsumer(subscriptionId, p2);
        vm.deal(user1, 10 ether);
        vm.startPrank(user1);
        NFTBlindBox(p2).purchaseBlindBox{value: PUBLIC_PRICE}();
        NFTBlindBox(p2).purchaseBlindBox{value: PUBLIC_PRICE}();
        vm.expectRevert(NFTBlindBox.MaxSupplyReached.selector);
        NFTBlindBox(p2).purchaseBlindBox{value: PUBLIC_PRICE}();
        vm.stopPrank();
    }

    // ==================================================================
    // 购买成功
    // ==================================================================

    function test_PurchaseBlindBox_Whitelist() public {
        _activateWhitelist(user1);
        vm.prank(user1);
        nft.purchaseBlindBox{value: WHITELIST_PRICE}();

        assertEq(nft.totalSupply(), 1);
        assertEq(nft.ownerOf(0), user1);
        (, bool isRevealed,,) = nft.boxInfos(0);
        assertFalse(isRevealed);
        assertEq(whitelistPhase.mintedPerWallet(user1), 1);
    }

    function test_PurchaseBlindBox_Public() public {
        _activatePublic();
        vm.prank(user1);
        nft.purchaseBlindBox{value: PUBLIC_PRICE}();

        assertEq(nft.totalSupply(), 1);
        assertEq(nft.ownerOf(0), user1);
    }

    function test_PurchaseBlindBox_EmitsEvents() public {
        _activatePublic();
        vm.expectEmit(true, true, false, false);
        emit NFTBlindBox.BlindBoxPurchased(user1, 0);
        vm.prank(user1);
        nft.purchaseBlindBox{value: PUBLIC_PRICE}();
    }

    // ==================================================================
    // VRF 回调 + 揭示
    // ==================================================================

    function test_RevealBlindBox() public {
        uint256 requestId = _buyPublic(user1);
        assertTrue(requestId > 0, "requestId should be captured");

        // 模拟 Chainlink 节点回调
        vrfCoordinator.fulfillRandomWords(requestId, address(nft));
        (,, bool fulfilled,) = nft.boxInfos(0);
        assertTrue(fulfilled, "VRF should be fulfilled");

        // 揭示
        vm.prank(user1);
        nft.revealBlindBox(0);

        (, bool revealed,,) = nft.boxInfos(0);
        assertTrue(revealed);
        // tokenURI 不再是盲盒占位图
        string memory uri = nft.tokenURI(0);
        assertFalse(_strEq(uri, BLIND_URI));
    }

    function test_RevealReverts_BeforeVRF() public {
        _buyPublic(user1);
        vm.prank(user1);
        vm.expectRevert(NFTBlindBox.RandomnessNotReady.selector);
        nft.revealBlindBox(0);
    }

    function test_RevealReverts_AlreadyRevealed() public {
        uint256 requestId = _buyPublic(user1);
        _revealToken(0, requestId, user1);
        vm.prank(user1);
        vm.expectRevert(NFTBlindBox.AlreadyRevealed.selector);
        nft.revealBlindBox(0);
    }

    function test_RevealReverts_NotTokenOwner() public {
        uint256 requestId = _buyPublic(user1);
        vrfCoordinator.fulfillRandomWords(requestId, address(nft));
        vm.prank(user2); // user2 不是 owner
        vm.expectRevert(NFTBlindBox.NotTokenOwner.selector);
        nft.revealBlindBox(0);
    }

    // ==================================================================
    // 稀有度分布（通过多次揭示验证概率大致正确）
    // ==================================================================

    function test_RarityDistribution() public {
        _activatePublic();
        uint256[5] memory counts;
        uint256 total = 100;

        for (uint256 i = 0; i < total; i++) {
            address buyer = address(uint160(i + 100));
            vm.deal(buyer, 1 ether);
            vm.prank(buyer);
            nft.purchaseBlindBox{value: PUBLIC_PRICE}();
            vrfCoordinator.fulfillRandomWords(i + 1, address(nft));
            vm.prank(buyer);
            nft.revealBlindBox(i);
            (BlindBoxTypes.Rarity rarity,,,) = nft.boxInfos(i);
            counts[uint256(rarity)]++;
        }

        // 概率验证（给较大容差，100 次采样）
        assertGt(counts[0], 30, "Common should be > 30%");   // 期望 50%
        assertGt(counts[1], 10, "Uncommon should be > 10%"); // 期望 25%
        assertGt(counts[2], 5,  "Rare should be > 5%");      // 期望 15%
        console.log("Common:", counts[0]);
        console.log("Uncommon:", counts[1]);
        console.log("Rare:", counts[2]);
        console.log("Epic:", counts[3]);
        console.log("Legendary:", counts[4]);
    }

    // ==================================================================
    // 元数据
    // ==================================================================

    function test_TokenURI_BeforeReveal() public {
        _buyPublic(user1);
        string memory uri = nft.tokenURI(0);
        assertTrue(_strEq(uri, BLIND_URI), "Should return blindbox URI before reveal");
    }

    function test_TokenURI_AfterReveal() public {
        uint256 requestId = _buyPublic(user1);
        _revealToken(0, requestId, user1);
        string memory uri = nft.tokenURI(0);
        // 揭示后 URI 以 REVEAL_BASE 开头
        assertTrue(_startsWith(uri, REVEAL_BASE), "Should return revealed URI after reveal");
    }

    // 精确匹配：控制 VRF 随机数，断言每种稀有度返回对应文件名
    // roll = randomness % 100
    // Common:    roll < 50   → 使用 randomness = 0
    // Uncommon:  50 ≤ roll < 75  → 使用 randomness = 50
    // Rare:      75 ≤ roll < 90  → 使用 randomness = 75
    // Epic:      90 ≤ roll < 98  → 使用 randomness = 90
    // Legendary: roll ≥ 98   → 使用 randomness = 98

    function test_TokenURI_ExactMatch_Common() public {
        uint256 requestId = _buyPublic(user1);
        uint256[] memory words = new uint256[](1);
        words[0] = 0; // 0 % 100 = 0 → Common
        vrfCoordinator.fulfillRandomWordsWithOverride(requestId, address(nft), words);
        vm.prank(user1);
        nft.revealBlindBox(0);

        assertEq(nft.tokenURI(0), string.concat(REVEAL_BASE, "/common.json"));
    }

    function test_TokenURI_ExactMatch_Uncommon() public {
        uint256 requestId = _buyPublic(user1);
        uint256[] memory words = new uint256[](1);
        words[0] = 50; // 50 % 100 = 50 → Uncommon
        vrfCoordinator.fulfillRandomWordsWithOverride(requestId, address(nft), words);
        vm.prank(user1);
        nft.revealBlindBox(0);

        assertEq(nft.tokenURI(0), string.concat(REVEAL_BASE, "/uncommon.json"));
    }

    function test_TokenURI_ExactMatch_Rare() public {
        uint256 requestId = _buyPublic(user1);
        uint256[] memory words = new uint256[](1);
        words[0] = 75; // 75 % 100 = 75 → Rare
        vrfCoordinator.fulfillRandomWordsWithOverride(requestId, address(nft), words);
        vm.prank(user1);
        nft.revealBlindBox(0);

        assertEq(nft.tokenURI(0), string.concat(REVEAL_BASE, "/rare.json"));
    }

    function test_TokenURI_ExactMatch_Epic() public {
        uint256 requestId = _buyPublic(user1);
        uint256[] memory words = new uint256[](1);
        words[0] = 90; // 90 % 100 = 90 → Epic
        vrfCoordinator.fulfillRandomWordsWithOverride(requestId, address(nft), words);
        vm.prank(user1);
        nft.revealBlindBox(0);

        assertEq(nft.tokenURI(0), string.concat(REVEAL_BASE, "/epic.json"));
    }

    function test_TokenURI_ExactMatch_Legendary() public {
        uint256 requestId = _buyPublic(user1);
        uint256[] memory words = new uint256[](1);
        words[0] = 98; // 98 % 100 = 98 → Legendary
        vrfCoordinator.fulfillRandomWordsWithOverride(requestId, address(nft), words);
        vm.prank(user1);
        nft.revealBlindBox(0);

        assertEq(nft.tokenURI(0), string.concat(REVEAL_BASE, "/legendary.json"));
    }

    function test_TokenURI_RevertsForNonexistentToken() public {
        vm.expectRevert();
        nft.tokenURI(999);
    }

    // ==================================================================
    // 策略替换（核心模块化验证）
    // ==================================================================

    function test_ReplaceSaleStrategy() public {
        // 部署一个新的 MultiPhaseSaleStrategy
        vm.startPrank(owner);
        MultiPhaseSaleStrategy newSale = new MultiPhaseSaleStrategy(owner, address(nft));
        PublicPhase newPub = new PublicPhase(owner, address(newSale), 0.05 ether);
        newSale.registerPhase(address(newPub));
        newSale.activatePhase(1);

        nft.setSaleStrategy(address(newSale));
        vm.stopPrank();

        assertEq(address(nft.saleStrategy()), address(newSale));

        // 用新价格购买
        vm.prank(user1);
        nft.purchaseBlindBox{value: 0.05 ether}();
        assertEq(nft.totalSupply(), 1);
    }

    function test_AddNewPhase_WithoutUpgradingNFTContract() public {
        // 演示：加一个新阶段（OG 折扣阶段），完全不碰 nft 合约
        vm.startPrank(owner);
        // 用 PublicPhase 模拟一个低价 OG 阶段
        PublicPhase ogPhase = new PublicPhase(owner, address(saleStrategy), 0.005 ether);
        uint256 ogPhaseId = saleStrategy.registerPhase(address(ogPhase));
        saleStrategy.activatePhase(ogPhaseId);
        vm.stopPrank();

        // NFT 合约地址没变，用新阶段的价格购买成功
        vm.prank(user1);
        nft.purchaseBlindBox{value: 0.005 ether}();
        assertEq(nft.totalSupply(), 1);
    }

    // ==================================================================
    // 提款
    // ==================================================================

    function test_Withdraw() public {
        _activatePublic();
        vm.prank(user1);
        nft.purchaseBlindBox{value: PUBLIC_PRICE}();

        uint256 ownerBefore = owner.balance;
        vm.prank(owner);
        nft.withdraw(payable(owner)); // withdraw 现在需要传目标地址

        assertEq(owner.balance, ownerBefore + PUBLIC_PRICE);
        assertEq(address(nft).balance, 0);
    }

    function test_Withdraw_ToCustomAddress() public {
        _activatePublic();
        vm.prank(user1);
        nft.purchaseBlindBox{value: PUBLIC_PRICE}();

        address payable coldWallet = payable(makeAddr("coldWallet"));
        vm.prank(owner);
        nft.withdraw(coldWallet);

        assertEq(coldWallet.balance, PUBLIC_PRICE);
        assertEq(address(nft).balance, 0);
    }

    function test_WithdrawReverts_ZeroAddress() public {
        vm.prank(owner);
        vm.expectRevert(NFTBlindBox.WithdrawFailed.selector);
        nft.withdraw(payable(address(0)));
    }

    function test_WithdrawReverts_NotOwner() public {
        vm.prank(user1);
        vm.expectRevert();
        nft.withdraw(payable(user1));
    }

    // ==================================================================
    // 全局暂停恢复
    // ==================================================================

    function test_PauseAndResume() public {
        vm.startPrank(owner);
        saleStrategy.activatePhase(publicPhaseId);
        saleStrategy.setPaused(true);
        vm.stopPrank();

        // 暂停后购买失败
        vm.prank(user1);
        vm.expectRevert(MultiPhaseSaleStrategy.SaleGloballyPaused.selector);
        nft.purchaseBlindBox{value: PUBLIC_PRICE}();

        // 恢复后购买成功
        vm.prank(owner);
        saleStrategy.setPaused(false);
        vm.prank(user1);
        nft.purchaseBlindBox{value: PUBLIC_PRICE}();
        assertEq(nft.totalSupply(), 1);
    }

    // ==================================================================
    // ERC-165 接口合规校验
    // ==================================================================

    function test_SetStrategy_RevertsForNonCompliantContract() public {
        // 传入一个不实现 ISaleStrategy 接口的合约地址
        address nonCompliant = address(new SimpleRarityStrategy()); // 实现的是 IRarityStrategy
        vm.prank(owner);
        vm.expectRevert(NFTBlindBox.InvalidStrategy.selector);
        nft.setSaleStrategy(nonCompliant);
    }

    function test_SetRarityStrategy_RevertsForNonCompliantContract() public {
        address nonCompliant = address(new SimpleIPFSMetadata(owner, "", "")); // 实现的是 IMetadataStrategy
        vm.prank(owner);
        vm.expectRevert(NFTBlindBox.InvalidStrategy.selector);
        nft.setRarityStrategy(nonCompliant);
    }

    function test_SetCallbackGasLimit() public {
        vm.prank(owner);
        nft.setCallbackGasLimit(200_000);
        assertEq(nft.callbackGasLimit(), 200_000);
    }

    function test_SetCallbackGasLimit_RevertsForNonOwner() public {
        vm.prank(user1);
        vm.expectRevert();
        nft.setCallbackGasLimit(200_000);
    }

    // ==================================================================
    // 工具函数
    // ==================================================================

    function _strEq(string memory a, string memory b) internal pure returns (bool) {
        return keccak256(bytes(a)) == keccak256(bytes(b));
    }

    function _startsWith(string memory str, string memory prefix) internal pure returns (bool) {
        bytes memory s = bytes(str);
        bytes memory p = bytes(prefix);
        if (s.length < p.length) return false;
        for (uint256 i = 0; i < p.length; i++) {
            if (s[i] != p[i]) return false;
        }
        return true;
    }
}

// ============================================================
// 升级测试
// ============================================================
contract NFTBlindBoxUpgradeTest is NFTBlindBoxTest {
    NFTBlindBoxV2 internal nftV2;

    function test_UpgradeToV2() public {
        // 购买一个 token，验证升级后数据保留
        _activatePublic();
        vm.prank(user1);
        nft.purchaseBlindBox{value: PUBLIC_PRICE}();
        assertEq(nft.totalSupply(), 1);

        // 部署 V2 实现合约
        vm.startPrank(owner);
        NFTBlindBoxV2 implV2 = new NFTBlindBoxV2(address(vrfCoordinator));

        bytes memory initV2Data = abi.encodeWithSelector(
            NFTBlindBoxV2.initializeV2.selector,
            2 // version
        );
        nft.upgradeToAndCall(address(implV2), initV2Data);
        vm.stopPrank();

        nftV2 = NFTBlindBoxV2(address(nft));

        // 原有状态保留
        assertEq(nftV2.totalSupply(), 1);
        assertEq(nftV2.ownerOf(0), user1);
        assertEq(nftV2.name(), "NFT Blind Box");
        assertEq(address(nftV2.saleStrategy()), address(saleStrategy));

        // V2 新增状态
        assertEq(nftV2.version(), 2);
    }

    function test_UpgradeReverts_NotOwner() public {
        vm.prank(owner);
        NFTBlindBoxV2 implV2 = new NFTBlindBoxV2(address(vrfCoordinator));

        vm.prank(user1); // 非 owner
        vm.expectRevert();
        nft.upgradeToAndCall(address(implV2), "");
    }

    function test_V2_PurchaseCountStats() public {
        // 升级到 V2
        vm.startPrank(owner);
        NFTBlindBoxV2 implV2 = new NFTBlindBoxV2(address(vrfCoordinator));
        nft.upgradeToAndCall(
            address(implV2),
            abi.encodeWithSelector(NFTBlindBoxV2.initializeV2.selector, 2)
        );
        saleStrategy.activatePhase(publicPhaseId);
        vm.stopPrank();

        nftV2 = NFTBlindBoxV2(address(nft));

        // 购买两次，验证统计
        vm.startPrank(user1);
        nftV2.purchaseBlindBox{value: PUBLIC_PRICE}();
        nftV2.purchaseBlindBox{value: PUBLIC_PRICE}();
        vm.stopPrank();

        assertEq(nftV2.userPurchaseCount(user1), 2);
    }

    function test_V2_RarityCountStats() public {
        // 升级到 V2
        vm.startPrank(owner);
        NFTBlindBoxV2 implV2 = new NFTBlindBoxV2(address(vrfCoordinator));
        nft.upgradeToAndCall(
            address(implV2),
            abi.encodeWithSelector(NFTBlindBoxV2.initializeV2.selector, 2)
        );
        saleStrategy.activatePhase(publicPhaseId);
        vm.stopPrank();

        nftV2 = NFTBlindBoxV2(address(nft));

        // 购买并揭示，验证 rarityCount 累加
        vm.prank(user1);
        nftV2.purchaseBlindBox{value: PUBLIC_PRICE}();
        vrfCoordinator.fulfillRandomWords(1, address(nftV2));
        vm.prank(user1);
        nftV2.revealBlindBox(0);

        // 揭示后对应稀有度的计数应该 +1
        (BlindBoxTypes.Rarity rarity,,,) = nftV2.boxInfos(0);
        assertEq(nftV2.rarityCount(uint256(rarity)), 1);

        // getAllRarityCounts 总和应等于已揭示数量
        (uint256 c, uint256 u, uint256 r, uint256 e, uint256 l) = nftV2.getAllRarityCounts();
        assertEq(c + u + r + e + l, 1);
    }
}
