// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.10;

// Vendor
import {DSTestPlus} from "solmate/test/utils/DSTestPlus.sol";

// Test utilities
import {MockERC721} from "../mocks/MockERC721.sol";
import {ERC721User} from "../users/ERC721User.sol";

contract ERC721Test is DSTestPlus {
    MockERC721 token;

    function setUp() public {
        token = new MockERC721("Token", "TKN");
    }

    function invariantMetadata() public {
        assertEq(token.name(), "Token");
        assertEq(token.symbol(), "TKN");
    }

    function testMetadata(string memory name, string memory symbol) public {
        MockERC721 tkn = new MockERC721(name, symbol);
        assertEq(tkn.name(), name);
        assertEq(tkn.symbol(), symbol);
    }

    function testMint(
        address usr,
        uint256 tokenId,
        string memory tokenURI
    ) public {
        token.mint(usr, tokenId, tokenURI);

        assertEq(token.totalSupply(), 1);
        assertEq(token.balanceOf(usr), 1);
        assertEq(token.ownerOf(tokenId), usr);
    }

    function testMintSameToken(
        address usr,
        uint256 tokenId,
        string memory tokenURI
    ) public {
        if (usr == address(0)) return;

        token.mint(usr, tokenId, tokenURI);

        try token.mint(usr, tokenId, tokenURI) {
            fail();
        } catch Error(string memory error) {
            assertEq(error, "ALREADY_MINTED");
        }
    }

    function testSafeTransferFromWithApprove(uint256 tokenId) public {
        ERC721User usr = new ERC721User(token);
        ERC721User receiver = new ERC721User(token);
        ERC721User operator = new ERC721User(token);

        // first mint a token
        token.mint(address(usr), tokenId, "");

        // The operator should not be able to transfer the unapproved token
        try operator.safeTransferFrom(address(usr), address(receiver), tokenId) {
            fail();
        } catch Error(string memory error) {
            assertEq(error, "NOT_APPROVED");
        }

        // then approve an operator for the token
        usr.approve(address(operator), tokenId);

        // The operator should be able to transfer the approved token
        operator.safeTransferFrom(address(usr), address(receiver), tokenId);
        assertEq(token.balanceOf(address(usr)), 0);
        assertEq(token.balanceOf(address(receiver)), 1);
        assertEq(token.ownerOf(tokenId), address(receiver));

        // The operator now should not be able to transfer the token again
        // since it was not approved by the current user
        try operator.safeTransferFrom(address(receiver), address(usr), tokenId) {
            fail();
        } catch Error(string memory error) {
            assertEq(error, "NOT_APPROVED");
        }
    }

    function testSafeTransferFromWithApproveForAll(uint256 tokenId) public {
        ERC721User usr = new ERC721User(token);
        ERC721User receiver = new ERC721User(token);
        ERC721User operator = new ERC721User(token);

        // first mint two tokens, only one will be approved
        token.mint(address(usr), tokenId, "");

        // The operator should not be able to transfer the unapproved token
        try operator.safeTransferFrom(address(usr), address(receiver), tokenId) {
            fail();
        } catch Error(string memory error) {
            assertEq(error, "NOT_APPROVED");
        }

        // then approve an operator
        usr.setApprovalForAll(address(operator), true);

        // The operator should be able to transfer any token from usr
        operator.safeTransferFrom(address(usr), address(receiver), tokenId);
        assertEq(token.balanceOf(address(usr)), 0);
        assertEq(token.balanceOf(address(receiver)), 1);
        assertEq(token.ownerOf(tokenId), address(receiver));

        // The operator now should not be able to transfer the token
        // since it was not approved by the current user
        try operator.safeTransferFrom(address(receiver), address(usr), tokenId) {
            fail();
        } catch Error(string memory error) {
            assertEq(error, "NOT_APPROVED");
        }
    }
}
