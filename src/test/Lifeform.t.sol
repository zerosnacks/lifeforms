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

contract User is ERC721Holder, DSTestPlus {
    Lifeform lifeform;

    constructor(Lifeform _lifeform) {
        lifeform = _lifeform;
    }

    function doDeposit(uint256 tokenId, uint256 underlyingAmount) public {
        emit log_named_address("doDeposit", msg.sender);

        return lifeform.deposit(tokenId, underlyingAmount);
    }

    function doWithdraw(uint256 tokenId, uint256 underlyingAmount) public {
        emit log_named_address("doWithdraw", msg.sender);

        return lifeform.withdraw(tokenId, underlyingAmount);
    }
}

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
    address internal immutable alice = address(new User(lifeform));
    address internal immutable bob = address(new User(lifeform));

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

        uint256 id = lifeform.mint{value: salePrice}(usr); // Of course we have to send money with

        assertEq(lifeform.totalSupply(), 1);
        assertEq(lifeform.balanceOf(usr), 1);
        assertEq(lifeform.ownerOf(id), usr);
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

    // function testAtomicTransfer() public {
    //     underlying.mint(self, 10e18);
    //     underlying.approve(address(lifeform), 10e18);

    //     lifeform.flipSale();

    //     uint256 id = lifeform.mint{value: salePrice}(self);
    //     assertEq(lifeform.totalSupply(), 1);
    //     assertEq(lifeform.balanceOf(self), 1);
    //     assertEq(lifeform.ownerOf(id), self);

    //     lifeform.deposit(id, 1e18);
    //     assertEq(underlying.balanceOf(self), 9e18);

    //     lifeform.safeTransferFrom(self, alice, id);
    //     assertEq(lifeform.balanceOf(self), 0);
    //     assertEq(lifeform.balanceOf(alice), 1);
    //     assertEq(lifeform.ownerOf(id), alice);
    //     assertEq(lifeform.tokenBalances(id), 1e18);

    //     // TODO: Make it so you can send requests to the contract as alice

    //     emit log_named_address("testAtomicTransfer", msg.sender);

    //     assertEq(underlying.balanceOf(alice), 0);
    //     User(alice).doWithdraw(id, 1e18);
    //     assertEq(lifeform.tokenBalances(id), 0);
    //     assertEq(underlying.balanceOf(alice), 1e18);

    //     underlying.mint(alice, 10e18);
    //     underlying.approve(alice, 10e18);
    //     User(alice).doDeposit(id, 1e18);
    //     assertEq(lifeform.tokenBalances(id), 2e18);

    //     // TODO: there is currently a problem with the access to the token balance not being transferred to the new user

    //     // alice.withdrawToken(id, 1e18);
    //     // assertEq(underlying.balanceOf(alice), 1e18);

    //     // lifeform.safeTransferFrom(self, alice, id);
    // }
}
