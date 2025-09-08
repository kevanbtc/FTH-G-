// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {AccessControl} from "openzeppelin-contracts/contracts/access/AccessControl.sol";

/// @notice Minimal Proof-of-Reserves oracle (wire to Chainlink OCR / external adapter in prod).
contract PoROracle is AccessControl {
    bytes32 public constant ATTESTOR = keccak256("ATTESTOR");

    bytes32 public immutable ASSET_KEY; // e.g., keccak256("GOLD_LBMA_KG")
    uint256 private _reservesKg;
    string public lastProofCid; // IPFS/Arweave proof doc (vault certs, bar lists, etc.)
    uint256 public lastUpdate;

    event ReservesUpdated(uint256 kg, string cid);

    constructor(address admin, bytes32 assetKey_) {
        _grantRole(DEFAULT_ADMIN_ROLE, admin);
        _grantRole(ATTESTOR, admin);
        ASSET_KEY = assetKey_;
    }

    function setReserves(uint256 kg, string calldata cid) external onlyRole(ATTESTOR) {
        _reservesKg = kg;
        lastProofCid = cid;
        lastUpdate = block.timestamp;
        emit ReservesUpdated(kg, cid);
    }

    function totalReservesInKg() external view returns (uint256) {
        return _reservesKg;
    }

    function reservesAsset() external view returns (bytes32) {
        return ASSET_KEY;
    }
}
