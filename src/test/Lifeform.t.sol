// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.0;

// Vendor
import {DSTestPlus} from "solmate/test/utils/DSTestPlus.sol";
import {ERC20} from "solmate/tokens/ERC20.sol";

// Contracts
import {Lifeform} from "../Lifeform.sol";

contract LifeformsTest is DSTestPlus {
    Lifeform lifeform;

    function setUp() public {
        lifeform = new Lifeform("Lifeform", "LIFE", 1000, 10, 10000, ERC20(address(0)));
    }
}
