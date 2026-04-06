// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Script} from "forge-std/Script.sol";
import {console} from "forge-std/console.sol";
import {Upgrades, Options} from "openzeppelin-foundry-upgrades/Upgrades.sol";
import {VRFCoordinatorV2Mock} from "@chainlink/contracts/src/v0.8/vrf/mocks/VRFCoordinatorV2Mock.sol";
import {NFTBlindBox} from "../src/NFTBlindBox.sol";
import {NFTBlindBoxV2} from "../src/NFTBlindBoxV2.sol";
import {MultiPhaseSaleStrategy} from "../src/strategies/MultiPhaseSaleStrategy.sol";
import {WhitelistPhase} from "../src/strategies/phases/WhitelistPhase.sol";
import {PublicPhase} from "../src/strategies/phases/PublicPhase.sol";
import {SimpleRarityStrategy} from "../src/strategies/SimpleRarityStrategy.sol";
import {SimpleIPFSMetadata} from "../src/strategies/SimpleIPFSMetadata.sol";

// ── 关于 OZ 升级验证器（openzeppelin-foundry-upgrades）──────────────────────
//
// Upgrades.deployUUPSProxy / upgradeProxy 在部署前会运行一个静态分析工具，
// 检查合约是否符合"可升级合约规范"。这个工具只做代码静态扫描，不理解业务语义，
// 因此当我们引入第三方库（如 Chainlink VRFConsumerBaseV2）时，
// 库本身违反了规范（有 constructor、有 immutable），就需要我们手动告知验证器：
// "我知道这里的风险，并且我已经理解并接受"。
//
// 具体来说有三类"跳过"场景：
//
// 1. unsafeAllow = "constructor"
//    规范：可升级合约不能有 constructor（delegatecall 不执行 constructor）。
//    原因：Chainlink VRFConsumerBaseV2 有 constructor 用来设置 vrfCoordinator。
//    风险：constructor 里不能写任何影响代理存储的业务逻辑（我们只设置了 immutable）。
//
// 2. unsafeAllow = "state-variable-immutable"
//    规范：可升级合约不应使用 immutable（immutable 存在字节码里，升级后新实现的值可能不同）。
//    原因：Chainlink 将 vrfCoordinator 声明为 immutable，我们沿用了这种方式。
//    处理：通过 opts.constructorData 把 VRF_COORDINATOR 传给验证器，让它完成模拟分析。
//    风险：VRF coordinator 地址极少变更，实际风险可接受。
//
// 3. unsafeAllow = "missing-initializer-call"（仅升级脚本）
//    规范：initializer 必须调用所有父合约的 __XxxInit()。
//    原因：initializeV2 是 reinitializer，父合约 init 在 V1 的 initialize() 里已调完，
//          不需要也不能重复调用（会因版本号冲突 revert）。验证器做静态扫描不理解此上下文。
//    风险：无实际风险，逻辑正确。

/**
 * @dev 网络配置结构体，隔离各链的差异化参数
 *      链地址、key hash 等写死在代码里只能跑单链，改为按 chainid 选择配置后，
 *      同一份脚本可以无修改地部署到任意已支持的网络。
 */
struct NetworkConfig {
    address vrfCoordinator; // 各链 Chainlink VRF Coordinator 合约地址不同
    bytes32 keyHash;        // 各链 Gas Lane（决定 VRF 响应速度/费用）不同
    uint64  subscriptionId; // 本地 Anvil 时由脚本自动创建；测试网/主网从 .env 读取
}

/**
 * @dev 销售/NFT 参数结构体
 *      使用结构体而非展开的局部变量，是为了避免 Solidity 的 Stack Too Deep 限制
 *      （EVM 函数调用栈最多 16 个局部变量槽，超过则编译报错）
 */
struct SaleConfig {
    string  nftName;
    string  nftSymbol;
    uint256 maxSupply;
    uint256 whitelistPrice;
    uint256 publicPrice;
    uint256 maxPerWallet;
    string  blindBoxURI;
    string  baseTokenURI;
}

/**
 * @notice 完整部署脚本
 *
 * 部署顺序：
 *   1. 获取当前网络配置（按 block.chainid 选择）
 *   2. 稀有度策略 + 元数据策略（无依赖）
 *   3. MultiPhaseSaleStrategy（nftContract 先用占位地址）
 *   4. WhitelistPhase + PublicPhase
 *   5. 注册阶段到 MultiPhaseSaleStrategy
 *   6. NFTBlindBox implementation + proxy
 *   7. 修正 MultiPhaseSaleStrategy 的 nftContract 为 proxy 地址
 *   8. 将 proxy 注册为 VRF Consumer（需要在 Chainlink 控制台操作，本地自动完成）
 *
 * 使用方法：
 *   make deploy-local    → Anvil（自动部署 VRF Mock，无需任何外部配置）
 *   make deploy-sepolia  → Sepolia（需要 .env 里的 VRF_SUBSCRIPTION_ID）
 */
