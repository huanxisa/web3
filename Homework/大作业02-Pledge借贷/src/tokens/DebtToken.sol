// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

/// @title DebtToken - 债务份额代币（sp/jp Token）
/// @notice 贷款人（sp）和借款人（jp）各自对应一种 DebtToken
/// @dev  spToken：贷款人存款时铸造，代表其出借份额
///       jpToken：借款人抵押时铸造，代表其借款债务
///       两者都是独立的 ERC20，由 PledgePool 合约 mint/burn
contract DebtToken is ERC20, Ownable {
    uint8 private immutable _DEC;

    error ZeroAmount();

    constructor(
        string memory name_,
        string memory symbol_,
        uint8 decimals_,
        address pledgePool_
    ) ERC20(name_, symbol_) Ownable(pledgePool_) {
        _DEC = decimals_;
    }

    /// @notice 铸造（存款时调用）
    function mint(address to, uint256 amount) external onlyOwner {
        if (amount == 0) revert ZeroAmount();
        _mint(to, amount);
    }

    /// @notice 销毁（取款/退款时调用）
    function burn(address from, uint256 amount) external onlyOwner {
        if (amount == 0) revert ZeroAmount();
        _burn(from, amount);
    }

    function decimals() public view override returns (uint8) {
        return _DEC;
    }
}
