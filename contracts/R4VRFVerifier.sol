// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

/// @title R4VRFVerifier - Minimal ECDSA-based randomness verifier (R4 VRF v0)
/// @notice Verifies that a 32-byte random value was signed by a known ECDSA signer.
/// @dev Hash scheme: hash = keccak256(R); verification uses ecrecover.
contract R4VRFVerifier {
    /// @notice Authorized signer address.
    address public immutable signer;

    constructor(address _signer) {
        signer = _signer;
    }

    /// @notice Verify randomness R and ECDSA signature (v,r,s).
    /// @param R 32-byte random value.
    /// @param v Signature recovery id.
    /// @param r Signature component r.
    /// @param s Signature component s.
    /// @return ok True if the signature is valid.
    function verifyRandomness(
        bytes32 R,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) public view returns (bool ok) {
        bytes32 hash = keccak256(abi.encodePacked(R));
        address recovered = ecrecover(hash, v, r, s);
        return recovered == signer;
    }
}
