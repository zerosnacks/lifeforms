// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.0;

// Vendor
import {DSTestPlus} from "solmate/test/utils/DSTestPlus.sol";
import {ERC20} from "solmate/tokens/ERC20.sol";
import {MockERC20} from "solmate/test/utils/mocks/MockERC20.sol";

// Contracts
import {Lifeform} from "../Lifeform.sol";

// Utilities
import {ERC721User} from "./abstracts/users/ERC721User.sol";

contract LifeformTest is DSTestPlus {
    Lifeform lifeform;
    MockERC20 underlying;

    string private name = "Lifeform";
    string private symbol = "LIFE";
    uint256 private maxSupply = 1000;
    uint256 private salePrice = 1e16;
    uint256 private tokenCap = 25e18;
    uint256 private tokenScalar = 100;

    // Users
    address internal immutable self = address(this);

    // Proxy
    // 0x2f800db0fdb5223b3c3f354886d907a671414a7f

    // Use Mock BCT token
    // 0xddb857badb65657ebc766c90045403875fc29d27

    function setUp() public {
        underlying = new MockERC20("Mock Token", "TKN", 18);

        lifeform = new Lifeform(
            maxSupply, // maxSupply
            salePrice, // salePrice
            tokenCap, // tokenCap
            tokenScalar, // tokenScalar
            underlying // underlying
        );
    }

    function invariantMetadata() public {
        assertEq(lifeform.name(), name);
        assertEq(lifeform.symbol(), symbol);
    }

    function testMint(address usr) public {
        lifeform.flipSale();

        uint256 tokenId = lifeform.mint{value: salePrice}(usr); // Of course we have to send money with

        assertEq(lifeform.totalSupply(), 1);
        assertEq(lifeform.balanceOf(usr), 1);
        assertEq(lifeform.ownerOf(tokenId), usr);
    }

    function testAtomicDepositWithdraw() public {
        underlying.mint(self, 10e18);
        underlying.approve(address(lifeform), 10e18);

        lifeform.flipSale();

        uint256 id = lifeform.mint{value: salePrice}(self);

        assertEq(lifeform.totalSupply(), 1);
        assertEq(lifeform.balanceOf(self), 1);
        assertEq(lifeform.ownerOf(id), self);

        uint256 preDepositBal = underlying.balanceOf(self);

        assertEq(lifeform.tokenBalances(id), 0);

        lifeform.deposit(id, 1e18);

        assertEq(lifeform.tokenBalances(id), 1e18);

        lifeform.withdraw(id, 1e18);

        assertEq(lifeform.tokenBalances(id), 0);
        assertEq(underlying.balanceOf(self), preDepositBal);
    }

    function testTokenURI() public {
        underlying.mint(self, 100e18);
        underlying.approve(address(lifeform), 100e18);
        lifeform.flipSale();

        uint256 id = lifeform.mint{value: salePrice}(self);
        assertEq(lifeform.totalSupply(), 1);
        assertEq(lifeform.balanceOf(self), 1);
        assertEq(lifeform.ownerOf(id), self);

        emit log_named_string("TokenURI", lifeform.tokenURI(id));

        lifeform.deposit(id, 20e18);

        emit log_named_string("TokenURI", lifeform.tokenURI(id));
    }

    function testSafeTransferFromWithApprove() public {
        lifeform.flipSale();

        ERC721User usr = new ERC721User(lifeform);
        ERC721User receiver = new ERC721User(lifeform);
        ERC721User operator = new ERC721User(lifeform);

        // First mint a token
        uint256 tokenId = lifeform.mint{value: salePrice}(address(usr));

        // The operator should not be able to transfer the unapproved token
        try operator.safeTransferFrom(address(usr), address(receiver), tokenId) {
            fail();
        } catch Error(string memory error) {
            assertEq(error, "NOT_APPROVED");
        }

        // Then approve an operator for the token
        usr.approve(address(operator), tokenId);

        // The operator should be able to transfer the approved token
        operator.safeTransferFrom(address(usr), address(receiver), tokenId);
        assertEq(lifeform.balanceOf(address(usr)), 0);
        assertEq(lifeform.balanceOf(address(receiver)), 1);
        assertEq(lifeform.ownerOf(tokenId), address(receiver));

        // The operator now should not be able to transfer the token again
        // since it was not approved by the current user
        try operator.safeTransferFrom(address(receiver), address(usr), tokenId) {
            fail();
        } catch Error(string memory error) {
            assertEq(error, "NOT_APPROVED");
        }
    }

    function testSafeTransferFromWithApproveForAll() public {
        lifeform.flipSale();

        ERC721User usr = new ERC721User(lifeform);
        ERC721User receiver = new ERC721User(lifeform);
        ERC721User operator = new ERC721User(lifeform);

        // First mint a token
        uint256 tokenId = lifeform.mint{value: salePrice}(address(usr));

        // The operator should not be able to transfer the unapproved token
        try operator.safeTransferFrom(address(usr), address(receiver), tokenId) {
            fail();
        } catch Error(string memory error) {
            assertEq(error, "NOT_APPROVED");
        }

        // Then approve an operator
        usr.setApprovalForAll(address(operator), true);

        // The operator should be able to transfer any token from usr
        operator.safeTransferFrom(address(usr), address(receiver), tokenId);
        assertEq(lifeform.balanceOf(address(usr)), 0);
        assertEq(lifeform.balanceOf(address(receiver)), 1);
        assertEq(lifeform.ownerOf(tokenId), address(receiver));

        // The operator now should not be able to transfer the token
        // since it was not approved by the current user
        try operator.safeTransferFrom(address(receiver), address(usr), tokenId) {
            fail();
        } catch Error(string memory error) {
            assertEq(error, "NOT_APPROVED");
        }
    }
}
