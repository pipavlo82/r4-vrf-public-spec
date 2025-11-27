# Post-Quantum Migration Strategy

**Document version:** v0  
**Scope:** R4 VRF ECDSA-based verifier with PQ-ready design

This document describes how R4 VRF migrates from classical ECDSA verification to post-quantum (PQ) signature schemes, with minimal changes to on-chain code and no changes to core VRF semantics.

**Intended audience:**
- Protocol and infrastructure engineers integrating R4 VRF into L2s, AA bundlers, and rollups
- Security reviewers evaluating the migration path
- Researchers considering PQ-ready randomness for Ethereum-aligned systems

---

## 1. Scope and Status

**R4 VRF v0 provides:**
- Minimal Solidity verifier based on `keccak256` + `ecrecover`
- Single-signer trust model optimized for L2/AA/private rollup use cases
- Clearly defined migration path toward ML-DSA-65 (NIST FIPS 204)

**What this document does NOT do:**
- Define a new PQ signature scheme
- Specify an Ethereum EIP/precompile
- Claim R4 VRF is PQ-secure today — it documents **how to get there**

---

## 2. Threat Model and PQ Motivation

### 2.1 Classical vs Quantum Adversary

R4 VRF v0 security assumptions:

| Component | Algorithm | Quantum Status |
|-----------|-----------|----------------|
| Hashing | `keccak256` | PQ-resilient (Grover-bounded) |
| Signatures | `secp256k1` ECDSA | **Not PQ-secure** |
| On-chain verification | `ecrecover` precompile | **Not PQ-secure** |

**Under a classical adversary:**  
ECDSA is considered secure with current best knowledge.

