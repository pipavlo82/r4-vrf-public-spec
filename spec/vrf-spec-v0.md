# R4 VRF v0 — Minimal Verifiable Randomness Specification

Version: v0  
Status: Draft / Experimental

---

## 1. Scope

Defines a minimal, auditable, ECDSA-based VRF with on-chain verification.

---

## 2. Message format


R – 32-byte random value
hash – keccak256(R)
sig – ECDSA signature (v, r, s)
signer – expected address


---

## 3. Off-chain generation

1. Generate `R : bytes32`
2. Compute `hash = keccak256(R)`
3. Produce signature `(v, r, s) = Sign(sk, hash)`
4. Output `R, v, r, s`

---

## 4. On-chain verification

Contract recomputes:



hash = keccak256(R)
recovered = ecrecover(hash, v, r, s)


Verification succeeds iff:



recovered == signer


---

## 5. Threat Model

- Attackers cannot forge signatures under ECDSA secp256k1.
- The on-chain contract only verifies authenticity of the signature.
- The protocol does **not** guarantee that the randomness was unbiased.
- Consumer must decide whether trusted execution or multi-party schemes are needed.

---

## 6. Limitations

R4 VRF v0 does **not** provide:
- VRF proof objects
- multi-party randomness
- slashing or anti-bias protections
- post-quantum security

These belong to higher protocol layers or future versions.

---

## 7. Future Directions

Planned research extensions:
- domain-separated hashing
- PQ dual signature: `(ECDSA, ML-DSA-65)`
- distributed committee signing
- beacon-like aggregation
