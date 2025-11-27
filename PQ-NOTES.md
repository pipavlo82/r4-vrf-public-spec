R4 — Post-Quantum Notes
Status, Migration Path & Production Guarantees
Version: 1.0
Updated: November 2025

1. Overview
R4 implements a dual-signature post-quantum readiness model designed to ensure long-term verifiability of VRF outputs, even after classical cryptography becomes insecure.
R4 already ships production endpoints with:

ECDSA(secp256k1) signature (EVM compatible)
ML-DSA-65 (FIPS 204) signature (quantum-resistant)
Kyber-based sealed entropy seeds (FIPS 203)
Hash-based deterministic VRF pipeline (curve-free)

This document describes the current status, rationale, and PQ migration phases.

2. Why Post-Quantum Now?
Quantum computers, once scaled, will break:

Elliptic-curve signatures (ECDSA, Ed25519)
Elliptic-curve VRFs (ECVRF)
Pairing-based schemes (BLS, BN254)
Hash-to-curve constructions dependent on discrete log assumptions

Time estimates vary, but consensus is:

ECDSA L1 / bridge keys are high-value targets
Targeted break is possible years before full-scale practical quantum machines
Auditability of randomness becomes impossible retroactively

R4 solves this today via dual-sign.

3. Production Status (Already Live)
The R4 /v1/vrf?sig=ecdsa endpoint already returns PQ signatures. Example response:
json{
  "signature_type": "ECDSA(secp256k1) + ML-DSA-65",
  "pq_scheme": "ML-DSA-65",
  "signer_addr": "0x1c091be3d997B04a9AE3967F8632FEBb0Fe72293"
}
```

### 3.1 Live Guarantees

- **Classical layer:** ECDSA verifies on-chain today
- **PQ layer:** ML-DSA-65 verifies offline today; on-chain later
- Both signatures cover the same randomness R
- All outputs remain verifiable long after ECDSA is broken

### 3.2 Why This Matters

A VRF or oracle without PQ signatures becomes:

- Unverifiable after quantum era
- Legally useless for audits
- Economically unsafe for high-value systems

R4 eliminates this risk.

---

## 4. Dual-Signature Architecture
```
Randomness R  
     │  
     ├── ECDSA(secp256k1)     → On-chain verification today  
     └── ML-DSA-65 (FIPS 204) → PQ audit trail, offline/on-chain future
Guarantees
PropertyECDSAML-DSA-65Pre-quantum✔ Works✔ WorksPost-quantum✖ Broken✔ SecureOn-chain today✔ Native EVM✖ Not yetLong-term audit✖ Invalid✔ Valid indefinitely

5. Migration Phases
R4 PQ migration is structured into four phases.
Phase 0 — Production (Current)
Status: 100% live

Dual-signature engine
PQ digest commitments
VRF deterministic pipeline
ML-DSA signatures included in API responses

Phase 1 — Hybrid Verification (Q2 2025)

Libraries for ML-DSA verification (off-chain)
On-chain ECDSA + off-chain PQ audits
PQ-ready test vectors

Phase 2 — PQ On-Chain (2026)
Depends on EVM upgrades:

PQSIGVERIFY precompile
ML-DSA or Falcon Verify opcode
GAS-optimized PQ verification

R4 will expose:
solidityverifyPQ(vrf_output, pq_signature, pq_public_key) → bool
Phase 3 — Pure PQ Mode (Future)
After ECDSA deprecation:

VRF outputs signed only by ML-DSA
Kyber-sealed entropy
Hash-based curve-free VRF proofs become primary


6. Cryptographic Assumptions
R4 avoids classical hard problems:
❌ Does not rely on:

Discrete log
EC groups
Pairing assumptions
Polynomial commitments relying on DLP

✔ Instead depends on:

Hash collision resistance (Keccak512, BLAKE2s, SHAKE)
Module-LWE (Kyber, ML-DSA)
Deterministic hash-based VRF folding
Chaotic + multi-entropy source mixing

The system remains secure under Grover's model with parameter expansion.

7. Compatibility With Ethereum
Works today:

ECDSA verification
Deterministic VRF outputs
Single-signer model for sequencers/AA

Works tomorrow:

ML-DSA verification via precompile
PQ wallets (AA + RIP-7560)
PQ-ready VRF proof structures


8. Summary
R4 is the first production system offering:

Dual ECDSA + PQ signatures
Curve-free VRF design
Kyber-sealed entropy
Future-native cryptography
Long-term auditability

This makes R4 uniquely suitable for:

L2 sequencer fairness
AA bundler selection
ZK prover assignment
Enterprise verifiable randomness
Post-quantum blockchain infrastructure
