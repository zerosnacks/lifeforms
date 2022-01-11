// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.0;

// Vendor
import {DSTestPlus} from "solmate/test/utils/DSTestPlus.sol";
import {ERC20} from "solmate/tokens/ERC20.sol";
import {MockERC20} from "solmate/test/utils/mocks/MockERC20.sol";

// Contracts
import {Lifeforms} from "../Lifeforms.sol";

// Test utilities
import {LifeformsUser} from "./users/LifeformsUser.sol";

contract LifeformsTest is DSTestPlus {
    Lifeforms lifeforms;
    MockERC20 underlying;

    string private name = "Lifeforms";
    string private symbol = "LIFE";
    uint256 private maxSupply = 3;

    // Users
    address internal immutable self = address(this);

    function setUp() public {
        underlying = new MockERC20("Mock Token", "TKN", 18);

        lifeforms = new Lifeforms(
            maxSupply, // maxSupply
            underlying // underlying
        );
    }

    function invariantMetadata() public {
        assertEq(lifeforms.name(), name);
        assertEq(lifeforms.symbol(), symbol);
    }

    function testMintCap(address usr) public {
        // Contract reverts on address(0) as it is not a valid receiver
        // For fuzzing we override this path with a valid path
        if (usr == address(0)) {
            usr = address(0xBEEF);
        }

        uint256 tokenId1 = lifeforms.mint(usr);
        assertEq(lifeforms.totalSupply(), 1);
        assertEq(lifeforms.balanceOf(usr), 1);
        assertEq(lifeforms.ownerOf(tokenId1), usr);

        uint256 tokenId2 = lifeforms.mint(usr);
        assertEq(lifeforms.totalSupply(), 2);
        assertEq(lifeforms.balanceOf(usr), 2);
        assertEq(lifeforms.ownerOf(tokenId2), usr);

        uint256 tokenId3 = lifeforms.mint(usr);
        assertEq(lifeforms.totalSupply(), 3);
        assertEq(lifeforms.balanceOf(usr), 3);
        assertEq(lifeforms.ownerOf(tokenId3), usr);

        try lifeforms.mint(usr) {
            fail();
        } catch Error(string memory error) {
            assertEq(error, "ALL_TOKENS_MINTED");
        }
    }

    function testAtomicDepositWithdraw() public {
        LifeformsUser usr = new LifeformsUser(lifeforms, underlying);

        underlying.mint(address(usr), 10e18);
        usr.approveToken(10e18);

        uint256 tokenId = lifeforms.mint(address(usr));
        assertEq(lifeforms.totalSupply(), 1);
        assertEq(lifeforms.balanceOf(address(usr)), 1);
        assertEq(lifeforms.ownerOf(tokenId), address(usr));

        uint256 preDepositBal = underlying.balanceOf(address(usr));

        assertEq(lifeforms.tokenBalances(tokenId), 0);

        emit log_named_string("TokenURI 0 BCT", lifeforms.tokenURI(tokenId));

        usr.depositToken(tokenId, 5e18);
        assertEq(lifeforms.tokenBalances(tokenId), 5e18);
        assertEq(underlying.balanceOf(address(usr)), 5e18);

        emit log_named_string("TokenURI 5 BCT", lifeforms.tokenURI(tokenId));

        usr.withdrawToken(tokenId, 5e18);
        assertEq(lifeforms.tokenBalances(tokenId), 0);

        emit log_named_string("TokenURI 0 BCT", lifeforms.tokenURI(tokenId));

        assertEq(underlying.balanceOf(address(usr)), preDepositBal);
    }

    function testDepositWithdraw() public {
        LifeformsUser usr = new LifeformsUser(lifeforms, underlying);

        underlying.mint(address(usr), 10e18);

        uint256 tokenId = lifeforms.mint(address(usr));
        assertEq(lifeforms.totalSupply(), 1);
        assertEq(lifeforms.balanceOf(address(usr)), 1);
        assertEq(lifeforms.ownerOf(tokenId), address(usr));

        usr.approveToken(10e18);
        usr.depositToken(tokenId, 10e18);
        assertEq(lifeforms.balanceOfToken(tokenId), 10e18);
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
        assertEq(lifeforms.balanceOfToken(tokenId), 7e18);
        assertEq(underlying.balanceOf(address(usr)), 3e18);
    }

    function testSafeTransferFromWithApproveDepositWithdraw() public {
        LifeformsUser usr = new LifeformsUser(lifeforms, underlying);
        LifeformsUser receiver = new LifeformsUser(lifeforms, underlying);
        LifeformsUser operator = new LifeformsUser(lifeforms, underlying);

        underlying.mint(address(usr), 100e18);

        // First mint a token
        uint256 tokenId = lifeforms.mint(address(usr));
        assertEq(lifeforms.totalSupply(), 1);
        assertEq(lifeforms.balanceOf(address(usr)), 1);
        assertEq(lifeforms.ownerOf(tokenId), address(usr));

        // The operator should not be able to transfer the unapproved token
        try operator.safeTransferFrom(address(usr), address(receiver), tokenId) {
            fail();
        } catch Error(string memory error) {
            assertEq(error, "NOT_AUTHORIZED");
        }

        // Then owner should be able to deposit underlying token after approving
        usr.approveToken(10e18);
        usr.depositToken(tokenId, 10e18);
        assertEq(lifeforms.balanceOfToken(tokenId), 10e18);
        assertEq(underlying.balanceOf(address(usr)), 90e18);

        // Then approve an operator for the token
        usr.approve(address(operator), tokenId);

        // The operator should be able to withdraw the underlying token
        operator.withdrawToken(tokenId, 1e18);
        assertEq(lifeforms.balanceOfToken(tokenId), 9e18);
        assertEq(underlying.balanceOf(address(operator)), 1e18);

        // The operator should be able to transfer the approved token
        operator.safeTransferFrom(address(usr), address(receiver), tokenId);
        assertEq(lifeforms.balanceOf(address(usr)), 0);
        assertEq(lifeforms.balanceOf(address(receiver)), 1);
        assertEq(lifeforms.ownerOf(tokenId), address(receiver));

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
            assertEq(error, "NOT_AUTHORIZED");
        }

        // The new owner should be able to withdraw the underlying token
        receiver.withdrawToken(tokenId, 4e18);
        assertEq(lifeforms.balanceOfToken(tokenId), 5e18);
        assertEq(underlying.balanceOf(address(receiver)), 4e18);

        // Then new owner should be able to deposit underlying token after approving
        receiver.approveToken(3e18);
        receiver.depositToken(tokenId, 3e18);
        assertEq(lifeforms.balanceOfToken(tokenId), 8e18);
        assertEq(underlying.balanceOf(address(receiver)), 1e18);
    }

    function testSafeTransferFromWithApproveForAll() public {
        LifeformsUser usr = new LifeformsUser(lifeforms, underlying);
        LifeformsUser receiver = new LifeformsUser(lifeforms, underlying);
        LifeformsUser operator = new LifeformsUser(lifeforms, underlying);

        // First mint a token
        uint256 tokenId = lifeforms.mint(address(usr));
        assertEq(lifeforms.totalSupply(), 1);
        assertEq(lifeforms.balanceOf(address(usr)), 1);
        assertEq(lifeforms.ownerOf(tokenId), address(usr));

        // The operator should not be able to transfer the unapproved token
        try operator.safeTransferFrom(address(usr), address(receiver), tokenId) {
            fail();
        } catch Error(string memory error) {
            assertEq(error, "NOT_AUTHORIZED");
        }

        // Then approve an operator
        usr.setApprovalForAll(address(operator), true);

        // The operator should be able to transfer any token from usr
        operator.safeTransferFrom(address(usr), address(receiver), tokenId);
        assertEq(lifeforms.balanceOf(address(usr)), 0);
        assertEq(lifeforms.balanceOf(address(receiver)), 1);
        assertEq(lifeforms.ownerOf(tokenId), address(receiver));

        // The operator now should not be able to transfer the token
        // since it was not approved by the current user
        try operator.safeTransferFrom(address(receiver), address(usr), tokenId) {
            fail();
        } catch Error(string memory error) {
            assertEq(error, "NOT_AUTHORIZED");
        }
    }

    function testOwner() public {
        assertEq(lifeforms.owner(), address(this));
    }

    function testClaim() public {
        LifeformsUser usr = new LifeformsUser(lifeforms, underlying);

        uint256 initialOwnerBalance = address(this).balance;
        assertEq(address(lifeforms).balance, 0);

        lifeforms.mint{value: 1 ether}(address(usr));
        assertEq(address(lifeforms).balance, 1 ether);
        assertEq(address(this).balance, initialOwnerBalance - 1 ether);

        try usr.claim() {
            fail();
        } catch Error(string memory error) {
            assertEq(error, "NOT_OWNER");
        }

        lifeforms.claim();

        assertEq(address(lifeforms).balance, 0);
        assertEq(address(this).balance, initialOwnerBalance);
    }

    // Required for `testClaim()`
    // solhint-disable-next-line no-empty-blocks
    receive() external payable {}
}
