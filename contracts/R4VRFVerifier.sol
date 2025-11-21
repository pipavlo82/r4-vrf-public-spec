// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

contract R4VRFVerifier {
    address public immutable signer;

    constructor(address _signer) {
        signer = _signer;
    }

    function verifyRandomness(
        bytes32 R,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) public view returns (bool) {
        bytes32 hash = keccak256(abi.encodePacked(R));
        address recovered = ecrecover(hash, v, r, s);
        return recovered == signer;
    }
}