contract DeployScript is Script {

    // ── 销售/NFT 参数（从 .env 读取，未设置时使用括号内默认值）────────────
    // 这些参数在不同项目/不同环境里可能不同，抽到 .env 便于按需覆盖，
    // 而不需要修改合约或脚本代码。
    function getSaleConfig() internal view returns (SaleConfig memory cfg) {
        cfg.nftName        = vm.envOr("NFT_NAME",       string("NFT Blind Box"));
        cfg.nftSymbol      = vm.envOr("NFT_SYMBOL",     string("NBB"));
        cfg.maxSupply      = vm.envOr("MAX_SUPPLY",      uint256(1000));
        cfg.whitelistPrice = vm.envOr("WHITELIST_PRICE", uint256(0.01 ether));
        cfg.publicPrice    = vm.envOr("PUBLIC_PRICE",    uint256(0.02 ether));
        cfg.maxPerWallet   = vm.envOr("MAX_PER_WALLET",  uint256(3));

        // IPFS URI：上传 Pinata 后填入 .env；未填时使用占位符，部署后可通过
        // setBlindBoxURI / setBaseTokenURI 更新，无需重新部署合约
        string memory jsonCid = vm.envOr("JSON_FOLDER_CID", string("YOUR_JSON_FOLDER_CID"));
        cfg.blindBoxURI  = string.concat("ipfs://", jsonCid, "/blindbox.json");
        cfg.baseTokenURI = string.concat("ipfs://", jsonCid);
    }

    // ── 按 chainid 选择网络配置 ───────────────────────────────────────────
    // 新增网络时只需在此函数里追加一个 else if 分支，其余代码无需改动。
    // 来源：https://docs.chain.link/vrf/v2/subscription/supported-networks
    function getNetworkConfig() internal returns (NetworkConfig memory config) {
        if (block.chainid == 31337) {
            // ── 本地 Anvil ──────────────────────────────────────────────
            // Chainlink 合约在本地不存在，需要部署 Mock 合约来模拟 VRF 行为。
            // baseFee / gasPriceLink 是 Mock 的收费参数，本地测试用任意值即可。
            VRFCoordinatorV2Mock mockCoordinator = new VRFCoordinatorV2Mock(
                0.1 ether,  // baseFee（LINK）
                1e9         // gasPriceLink
            );
            uint64 subId = mockCoordinator.createSubscription();
            mockCoordinator.fundSubscription(subId, 100 ether); // 测试用足额 LINK
            config.vrfCoordinator = address(mockCoordinator);
            config.keyHash        = bytes32(0); // Mock 不校验 keyHash，任意值均可
            config.subscriptionId = subId;
            console.log("VRFMock deployed:", address(mockCoordinator));
            console.log("Subscription ID :", subId);

        } else if (block.chainid == 11155111) {
            // ── Sepolia 测试网 ─────────────────────────────────────────
            config.vrfCoordinator = 0x8103B0A8A00be2DDC778e6e7eaa21791Cd364625;
            config.keyHash        = 0x474e34a077df58807dbe9c96d3c009b23b3c6d0cce433e59bbf5b34f823bc56c;
            config.subscriptionId = uint64(vm.envUint("VRF_SUBSCRIPTION_ID"));

        } else if (block.chainid == 1) {
            // ── Ethereum 主网 ──────────────────────────────────────────
            config.vrfCoordinator = 0x271682DEB8C4E0901D1a1550aD2e64D568E69909;
            config.keyHash        = 0x8af398995b04c28e9951adb9721ef74c74f93e6a478f39e7e0777be13527e7ef;
            config.subscriptionId = uint64(vm.envUint("VRF_SUBSCRIPTION_ID"));

        } else {
            revert(string.concat(
                "Unsupported chainId: ",
                vm.toString(block.chainid),
                ". Add network config in getNetworkConfig()."
            ));
        }
    }

    function run() external returns (address proxy) {
        NetworkConfig memory net = getNetworkConfig();
        SaleConfig memory sale = getSaleConfig();
        address deployer = msg.sender;

        console.log("Deployer        :", deployer);
        console.log("Chain ID        :", block.chainid);
        console.log("VRF Coordinator :", net.vrfCoordinator);
        console.log("Subscription ID :", net.subscriptionId);
        console.log("NFT Name        :", sale.nftName);
        console.log("Max Supply      :", sale.maxSupply);

        vm.startBroadcast();

        // ── 1. 无状态策略（稀有度 + 元数据）─────────────────────────────
        SimpleRarityStrategy rarityStrategy = new SimpleRarityStrategy();
        SimpleIPFSMetadata metadataStrategy = new SimpleIPFSMetadata(
            deployer, sale.blindBoxURI, sale.baseTokenURI
        );
        console.log("RarityStrategy  :", address(rarityStrategy));
        console.log("MetadataStrategy:", address(metadataStrategy));

        // ── 2. 销售编排器（nftContract 先用占位 address(0)）──────────────
        MultiPhaseSaleStrategy saleStrategy = new MultiPhaseSaleStrategy(
            deployer, address(0)
        );
        console.log("SaleStrategy    :", address(saleStrategy));

        // ── 3. 销售阶段 ───────────────────────────────────────────────────
        WhitelistPhase whitelistPhase = new WhitelistPhase(
            deployer, address(saleStrategy), sale.whitelistPrice, sale.maxPerWallet
        );
        PublicPhase publicPhase = new PublicPhase(
            deployer, address(saleStrategy), sale.publicPrice
        );
        console.log("WhitelistPhase  :", address(whitelistPhase));
        console.log("PublicPhase     :", address(publicPhase));

        // ── 4. 注册阶段（默认不激活，部署后手动切换）─────────────────────
        saleStrategy.registerPhase(address(whitelistPhase));
        saleStrategy.registerPhase(address(publicPhase));

        // ── 5. NFTBlindBox 实现合约 + 代理 ───────────────────────────────
        bytes memory initData = abi.encodeWithSelector(
            NFTBlindBox.initialize.selector,
            sale.nftName,
            sale.nftSymbol,
            net.keyHash,
            net.subscriptionId,
            sale.maxSupply,
            address(saleStrategy),
            address(rarityStrategy),
            address(metadataStrategy)
        );

        // opts 说明见文件顶部注释
        Options memory opts;
        opts.constructorData = abi.encode(net.vrfCoordinator);
        opts.unsafeAllow = "constructor,state-variable-immutable";

        proxy = Upgrades.deployUUPSProxy(
            "NFTBlindBox.sol:NFTBlindBox",
            initData,
            opts
        );
        console.log("Proxy (NFTBlindBox):", proxy);

        // ── 6. 修正 saleStrategy 的 nftContract ──────────────────────────
        saleStrategy.setNftContract(proxy);

        // ── 7. 本地 Anvil：自动把 proxy 注册为 VRF Consumer ──────────────
        // 测试网/主网需要在 Chainlink 控制台手动操作
        if (block.chainid == 31337) {
            VRFCoordinatorV2Mock(net.vrfCoordinator)
                .addConsumer(net.subscriptionId, proxy);
            console.log("VRF consumer registered (local mock)");
        }

        vm.stopBroadcast();

        // ── 后续手动操作清单（测试网/主网）──────────────────────────────
        if (block.chainid != 31337) {
            console.log("");
            console.log("=== Post-deploy checklist ===");
            console.log("1. Add proxy as VRF consumer:", proxy);
            console.log("   https://vrf.chain.link");
            console.log("2. Activate whitelist: make activate-whitelist");
            console.log("3. Switch to public:   make activate-public");
        }
    }
}

