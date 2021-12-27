// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.0;

// Vendor
import {DSTestPlus} from "solmate/test/utils/DSTestPlus.sol";
import {ERC20} from "solmate/tokens/ERC20.sol";
import {MockERC20} from "solmate/test/utils/mocks/MockERC20.sol";

// Contracts
import {Lifeform} from "../Lifeform.sol";

// Test utilities
import {LifeformUser} from "./users/LifeformUser.sol";

contract LifeformLogicTest is DSTestPlus {
    Lifeform private lifeform;
    MockERC20 private underlying;

    string private name = "Lifeform";
    string private symbol = "LIFE";
    uint256 private maxSupply = 3;
    uint256 private salePrice = 10e18;
    uint256 private tokenCap = 10e18;
    uint256 private tokenScalar = 250;

    // Users
    address internal immutable self = address(this);

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

    function testFailSaleNotActive(address usr) public {
        lifeform.mint{value: salePrice}(address(usr));
    }

    function testMintCap(address usr) public {
        lifeform.flipSale();

        uint256 tokenId1 = lifeform.mint{value: salePrice}(usr);
        assertEq(lifeform.totalSupply(), 1);
        assertEq(lifeform.balanceOf(usr), 1);
        assertEq(lifeform.ownerOf(tokenId1), usr);

        uint256 tokenId2 = lifeform.mint{value: salePrice}(usr);
        assertEq(lifeform.totalSupply(), 2);
        assertEq(lifeform.balanceOf(usr), 2);
        assertEq(lifeform.ownerOf(tokenId2), usr);

        uint256 tokenId3 = lifeform.mint{value: salePrice}(usr);
        assertEq(lifeform.totalSupply(), 3);
        assertEq(lifeform.balanceOf(usr), 3);
        assertEq(lifeform.ownerOf(tokenId3), usr);

        try lifeform.mint{value: salePrice}(usr) {
            fail();
        } catch Error(string memory error) {
            assertEq(error, "ALL_TOKENS_MINTED");
        }
    }

    function testAtomicDepositWithdraw() public {
        underlying.mint(self, 10e18);
        underlying.approve(address(lifeform), 10e18);

        lifeform.flipSale();

        uint256 tokenId = lifeform.mint{value: salePrice}(self);

        assertEq(lifeform.totalSupply(), 1);
        assertEq(lifeform.balanceOf(self), 1);
        assertEq(lifeform.ownerOf(tokenId), self);

        uint256 preDepositBal = underlying.balanceOf(self);

        assertEq(lifeform.tokenBalances(tokenId), 0);

        lifeform.depositToken(tokenId, 1e18);

        assertEq(lifeform.tokenBalances(tokenId), 1e18);

        lifeform.withdrawToken(tokenId, 1e18);

        assertEq(lifeform.tokenBalances(tokenId), 0);
        assertEq(underlying.balanceOf(self), preDepositBal);
    }

    function testTokenURI() public {
        LifeformUser usr = new LifeformUser(lifeform, underlying);

        lifeform.flipSale();
        underlying.mint(address(usr), 5e18);
        usr.approveToken(5e18);

        uint256 tokenId = lifeform.mint{value: salePrice}(address(usr));
        assertEq(lifeform.totalSupply(), 1);
        assertEq(lifeform.balanceOf(address(usr)), 1);
        assertEq(lifeform.ownerOf(tokenId), address(usr));

        emit log_named_string("TokenURI", lifeform.tokenURI(tokenId));

        usr.depositToken(tokenId, 5e18);

        emit log_named_string("TokenURI", lifeform.tokenURI(tokenId));
    }

    function testTokenCap() public {
        LifeformUser usr = new LifeformUser(lifeform, underlying);

        lifeform.flipSale();
        underlying.mint(address(usr), 100e18);

        // First mint a token
        uint256 tokenId = lifeform.mint{value: salePrice}(address(usr));
        assertEq(lifeform.totalSupply(), 1);
        assertEq(lifeform.balanceOf(address(usr)), 1);
        assertEq(lifeform.ownerOf(tokenId), address(usr));

        usr.approveToken(100e18);

        // Token deposit should be limited to token cap
        try usr.depositToken(tokenId, 100e18) {
            fail();
        } catch Error(string memory error) {
            assertEq(error, "TOKEN_RESERVE_IS_CAPPED");
        }
    }

    function testDepositWithdraw() public {
        LifeformUser usr = new LifeformUser(lifeform, underlying);

        lifeform.flipSale();
        underlying.mint(address(usr), 10e18);

        uint256 tokenId = lifeform.mint{value: salePrice}(address(usr));
        assertEq(lifeform.totalSupply(), 1);
        assertEq(lifeform.balanceOf(address(usr)), 1);
        assertEq(lifeform.ownerOf(tokenId), address(usr));

        usr.approveToken(10e18);
        usr.depositToken(tokenId, 10e18);
        assertEq(lifeform.balanceOfToken(tokenId), 10e18);
        assertEq(underlying.balanceOf(address(usr)), 0);

        // Token withdraw limit should be limited to token id balance
        try usr.withdrawToken(tokenId, 100e18) {
            fail();
        } catch Error(string memory error) {
            assertEq(error, "AMOUNT_EXCEEDS_TOKEN_ID_BALANCE");
        }

        usr.withdrawToken(tokenId, 1e18);
        usr.withdrawToken(tokenId, 1e18);
        usr.withdrawToken(tokenId, 1e18);
        assertEq(lifeform.balanceOfToken(tokenId), 7e18);
        assertEq(underlying.balanceOf(address(usr)), 3e18);
    }

    function testSafeTransferFromWithApproveDepositWithdraw() public {
        LifeformUser usr = new LifeformUser(lifeform, underlying);
        LifeformUser receiver = new LifeformUser(lifeform, underlying);
        LifeformUser operator = new LifeformUser(lifeform, underlying);

        lifeform.flipSale();
        underlying.mint(address(usr), 100e18);

        // First mint a token
        uint256 tokenId = lifeform.mint{value: salePrice}(address(usr));
        assertEq(lifeform.totalSupply(), 1);
        assertEq(lifeform.balanceOf(address(usr)), 1);
        assertEq(lifeform.ownerOf(tokenId), address(usr));

        // The operator should not be able to transfer the unapproved token
        try operator.safeTransferFrom(address(usr), address(receiver), tokenId) {
            fail();
        } catch Error(string memory error) {
            assertEq(error, "NOT_APPROVED");
        }

        // Then owner should be able to deposit underlying token after approving
        usr.approveToken(10e18);
        usr.depositToken(tokenId, 10e18);
        assertEq(lifeform.balanceOfToken(tokenId), 10e18);
        assertEq(underlying.balanceOf(address(usr)), 90e18);

        // Then approve an operator for the token
        usr.approve(address(operator), tokenId);

        // The operator should be able to withdraw the underlying token
        operator.withdrawToken(tokenId, 1e18);
        assertEq(lifeform.balanceOfToken(tokenId), 9e18);
        assertEq(underlying.balanceOf(address(operator)), 1e18);

        // The operator should be able to transfer the approved token
        operator.safeTransferFrom(address(usr), address(receiver), tokenId);
        assertEq(lifeform.balanceOf(address(usr)), 0);
        assertEq(lifeform.balanceOf(address(receiver)), 1);
        assertEq(lifeform.ownerOf(tokenId), address(receiver));

        // The operator now should not be able to withdraw the underlying token
        try operator.withdrawToken(tokenId, 5e18) {
            fail();
        } catch Error(string memory error) {
            assertEq(error, "TOKEN_MUST_BE_OWNED");
        }

        // The operator now should not be able to transfer the token again
        // since it was not approved by the current user
        try operator.safeTransferFrom(address(receiver), address(usr), tokenId) {
            fail();
        } catch Error(string memory error) {
            assertEq(error, "NOT_APPROVED");
        }

        // The new owner should be able to withdraw the underlying token
        receiver.withdrawToken(tokenId, 4e18);
        assertEq(lifeform.balanceOfToken(tokenId), 5e18);
        assertEq(underlying.balanceOf(address(receiver)), 4e18);

        // Then new owner should be able to deposit underlying token after approving
        receiver.approveToken(3e18);
        receiver.depositToken(tokenId, 3e18);
        assertEq(lifeform.balanceOfToken(tokenId), 8e18);
        assertEq(underlying.balanceOf(address(receiver)), 1e18);
    }

    function testSafeTransferFromWithApproveForAll() public {
        lifeform.flipSale();

        LifeformUser usr = new LifeformUser(lifeform, underlying);
        LifeformUser receiver = new LifeformUser(lifeform, underlying);
        LifeformUser operator = new LifeformUser(lifeform, underlying);

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

contract LifeformGasTest is DSTestPlus {
    Lifeform private lifeform;
    MockERC20 private underlying;
    uint256 private tokenId;
    LifeformUser private usr;

    string private name = "Lifeform";
    string private symbol = "LIFE";
    uint256 private maxSupply = 100;
    uint256 private salePrice = 10e18;
    uint256 private tokenCap = 10e18;
    uint256 private tokenScalar = 250;

    function setUp() public {
        underlying = new MockERC20("Mock Token", "TKN", 18);

        lifeform = new Lifeform(
            maxSupply, // maxSupply
            salePrice, // salePrice
            tokenCap, // tokenCap
            tokenScalar, // tokenScalar
            underlying // underlying
        );

        usr = new LifeformUser(lifeform, underlying);

        lifeform.flipSale();
        underlying.mint(address(usr), 20e18);
        usr.approveToken(20e18);

        tokenId = lifeform.mint{value: salePrice}(address(usr));
    }

    function testMint() public {
        tokenId = lifeform.mint{value: salePrice}(address(usr));
    }

    function testDepositToken() public {
        usr.depositToken(tokenId, 5e18);
    }

    function testWithdrawToken() public {
        usr.withdrawToken(tokenId, 4e18);
    }
}
