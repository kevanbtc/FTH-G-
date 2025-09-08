// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {ERC721} from "openzeppelin-contracts/contracts/token/ERC721/ERC721.sol";
import {AccessControl} from "openzeppelin-contracts/contracts/access/AccessControl.sol";

/// @notice Minimal soulbound KYC credential (non-transferable)
contract KYCSoulbound is ERC721, AccessControl {
    bytes32 public constant ISSUER = keccak256("ISSUER");
    uint256 public nextId;

    constructor(address admin) ERC721("FTH-KYC", "KYC") {
        _grantRole(DEFAULT_ADMIN_ROLE, admin);
        _grantRole(ISSUER, admin);
    }

    function issue(address to) external onlyRole(ISSUER) {
        _safeMint(to, ++nextId);
    }

    function revoke(uint256 tokenId) external onlyRole(ISSUER) {
        _burn(tokenId);
    }

    function _transfer(address, address, uint256) internal pure override {
        revert("soulbound");
    }
}
