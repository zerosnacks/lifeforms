// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.0;

// Vendor
import {DSTestPlus} from "solmate/test/utils/DSTestPlus.sol";
import {ERC20} from "solmate/tokens/ERC20.sol";

// Contracts
import {MockBCT} from "../MockBCT.sol";

// Test utilities
import {MockBCTUser} from "./users/MockBCTUser.sol";

contract MockBCTTest is DSTestPlus {
    MockBCT mockbct;

    string private name = "MockBCT";
    string private symbol = "MBCT";
    uint8 private decimals = 18;

    function setUp() public {
        mockbct = new MockBCT(name, symbol, decimals);
    }

    function testMintBurn() public {
        MockBCTUser usr = new MockBCTUser(mockbct);

        usr.mint(1000e18);

        assertEq(mockbct.balanceOf(address(usr)), 1000e18);

        usr.burn(100e18);

        assertEq(mockbct.balanceOf(address(usr)), 900e18);

        try usr.mint(5000e18) {
            fail();
        } catch Error(string memory error) {
            assertEq(error, "MINT_AMOUNT_CAPPED");
        }
    }
}