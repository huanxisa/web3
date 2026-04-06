// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {IRarityStrategy} from "../interfaces/IRarityStrategy.sol";
import {BlindBoxTypes} from "../interfaces/IBlindBoxTypes.sol";
import {ERC165} from "@openzeppelin/contracts/utils/introspection/ERC165.sol";
import {IERC165} from "@openzeppelin/contracts/utils/introspection/IERC165.sol";

contract SimpleRarityStrategy is IRarityStrategy, ERC165 {
    function assignRarity(BlindBoxTypes.BoxInfo calldata box)
        external
        pure
        override
        returns (BlindBoxTypes.Rarity)
    {
        uint256 roll = box.pendingRandomness % 100;
        if (roll < 50) return BlindBoxTypes.Rarity.Common;
        if (roll < 75) return BlindBoxTypes.Rarity.Uncommon;
        if (roll < 90) return BlindBoxTypes.Rarity.Rare;
        if (roll < 98) return BlindBoxTypes.Rarity.Epic;
        return BlindBoxTypes.Rarity.Legendary;
    }

    function supportsInterface(bytes4 interfaceId)
        public view override(ERC165, IERC165)
        returns (bool)
    {
        return interfaceId == type(IRarityStrategy).interfaceId
            || super.supportsInterface(interfaceId);
    }
}
