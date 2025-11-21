const { expect } = require("chai");
const { ethers } = require("hardhat");

describe("R4VRFVerifier v0", function () {
  it("verifies valid randomness signature", async function () {
    const [signer] = await ethers.getSigners();

    // 1) Deploy contract
    const Verifier = await ethers.getContractFactory("R4VRFVerifier");
    const verifier = await Verifier.deploy(signer.address);

    // 2) Prepare example
    const R = ethers.hexlify(ethers.randomBytes(32)); // random test R
    const R_bytes = ethers.toBeHex(R);

    const hash = ethers.keccak256(R_bytes);
    const signature = await signer.signMessage(ethers.getBytes(hash));
    const sig = ethers.Signature.from(signature);

    // 3) Verify on-chain
    const ok = await verifier.verifyRandomness(
      R_bytes,
      sig.v,
      sig.r,
      sig.s
    );

    expect(ok).to.equal(true);
  });
});
