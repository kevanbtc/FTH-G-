// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {ERC721} from "openzeppelin-contracts/contracts/token/ERC721/ERC721.sol";
import {AccessControl} from "openzeppelin-contracts/contracts/access/AccessControl.sol";

/// @notice Soulbound KYC credential for allowlisting. Non-transferable on OZ v5.
/// Transfer blocking is implemented by overriding `_update` (v5 pattern).
contract KYCSoulbound is ERC721, AccessControl {
    bytes32 public constant ISSUER = keccak256("ISSUER");
    uint256 public nextId;

    constructor(address admin) ERC721("FTH-KYC", "KYC") {
        _grantRole(DEFAULT_ADMIN_ROLE, admin);
        _grantRole(ISSUER, admin);
    }

    /// @notice Issue a non-transferable credential to `to`.
    function issue(address to) external onlyRole(ISSUER) {
        _safeMint(to, ++nextId);
    }

    /// @notice Revoke (burn) a credential.
    function revoke(uint256 tokenId) external onlyRole(ISSUER) {
        _burn(tokenId);
    }

    /// @dev OZ v5: block transfers by overriding `_update`.
    /// Allows only mint (from == address(0)) and burn (to == address(0)).
    function _update(address to, uint256 tokenId, address auth) internal virtual override returns (address) {
        address from = _ownerOf(tokenId);
        bool isMint = (from == address(0));
        bool isBurn = (to == address(0));
        if (!isMint && !isBurn) revert("soulbound");
        return super._update(to, tokenId, auth);
    }

    /// @dev Resolve multiple inheritance for supportsInterface.
    function supportsInterface(bytes4 interfaceId) public view virtual override(AccessControl, ERC721) returns (bool) {
        return super.supportsInterface(interfaceId);
    }
}
