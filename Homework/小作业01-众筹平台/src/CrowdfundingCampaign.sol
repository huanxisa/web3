// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

// 【笔记】具名导入写法：import {X} from "..."，只引入需要的符号，避免命名空间污染，是 Solidity 社区主流规范
// 【笔记】ReentrancyGuard：防重入攻击。nonReentrant 修饰符用一把锁（_status）保证函数执行期间不能被嵌套调用。
//         锁粒度是「单笔交易」级别，不同地址的不同交易之间相互独立，以太坊单线程顺序执行，不存在并发。
//         注意：两个 nonReentrant 函数不能互相调用（锁只有一把）；nonReentrantView 只能用于 view 函数。
//         当前版本基于 storage 实现，已标记废弃，v6.0 将替换为 ReentrancyGuardTransient（基于 EIP-1153 瞬态存储，Gas 更低）。
// 【笔记】Ownable：OZ 封装的 owner 权限管理，内含 address owner、onlyOwner modifier、零地址检查。
//         继承后无需手写这些逻辑；OZ v5 构造函数需要显式传入 owner 地址：Ownable(_owner)
import {ReentrancyGuard} from "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

contract CrowdfundingCampaign is ReentrancyGuard, Ownable {
    // ========== 枚举 ==========

    enum State {
        Preparing,
        Active,
        Success,
        Failed,
        Closed
    }

    // ========== 状态变量 ==========

    // 【笔记】immutable：变量只能在构造函数中赋值一次，之后永久锁定，任何函数都不能修改。
    //         编译时直接内嵌到字节码（PUSH 指令），读取消耗约 3 gas；
    //         普通 storage 变量读取消耗约 2100 gas（SLOAD）。
    //         适用于部署后不变的值（如 goal、owner），频繁读取时 Gas 优化显著。
    uint256 private immutable GOAL;
    uint256 private deadline;
    uint256 private totalRaised;
    State private state;
    uint256 private immutable DURATION_IN_DASYS;

    mapping(address => uint256) private contributions;
    uint256 private contributorsCount; //在这个合约中只使用了这个属性的length，是否可以考虑删除掉用一个Uint256类型即可代替

    // ========== 事件 ==========

    event ContributionReceived(
        address indexed contributor,
        uint256 amount,
        uint256 totalRaised
    );
    event StateChanged(State indexed from, State indexed to);
    event FundsWithdrawn(address indexed owner, uint256 amount);
    event Refunded(address indexed contributor, uint256 amount);

    modifier inState(State _state) {
        // TODO: 验证当前 state 等于 _state
        _inState(_state);
        _;
    }

    function _inState(State _state) internal view {
        require(state == _state, "Invalid state");
    }

    // ========== 构造函数 ==========

    constructor(
        address _owner,
        uint256 _goal,
        uint256 _durationInDays
    ) Ownable(_owner) {
        // TODO: 验证参数合法性（_goal > 0，_durationInDays > 0 且 <= 90，_owner 非零地址）
        // TODO: 设置 owner、goal、deadline、state 初始值
        require(_goal > 0, "Goal must be positive");
        require(_durationInDays > 0, "Duration must be greater than 0");
        DURATION_IN_DASYS = _durationInDays;
        GOAL = _goal;
        state = State.Preparing;
    }

    // ========== 核心功能函数 ==========

    /// @notice owner 调用，将状态从 Preparing 切换到 Active
    function start() external onlyOwner inState(State.Preparing) {
        // TODO: 切换 state 到 Active，触发 StateChanged 事件
        // 【笔记】block.timestamp：业界标准时间戳来源，以天/周为单位的截止时间完全可靠。
        //         验证者可小幅操控（偏差几十秒内），秒级精确场景不适用。
        //         1 days 是 Solidity 时间单位字面量，等于 86400 秒，推荐写法。
        //         deadline 放在 start() 里计算（而非构造函数），避免部署到启动之间的时间差导致 deadline 提前。
        // 【笔记】this 在 Solidity 中指当前合约地址（address 类型），不能用来给状态变量赋值。
        //         状态变量直接写变量名赋值，无需任何前缀。
        deadline = block.timestamp + (DURATION_IN_DASYS * 1 days);
        changeState(State.Active);
    }

    /// @notice 用户参与众筹，发送 ETH
    function contribute() external payable inState(State.Active) {
        // TODO: 验证截止时间未到，msg.value > 0
        require(block.timestamp < deadline, "Campaign ended");
        require(msg.value > 0, "Amount must be greater than 0");
        // TODO: 若首次贡献，记录到 contributors 数组
        if (contributions[msg.sender] == 0) {
            contributorsCount += 1;
        }
        // TODO: 累加 contributions[msg.sender] 和 totalRaised
        contributions[msg.sender] += msg.value;
        totalRaised += msg.value;
        emit ContributionReceived(msg.sender, msg.value, totalRaised);
        // TODO: 触发 ContributionReceived 事件
        // TODO: 若 totalRaised >= goal，自动切换到 Success 并触发 StateChanged
        if (totalRaised >= GOAL) {
            changeState(State.Success);
        }
    }

    /// @notice 截止时间到且未达标时，任何人可调用，将状态切换到 Failed
    function finalize() external inState(State.Active) {
        // TODO: 验证 block.timestamp >= deadline 且 totalRaised < goal
        require(block.timestamp >= deadline, "Campaign not ended");
        require(totalRaised < GOAL, "Goal already reached");
        changeState(State.Failed);
        // TODO: 切换 state 到 Failed，触发 StateChanged 事件
    }

    /// @notice owner 在 Success 状态下提取资金（CEI 模式）
    function withdraw() external onlyOwner inState(State.Success) nonReentrant {
        // TODO: 记录提取金额
        uint256 amount = address(this).balance;
        require(amount > 0, "No funds to withdraw");
        // TODO: 先切换 state 到 Closed（Effects，防重入）
        // TODO: 触发 StateChanged 事件
        changeState(State.Closed);
        // TODO: 使用 call 发送 ETH，验证成功
        (bool ok, ) = owner().call{value: amount}("");
        require(ok, "Transfer failed");
        // TODO: 触发 FundsWithdrawn 事件
        emit FundsWithdrawn(owner(), amount);
    }

    function changeState(State _state) private {
        emit StateChanged(state, _state);
        state = _state;
    }

    /// @notice 用户在 Failed 状态下申请退款（CEI 模式）
    function refund() external inState(State.Failed) nonReentrant {
        // TODO: 读取 contributions[msg.sender]，验证 > 0
        uint256 amount = contributions[msg.sender];
        require(amount > 0, "No contribution to refund");
        // TODO: 先清零 contributions[msg.sender]（Effects，防重入）
        contributions[msg.sender] = 0;
        (bool ok, ) = msg.sender.call{value: amount}("");
        require(ok, "Refund failed");
        // TODO: 使用 call 退款，验证成功
        // TODO: 触发 Refunded 事件
        emit Refunded(msg.sender, amount);
    }

    // ========== 查询函数 ==========

    /// @notice 返回项目详情
    function getCampaignInfo()
        external
        view
        returns (
            address _owner,
            uint256 _goal,
            uint256 _deadline,
            uint256 _totalRaised,
            State _state,
            uint256 _contributorCount
        )
    {
        // TODO: 返回各字段
        return (owner(), GOAL, deadline, totalRaised, state, contributorsCount);
    }

    /// @notice 查询某地址的贡献金额
    function getContribution(
        address _contributor
    ) external view returns (uint256) {
        // TODO: 返回 contributions[_contributor]
        return contributions[_contributor];
    }
}
