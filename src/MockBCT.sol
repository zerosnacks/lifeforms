// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.0;

// Vendor
import {ERC20} from "solmate/tokens/ERC20.sol";

contract MockBCT is ERC20 {
    // ================
    // INTERNAL STORAGE
    // ================

    /// @notice The base unit of the underlying token.
    /// @dev Equal to 10 ** decimals. Used for fixed point arithmetic.
    uint256 public immutable BASE_UNIT;

    // ===========
    // CONSTRUCTOR
    // ===========

    /// @notice Creates a new MockBCT instance.
    /// @param _name Token name.
    /// @param _symbol Symbol name.
    /// @param _decimals Number of decimals the token has.
    constructor(
        string memory _name,
        string memory _symbol,
        uint8 _decimals
    ) ERC20(_name, _symbol, _decimals) {
        BASE_UNIT = 10**_decimals;
    }

    // ==========
    // MINT LOGIC
    // ==========

    /// @notice Mint tokens to sender.
    /// @param amount Amount of tokens to mint within limits.
    function mint(uint256 amount) external {
        require(amount <= 2500 * BASE_UNIT, "MINT_AMOUNT_CAPPED");
        _mint(msg.sender, amount);
    }

    // ==========
    // BURN LOGIC
    // ==========

    /// @notice Mint tokens from sender.
    /// @param amount Amount of tokens to burn.
    function burn(uint256 amount) external {
        _burn(msg.sender, amount);
    }
}