/**
 * @notice 升级到 V2 的脚本（独立运行）
 * 使用方法：make upgrade-sepolia
 */
contract UpgradeToV2Script is Script {

    // 同 DeployScript，根据 chainid 选择 VRF coordinator 地址
    // 升级验证时 opts.constructorData 需要它来模拟 constructor 执行
    function getVrfCoordinator() internal view returns (address) {
        if (block.chainid == 31337)    return address(0); // 本地升级不需要真实地址
        if (block.chainid == 11155111) return 0x8103B0A8A00be2DDC778e6e7eaa21791Cd364625;
        if (block.chainid == 1)        return 0x271682DEB8C4E0901D1a1550aD2e64D568E69909;
        revert("Unsupported chainId");
    }

    function run() external {
        address proxyAddress = vm.envAddress("PROXY_ADDRESS");
        address vrfCoordinator = getVrfCoordinator();

        console.log("Upgrading proxy  :", proxyAddress);
        console.log("Chain ID         :", block.chainid);
        console.log("VRF Coordinator  :", vrfCoordinator);

        vm.startBroadcast();

        bytes memory initV2Data = abi.encodeWithSelector(
            NFTBlindBoxV2.initializeV2.selector,
            2
        );

        // opts 说明见文件顶部注释
        Options memory opts;
        opts.constructorData = abi.encode(vrfCoordinator);
        opts.unsafeAllow = "constructor,state-variable-immutable,missing-initializer-call";

        Upgrades.upgradeProxy(
            proxyAddress,
            "NFTBlindBoxV2.sol:NFTBlindBoxV2",
            initV2Data,
            opts
        );
        console.log(
            "Upgrade complete. Version:",
            NFTBlindBoxV2(proxyAddress).version()
        );

        vm.stopBroadcast();
    }
}
