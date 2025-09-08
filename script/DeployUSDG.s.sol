// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Script} from "forge-std/Script.sol";
import {console2} from "forge-std/console2.sol";

import {PoROracle} from "../contracts/oracles/PoROracle.sol";
import {FTHUSDG} from "../contracts/core/FTHUSDG.sol";

contract DeployUSDG is Script {
    function run() external {
        // Optional override via ASSET_KEY_NUM (uint256). Default = keccak256("GOLD_LBMA_KG")
        uint256 assetKeyNum = vm.envOr("ASSET_KEY_NUM", uint256(0));
        bytes32 assetKey = assetKeyNum == 0 ? keccak256("GOLD_LBMA_KG") : bytes32(assetKeyNum);

        uint256 usdPerKg = vm.envOr("USD_PER_KG", uint256(60_000_000_000)); // $60k * 1e6
        uint256 initKg = vm.envOr("INIT_KG", uint256(1000));
        string memory cid = vm.envOr("PROOF_CID", string("ipfs://proof"));

        // Use the broadcaster passed via --private-keys / --account
        vm.startBroadcast();

        PoROracle por = new PoROracle(tx.origin, assetKey);
        por.setReserves(initKg, cid);

        FTHUSDG usdg = new FTHUSDG("FTH-USDG", "USDG", tx.origin, address(por), assetKey, usdPerKg);

        vm.stopBroadcast();

        console2.log("PoROracle:", address(por));
        console2.log("FTHUSDG  :", address(usdg));
    }
}
