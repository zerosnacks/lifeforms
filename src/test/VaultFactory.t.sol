// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.0;

// Vendor
import {Authority} from "../vendor/solmate/auth/Auth.sol";
import {DSTestPlus} from "../vendor/solmate/test/utils/DSTestPlus.sol";
import {MockERC20} from "../vendor/solmate/test/utils/mocks/MockERC20.sol";

// Contracts
import {Vault} from "../Vault.sol";
import {VaultFactory} from "../VaultFactory.sol";

contract VaultFactoryTest is DSTestPlus {
    VaultFactory vaultFactory;

    MockERC20 underlying;

    function setUp() public {
        underlying = new MockERC20("Mock Token", "TKN", 18);

        vaultFactory = new VaultFactory(address(this), Authority(address(0)));
    }

    function testDeployVault() public {
        Vault vault = vaultFactory.deployVault(underlying);

        assertTrue(vaultFactory.isVaultDeployed(vault));
        assertEq(address(vaultFactory.getVaultFromUnderlying(underlying)), address(vault));
        assertEq(address(vault.UNDERLYING()), address(underlying));
    }

    function testFailNoDuplicateVaults() public {
        vaultFactory.deployVault(underlying);
        vaultFactory.deployVault(underlying);
    }

    function testIsVaultDeployed() public {
        assertFalse(vaultFactory.isVaultDeployed(Vault(payable(address(0xBEEF)))));
    }
}
