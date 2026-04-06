// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {ERC165} from "@openzeppelin/contracts/utils/introspection/ERC165.sol";
import {IERC165} from "@openzeppelin/contracts/utils/introspection/IERC165.sol";
import {ISaleStrategy} from "../interfaces/ISaleStrategy.sol";
import {IPhaseStrategy} from "../interfaces/IPhaseStrategy.sol";

/**
 * @title MultiPhaseSaleStrategy
 * @notice ISaleStrategy 的多阶段实现，作为阶段策略的编排器
 *
 * 职责分工：
 *   本合约（全局视角）：
 *     - 全局暂停（paused）
 *     - 阶段注册、切换、查询
 *     - 将购买校验和记录分发给当前活跃的 IPhaseStrategy
 *
 *   IPhaseStrategy 实现（阶段视角）：
 *     - 本阶段的准入条件（白名单 / 无限制 / OG 资格）
 *     - 本阶段的定价逻辑（固定价 / 荷兰拍动态价 / 折扣价）
 *     - 本阶段的限购计数
 *
 * 扩展方式：
 *   想增加一个新阶段（如荷兰拍）：
 *     1. 部署 DutchAuctionPhase 合约
 *     2. 调用 registerPhase(address(dutchAuctionPhase)) → 得到 phaseId
 *     3. 调用 activatePhase(phaseId) 切换过去
 *     → 主合约 NFTBlindBox 完全不需要改动
 *
 * 权限模型：
 *   - owner：NFT 项目方，可注册阶段、切换阶段、暂停
 *   - nftContract：NFTBlindBox 代理合约，唯一可以调用 recordPurchase 的地址
 */
contract MultiPhaseSaleStrategy is ISaleStrategy, ERC165, Ownable {
    // ========== 状态变量 ==========

    address public nftContract;          // 唯一被允许调用 recordPurchase 的地址
    bool public paused;                  // 全局暂停开关
    uint256 public activePhaseId;        // 当前活跃阶段（0 = 无活跃阶段）
    IPhaseStrategy[] private _phases;    // 已注册的阶段列表（index + 1 = phaseId）

    // ========== 事件 ==========

    event PhaseRegistered(uint256 indexed phaseId, address indexed phaseContract, string name);
    event PhaseActivated(uint256 indexed phaseId, string name);
    event SalePaused(bool paused);
    event NftContractUpdated(address indexed newContract);

    // ========== 错误 ==========

    error SaleGloballyPaused();
    error NoActivePhase();
    error InvalidPhaseId(uint256 phaseId);
    error UnauthorizedCaller();
    error InvalidAddress();

    // ========== 构造 ==========

    constructor(address owner_, address nftContract_) Ownable(owner_) {
        nftContract = nftContract_;
    }

    // ========== 修饰符 ==========

    modifier onlyNftContract() {
        if (msg.sender != nftContract) revert UnauthorizedCaller();
        _;
    }

    modifier whenNotPaused() {
        if (paused) revert SaleGloballyPaused();
        _;
    }

    modifier whenPhaseActive() {
        if (activePhaseId == 0) revert NoActivePhase();
        _;
    }

    // ========== ISaleStrategy 实现 ==========

    /// @inheritdoc ISaleStrategy
    function canPurchase(address buyer, uint256 payment)
        external
        view
        override
        whenNotPaused
        whenPhaseActive
    {
        _phases[activePhaseId - 1].canBuyInPhase(buyer, payment);
    }

    /// @inheritdoc ISaleStrategy
    function recordPurchase(address buyer)
        external
        override
        onlyNftContract
        whenPhaseActive
    {
        _phases[activePhaseId - 1].recordPurchaseInPhase(buyer);
    }

    // ========== 阶段管理（仅 owner） ==========

    /**
     * @notice 注册一个新的销售阶段
     * @param phaseContract 实现 IPhaseStrategy 的合约地址
     * @return phaseId      分配给该阶段的 ID（从 1 开始）
     */
    function registerPhase(address phaseContract) external onlyOwner returns (uint256 phaseId) {
        if (phaseContract == address(0)) revert InvalidAddress();
        _phases.push(IPhaseStrategy(phaseContract));
        phaseId = _phases.length; // 1-indexed
        emit PhaseRegistered(phaseId, phaseContract, IPhaseStrategy(phaseContract).phaseName());
    }

    /**
     * @notice 切换到指定阶段（0 = 暂停，无活跃阶段）
     * @param phaseId 目标阶段 ID（registerPhase 返回的值）
     */
    function activatePhase(uint256 phaseId) external onlyOwner {
        if (phaseId > _phases.length) revert InvalidPhaseId(phaseId);
        activePhaseId = phaseId;
        if (phaseId == 0) {
            emit PhaseActivated(0, "Paused");
        } else {
            emit PhaseActivated(phaseId, _phases[phaseId - 1].phaseName());
        }
    }

    /**
     * @notice 全局暂停/恢复（比切换阶段更快的紧急开关）
     */
    function setPaused(bool _paused) external onlyOwner {
        paused = _paused;
        emit SalePaused(_paused);
    }

    /**
     * @notice 更新 NFT 主合约地址（部署后修正用）
     */
    function setNftContract(address _nftContract) external onlyOwner {
        if (_nftContract == address(0)) revert InvalidAddress();
        nftContract = _nftContract;
        emit NftContractUpdated(_nftContract);
    }

    // ========== 查询 ==========

    /// @notice 返回已注册阶段的总数
    function phaseCount() external view returns (uint256) {
        return _phases.length;
    }

    /// @notice 返回指定 phaseId 对应的合约地址
    function getPhase(uint256 phaseId) external view returns (address) {
        if (phaseId == 0 || phaseId > _phases.length) revert InvalidPhaseId(phaseId);
        return address(_phases[phaseId - 1]);
    }

    /// @notice 返回当前活跃阶段的合约地址（address(0) 表示无活跃阶段）
    function activePhase() external view returns (address) {
        if (activePhaseId == 0) return address(0);
        return address(_phases[activePhaseId - 1]);
    }

    /// @inheritdoc ERC165
    function supportsInterface(bytes4 interfaceId)
        public view override(ERC165, IERC165)
        returns (bool)
    {
        return interfaceId == type(ISaleStrategy).interfaceId
            || super.supportsInterface(interfaceId);
    }
}
