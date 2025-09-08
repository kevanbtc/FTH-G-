// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "forge-std/Test.sol";
import {FTHUSDG} from "../contracts/core/FTHUSDG.sol";
import {PoROracle} from "../contracts/oracles/PoROracle.sol";

contract FTHUSDGTest is Test {
    FTHUSDG usd;
    PoROracle por;
    address admin = address(0xA11CE);
    bytes32 constant GOLD = keccak256("GOLD_LBMA_KG");

    function setUp() public {
        vm.startPrank(admin);
        por = new PoROracle(admin, GOLD);
        por.setReserves(1000, "ipfs://proof"); // 1000 kg
        usd = new FTHUSDG("FTH-USDG", "USDG", admin, address(por), GOLD, 60000000); // $60k/kg * 1e6
        usd.grantRole(usd.COMPLIANCE(), admin);
        usd.grantRole(usd.RESERVE_MANAGER(), admin);
        usd.setCompliance(address(this), true);
        vm.stopPrank();
    }

    function testMintWithinCap() public {
        vm.prank(admin);
        usd.mint(address(this), 1_000_000e6); // $1,000,000 worth
        assertEq(usd.totalSupply(), 1_000_000e6);
    }
}
