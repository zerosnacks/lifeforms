// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.0;

// Vendor
import {DSTestPlus} from "solmate/test/utils/DSTestPlus.sol";
import {MockERC20} from "solmate/test/utils/mocks/MockERC20.sol";

// Utilities
import {ERC721Holder} from "./ERC721Holder.sol";

// Contracts
import {Lifeform} from "../../Lifeform.sol";

contract LifeformUser is ERC721Holder {
    Lifeform lifeform;

    constructor(Lifeform _lifeform) {
        lifeform = _lifeform;
    }
}
