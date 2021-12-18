// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.0;

// Vendor
import {Auth} from "solmate/auth/Auth.sol";
import {ERC20} from "solmate/tokens/ERC20.sol";
import {SafeTransferLib} from "solmate/utils/SafeTransferLib.sol";
import {ReentrancyGuard} from "solmate/utils/ReentrancyGuard.sol";

// Abstracts
import {ERC721} from "./abstracts/ERC721.sol";
import {NFTSVG} from "./abstracts/NFTSVG.sol";

/// @title Lifeform
/// @notice Carbon bearing NFT
contract Lifeform is ERC721, NFTSVG, Auth, ReentrancyGuard {
    using SafeTransferLib for ERC20;

    // ======
    // EVENTS
    // ======

    /// @notice Emitted after a successful deposit.
    /// @param user The address that deposited into the NFT.
    /// @param tokenId The token id the user deposited to.
    /// @param underlyingAmount The amount of underlying tokens that were deposited.
    event Deposit(address indexed user, uint256 tokenId, uint256 underlyingAmount);

    /// @notice Emitted after a successful withdrawal.
    /// @param user The address that withdrew from the NFT.
    /// @param tokenId The token id the user withdrew from.
    /// @param underlyingAmount The amount of underlying tokens that were withdrawn.
    event Withdraw(address indexed user, uint256 tokenId, uint256 underlyingAmount);

    /// @notice Emitted after a succesful rescue.
    /// @param token The token who needs to be rescued.
    /// @param amount The amount of token that were deposited that need to be rescued.
    event Rescue(address token, uint256 amount);

    // =========
    // CONSTANTS
    // =========

    /// @notice The underlying token the NFT accepts.
    ERC20 public immutable UNDERLYING;

    /// @notice The base unit of the underlying token.
    /// @dev Equal to 10 ** decimals. Used for fixed point arithmetic.
    uint256 public immutable BASE_UNIT;

    /// @notice Whether the sale is active.
    bool public isSaleActive;

    /// @notice Maximum number of token instances that can be minted on this contract.
    uint256 public maxSupply;

    /// @notice Price of each minted token instance.
    uint256 public salePrice;

    // =============
    // ERC20-LIKE STORAGE
    // =============

    uint256 public tokenTotalReserves;

    mapping(uint256 => uint256) public tokenBalances;

    mapping(uint256 => mapping(uint256 => uint256)) public tokenAllowances;

    // ===========
    // CONSTRUCTOR
    // ===========

    constructor(
        string memory _name,
        string memory _symbol,
        uint256 _maxSupply,
        uint256 _salePrice,
        ERC20 _underlying
    ) ERC721(_name, _symbol) Auth(Auth(msg.sender).owner(), Auth(msg.sender).authority()) {
        maxSupply = _maxSupply;
        salePrice = _salePrice;
        UNDERLYING = _underlying;
        BASE_UNIT = 10**UNDERLYING.decimals();
    }

    // ==========
    // MINT LOGIC
    // ==========

    function mint(address to) external payable {
        require(totalSupply + 1 <= maxSupply, "ALL_TOKENS_MINTED");
        require(isSaleActive, "SALE_NOT_ACTIVE");
        require(salePrice <= msg.value, "INSUFFICIENT_ETHER");

        _mint(to, totalSupply, tokenURI(totalSupply));
    }

    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        return
            generateTokenURI(
                // tokenId
                tokenId,
                // tokenBalance
                tokenBalances[tokenId] / BASE_UNIT,
                // totalReserves
                tokenTotalReserves / BASE_UNIT
            );
    }

    // ========================
    // DEPOSIT / WITHDRAW LOGIC
    // ========================

    /// @notice Deposit a specific amount of underlying tokens from an owned token id.
    /// @param tokenId The token id to deposit to.
    /// @param underlyingAmount The amount of the underlying token to deposit.
    function deposit(uint256 tokenId, uint256 underlyingAmount) external nonReentrant {
        // We don't allow depositing 0 to prevent emitting a useless event.
        require(underlyingAmount != 0, "AMOUNT_CANNOT_BE_ZERO");
        require(_isApprovedOrOwner(tokenId, msg.sender), "TOKEN_MUST_BE_OWNED");

        // Transfer the provided amount of underlying tokens from msg.sender to this contract.
        UNDERLYING.safeTransferFrom(msg.sender, address(this), underlyingAmount);

        // Cannot underflow because a user's balance
        // will never be larger than the total supply.
        unchecked {
            tokenBalances[tokenId] += underlyingAmount;
            tokenTotalReserves += underlyingAmount;
        }

        emit Deposit(msg.sender, tokenId, underlyingAmount);
    }

    /// @notice Withdraw a specific amount of underlying tokens from an owned token id.
    /// @param tokenId The token id to withdraw from.
    /// @param underlyingAmount The amount of underlying tokens to withdraw.
    function withdraw(uint256 tokenId, uint256 underlyingAmount) external nonReentrant {
        // We don't allow withdrawing 0 to prevent emitting a useless event.
        require(underlyingAmount != 0, "AMOUNT_CANNOT_BE_ZERO");
        require(_isApprovedOrOwner(tokenId, msg.sender), "TOKEN_MUST_BE_OWNED");
        require(underlyingAmount <= tokenBalances[tokenId], "AMOUNT_EXCEEDS_TOKEN_ID_BALANCE");

        // Transfer the provided amount of underlying tokens to msg.sender from this contract.
        UNDERLYING.safeTransfer(msg.sender, underlyingAmount);

        // Cannot underflow because a user's balance
        // will never be larger than the total supply.
        unchecked {
            tokenBalances[tokenId] -= underlyingAmount;
            tokenTotalReserves -= underlyingAmount;
        }

        emit Withdraw(msg.sender, tokenId, underlyingAmount);
    }

    /// @notice Check if spender owns the token or is approved to interact with the token.
    /// @param spender The proposed spender.
    /// @param tokenId The token id to withdraw from.
    function _isApprovedOrOwner(uint256 tokenId, address spender) internal view virtual returns (bool) {
        address owner = ownerOf[tokenId];
        return (spender == owner || getApproved[tokenId] == spender || isApprovedForAll[owner][spender]);
    }

    // ====================
    // ADMINISTRATIVE LOGIC
    // ====================

    /// @notice Flips sale to active or inactive.
    function flipSale() external requiresAuth {
        isSaleActive = !isSaleActive;
    }

    /// @notice Withdraw all received funds.
    /// @dev Caller will recevie any ETH held as float.
    function withdraw(address to) external requiresAuth {
        payable(to).transfer(address(this).balance);
    }

    // =================
    // DESTRUCTION LOGIC
    // =================

    /// @notice Rescues arbitrary ERC20 tokens send to the contract by sending them to the contract owner.
    /// @dev Caller will receive any ERC20 token held as float.
    function rescue(ERC20 token, uint256 tokenAmount) external requiresAuth {
        // We don't allow depositing 0 to prevent emitting a useless event.
        require(tokenAmount != 0, "AMOUNT_CANNOT_BE_ZERO");

        // Prevent authorized user from seizing underlying asset.
        require(token != UNDERLYING, "NOT_PERMITTED");

        ERC20(token).safeTransfer(msg.sender, tokenAmount);

        emit Rescue(address(token), tokenAmount);
    }

    /// @notice Self destructs, enabling it to be redeployed.
    /// @dev Caller will receive any ETH held as float.
    function destroy() external requiresAuth {
        selfdestruct(payable(msg.sender));
    }

    // ===================
    // RECIEVE ETHER LOGIC
    // ===================

    /// @dev Required for the Vault to receive unwrapped ETH.
    receive() external payable {}
}
