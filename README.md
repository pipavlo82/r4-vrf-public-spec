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
