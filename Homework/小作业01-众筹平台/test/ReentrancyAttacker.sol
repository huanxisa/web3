// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {CrowdfundingCampaign} from "../src/CrowdfundingCampaign.sol";

contract ReentrancyAttacker {
    CrowdfundingCampaign public campaign;
    uint256 public attackCount;

    constructor(address _campaign) {
        campaign = CrowdfundingCampaign(_campaign);
    }

    function attack() public {
        campaign.refund();
    }

    receive() external payable {
        attackCount++;
        if (attackCount < 3) {
            campaign.refund(); // 试图重入
        }
    }
}
