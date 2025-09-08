// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {AccessControl} from "openzeppelin-contracts/contracts/access/AccessControl.sol";
import {IERC20} from "openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";

/// @notice Simple parametric insurance pool paying claims in a stablecoin.
contract InsurancePool is AccessControl {
    bytes32 public constant MANAGER = keccak256("MANAGER");
    IERC20 public immutable stable;

    event PremiumPaid(address indexed from, uint256 amount);
    event ClaimPaid(address indexed to, uint256 amount);

    constructor(address admin, IERC20 stable_) {
        _grantRole(DEFAULT_ADMIN_ROLE, admin);
        _grantRole(MANAGER, admin);
        stable = stable_;
    }

    function payPremium(uint256 amount) external {
        require(stable.transferFrom(msg.sender, address(this), amount), "transfer fail");
        emit PremiumPaid(msg.sender, amount);
    }

    function payClaim(address to, uint256 amount) external onlyRole(MANAGER) {
        require(stable.transfer(to, amount), "transfer fail");
        emit ClaimPaid(to, amount);
    }
}
