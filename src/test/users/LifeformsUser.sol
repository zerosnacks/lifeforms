// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.0;

// Vendor
import {ERC20} from "solmate/tokens/ERC20.sol";
import {ERC721TokenReceiver} from "solmate/tokens/ERC721.sol";

// Contracts
import {Lifeforms} from "../../Lifeforms.sol";

contract LifeformsUser is ERC721TokenReceiver {
    Lifeforms lifeforms;
    ERC20 underlying;

    constructor(Lifeforms _lifeforms, ERC20 _underlying) {
        lifeforms = _lifeforms;
        underlying = _underlying;
    }

    // ==================
    // ERC20-LIKE METHODS
    // ==================

    function balanceOfToken(uint256 tokenId) public virtual returns (uint256) {
        return lifeforms.balanceOfToken(tokenId);
    }

    function approveToken(uint256 underlyingAmount) public virtual returns (bool) {
        return underlying.approve(address(lifeforms), underlyingAmount);
    }

    function depositToken(uint256 tokenId, uint256 underlyingAmount) public virtual {
        lifeforms.depositToken(tokenId, underlyingAmount);
    }

    function withdrawToken(uint256 tokenId, uint256 underlyingAmount) public virtual {
        lifeforms.withdrawToken(tokenId, underlyingAmount);
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
        return ERC721TokenReceiver.onERC721Received.selector;
    }

    function approve(address spender, uint256 tokenId) public virtual {
        lifeforms.approve(spender, tokenId);
    }

    function setApprovalForAll(address operator, bool approved) public virtual {
        lifeforms.setApprovalForAll(operator, approved);
    }

    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual {
        lifeforms.transferFrom(from, to, tokenId);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual {
        lifeforms.safeTransferFrom(from, to, tokenId);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory data
    ) public {
        lifeforms.safeTransferFrom(from, to, tokenId, data);
    }
}
