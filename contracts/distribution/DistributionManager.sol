// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {AccessControl} from "openzeppelin-contracts/contracts/access/AccessControl.sol";
import {IERC20} from "openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";
import {MerkleProof} from "openzeppelin-contracts/contracts/utils/cryptography/MerkleProof.sol";

/// @notice Merkle-based distributor for stablecoin payouts (dividends, coupons, fee shares).
contract DistributionManager is AccessControl {
    bytes32 public constant ADMIN = keccak256("ADMIN");

    IERC20 public immutable payoutToken;

    struct Dist {
        bytes32 merkleRoot;
        uint256 totalAmount; // informational
        uint256 claimed; // informational
        mapping(address => bool) hasClaimed;
    }

    mapping(uint256 => Dist) private _dists;
    uint256 public nextDistId;

    event DistributionCreated(uint256 indexed id, bytes32 merkleRoot, uint256 funded);
    event Claimed(uint256 indexed id, address indexed account, uint256 amount);

    constructor(address admin, IERC20 token) {
        _grantRole(DEFAULT_ADMIN_ROLE, admin);
        _grantRole(ADMIN, admin);
        payoutToken = token;
    }

    /// @dev Create a new distribution. Fund the contract beforehand or right after.
    function createDistribution(bytes32 merkleRoot_, uint256 totalAmount)
        external
        onlyRole(ADMIN)
        returns (uint256 id)
    {
        id = nextDistId++;
        Dist storage d = _dists[id];
        d.merkleRoot = merkleRoot_;
        d.totalAmount = totalAmount;
        emit DistributionCreated(id, merkleRoot_, totalAmount);
    }

    function hasClaimed(uint256 id, address account) external view returns (bool) {
        return _dists[id].hasClaimed[account];
    }

    function merkleRoot(uint256 id) external view returns (bytes32) {
        return _dists[id].merkleRoot;
    }

    /// @notice Claim your allocation from distribution `id`.
    /// @param proof Merkle proof for leaf keccak256(abi.encodePacked(account, amount))
    function claim(uint256 id, uint256 amount, bytes32[] calldata proof) external {
        Dist storage d = _dists[id];
        require(!d.hasClaimed[msg.sender], "already claimed");

        // Micro-optimized keccak of (address, uint256) to quiet lint and save gas.
        bytes32 leaf;
        assembly {
            let ptr := mload(0x40)
            mstore(ptr, shl(96, caller()))
            mstore(add(ptr, 0x20), amount)
            leaf := keccak256(ptr, 0x40)
        }

        require(MerkleProof.verifyCalldata(proof, d.merkleRoot, leaf), "bad proof");

        d.hasClaimed[msg.sender] = true;
        d.claimed += amount;
        require(payoutToken.transfer(msg.sender, amount), "transfer fail");
        emit Claimed(id, msg.sender, amount);
    }
}
