// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {ERC20} from "openzeppelin-contracts/contracts/token/ERC20/ERC20.sol";
import {ERC20Permit} from "openzeppelin-contracts/contracts/token/ERC20/extensions/ERC20Permit.sol";
import {AccessControl} from "openzeppelin-contracts/contracts/access/AccessControl.sol";

interface IPoROracle {
    function totalReservesInKg() external view returns (uint256);
    function reservesAsset() external view returns (bytes32);
}

/// @title FTH-USDG — Asset-backed stablecoin capped by Proof-of-Reserves
contract FTHUSDG is ERC20, ERC20Permit, AccessControl {
    bytes32 public constant RESERVE_MANAGER = keccak256("RESERVE_MANAGER");
    bytes32 public constant COMPLIANCE = keccak256("COMPLIANCE");

    IPoROracle public por;
    bytes32 public immutable backingAsset; // e.g., keccak256("GOLD_LBMA_KG")
    uint256 public immutable usdPerKg; // 1e6 decimals; e.g., $ value per kg * 1e6

    mapping(address => bool) public kycOk;

    event Minted(address indexed to, uint256 amount);
    event Burned(address indexed from, uint256 amount);
    event ComplianceUpdated(address indexed user, bool allowed);

    constructor(
        string memory name_,
        string memory symbol_,
        address admin_,
        address porOracle_,
        bytes32 backingAsset_,
        uint256 usdPerKg_
    ) ERC20(name_, symbol_) ERC20Permit(name_) {
        require(porOracle_ != address(0) && admin_ != address(0), "bad init");
        _grantRole(DEFAULT_ADMIN_ROLE, admin_);
        _grantRole(RESERVE_MANAGER, admin_);
        _grantRole(COMPLIANCE, admin_);
        por = IPoROracle(porOracle_);
        backingAsset = backingAsset_;
        usdPerKg = usdPerKg_;
        require(por.reservesAsset() == backingAsset_, "oracle/backing mismatch");
    }

    function setCompliance(address user, bool allowed) external onlyRole(COMPLIANCE) {
        kycOk[user] = allowed;
        emit ComplianceUpdated(user, allowed);
    }

    function _checkKYC(address user) internal view {
        require(kycOk[user], "compliance/kyc");
    }

    function _hardCap() internal view returns (uint256) {
        return por.totalReservesInKg() * usdPerKg;
    }

    function mint(address to, uint256 amount) external onlyRole(RESERVE_MANAGER) {
        _checkKYC(to);
        require(totalSupply() + amount <= _hardCap(), "exceeds PoR cap");
        _mint(to, amount);
        emit Minted(to, amount);
    }

    function burn(uint256 amount) external {
        _checkKYC(msg.sender);
        _burn(msg.sender, amount);
        emit Burned(msg.sender, amount);
    }
}
