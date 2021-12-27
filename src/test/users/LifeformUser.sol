// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.0;

// Vendor
import {ERC20} from "solmate/tokens/ERC20.sol";

// Contracts
import {Lifeform} from "../../Lifeform.sol";

// Interfaces
import {IERC721TokenReceiver} from "../../interfaces/IERC721TokenReceiver.sol";

contract LifeformUser is IERC721TokenReceiver {
    Lifeform lifeform;
    ERC20 underlying;

    constructor(Lifeform _lifeform, ERC20 _underlying) {
        lifeform = _lifeform;
        underlying = _underlying;
    }

    // ==================
    // ERC20-LIKE METHODS
    // ==================

    function balanceOfToken(uint256 tokenId) public virtual returns (uint256) {
        return lifeform.balanceOfToken(tokenId);
    }

    function approveToken(uint256 underlyingAmount) public virtual returns (bool) {
        return underlying.approve(address(lifeform), underlyingAmount);
    }

    function depositToken(uint256 tokenId, uint256 underlyingAmount) public virtual {
        lifeform.depositToken(tokenId, underlyingAmount);
    }

    function withdrawToken(uint256 tokenId, uint256 underlyingAmount) public virtual {
        lifeform.withdrawToken(tokenId, underlyingAmount);
    }

    // ==============
    // ERC721 METHODS
    // ==============

    function onERC721Received(
        address,
        address,
        uint256,
        bytes calldata
    ) public virtual override returns (bytes4) {
        return IERC721TokenReceiver.onERC721Received.selector;
    }

    function approve(address spender, uint256 tokenId) public virtual {
        lifeform.approve(spender, tokenId);
    }

    function setApprovalForAll(address operator, bool approved) public virtual {
        lifeform.setApprovalForAll(operator, approved);
    }

    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual {
        lifeform.transferFrom(from, to, tokenId);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual {
        lifeform.safeTransferFrom(from, to, tokenId);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory data
    ) public {
        lifeform.safeTransferFrom(from, to, tokenId, data);
    }
}
