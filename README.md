# R4 VRF — Public Specification for Verifiable Randomness

> Open, permissionless and verifiable randomness spec aligned with Ethereum’s long-term vision.

This repository contains a **minimal, open specification** and reference implementation of a verifiable randomness scheme (“R4 VRF”) designed for Ethereum and EVM-compatible chains.

The goal is to provide:
- A **simple, auditable VRF flow** based on ECDSA signatures.
- A **minimal on-chain verifier contract** (`R4VRFVerifier.sol`).
- A **clear spec** that anyone can implement, extend or critique.
- A natural path to **post-quantum dual-signature schemes** (ML-DSA-65) while keeping the base protocol permissionless and globally verifiable.

This repo intentionally does **not** include sealed entropy cores or commercial code.

---

## High-level design

1. Off-chain node generates a 256-bit random value `R`.
2. Computes `hash = keccak256(R)`.
3. Signs `hash` via ECDSA `(v, r, s)`.
4. Consumer receives: `R, v, r, s`.
5. Smart contract verifies signature via `ecrecover`.

---

## Files

- **spec/vrf-spec-v0.md** — formal specification.
- **contracts/R4VRFVerifier.sol** — on-chain verifier contract.

---
---

## 🔍 Motivation

R4 VRF focuses on simplicity and auditability. Instead of a complex oracle network,
it verifies randomness by checking an ECDSA signature on-chain.  
This is suitable for games, raffles, L2 internal mechanisms, DAO governance
and other cases where lightweight verifiable randomness is needed.

---
Post-Quantum Security Rationale

Modern blockchain systems increasingly depend on cryptographic proofs of randomness and message authenticity. However, classical primitives such as ECDSA, ECDH, and traditional VRF constructions are vulnerable to Shor’s algorithm, making long-term randomness integrity and signature verification unsafe in a post-quantum world.

R4 VRF / Entropy Stack introduces a hybrid security model:

1. PQ-Hardened Entropy Source

The core randomness is mixed using:

Multi-source entropy (system, jitter, chaos, π-based noise)

Keccak-based whitening

Post-quantum–safe hashing domains

Deterministic seed expansion without elliptic curves

This ensures that the randomness pipeline contains no quantum-breakable primitives.

2. PQ-Safe Verification Model

To guarantee long-term verifiability of randomness outputs:

Classical signatures (ECDSA/secp256k1) can be used for compatibility

PQ signatures (ML-DSA-65 / Dilithium3 / Kyber KEM for sealing seeds)
are supported for forward-secure deployments

Dual-signature mode ensures that even if elliptic curve cryptography is broken in the future, the PQ layer preserves non-repudiation and auditability.

3. No reliance on ecrecover

Traditional Ethereum verifiable functions rely on ecrecover, which is inherently non-PQ.
R4 VRF avoids this dependency by using:

explicit public keys

hash-to-curve–free VRF proof structure

PQ-friendly verification flow

4. PQ Upgrade Path

Because Ethereum L1 does not yet include post-quantum precompiles, R4 is designed to be compatible with:

future RIP-7560 (PQ verification hints)

EIP-7701 / 7702 (signature pipeline refactors)

late-stage PQ migration for AA (ERC-4337 bundlers)

attested nodes running PQ-safe sealing

This makes R4 a future-proof verifiable randomness system with minimal assumptions and maximum cryptographic longevity.
## ⚠️ Limitations (v0)

- Not a decentralized randomness beacon.
- Does not prevent bias from a malicious node (higher-level protocols must handle this).
- Uses classical ECDSA (post-quantum support planned in v1+).

---

## 🛤️ Future Work

**v1:** structured domain separation  
**v2:** dual signatures (ECDSA + ML-DSA-65)  
**v3:** committee-based randomness beacon  

## 🧪 Running tests (Hardhat)

This repo includes a minimal test verifying the end-to-end ECDSA flow.

### 1. Install dependencies

npm init -y
npm install --save-dev hardhat @nomicfoundation/hardhat-toolbox
npx hardhat

arduino
Copy code

Choose **"Create an empty hardhat.config.js"**.

### 2. Add Solidity config

Edit **hardhat.config.js**:

```js
require("@nomicfoundation/hardhat-toolbox");

module.exports = {
  solidity: "0.8.21"
};

3. Run tests
npx hardhat test

## License

Apache 2.0.
---

## 🔗 Related implementation (non-normative)

A full production-grade implementation of an entropy appliance and VRF pipeline
based on similar ideas (sealed core, FIPS readiness, dual ECDSA + ML-DSA-65 signatures)
is maintained separately:

- https://github.com/pipavlo82/r4-monorepo

This repository (`r4-vrf-public-spec`) is intentionally minimal and focuses only
on the open specification and a small reference verifier.
