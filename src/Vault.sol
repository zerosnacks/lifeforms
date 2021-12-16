// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.0;

// Vendor
import {Auth} from "solmate/auth/Auth.sol";
import {ERC20} from "solmate/tokens/ERC20.sol";
import {SafeTransferLib} from "solmate/utils/SafeTransferLib.sol";
import {FixedPointMathLib} from "solmate/utils/FixedPointMathLib.sol";

/// @title Vault
/// @author Inherits from Rari Capital (https://github.com/Rari-Capital/vaults/blob/main/src/Vault.sol)
contract Vault is ERC20, Auth {
    using SafeTransferLib for ERC20;
    using FixedPointMathLib for uint256;

    // Users are able to claim NFTs based on a merkle tree distribution after a certain amount of time
    // The longer and more you hold inside of the vault the higher the quality of NFT you get (and rarer)
    // You can cause natural events to happen at certain rates, this will then randomly selected you + some other depositors with a role
    // How can diamonds be generated

    // ======
    // EVENTS
    // ======

    /// @notice Emitted when the Vault is initialized.
    /// @param user The authorized user who triggered the initialization.
    event Initialized(address indexed user);

    /// @notice Emitted after a successful deposit.
    /// @param user The address that deposited into the Vault.
    /// @param underlyingAmount The amount of underlying tokens that were deposited.
    event Deposit(address indexed user, uint256 underlyingAmount);

    /// @notice Emitted after a successful withdrawal.
    /// @param user The address that withdrew from the Vault.
    /// @param underlyingAmount The amount of underlying tokens that were withdrawn.
    event Withdraw(address indexed user, uint256 underlyingAmount);

    /// @notice Emitted after a succesful rescue.
    /// @param token The token who needs to be rescued.
    /// @param amount The amount of token that were deposited that need to be rescued.
    event Rescue(address token, uint256 amount);

    // =========
    // CONSTANTS
    // =========

    /// @notice Whether the Vault has been initialized yet.
    /// @dev Can go from false to true, never from true to false.
    bool public isInitialized;

    /// @notice The underlying token the Vault accepts.
    ERC20 public immutable UNDERLYING;

    /// @notice The base unit of the underlying token.
    /// @dev Equal to 10 ** decimals. Used for fixed point arithmetic.
    uint256 public immutable BASE_UNIT;

    // ===========
    // CONSTRUCTOR
    // ===========

    constructor(ERC20 _underlying)
        ERC20(
            // ex: ZS Dai Stablecoin Vault
            string(abi.encodePacked("ZS ", _underlying.name(), " Vault")),
            // ex: zsDAI
            string(abi.encodePacked("zs", _underlying.symbol())),
            // ex: 18
            _underlying.decimals()
        )
        Auth(Auth(msg.sender).owner(), Auth(msg.sender).authority())
    {
        UNDERLYING = _underlying;
        BASE_UNIT = 10**decimals;

        // Prevent minting of zsTokens until
        // the initialize function is called.
        totalSupply = type(uint256).max;
    }

    // ====================
    // INITIALIZATION LOGIC
    // ====================

    /// @notice Initializes the Vault, enabling it to receive deposits.
    /// @dev All critical parameters must already be set before calling.
    function initialize() external requiresAuth {
        // Ensure the Vault has not already been initialized.
        require(!isInitialized, "ALREADY_INITIALIZED");

        // Mark the Vault as initialized.
        isInitialized = true;

        // Open for deposits.
        totalSupply = 0;

        emit Initialized(msg.sender);
    }

    // ========================
    // DEPOSIT / WITHDRAW LOGIC
    // ========================

    /// @notice Deposit a specific amount of underlying tokens.
    /// @param underlyingAmount The amount of the underlying token to deposit.
    function deposit(uint256 underlyingAmount) external {
        // We don't allow depositing 0 to prevent emitting a useless event.
        require(underlyingAmount != 0, "AMOUNT_CANNOT_BE_ZERO");

        // Determine the equivalent amount of zsTokens and mint them.
        _mint(msg.sender, underlyingAmount.fdiv(exchangeRate(), BASE_UNIT));

        emit Deposit(msg.sender, underlyingAmount);

        // Transfer in underlying tokens from the user.
        // This will revert if the user does not have the amount specified.
        UNDERLYING.safeTransferFrom(msg.sender, address(this), underlyingAmount);
    }

    /// @notice Withdraw a specific amount of underlying tokens.
    /// @param underlyingAmount The amount of underlying tokens to withdraw.
    function withdraw(uint256 underlyingAmount) external {
        // We don't allow withdrawing 0 to prevent emitting a useless event.
        require(underlyingAmount != 0, "AMOUNT_CANNOT_BE_ZERO");

        // Determine the equivalent amount of zsTokens and burn them.
        // This will revert if the user does not have enough zsTokens.
        _burn(msg.sender, underlyingAmount.fdiv(exchangeRate(), BASE_UNIT));

        emit Withdraw(msg.sender, underlyingAmount);

        // Transfer the provided amount of underlying tokens.
        UNDERLYING.safeTransfer(msg.sender, underlyingAmount);
    }

    /// @notice Redeem a specific amount of zsTokens for underlying tokens.
    /// @param zsTokenAmount The amount of zsTokens to redeem for underlying tokens.
    function redeem(uint256 zsTokenAmount) external {
        // We don't allow redeeming 0 to prevent emitting a useless event.
        require(zsTokenAmount != 0, "AMOUNT_CANNOT_BE_ZERO");

        // Determine the equivalent amount of underlying tokens.
        uint256 underlyingAmount = zsTokenAmount.fmul(exchangeRate(), BASE_UNIT);

        // Burn the provided amount of zsTokens.
        // This will revert if the user does not have enough zsTokens.
        _burn(msg.sender, zsTokenAmount);

        emit Withdraw(msg.sender, underlyingAmount);

        // Transfer the provided amount of underlying tokens.
        UNDERLYING.safeTransfer(msg.sender, underlyingAmount);
    }

    // ======================
    // VAULT ACCOUNTING LOGIC
    // ======================

    /// @notice Returns a user's Vault balance in underlying tokens.
    /// @param user The user to get the underlying balance of.
    /// @return The user's Vault balance in underlying tokens.
    function balanceOfUnderlying(address user) external view returns (uint256) {
        return balanceOf[user].fmul(exchangeRate(), BASE_UNIT);
    }

    /// @notice Returns the amount of underlying tokens an zsToken can be redeemed for.
    /// @return The amount of underlying tokens an zsToken can be redeemed for.
    function exchangeRate() public view returns (uint256) {
        // Get the total supply of zsTokens.
        uint256 zsTokenSupply = totalSupply;

        // If there are no zsTokens in circulation, return an exchange rate of 1:1.
        if (zsTokenSupply == 0) return BASE_UNIT;

        // Calculate the exchange rate by dividing the total holdings by the zsToken supply.
        return UNDERLYING.balanceOf(address(this)).fdiv(zsTokenSupply, BASE_UNIT);
    }

    // =================
    // DESTRUCTION LOGIC
    // =================

    /// @notice Rescues arbitrary ERC20 tokens send to the Vault by sending them to the contract owner.
    /// @dev Caller will receive any ERC20 token held as float in the Vault.
    function rescue(ERC20 token, uint256 tokenAmount) external requiresAuth {
        // We don't allow depositing 0 to prevent emitting a useless event.
        require(tokenAmount != 0, "AMOUNT_CANNOT_BE_ZERO");

        // Prevent authorized user from seizing underlying asset.
        require(token != UNDERLYING, "NOT_PERMITTED");

        ERC20(token).safeTransfer(msg.sender, tokenAmount);

        emit Rescue(address(token), tokenAmount);
    }

    /// @notice Self destructs a Vault, enabling it to be redeployed.
    /// @dev Caller will receive any ETH held as float in the Vault.
    function destroy() external requiresAuth {
        selfdestruct(payable(msg.sender));
    }

    // ===================
    // RECIEVE ETHER LOGIC
    // ===================

    /// @dev Required for the Vault to receive unwrapped ETH.
    receive() external payable {}
}
