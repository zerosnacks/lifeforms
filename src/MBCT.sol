// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.0;

// Vendor
import {Trust} from "solmate/auth/Trust.sol";
import {ERC20} from "solmate/tokens/ERC20.sol";

contract MBCT is ERC20, Trust {
    constructor(
        string memory _name,
        string memory _symbol,
        uint8 _decimals
    ) ERC20(_name, _symbol, _decimals) Trust(msg.sender) {}

    function mint(address to, uint256 amount) external requiresTrust {
        _mint(to, amount);
    }

    function burn(address to, uint256 amount) external requiresTrust {
        _burn(to, amount);
    }
}
