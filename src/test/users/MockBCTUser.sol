// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.0;

// Contracts
import {MockBCT} from "../../MockBCT.sol";

contract MockBCTUser {
    MockBCT mockbct;

    constructor(MockBCT _mockbct) {
        mockbct = _mockbct;
    }

    // ==========
    // MINT LOGIC
    // ==========
    function mint(uint256 amount) public {
        mockbct.mint(amount);
    }


    // ==========
    // BURN LOGIC
    // ==========
    function burn(uint256 amount) public {
        mockbct.burn(amount);
    }
}