**Under a quantum adversary** (Shor's algorithm):
- ECDSA private keys can be recovered from public keys/signatures
- Past ECDSA signatures can be forged retroactively
- Any ECDSA-based attestations lose long-term integrity

### 2.2 What Needs to be PQ-Safe?

| Layer | Today (v0) | PQ Perspective |
|-------|-----------|----------------|
| Entropy generation | R4 core (non-ECC, DRBG + hashes) | Can be PQ-aligned already |
| Hashing | `keccak256` | PQ-resilient (Grover-bounded) |
| Off-chain signatures | ECDSA (secp256k1) | **Not PQ-secure** |
| On-chain verification | `ecrecover` | **Not PQ-secure** |
| Transport / TLS | Classical (implementation-specific) | Outside spec, but relevant |

**Main PQ challenge:** The signature layer (both off-chain and on-chain), not the hash or entropy core.

---

## 3. Migration Phases Overview

Four-phase model for PQ transition:

| Phase | Off-chain Node | On-chain Verifier | Goal |
|-------|----------------|-------------------|------|
| **0** | ECDSA | ECDSA (`ecrecover`) | Production today |
| **1** | ECDSA + ML-DSA-65 (dual-sign) | ECDSA only | Forensic PQ audit trail |
| **2** | ECDSA + ML-DSA-65 (dual-sign) | ECDSA + ML-DSA-65 (precompile/adapter) | Live PQ verification path |
| **3** | ML-DSA-65 only | ML-DSA-65 only | Full PQ regime |

**ML-DSA-65** refers to NIST FIPS 204 profile (Dilithium-class scheme).

### 3.1 Phase 0 — Today (ECDSA Only)

**Off-chain node:**
1. Generates randomness `R`
2. Computes `digest = keccak256(R)`
3. Signs `digest` with ECDSA → `(v, r, s)`

**On-chain:**
1. Recomputes `digest' = keccak256(R)`
2. Uses `ecrecover(digest', v, r, s)` to recover signer
3. Compares with `trustedSigner`

This is the current implementation in `R4VRFVerifier.sol`.

### 3.2 Phase 1 — Dual-Signing (ECDSA + ML-DSA-65, Off-Chain Only)

**Node behaviour:**
- Continue producing the same ECDSA signature as in Phase 0
- Additionally:
  - Maintain a separate ML-DSA-65 keypair `(pk_pq, sk_pq)`
  - Compute the same message digest `digest_pq` as for ECDSA (or domain-separated variant)
  - Produce a PQ signature: `sig_pq = MLDSA65.Sign(sk_pq, digest_pq)`

**JSON response example:**
```json
{
  "randomness": "0x1a2b3c...",
  "signature_ecdsa": {
    "v": 27,
    "r": "0x4d5e6f...",
    "s": "0x7g8h9i..."
  },
  "signature_pq": {
    "scheme": "ML-DSA-65",
    "public_key_id": "ml-dsa-65-mainnet-2025Q4",
    "sig": "0xabcd..."
  },
  "timestamp": "2025-11-20T23:14:10Z"
}
```

**On-chain behaviour:**  
Unchanged (still uses only the ECDSA part).

**Why Phase 1 matters:**  
Even if ECDSA keys are broken in the future, the ML-DSA-65 signatures can still act as cryptographic evidence that a given randomness output was produced at or before some time. This is especially useful for forensic analysis, audits, and off-chain accountability.

### 3.3 Phase 2 — Hybrid Verification (ECDSA + ML-DSA-65 On-Chain)

**Prerequisite:**  
An Ethereum (or EVM) precompile or efficient verifier for ML-DSA-65 exists, for example:

```
PQSIGVERIFY(digest, sig_pq, pk_pq) → (bool)
```

or a canonical contract that wraps PQ verification logic.

**Verifier patterns:**

**Optional PQ verification (soft-enforced):**
```solidity
function verifyHybrid(
    bytes32 randomness,
    uint8 v,
    bytes32 r,
    bytes32 s,
    bytes calldata sigPq,
    bytes calldata pkPq
) external view returns (bool) {
    // Classical path (for full compatibility)
    bytes32 digest = keccak256(abi.encodePacked(randomness));
    address recovered = ecrecover(digest, v, r, s);
    bool classicalOk = (recovered == trustedSigner);

    // PQ path (if available / enabled)
    bool pqOk = PQSigVerify(digest, sigPq, pkPq); // via precompile or adapter

    // Policy example: require classicalOk && pqOk
    return classicalOk && pqOk;
}
```

**Configurable policy (config via storage):**
- Only ECDSA (legacy)
- ECDSA and PQ (strict hybrid)
- PQ-only (for future Phase 3)

This phase allows gradual tightening of security assumptions as PQ tooling matures.

### 3.4 Phase 3 — PQ-Only (ML-DSA-65 Only)

**Final state:**

**Off-chain node:**
- Signs only with ML-DSA-65 (no ECDSA)

**On-chain:**
- Verifier uses only PQ precompile / adapter

**Transition conditions (examples):**
- PQ precompile is standardized and widely implemented
- ETH / L2 clients support PQ primitives at protocol level
- The ecosystem has a clear migration away from ECDSA for critical paths

---

## 4. What Exactly Is Signed?

R4 VRF keeps the message being signed intentionally simple and explicit.

### 4.1 Base Message (v0)

In v0, the Solidity verifier assumes:

```solidity
bytes32 digest = keccak256(abi.encodePacked(randomness));
```

Where:
- `randomness` is a 32-byte value (R, or derived from internal R4 output)
- `digest` is the message signed by ECDSA

### 4.2 Domain Separation for PQ (Recommended)

For PQ signatures, it is recommended to use domain separation to avoid cross-protocol confusion:

```
digest_pq = keccak256(
  "R4_VRF_V0_PQ" ||
  randomness ||
  slot_or_seq ||   // optional, if you bind to slot/batch
  chain_id        // optional, if multi-chain
)
```

**Node behaviour in Phase 1+:**
- For ECDSA: keep the existing digest for backward compatibility
- For PQ: use a slightly more structured digest with a fixed domain tag

**This ensures:**
- Existing ECDSA-based contracts do not break
- PQ signatures have an unambiguous semantic meaning

---

## 5. Ethereum / EVM Considerations

### 5.1 Current Reality

Today, on Ethereum mainnet and many L2s:
- `ecrecover` is the only widely available, cheap signature verification primitive
- There is no standardized ML-DSA-65 precompile yet
- PQ verification in Solidity is possible but gas-prohibitive for typical use

**Therefore:**
- R4 VRF v0 must remain ECDSA-based for on-chain verification
- PQ support is currently an off-chain feature (Phase 1)

### 5.2 Expected PQ On-Chain Options

In the future, PQ verification on-chain could be enabled via:

**New precompile (preferred):**
- Example: `0x0X` address for ML-DSA-65 verify
- Input: digest, signature, public key
- Output: boolean (valid / invalid)

**Canonical verifier contract:**
- Deployed once, possibly written in efficient low-level code or using a zk-proof
- VRF consumers delegate-call or regular-call this contract

**Rollup-specific precompiles:**
- Individual L2s adopt their own PQ precompiles ahead of L1
- R4 VRF verifier is configured per-chain to use the correct primitive

R4 VRF is neutral to how PQ verification appears on-chain — it assumes an eventual `PQSigVerify`-like abstraction.

---

## 6. Implementation Guidance for Node Operators

### 6.1 Key Management

For dual-signing (Phase 1+):

**Maintain two independent keypairs:**
- ECDSA `sk_ecdsa`, `pk_ecdsa`
- ML-DSA-65 `sk_pq`, `pk_pq`

**Store keys in HSM** or other secure key management system where possible.

**Version the PQ public key** with an identifier:
```
public_key_id = "ml-dsa-65-mainnet-2025Q4"
```
and include it in JSON responses.

### 6.2 Logging and Audit

**Log both signatures** (ECDSA + PQ) for each VRF response.

**Include:**
- `randomness`
- `digest` (or its hex representation)
- timestamps
- key identifiers

This enables future forensic analysis if classical keys are ever compromised.

---

## 7. Security Notes and Limitations

### 7.1 R4 VRF v0 Is Not PQ-Secure On-Chain

Even with dual-signing in Phase 1, until on-chain verification uses PQ signatures:
- A quantum adversary can still forge ECDSA signatures
- Contracts that rely only on ECDSA verification remain vulnerable in a far-future quantum scenario

**The main benefit of Phase 1 is:**  
Building a PQ audit trail and operational practice before on-chain PQ primitives exist.

### 7.2 Trust Model Remains Single-Signer

The PQ migration does not change the trust model of R4 VRF:
- It is still a single-signer system (centralized signer)
- PQ only strengthens cryptographic robustness, not decentralization or unbiasability

**If you need:**
- Protocol-level unbiasability
- Multi-party DKG
- Threshold VRF / randomness beacons

...then a committee-based design (e.g., DKG + threshold signatures) is more appropriate. R4 VRF is explicitly targeted at off-L1 environments (L2s, AA, private rollups) where operators are already trusted.

---

## 8. Summary

R4 VRF v0 uses ECDSA for on-chain verification and is not post-quantum secure today.

The hash layer (`keccak256`) and entropy core can already be aligned with PQ best practices.

A four-phase migration (0 → 3) cleanly separates:
- Production reality (ECDSA)
- Dual-signing for audit
- Hybrid on-chain verification
- PQ-only future regime

Dual-signing with ML-DSA-65 (FIPS 204) is the primary recommended path.

The migration can be implemented with:
- Minimal changes to the Solidity interface
- No change to the basic idea that "R is the randomness, and we verify its signature"

**R4 VRF's PQ story is intentionally pragmatic:**  
Start with ECDSA. Add PQ signatures off-chain. Adopt PQ verification on-chain once the ecosystem is ready.

---

## 9. References

- NIST FIPS 204 — Module-Lattice-Based Digital Signature Standard (ML-DSA)
- NIST FIPS 140-3 — Security Requirements for Cryptographic Modules
- NIST SP 800-90A — Recommendation for Random Number Generation Using Deterministic RBGs
- Ethereum ecosystem discussions on PQ migration and signature precompiles
