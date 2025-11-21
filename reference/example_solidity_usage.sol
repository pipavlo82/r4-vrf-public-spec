// Example usage of R4VRFVerifier in a consumer contract

contract Consumer {
    R4VRFVerifier public verifier;

    constructor(address verifierAddress) {
        verifier = R4VRFVerifier(verifierAddress);
    }

    function useRandomness(
        bytes32 R,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external view returns (bytes32) {
        require(verifier.verifyRandomness(R, v, r, s), "Invalid VRF signature");
        return R;
    }
}
