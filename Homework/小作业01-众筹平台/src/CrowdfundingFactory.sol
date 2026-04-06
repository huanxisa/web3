// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {CrowdfundingCampaign} from "./CrowdfundingCampaign.sol";

contract CrowdfundingFactory {
    // ========== 状态变量 ==========

    address[] public campaigns;
    mapping(address => uint256[]) public userCampaigns;

    // ========== 事件 ==========

    event CampaignCreated(
        address indexed creator,
        address indexed campaignAddress,
        uint256 goal,
        uint256 durationInDays
    );

    // ========== 核心功能函数 ==========

    /// @notice 创建一个新的众筹项目合约
    /// @param _goal 目标金额（wei）
    /// @param _durationInDays 众筹持续天数
    /// @return campaignAddr 新部署的合约地址
    function createCampaign(
        uint256 _goal,
        uint256 _durationInDays
    ) external returns (address campaignAddr) {
        // TODO: 验证参数合法性（同 Campaign 构造函数的要求）
        require(_goal > 0, "Goal must be greater than 0");
        require(_durationInDays > 0, "Duration must be greater than 0");
        // TODO: 使用 new 部署 CrowdfundingCampaign，传入 msg.sender 作为 owner
        CrowdfundingCampaign campaign = new CrowdfundingCampaign(
            msg.sender,
            _goal,
            _durationInDays
        );
        // TODO: 将新地址推入 campaigns 数组
        campaigns.push(address(campaign));
        // TODO: 将 campaigns 数组当前索引推入 userCampaigns[msg.sender]
        userCampaigns[msg.sender].push(campaigns.length - 1);
        // TODO: 触发 CampaignCreated 事件
        emit CampaignCreated(
            msg.sender,
            address(campaign),
            _goal,
            _durationInDays
        );
        // TODO: 返回新合约地址
        return address(campaign);
    }

    // ========== 查询函数 ==========

    /// @notice 返回所有众筹项目地址
    function getAllCampaigns() external view returns (address[] memory) {
        // TODO: 返回 campaigns
        return campaigns;
    }

    /// @notice 返回某用户创建的众筹项目索引列表
    function getUserCampaigns(
        address _user
    ) external view returns (uint256[] memory) {
        // TODO: 返回 userCampaigns[_user]
        return userCampaigns[_user];
    }

    /// @notice 返回众筹项目总数
    function getCampaignCount() external view returns (uint256) {
        // TODO: 返回 campaigns.length
        return campaigns.length;
    }
}
