// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.0;

// Vendor
import {DSTestPlus} from "solmate/test/utils/DSTestPlus.sol";
import {ERC20} from "solmate/tokens/ERC20.sol";
import {MockERC20} from "solmate/test/utils/mocks/MockERC20.sol";

// Contracts
import {Lifeform} from "../Lifeform.sol";

// Utilities
import {ERC721Holder} from "./utilities/ERC721Holder.sol";

contract User is ERC721Holder {}

contract LifeformTest is DSTestPlus {
    Lifeform lifeform;
    MockERC20 underlying;

    string private name = "Lifeform";
    string private symbol = "LIFE";
    uint256 private maxSupply = 1000;
    uint256 private salePrice = 0.1 ether;
    uint256 private tokenCap = 5e18;

    // Users
    User aliceUser = new User();
    User bobUser = new User();

    address internal immutable self = address(this);
    address internal immutable alice = address(aliceUser);
    address internal immutable bob = address(bobUser);

    // Proxy
    // 0x2f800db0fdb5223b3c3f354886d907a671414a7f

    // Use Mock BCT token
    // 0xddb857badb65657ebc766c90045403875fc29d27

    function setUp() public {
        underlying = new MockERC20("Mock Token", "TKN", 18);

        lifeform = new Lifeform(
            name, // name
            symbol, // symbol
            maxSupply, // maxSupply
            salePrice, // salePrice
            tokenCap, // tokenCap
            underlying // underlying
        );
    }

    function invariantMetadata() public {
        assertEq(lifeform.name(), name);
        assertEq(lifeform.symbol(), symbol);
    }

    function testMint(address usr) public {
        lifeform.flipSale();

        uint256 id = lifeform.mint{value: 0.1 ether}(usr); // Of course we have to send money with

        assertEq(lifeform.totalSupply(), 1);
        assertEq(lifeform.balanceOf(usr), 1);
        assertEq(lifeform.ownerOf(id), usr);
    }

    function testAtomicDepositWithdraw() public {
        underlying.mint(self, 10e18);
        underlying.approve(address(lifeform), 10e18);

        lifeform.flipSale();

        uint256 id = lifeform.mint{value: 0.1 ether}(self);

        assertEq(lifeform.totalSupply(), 1);
        assertEq(lifeform.balanceOf(self), 1);
        assertEq(lifeform.ownerOf(id), self);

        uint256 preDepositBal = underlying.balanceOf(self);

        assertEq(lifeform.tokenBalances(id), 0);

        lifeform.deposit(id, 1e18);

        assertEq(lifeform.tokenBalances(id), 1e18);

        lifeform.withdraw(self, id, 1e18);

        assertEq(lifeform.tokenBalances(id), 0);
        assertEq(underlying.balanceOf(self), preDepositBal);
    }

    function testAtomicTransferAliceBob() public {
        underlying.mint(self, 10e18);
        underlying.approve(address(lifeform), 10e18);

        lifeform.flipSale();

        uint256 id = lifeform.mint{value: 0.1 ether}(self);
        assertEq(lifeform.totalSupply(), 1);
        assertEq(lifeform.balanceOf(self), 1);
        assertEq(lifeform.ownerOf(id), self);

        lifeform.deposit(id, 1e18);
        assertEq(underlying.balanceOf(self), 9e18);

        lifeform.safeTransferFrom(self, alice, id);
        assertEq(lifeform.balanceOf(self), 0);
        assertEq(lifeform.balanceOf(alice), 1);
        assertEq(lifeform.ownerOf(id), alice);
        assertEq(lifeform.tokenBalances(id), 1e18);

        // TODO: Make it so you can send requests to the contract as alice

        // assertEq(underlying.balanceOf(alice), 0);
        // lifeform.withdraw(alice, id, 1e18);
        // assertEq(lifeform.tokenBalances(id), 0);
        // assertEq(underlying.balanceOf(alice), 1e18);

        // underlying.mint(alice, 10e18);
        // underlying.approve(alice, 10e18);
        // LifeformUser(alice).deposit(id, 1e18);
        // assertEq(lifeform.tokenBalances(id), 2e18);

        // TODO: there is currently a problem with the access to the token balance not being transferred to the new user

        // alice.withdrawToken(id, 1e18);
        // assertEq(underlying.balanceOf(alice), 1e18);

        // lifeform.safeTransferFrom(self, alice, id);
    }
}
