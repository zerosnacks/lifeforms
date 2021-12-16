// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.0;

// Vendor
import {DSTestPlus} from "solmate/test/utils/DSTestPlus.sol";

// Contracts
import {Diamond} from "../Diamond.sol";

contract DiamondsTest is DSTestPlus {
    Diamond diamond;

    function setUp() public {
        diamond = new Diamond("Diamond", "DIM", "", 1000);
    }

    // =================
    // MINT / BURN TESTS
    // =================

    function testAtomicMintBurn() public {
        uint256 preDepositBal = diamond.balanceOf(address(this));

        diamond.mint(address(this), 0, "");
        diamond.burn(0);
    }
}
