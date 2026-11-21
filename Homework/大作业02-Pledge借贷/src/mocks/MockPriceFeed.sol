// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {AggregatorV3Interface} from "@chainlink/contracts/src/v0.8/shared/interfaces/AggregatorV3Interface.sol";

/// @notice 测试用 Chainlink 价格预言机 Mock，owner 可手动设置价格
contract MockPriceFeed is AggregatorV3Interface {
    int256 private _price;
    uint8 private _dec;
    address private _owner;

    constructor(int256 initialPrice, uint8 dec) {
        _price = initialPrice;
        _dec = dec;
        _owner = msg.sender;
    }

    /// @notice 测试时手动修改价格（模拟价格下跌触发清算）
    function setPrice(int256 newPrice) external {
        require(msg.sender == _owner, "not owner");
        _price = newPrice;
    }

    function decimals() external view override returns (uint8) {
        return _dec;
    }

    function description() external pure override returns (string memory) {
        return "Mock Price Feed";
    }

    function version() external pure override returns (uint256) {
        return 1;
    }

    function getRoundData(uint80)
        external
        view
        override
        returns (uint80, int256, uint256, uint256, uint80)
    {
        return (1, _price, block.timestamp, block.timestamp, 1);
    }

    function latestRoundData()
        external
        view
        override
        returns (uint80, int256, uint256, uint256, uint80)
    {
        return (1, _price, block.timestamp, block.timestamp, 1);
    }
}
