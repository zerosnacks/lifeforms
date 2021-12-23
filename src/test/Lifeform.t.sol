// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.0;

// Vendor
import {DSTestPlus} from "solmate/test/utils/DSTestPlus.sol";
import {ERC20} from "solmate/tokens/ERC20.sol";
import {MockERC20} from "solmate/test/utils/mocks/MockERC20.sol";

// Contracts
import {Lifeform} from "../Lifeform.sol";

contract LifeformTest is DSTestPlus {
    Lifeform lifeform;
    MockERC20 underlying;

    string private name = "Lifeform";
    string private symbol = "LIFE";
    uint256 private maxSupply = 1000;
    uint256 private salePrice = 0.1 ether;
    uint256 private tokenCap = 5e18;

    // Users
    address private alice = address(bytes20("alice"));
    address private bob = address(bytes20("bob"));

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
        underlying.mint(address(this), 10e18);
        underlying.approve(address(lifeform), 10e18);

        lifeform.flipSale();

        uint256 id = lifeform.mint{value: 0.1 ether}(address(this));

        assertEq(lifeform.totalSupply(), 1);
        assertEq(lifeform.balanceOf(address(this)), 1);
        assertEq(lifeform.ownerOf(id), address(this));

        uint256 preDepositBal = underlying.balanceOf(address(this));

        assertEq(lifeform.tokenBalances(id), 0);

        lifeform.depositToken(id, 1e18);

        assertEq(lifeform.tokenBalances(id), 1e18);

        lifeform.withdrawToken(id, 1e18);

        assertEq(lifeform.tokenBalances(id), 0);
        assertEq(underlying.balanceOf(address(this)), preDepositBal);
    }

    function testAtomicTransferAliceBob() public {
        underlying.mint(address(this), 10e18);
        underlying.approve(address(lifeform), 10e18);

        lifeform.flipSale();

        uint256 id = lifeform.mint{value: 0.1 ether}(address(this));
        assertEq(lifeform.totalSupply(), 1);
        assertEq(lifeform.balanceOf(address(this)), 1);
        assertEq(lifeform.ownerOf(id), address(this));

        lifeform.depositToken(id, 1e18);

        lifeform.safeTransferFrom(address(this), address(alice), id);
        assertEq(lifeform.balanceOf(address(this)), 0);
        assertEq(lifeform.balanceOf(address(alice)), 1);
        assertEq(lifeform.ownerOf(id), address(alice));
        assertEq(lifeform.tokenBalances(id), 1e18);

        // underlying.mint(address(alice), 10e18);
        // underlying.approve(address(alice), 10e18);
        // LifeformUser(alice).depositToken(id, 1e18);
        // assertEq(lifeform.tokenBalances(id), 2e18);

        // TODO: there is currently a problem with the access to the token balance not being transferred to the new user

        // alice.withdrawToken(id, 1e18);
        // assertEq(underlying.balanceOf(address(alice)), 1e18);

        // lifeform.safeTransferFrom(address(this), alice, id);
    }
}
