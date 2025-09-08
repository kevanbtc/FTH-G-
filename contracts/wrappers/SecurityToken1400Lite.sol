// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {ERC20} from "openzeppelin-contracts/contracts/token/ERC20/ERC20.sol";
import {ERC20Permit} from "openzeppelin-contracts/contracts/token/ERC20/extensions/ERC20Permit.sol";
import {AccessControl} from "openzeppelin-contracts/contracts/access/AccessControl.sol";

/// @title SecurityToken1400Lite
/// @notice ERC-1400 "lite": restricted ERC20 with allowlist + admin issuance/redemption.
///         Uses OZ v5 ERC20._update(from, to, value) to gate transfers.
contract SecurityToken1400Lite is ERC20, ERC20Permit, AccessControl {
    bytes32 public constant ISSUER = keccak256("ISSUER");
    bytes32 public constant COMPLIANCE = keccak256("COMPLIANCE");
    bytes32 public constant REDEEMER = keccak256("REDEEMER");

    mapping(address => bool) public allowed; // KYC/eligibility

    event AllowedSet(address indexed user, bool allowed_);

    constructor(string memory name_, string memory symbol_, address admin_) ERC20(name_, symbol_) ERC20Permit(name_) {
        _grantRole(DEFAULT_ADMIN_ROLE, admin_);
        _grantRole(ISSUER, admin_);
        _grantRole(COMPLIANCE, admin_);
        _grantRole(REDEEMER, admin_);
    }

    function setAllowed(address user, bool isAllowed) external onlyRole(COMPLIANCE) {
        allowed[user] = isAllowed;
        emit AllowedSet(user, isAllowed);
    }

    function _checkAllowed(address user) internal view {
        require(allowed[user], "compliance/not-allowed");
    }

    /// @notice Admin issuance to eligible investors.
    function issue(address to, uint256 amount) external onlyRole(ISSUER) {
        _checkAllowed(to);
        _mint(to, amount);
    }

    /// @notice Admin redemption (company buyback or forced redemption as per docs).
    function redeem(address from, uint256 amount) external onlyRole(REDEEMER) {
        _checkAllowed(from);
        _burn(from, amount);
    }

    /// @dev OZ v5: gate transfers by overriding _update(from, to, value).
    function _update(address from, address to, uint256 value) internal virtual override {
        if (from != address(0) && to != address(0)) {
            _checkAllowed(from);
            _checkAllowed(to);
        }
        super._update(from, to, value);
    }

    /// @notice Optional: 6 decimals for parity with USDG.
    function decimals() public pure override returns (uint8) {
        return 6;
    }
}
