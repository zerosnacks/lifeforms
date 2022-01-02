// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.0;

// Vendor
import {ERC20} from "solmate/tokens/ERC20.sol";
import {SafeTransferLib} from "solmate/utils/SafeTransferLib.sol";
import {FixedPointMathLib} from "solmate/utils/FixedPointMathLib.sol";

// Abstracts
import {ERC721} from "./abstracts/ERC721.sol";
import {NFTSVG} from "./abstracts/NFTSVG.sol";
import {Ownable} from "./abstracts/Ownable.sol";

/// @title Lifeform
/// @notice Carbon bearing NFT allowing users to store BCT (Base Carbon Tonne) carbon credits inside of NFTs
contract Lifeform is ERC721, NFTSVG, Ownable {
    using SafeTransferLib for ERC20;
    using FixedPointMathLib for uint256;

    // ======
    // EVENTS
    // ======

    /// @notice Emitted after a successful deposit.
    /// @param user The address that deposited into the NFT.
    /// @param tokenId The token id the user deposited to.
    /// @param underlyingAmount The amount of underlying tokens that were deposited.
    event TokenDeposit(address indexed user, uint256 tokenId, uint256 underlyingAmount);

    /// @notice Emitted after a successful withdrawal.
    /// @param user The address that withdrew from the NFT.
    /// @param tokenId The token id the user withdrew from.
    /// @param underlyingAmount The amount of underlying tokens that were withdrawn.
    event TokenWithdraw(address indexed user, uint256 tokenId, uint256 underlyingAmount);

    // ==================
    // ERC20-LIKE STORAGE
    // ==================

    /// @notice Tracks the total amount of underlying tokens deposited.
    uint256 public tokenTotalReserve;

    /// @notice Caps the amount of underlying tokens that are allowed to be deposited per token.
    uint256 public tokenCap;

    /// @notice The amount of effect that the deposited underlying tokens have the visual image.
    uint256 public tokenScalar;

    /// @notice Mapping of underlying token balances.
    mapping(uint256 => uint256) public tokenBalances;

    // ================
    // INTERNAL STORAGE
    // ================

    /// @notice The underlying token the NFT accepts.
    ERC20 public immutable UNDERLYING;

    /// @notice The base unit of the underlying token.
    /// @dev Equal to 10 ** decimals. Used for fixed point arithmetic.
    uint256 public immutable BASE_UNIT;

    /// @notice Whether the sale is active.
    bool public isSaleActive;

    /// @notice Whether the contract is paused.
    bool public isPaused;

    /// @notice Maximum number of token instances that can be minted on this contract.
    uint256 public maxSupply;

    /// @notice Price of each minted token instance.
    uint256 public salePrice;

    // =========
    // MODIFIERS
    // =========

    /// @dev Modifier to make a function callable only when the contract is not paused.
    modifier whenUnpaused() {
        require(!isPaused, "MUST_BE_UNPAUSED");
        _;
    }

    // ===========
    // CONSTRUCTOR
    // ===========

    constructor(
        uint256 _maxSupply,
        uint256 _salePrice,
        uint256 _tokenCap,
        uint256 _tokenScalar,
        ERC20 _underlying
    ) ERC721("Lifeform", "LIFE") {
        maxSupply = _maxSupply;
        salePrice = _salePrice;
        tokenCap = _tokenCap;
        tokenScalar = _tokenScalar;
        UNDERLYING = _underlying;
        BASE_UNIT = 10**_underlying.decimals();
    }

    // ================
    // ERC20-LIKE LOGIC
    // ================

    /// @notice Read balance of token stored by token id.
    /// @param tokenId The token id to read balance of.
    function balanceOfToken(uint256 tokenId) external view returns (uint256) {
        return tokenBalances[tokenId];
    }

    /// @notice Approve underlying token to be spend in this contract.
    /// @param underlyingAmount The amount of the underlying tokens to approve.
    function approveToken(uint256 underlyingAmount) external whenUnpaused {
        UNDERLYING.approve(address(this), underlyingAmount);
    }

    /// @notice Deposit a specific amount of underlying tokens from an owned token id.
    /// @param tokenId The token id to deposit to.
    /// @param underlyingAmount The amount of the underlying tokens to deposit.
    function depositToken(uint256 tokenId, uint256 underlyingAmount) external whenUnpaused {
        // We don't allow depositing 0 to prevent emitting a useless event.
        require(underlyingAmount != 0, "AMOUNT_CANNOT_BE_ZERO");
        require(_isApprovedOrOwner(tokenId, msg.sender), "TOKEN_MUST_BE_OWNED");
        require(tokenBalances[tokenId] + underlyingAmount <= tokenCap, "TOKEN_RESERVE_IS_CAPPED");

        // Transfer the provided amount of underlying tokens from msg.sender to this contract.
        UNDERLYING.safeTransferFrom(msg.sender, address(this), underlyingAmount);

        // Cannot overflow because a user's balance
        // will never be larger than the total supply.
        unchecked {
            tokenBalances[tokenId] += underlyingAmount;
            tokenTotalReserve += underlyingAmount;
        }

        tokenURI[tokenId] = generateTokenURI(
            NFTSVG.SVGParams({
                tokenId: tokenId,
                tokenBalance: tokenBalances[tokenId] / BASE_UNIT,
                tokenScalar: tokenScalar
            })
        );

        emit TokenDeposit(msg.sender, tokenId, underlyingAmount);
    }

    /// @notice Withdraw a specific amount of underlying tokens from an owned token id.
    /// @param tokenId The token id to withdraw from.
    /// @param underlyingAmount The amount of underlying tokens to withdraw.
    function withdrawToken(uint256 tokenId, uint256 underlyingAmount) external whenUnpaused {
        // We don't allow withdrawing 0 to prevent emitting a useless event.
        require(underlyingAmount != 0, "AMOUNT_CANNOT_BE_ZERO");
        require(_isApprovedOrOwner(tokenId, msg.sender), "TOKEN_MUST_BE_OWNED");
        require(underlyingAmount <= tokenBalances[tokenId], "AMOUNT_EXCEEDS_TOKEN_ID_BALANCE");

        // Cannot underflow because a user's balance
        // will never be larger than the total supply.
        unchecked {
            tokenBalances[tokenId] -= underlyingAmount;
            tokenTotalReserve -= underlyingAmount;
        }

        // Transfer the provided amount of underlying tokens to msg.sender from this contract.
        UNDERLYING.safeTransfer(msg.sender, underlyingAmount);

        tokenURI[tokenId] = generateTokenURI(
            NFTSVG.SVGParams({
                tokenId: tokenId,
                tokenBalance: tokenBalances[tokenId] / BASE_UNIT,
                tokenScalar: tokenScalar
            })
        );

        emit TokenWithdraw(msg.sender, tokenId, underlyingAmount);
    }

    /// @notice Check if spender owns the token or is approved to interact with the token.
    /// @param spender The proposed spender.
    /// @param tokenId The token id to withdraw from.
    function _isApprovedOrOwner(uint256 tokenId, address spender) internal view virtual returns (bool) {
        require(ownerOf[tokenId] != address(0), "TOKEN_MUST_EXIST");
        address owner = ownerOf[tokenId];

        return (spender == owner || getApproved[tokenId] == spender || isApprovedForAll[owner][spender]);
    }

    // ==========
    // MINT LOGIC
    // ==========

    /// @notice Mint token to address
    /// @param to The address to mint to.
    function mint(address to) external payable whenUnpaused returns (uint256) {
        require(totalSupply + 1 <= maxSupply, "ALL_TOKENS_MINTED");
        require(isSaleActive, "SALE_NOT_ACTIVE");
        require(salePrice <= msg.value, "INSUFFICIENT_ETHER");

        uint256 id = totalSupply;

        _safeMint(to, id);

        tokenURI[id] = generateTokenURI(NFTSVG.SVGParams({tokenId: id, tokenBalance: 0, tokenScalar: tokenScalar}));

        return id;
    }

    // ===================
    // RECEIVE ETHER LOGIC
    // ===================

    /// @dev Required for the contract to receive unwrapped ETH.
    receive() external payable {}
}
