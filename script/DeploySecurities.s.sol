// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Script} from "forge-std/Script.sol";
import {console2} from "forge-std/console2.sol";

import {IERC20} from "openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";
import {SecurityToken1400Lite} from "../contracts/wrappers/SecurityToken1400Lite.sol";
import {DistributionManager} from "../contracts/distribution/DistributionManager.sol";

contract DeploySecurities is Script {
    function run() external {
        address usdgAddr = vm.envAddress("USDG_ADDRESS"); // set before running

        vm.startBroadcast();

        SecurityToken1400Lite sec = new SecurityToken1400Lite(
            vm.envOr("SEC_NAME", string("FTH-SEC")), vm.envOr("SEC_SYMBOL", string("FSEC")), tx.origin
        );

        DistributionManager dist = new DistributionManager(tx.origin, IERC20(usdgAddr));

        // Bootstrap: allow deployer as eligible investor
        sec.setAllowed(tx.origin, true);

        vm.stopBroadcast();

        console2.log("SecurityToken1400Lite:", address(sec));
        console2.log("DistributionManager  :", address(dist));
    }
}
