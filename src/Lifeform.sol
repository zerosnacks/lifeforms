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
    /// @param underlyingAmount The amount of underlying tokens that are allowed to be deposited.
    event TokenTotalReserveCapUpdate(address indexed user, uint256 underlyingAmount);

    /// @notice Emitted after a succesful rescue.
    /// @param user The address that rescued the ERC20 token.
    /// @param token The ERC20 token that was rescued.
    event Rescue(address indexed user, address token);

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

    // ==================
    // ERC20-LIKE STORAGE
    // ==================

    /// @notice Tracks the total amount of underlying tokens deposited.
    uint256 public tokenTotalReserve;

    /// @notice Caps the amount of underlying tokens that are allowed to be deposited.
    uint256 public tokenTotalReserveCap;

    /// @notice Mapping of underlying token balances.
    mapping(uint256 => uint256) public tokenBalances;

    // ===========
    // CONSTRUCTOR
    // ===========

    constructor(
        string memory _name,
        string memory _symbol,
        uint256 _maxSupply,
        uint256 _salePrice,
        uint256 _tokenTotalReserveCap,
        ERC20 _underlying
    ) ERC721(_name, _symbol) Auth(Auth(msg.sender).owner(), Auth(msg.sender).authority()) {
        maxSupply = _maxSupply;
        salePrice = _salePrice;
        UNDERLYING = _underlying;
        BASE_UNIT = 10**_underlying.decimals();
        tokenTotalReserveCap = _tokenTotalReserveCap;
    }

    // ==========
    // MINT LOGIC
    // ==========

    /// @notice Mint token to address
    /// @param to The address to mint to.
    function mint(address to) external payable whenUnpaused {
        require(balanceOf[msg.sender] <= 2, "USER_LIMITED_TO_MINT_TWO");
        require(totalSupply + 1 <= maxSupply, "ALL_TOKENS_MINTED");
        require(isSaleActive, "SALE_NOT_ACTIVE");
        require(salePrice <= msg.value, "INSUFFICIENT_ETHER");

        _mint(to, totalSupply, "");
    }

    /// @notice Get the token URI by token id.
    /// @param tokenId The token id to get token URI of.
    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        require(ownerOf[tokenId] != address(0), "TOKEN_MUST_EXIST");

        NFTSVG.SVGParams memory svgParams = NFTSVG.SVGParams({
            tokenId: tokenId,
            tokenBalance: tokenBalances[tokenId] / BASE_UNIT,
            totalTokenReserves: tokenTotalReserve / BASE_UNIT
        });

        return generateTokenURI(svgParams);
    }

    // ================
    // ERC20-LIKE LOGIC
    // ================

    /// @notice Approve this contract for moving underlying tokens
    /// @param underlyingAmount The amount of underlying tokens to approve.
    function approveToken(uint256 underlyingAmount) external whenUnpaused {
        UNDERLYING.approve(address(this), underlyingAmount);
    }

    /// @notice Deposit a specific amount of underlying tokens from an owned token id.
    /// @param tokenId The token id to deposit to.
    /// @param underlyingAmount The amount of the underlying tokens to deposit.
    function depositToken(uint256 tokenId, uint256 underlyingAmount) external nonReentrant whenUnpaused {
        // We don't allow depositing 0 to prevent emitting a useless event.
        require(underlyingAmount != 0, "AMOUNT_CANNOT_BE_ZERO");
        require(_isApprovedOrOwner(tokenId, msg.sender), "TOKEN_MUST_BE_OWNED");
        require(tokenTotalReserve + underlyingAmount <= tokenTotalReserveCap, "TOKEN_RESERVE_IS_CAPPED");

        // Transfer the provided amount of underlying tokens from msg.sender to this contract.
        UNDERLYING.safeTransferFrom(msg.sender, address(this), underlyingAmount);

        // Cannot overflow because a user's balance
        // will never be larger than the total supply.
        unchecked {
            tokenBalances[tokenId] += underlyingAmount;
            tokenTotalReserve += underlyingAmount;
        }

        emit TokenDeposit(msg.sender, tokenId, underlyingAmount);
    }

    /// @notice Withdraw a specific amount of underlying tokens from an owned token id.
    /// @param tokenId The token id to withdraw from.
    /// @param underlyingAmount The amount of underlying tokens to withdraw.
    function withdrawToken(uint256 tokenId, uint256 underlyingAmount) external nonReentrant whenUnpaused {
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

    // ====================
    // ADMINISTRATIVE LOGIC
    // ====================

    /// @notice Sets the token reserve cap.
    /// @param _tokenTotalReserveCap The token amount allowed to be deposited in the contract.
    function setTokenReserveCap(uint256 _tokenTotalReserveCap) external requiresAuth {
        tokenTotalReserveCap = _tokenTotalReserveCap;

        emit TokenTotalReserveCapUpdate(msg.sender, tokenTotalReserveCap);
    }

    /// @notice Flips to paused or unpaused.
    function flipPause() external requiresAuth {
        isPaused = !isPaused;

        emit Paused(msg.sender, isPaused);
    }

    /// @notice Flips to active or inactive.
    function flipSale() external requiresAuth {
        isSaleActive = !isSaleActive;

        emit SaleActive(msg.sender, isSaleActive);
    }

    /// @notice Claim all received funds.
    /// @dev Caller will receive any ETH held as float.
    /// @param to Address to send ETH to.
    function claim(address to) external requiresAuth {
        payable(to).transfer(address(this).balance);
    }

    // =================
    // DESTRUCTION LOGIC
    // =================

    /// @notice Rescues arbitrary ERC20 tokens send to the contract by sending them to the contract owner.
    /// @dev Caller will receive any ERC20 token held as float.
    /// @param token Address of ERC20 token to rescue.
    function rescue(ERC20 token) external requiresAuth {
        ERC20(token).safeTransfer(msg.sender, ERC20(token).balanceOf(address(this)));

        emit Rescue(msg.sender, address(token));
    }

    // TODO: remove before launch !!
    /// @notice Self destructs, enabling it to be redeployed.
    /// @dev Caller will receive any ETH held as float.
    function destroy() external requiresAuth {
        selfdestruct(payable(msg.sender));
    }

    // ===================
    // RECIEVE ETHER LOGIC
    // ===================

    /// @dev Required for the contract to receive unwrapped ETH.
    receive() external payable {}
}
