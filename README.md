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

## License

Apache 2.0.
