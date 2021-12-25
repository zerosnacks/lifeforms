// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.0;

// Vendor
import {Trust} from "solmate/auth/Trust.sol";
import {ERC20} from "solmate/tokens/ERC20.sol";
import {SafeTransferLib} from "solmate/utils/SafeTransferLib.sol";
import {FixedPointMathLib} from "solmate/utils/FixedPointMathLib.sol";

// Abstracts
import {ERC721} from "./abstracts/ERC721.sol";
import {NFTSVG} from "./abstracts/NFTSVG.sol";

/// @title Lifeform
/// @notice Carbon bearing NFT
contract Lifeform is ERC721, NFTSVG, Trust {
    using SafeTransferLib for ERC20;
    using FixedPointMathLib for uint256;

    // ======
    // EVENTS
    // ======

    /// @notice Emitted after a succesful pause state switch.
    /// @param user The address that paused the contract
    event Paused(address indexed user, bool isPaused);

    /// @notice Emitted after a succesful sale state switch.
    /// @param user The address that paused the contract
    event SaleActive(address indexed user, bool isSale);

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

    /// @notice Emitted after token total reserve update.
    /// @param user The address that updated the token total reserve cap.
    /// @param newTokenCap The amount of underlying tokens that are allowed to be deposited.
    event TokenCapUpdate(address indexed user, uint256 newTokenCap);

    /// @notice Emitted after token total reserve update.
    /// @param user The address that updated the token scalar.
    /// @param newTokenScalar The amount of effect that the deposited underlying tokens have the visual image.
    event TokenScalarUpdate(address indexed user, uint256 newTokenScalar);

    /// @notice Emitted after a succesful claim.
    /// @param user The address that claimed the ETH.
    /// @param to The address that the claimed ETH was transferred to.
    /// @param amount The amount of the ETH balance that was transferred.
    event Claim(address indexed user, address indexed to, uint256 amount);

    /// @notice Emitted after a succesful rescue.
    /// @param user The address that rescued the ERC20 token.
    /// @param token The ERC20 token that was rescued.
    event Rescue(address indexed user, address token);

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
    ) ERC721("Lifeform", "LIFE") Trust(msg.sender) {
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
        // TODO: at the moment everyone is able to withdraw anyones balance to the owners account (grift)

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
            tokenTotalReserve -= underlyingAmount;
        }

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

        // There should not be any way this is true as used cannot control token id.
        require(ownerOf[id] == address(0), "ALREADY_MINTED");

        // this is reasonably safe from overflow because incrementing `totalSupply` beyond
        // 'type(uint256).max' is exceedingly unlikely compared to optimization benefits,
        // and because the sum of all user balances can't exceed 'type(uint256).max'
        unchecked {
            totalSupply++;

            balanceOf[to]++;
        }

        ownerOf[id] = to;

        tokenURI[id] = generateTokenURI(NFTSVG.SVGParams({tokenId: id, tokenBalance: 0, tokenScalar: tokenScalar}));

        emit Transfer(address(0), to, id);

        return id;
    }

    // ====================
    // ADMINISTRATIVE LOGIC
    // ====================

    /// @notice Sets the token scalar.
    /// @param _tokenScalar The amount of effect that the deposited underlying tokens have the visual image.
    function setTokenScalar(uint256 _tokenScalar) external requiresTrust {
        tokenScalar = _tokenScalar;

        for (uint256 i = 0; i < totalSupply; i++) {
            tokenURI[i] = generateTokenURI(
                NFTSVG.SVGParams({tokenId: i, tokenBalance: tokenBalances[i], tokenScalar: tokenScalar})
            );
        }

        emit TokenScalarUpdate(msg.sender, tokenScalar);
    }

    /// @notice Sets the token reserve cap.
    /// @param _tokenCap The token amount allowed to be deposited per token id.
    function setTokenCap(uint256 _tokenCap) external requiresTrust {
        tokenCap = _tokenCap;

        emit TokenCapUpdate(msg.sender, tokenCap);
    }

    /// @notice Flips to paused or unpaused.
    function flipPause() external requiresTrust {
        isPaused = !isPaused;

        emit Paused(msg.sender, isPaused);
    }

    /// @notice Flips to active or inactive.
    function flipSale() external requiresTrust {
        isSaleActive = !isSaleActive;

        emit SaleActive(msg.sender, isSaleActive);
    }

    /// @notice Claim all received funds.
    /// @dev Caller will receive any ETH held as float.
    /// @param to Address to send ETH to.
    function claim(address to) external requiresTrust {
        uint256 selfBalance = address(this).balance;

        payable(to).transfer(selfBalance);

        emit Claim(msg.sender, to, selfBalance);
    }

    // =================
    // DESTRUCTION LOGIC
    // =================

    // TODO: decide on wheter this is feasible.
    /// @notice Rescues arbitrary ERC20 tokens send to the contract by sending them to the contract owner.
    /// @dev Caller will receive any ERC20 token held as float.
    /// @param token Address of ERC20 token to rescue.
    function rescue(ERC20 token) external requiresTrust {
        ERC20(token).safeTransfer(msg.sender, ERC20(token).balanceOf(address(this)));

        emit Rescue(msg.sender, address(token));
    }

    // TODO: remove before launch !!
    /// @notice Self destructs, enabling it to be redeployed.
    /// @dev Caller will receive any ETH held as float.
    function destroy() external requiresTrust {
        selfdestruct(payable(msg.sender));
    }

    // ===================
    // RECIEVE ETHER LOGIC
    // ===================

    /// @dev Required for the contract to receive unwrapped ETH.
    receive() external payable {}
}
