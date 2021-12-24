// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.0;

// Vendor
import {Trust} from "solmate/auth/Trust.sol";
import {ERC20} from "solmate/tokens/ERC20.sol";

contract MockBCT is ERC20, Trust {
    constructor() ERC20("MockBCT", "MBCT", 18) Trust(msg.sender) {}

    function mint(address to, uint256 amount) external requiresTrust {
        _mint(to, amount);
    }

    function burn(address to, uint256 amount) external requiresTrust {
        _burn(to, amount);
    }
}
