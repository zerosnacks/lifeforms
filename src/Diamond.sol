// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.0;

// Vendor
import {Auth} from "solmate/auth/Auth.sol";

// Abstracts
import {ERC721} from "./abstracts/ERC721.sol";

/// @title Diamond
/// @notice Carbon bearing NFT
contract Diamond is ERC721, Auth {
    // =========
    // CONSTANTS
    // =========

    // Whether the sale is active.
    bool public isSaleActive;

    // Maximum number of instances that can be minted on this contract.
    uint256 public maxSupply;

    // Maximum number of instances that can be minted at once by a single user.
    uint256 public maxAmount;

    // Price of each minted instance.
    uint256 public salePrice = 0.08 ether;

    // Base URI of the project
    string public baseURI;

    // ===========
    // CONSTRUCTOR
    // ===========

    constructor(
        string memory _name,
        string memory _symbol,
        string memory _baseURI,
        uint256 _maxSupply
    )
        ERC721(_name, _symbol)
        Auth(Auth(msg.sender).owner(), Auth(msg.sender).authority())
    {
        baseURI = _baseURI;
        maxSupply = _maxSupply;
    }

    // ==========
    // MINT LOGIC
    // ==========

    function mintToken(address to, uint256 amount) external payable {
        require(totalSupply + amount <= maxSupply, "ALL_TOKENS_MINTED");
        require(isSaleActive, "SALE_NOT_ACTIVE");
        require(amount > 0, "AMOUNT_IS_ZERO");
        require(amount <= maxAmount, "AMOUNT_EXCEEDS_MAX_MOUNT");
        require(salePrice * amount <= msg.value, "INSUFFICIENT_ETHER");

        for (uint256 i = 0; i < amount; i++) {
            if (totalSupply < maxSupply) {
                _mint(
                    to,
                    totalSupply,
                    string(abi.encodePacked(baseURI, totalSupply))
                );
            }
        }
    }

    // Construct a Uniswap V3-like SVG
    // https://etherscan.io/address/0x91ae842a5ffd8d12023116943e72a606179294f3#code#F35#L396
    // function tokenURI(uint256 tokenId) public view override returns (string) {
    //     string[17] memory parts;
    // }

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
