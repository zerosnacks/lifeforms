// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.0;

// Vendor
import {DSTestPlus} from "solmate/test/utils/DSTestPlus.sol";
import {ERC20} from "solmate/tokens/ERC20.sol";
import {MockERC20} from "solmate/test/utils/mocks/MockERC20.sol";

// Contracts
import {Lifeform} from "../Lifeform.sol";

contract LifeformsTest is DSTestPlus {
    Lifeform lifeform;
    MockERC20 underlying;

    // Proxy
    // 0x2f800db0fdb5223b3c3f354886d907a671414a7f

    // Use Mock BCT token
    // 0xddb857badb65657ebc766c90045403875fc29d27

    function setUp() public {
        underlying = new MockERC20("Mock Token", "TKN", 18);

        lifeform = new Lifeform(
            "Lifeform", // name
            "LIFE", // symbol
            1000, // maxSupply
            10, // salePrice
            10, // tokenCap
            underlying // underlying
        );
    }

    function invariantMetadata() public {
        assertEq(lifeform.name(), "lifeform");
        assertEq(lifeform.symbol(), "LIFE");
    }

    function testMint(address usr) public {
        lifeform.flipSale();

        lifeform.mint(usr);

        assertEq(lifeform.totalSupply(), 1);
        assertEq(lifeform.balanceOf(usr), 1);
        assertEq(lifeform.ownerOf(0), usr);
    }

    function testAtomicDepositWithdraw() public {
        underlying.mint(address(this), 1e18);
        underlying.approve(address(lifeform), 1e18);

        lifeform.flipSale();

        lifeform.mint(address(this));

        assertEq(lifeform.totalSupply(), 1);
        assertEq(lifeform.balanceOf(address(this)), 1);
        assertEq(lifeform.ownerOf(0), address(this));

        uint256 preDepositBal = underlying.balanceOf(address(this));

        lifeform.depositToken(0, 1e18);

        assertEq(lifeform.tokenBalances(0), 1e18);

        lifeform.withdrawToken(0, 1e18);

        assertEq(lifeform.tokenBalances(0), 0);
        assertEq(underlying.balanceOf(address(this)), preDepositBal);
    }
}
