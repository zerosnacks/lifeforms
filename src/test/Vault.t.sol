// // SPDX-License-Identifier: AGPL-3.0-only
// pragma solidity >=0.8.0;

// // Vendor
// import {WETH} from "solmate/tokens/WETH.sol";
// import {Authority} from "solmate/auth/Auth.sol";
// import {DSTestPlus} from "solmate/test/utils/DSTestPlus.sol";
// import {MockERC20} from "solmate/test/utils/mocks/MockERC20.sol";

// // Contracts
// import {Vault} from "../Vault.sol";
// import {VaultFactory} from "../VaultFactory.sol";

// contract VaultsTest is DSTestPlus {
//     Vault vault;
//     MockERC20 arbitrary;
//     MockERC20 underlying;

//     function setUp() public {
//         underlying = new MockERC20("Mock Token", "TKN", 18);

//         vault = new VaultFactory(address(this), Authority(address(0))).deployVault(underlying);

//         vault.initialize();
//     }

//     // ==========================
//     // DEPOSIT / WITHDRAWAL TESTS
//     // ==========================

//     function testAtomicDepositWithdraw() public {
//         underlying.mint(address(this), 1e18);
//         underlying.approve(address(vault), 1e18);

//         uint256 preDepositBal = underlying.balanceOf(address(this));

//         vault.deposit(1e18);

//         assertEq(vault.exchangeRate(), 1e18);
//         assertEq(vault.balanceOf(address(this)), 1e18);
//         assertEq(vault.balanceOfUnderlying(address(this)), 1e18);
//         assertEq(underlying.balanceOf(address(this)), preDepositBal - 1e18);

//         vault.withdraw(1e18);

//         assertEq(vault.exchangeRate(), 1e18);
//         assertEq(vault.balanceOf(address(this)), 0);
//         assertEq(vault.balanceOfUnderlying(address(this)), 0);
//         assertEq(underlying.balanceOf(address(this)), preDepositBal);
//     }

//     function testAtomicDepositRedeem() public {
//         underlying.mint(address(this), 1e18);
//         underlying.approve(address(vault), 1e18);

//         uint256 preDepositBal = underlying.balanceOf(address(this));

//         vault.deposit(1e18);

//         assertEq(vault.exchangeRate(), 1e18);
//         assertEq(vault.balanceOf(address(this)), 1e18);
//         assertEq(vault.balanceOfUnderlying(address(this)), 1e18);
//         assertEq(underlying.balanceOf(address(this)), preDepositBal - 1e18);

//         vault.redeem(1e18);

//         assertEq(vault.exchangeRate(), 1e18);
//         assertEq(vault.balanceOf(address(this)), 0);
//         assertEq(vault.balanceOfUnderlying(address(this)), 0);
//         assertEq(underlying.balanceOf(address(this)), preDepositBal);
//     }

//     // =====================================
//     // DEPOSIT/WITHDRAWAL SANITY CHECK TESTS
//     // =====================================

//     function testFailDepositWithNotEnoughApproval() public {
//         underlying.mint(address(this), 0.5e18);
//         underlying.approve(address(vault), 0.5e18);

//         vault.deposit(1e18);
//     }

//     function testFailWithdrawWithNotEnoughBalance() public {
//         underlying.mint(address(this), 0.5e18);
//         underlying.approve(address(vault), 0.5e18);

//         vault.deposit(0.5e18);

//         vault.withdraw(1e18);
//     }

//     function testFailRedeemWithNotEnoughBalance() public {
//         underlying.mint(address(this), 0.5e18);
//         underlying.approve(address(vault), 0.5e18);

//         vault.deposit(0.5e18);

//         vault.redeem(1e18);
//     }

//     function testFailRedeemWithNoBalance() public {
//         vault.redeem(1e18);
//     }

//     function testFailWithdrawWithNoBalance() public {
//         vault.withdraw(1e18);
//     }

//     function testFailDepositWithNoApproval() public {
//         vault.deposit(1e18);
//     }

//     function testFailRedeemZero() public {
//         vault.redeem(0);
//     }

//     function testFailWithdrawZero() public {
//         vault.withdraw(0);
//     }

//     function testFailDepositZero() public {
//         vault.deposit(0);
//     }

//     // ===============
//     // EDGE CASE TESTS
//     // ===============

//     function testFailInitializeTwice() public {
//         vault.initialize();
//     }

//     function testRescue() public {
//         arbitrary = new MockERC20("Arbitrary Token", "ARB", 18);
//         arbitrary.mint(address(vault), 1e18);

//         vault.rescue(arbitrary, 1e18);
//     }

//     function testDestroyVault() public {
//         vault.destroy();
//     }
// }

// contract UnInitializedVaultTest is DSTestPlus {
//     Vault vault;
//     MockERC20 underlying;

//     function setUp() public {
//         underlying = new MockERC20("Mock Token", "TKN", 18);

//         vault = new VaultFactory(address(this), Authority(address(0))).deployVault(underlying);
//     }

//     function testFailDeposit() public {
//         underlying.mint(address(this), 1e18);

//         underlying.approve(address(vault), 1e18);
//         vault.deposit(1e18);
//     }

//     function testInitializeAndDeposit() public {
//         assertFalse(vault.isInitialized());
//         assertEq(vault.totalSupply(), type(uint256).max);

//         vault.initialize();

//         assertTrue(vault.isInitialized());
//         assertEq(vault.totalSupply(), 0);

//         underlying.mint(address(this), 1e18);

//         underlying.approve(address(vault), 1e18);
//         vault.deposit(1e18);
//     }
// }
