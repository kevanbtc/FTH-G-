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
    bytes32 public immutable BACKING_ASSET; // e.g., keccak256("GOLD_LBMA_KG")
    uint256 public immutable USD_PER_KG; // USD price per kg scaled to 1e6 (USD 6 decimals)

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
        BACKING_ASSET = backingAsset_;
        USD_PER_KG = usdPerKg_;
        require(por.reservesAsset() == BACKING_ASSET, "oracle/backing mismatch");
    }

    function setCompliance(address user, bool allowed) external onlyRole(COMPLIANCE) {
        kycOk[user] = allowed;
        emit ComplianceUpdated(user, allowed);
    }

    function _checkKyc(address user) internal view {
        require(kycOk[user], "compliance/kyc");
    }

    /// @dev Hard cap: totalSupply(1e6) <= totalReservesKg * USD_PER_KG(1e6)
    function _hardCap() internal view returns (uint256) {
        return por.totalReservesInKg() * USD_PER_KG;
    }

    function mint(address to, uint256 amount) external onlyRole(RESERVE_MANAGER) {
        _checkKyc(to);
        require(totalSupply() + amount <= _hardCap(), "exceeds PoR cap");
        _mint(to, amount);
        emit Minted(to, amount);
    }

    function burn(uint256 amount) external {
        _checkKyc(msg.sender);
        _burn(msg.sender, amount);
        emit Burned(msg.sender, amount);
    }

    /// @notice USD-like 6 decimals for intuitive amounts ($1 == 1e6)
    function decimals() public pure override returns (uint8) {
        return 6;
    }
}
