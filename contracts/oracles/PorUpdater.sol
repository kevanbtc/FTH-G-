// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {AccessControl} from "openzeppelin-contracts/contracts/access/AccessControl.sol";
import {PoROracle} from "./PoROracle.sol";

contract PorUpdater is AccessControl {
    bytes32 public constant UPDATER = keccak256("UPDATER");
    PoROracle public immutable oracle;

    constructor(address admin, PoROracle por) {
        _grantRole(DEFAULT_ADMIN_ROLE, admin);
        _grantRole(UPDATER, admin);
        oracle = por;
    }

    function ocrUpdate(uint256 kg, string calldata cid) external onlyRole(UPDATER) {
        oracle.setReserves(kg, cid);
    }
}
