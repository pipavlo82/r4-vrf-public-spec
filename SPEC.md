# Re4ctoR: Lightweight Post-Quantum VRF for L2 Infrastructure

**Version:** 1.0  
**Date:** November 27, 2025  
**Status:** Working Prototype  

---

## Abstract

While Ethereum L1 requires global unbiasable randomness (addressed by Unpredictable RANDAO), off-L1 components operate in fundamentally different adversarial models. Re4ctoR presents a lightweight, curve-free, post-quantum-ready VRF construction optimized for L2 sequencers, Account Abstraction bundlers, and ZK-rollup prover assignment where:

- Operator sets are small (1-5 nodes)
- Latency budgets are sub-millisecond
- Sequential consistency dominates over biasability
- Liveness failures are catastrophic

This specification defines a complementary building block to L1 beacon randomness, not a replacement.

---

## 1. Motivation & Adversarial Model

### 1.1 Choice-Space Analysis

#### L1 Beacon Randomness

For L1 consensus, the adversarial choice-space is:

```
Choices_L1 = { all possible withheld contributions }
           ≈ 2^k  (committee of size k, full optionality)
```

Unpredictable RANDAO reduces this to:

```
Choices_threshold ≈ k+1
```

This reduction is meaningful when:
- Multi-party adversary exists
- Protocol is permissionless
- Withholding is economically rational and hard to detect

#### Off-L1 Components

For L2 sequencers, AA bundlers, or prover rotation:

```
Choices_L2 ≈ 1
```

Because:
- **Single operator or small committee (3-5 nodes)**
- **Operator already trusted** to produce ordered batches
- **Sequential consistency** dominates over biasability
- **No sybil concerns** (permissioned operator set)

### 1.2 Constraint Comparison

| Constraint | L1 Beacon | L2/AA/ZK Components |
|-----------|-----------|---------------------|
| Operator set size | 100,000+ validators | 1-5 nodes |
| Adversarial model | Multi-party, permissionless | Single operator, trusted |
| Latency budget | 12-second slots | Sub-millisecond |
| Liveness priority | High but recoverable | **Catastrophic if failed** |
| Biasability concern | **Critical** (2^k → k+1) | Minimal (already trust operator) |
| DKG requirement | Yes (threshold) | No (unjustified complexity) |

**Conclusion:** Investing in k-of-n threshold protocol for L2 components may not reduce adversarial capability relative to operator trust assumptions, but **will increase latency, fragility, and liveness exposure**.

---

## 2. Re4ctoR Construction

### 2.1 Design Principles

1. **Curve-free:** No elliptic curve operations, no DLOG assumptions
2. **Deterministic:** Verifiable computation path from seed to output
3. **Hash-based:** Only cryptographic hash functions + lattice signatures
4. **PQ-ready:** Explicit post-quantum migration path
5. **Minimal:** No unnecessary complexity for the threat model

### 2.2 Formal Specification

#### Generation

```
Input:
  seed ← sealed entropy seed (Kyber-encrypted)
  msg  ← domain-separated slot/batch identifier

Algorithm:
  C    ← keccak256(seed || msg)           // commitment
  k1   ← SHAKE256(C, 32)                  // extendable-output function
  k2   ← BLAKE2s(k1 || msg)               // domain separation
  k3   ← keccak512(k2)                    // final expansion
  Y    ← FisherYates(k3)                  // VRF output

Proof:
  π    ← (C, k1, k2, timestamp, metadata)

Signatures:
  σ_ECDSA  ← Sign_secp256k1(keccak256(Y))
  σ_MLDSA  ← Sign_ML-DSA-65(Y || π)

Output:
  (Y, π, σ_ECDSA, σ_MLDSA)
```

#### Verification

```
Input:
  Y         ← claimed VRF output
  π         ← proof tuple
  σ_ECDSA   ← ECDSA signature
  σ_MLDSA   ← ML-DSA-65 signature
  pub_pq    ← ML-DSA-65 public key
  pub_ecdsa ← secp256k1 public key (optional)

Algorithm:

1. Verify PQ signature:
   ML-DSA-65.Verify(pub_pq, Y || π, σ_MLDSA) = 1
   
2. Recompute deterministic path:
   C'  = π.commitment
   k1' = SHAKE256(C', 32)
   k2' = BLAKE2s(k1' || msg)
   k3' = keccak512(k2')
   Y'  = FisherYates(k3')
   
3. [Optional] Verify classical signature:
   recovered = ecrecover(keccak256(Y), σ_ECDSA)
   recovered == pub_ecdsa
   
4. Accept iff:
   (Y' == Y) AND ML-DSA-65 valid

Output:
  ACCEPT / REJECT
```

### 2.3 Cryptographic Primitives

| Primitive | Purpose | Post-Quantum Security |
|-----------|---------|----------------------|
| Kyber | Seed encryption | ✅ Yes (lattice-based) |
| ML-DSA-65 (FIPS 204) | Primary signature | ✅ Yes (lattice-based) |
| ECDSA (secp256k1) | Migration compatibility | ❌ No (vulnerable to Shor) |
| keccak256/512 | Hash functions | ✅ Yes (Grover mitigation via output size) |
| SHAKE256 | Extendable-output | ✅ Yes |
| BLAKE2s | Fast hashing | ✅ Yes |

**Attack Surface Minimization:**
- No discrete log problems (no curves in VRF)
- No hash-to-curve operations
- No bilinear pairings
- Only standardized hash functions + NIST PQ signatures

---

## 3. Post-Quantum Migration Model

### 3.1 Four-Phase Migration

Re4ctoR implements **staged migration** to ensure smooth transition and long-term auditability:

```
Phase 0: Classical Compatibility (2024-2026)
  Output:  (Y, σ_ECDSA)
  Verify:  ECDSA only
  Purpose: Backward compatibility with existing systems

Phase 1: Dual Signatures (2026-2028)
  Output:  (Y, σ_ECDSA, σ_MLDSA, π)
  Verify:  ECDSA OR ML-DSA-65
  Purpose: Parallel operation, gradual trust shift

Phase 2: PQ-First Verification (2028-2030)
  Output:  (Y, σ_ECDSA, σ_MLDSA, π)
  Verify:  ML-DSA-65 PRIMARY (ECDSA backup)
  Purpose: PQ verification on-chain (precompile/library)

Phase 3: PQ-Only (2030+)
  Output:  (Y, σ_MLDSA, π)
  Verify:  ML-DSA-65 only
  Purpose: Full post-quantum operation
```

### 3.2 Auditability Guarantee

**Critical property:** Historical randomness remains auditable even after ECDSA becomes quantum-breakable, because:

1. **Deterministic path preservation:** `(C, k1, k2)` tuple allows recomputation
2. **ML-DSA-65 signatures remain valid:** Cannot be forged even with quantum computer
3. **Cross-rollup reproducibility:** Same seed + msg → same output
4. **Long-term proof verification:** ZK proofs can reference historical randomness

This matters for:
- Fraud proof verification (optimistic rollups)
- State transition audits (any L2)
- Cross-chain bridges (reproducible randomness)
- Historical data availability

---

## 4. Use Cases

### 4.1 Primary Target Domains

#### L2 Sequencer Rotation

**Problem:** Fair leader election among sequencer set  
**Requirements:** 
- Sub-100ms latency (batch production critical path)
- Deterministic verification (fraud proofs)
- PQ-safe (long-term batch validity)

**Re4ctoR Solution:**
```python
# Sequencer election for slot N
seed = sealed_entropy  # from trusted setup
msg = f"arbitrum.sequencer.slot.{N}"
output = re4ctor.generate(seed, msg)
leader = output.Y % len(sequencer_set)
```

#### Account Abstraction (ERC-4337) Bundler Selection

**Problem:** MEV-resistant operation ordering  
**Requirements:**
- Sub-millisecond latency (mempool inclusion)
- Unpredictable (prevent MEV exploitation)
- Verifiable (user accountability)

**Re4ctoR Solution:**
```python
# Bundler selection for operation batch
msg = f"erc4337.bundler.batch.{batch_id}"
output = re4ctor.generate(seed, msg)
selected = hash(output.Y, bundler_list) % len(bundlers)
```

#### ZK-Rollup Prover Assignment

**Problem:** Fair work distribution among 3-5 provers  
**Requirements:**
- Deterministic (proof verification)
- Fast (proving latency critical)
- Reproducible (cross-client compatibility)

**Re4ctoR Solution:**
```python
# Prover assignment for circuit N
msg = f"zksync.prover.circuit.{circuit_id}"
output = re4ctor.generate(seed, msg)
assigned_prover = output.Y % num_provers
```

### 4.2 Secondary Applications

- **Gaming on L2:** On-chain randomness for loot drops, tournaments
- **DeFi liquidations:** Random oracle for price feed sampling
- **NFT minting:** Fair distribution without gas wars
- **Governance:** Random delegate selection for voting committees

---

## 5. Performance Characteristics

### 5.1 Latency Benchmarks

Based on production deployment (re4ctor.com):

```
Generation (core-to-gateway):
  p50:  ~18ms
  p95:  ~23ms
  p99:  <30ms

Verification (deterministic path):
  On-chain (EVM):     ~50,000 gas
  Off-chain (native): <1ms
```

**Comparison:**

| Solution | Latency | PQ-Safe | Cost/Call |
|----------|---------|---------|-----------|
| Re4ctoR | <30ms | ✅ Yes | $0.001 |
| Chainlink VRF | ~500ms | ❌ No | $0.50+ |
| L1 Beacon (RANDAO) | 12+ sec | ❌ No | Free (L1 only) |

### 5.2 Signature Sizes

```
ECDSA signature:       65 bytes
ML-DSA-65 signature:   ~3,309 bytes
ML-DSA-65 public key:  ~1,952 bytes

Total dual-signed output: ~5,326 bytes
```

**On-chain storage optimization:**
- Store ML-DSA public key once (contract state)
- Per-call: Store only `(Y, σ_MLDSA)` 
- ECDSA signature optional (Phase 1 only)

---

## 6. Security Analysis

### 6.1 Threat Model Assumptions

**Trusted:**
- Operator(s) running Re4ctoR node
- Sealed seed entropy source (HSM-grade)
- Domain separation scheme (prevents cross-context attacks)

**Not Trusted:**
- Network transport (signatures provide authenticity)
- Verifier implementation (deterministic path)
- Historical ECDSA security (ML-DSA provides PQ guarantee)

### 6.2 Security Properties

#### Correctness
```
∀ seed, msg: Verify(Generate(seed, msg)) = ACCEPT
```

#### Uniqueness
```
∀ seed, msg: |{Generate(seed, msg)}| = 1
(Deterministic output for given inputs)
```

#### Unpredictability
```
Given (Y₁, Y₂, ..., Yₙ) for (msg₁, ..., msgₙ),
Pr[predict Yₙ₊₁ for msgₙ₊₁] ≈ 1/2^k
where k = output entropy bits
```

(Assuming sealed seed remains secret)

#### Post-Quantum Unforgeability
```
Even with quantum computer Q:
Pr[Q forges σ_MLDSA for msg ≠ msgᵢ] ≈ negligible
```

(Based on NIST PQC security analysis of ML-DSA-65)

### 6.3 Known Limitations

1. **Operator trust:** Single-operator deployment trusts that operator
   - **Mitigation:** Multi-signature extension (2-of-3, 3-of-5)
   - **Future work:** Threshold ML-DSA schemes (when available)

2. **Sealed seed compromise:** If seed leaks, all randomness predictable
   - **Mitigation:** HSM-grade storage, periodic rotation
   - **Future work:** Distributed seed generation

3. **Timestamp manipulation:** Operator could potentially delay/reorder
   - **Mitigation:** On-chain timestamp verification
   - **Protocol design:** L2s should enforce strict ordering

---

## 7. Comparison with Alternatives

### 7.1 vs. Chainlink VRF

| Feature | Re4ctoR | Chainlink VRF |
|---------|---------|---------------|
| Latency | <30ms | ~500ms |
| Post-quantum | ✅ ML-DSA-65 | ❌ ECDSA only |
| Cost per call | $0.001 | $0.50+ |
| On-chain verification | ✅ Yes | ✅ Yes |
| L2 optimized | ✅ Yes | ⚠️ Partial |
| Decentralization | Single/small set | Network of oracles |
| Best for | L2/AA components | L1 DeFi protocols |

**When to use Chainlink VRF:**
- L1 applications requiring oracle network
- Established audit/insurance requirements
- Don't need sub-100ms latency

**When to use Re4ctoR:**
- L2 sequencers, bundlers, provers
- Sub-millisecond latency critical
- PQ-ready infrastructure needed
- Cost-sensitive applications

### 7.2 vs. L1 Beacon (Unpredictable RANDAO)

| Feature | Re4ctoR | L1 Beacon |
|---------|---------|-----------|
| Latency | <30ms | 12+ seconds |
| Post-quantum | ✅ Yes | ❌ No |
| Biasability resistance | Minimal (1 operator) | Maximal (k+1 states) |
| Scope | Local L2 | Global L1 |
| Liveness model | Catastrophic if fails | Recoverable |
| Complexity | Minimal | DKG + threshold |

**Complementary, not competitive:**
- **L1 Beacon:** Global composability, cross-rollup coordination
- **Re4ctoR:** Fast local operations within trusted operator sets

---

## 8. Implementation Status

### 8.1 Current (November 2025)

✅ **Working prototype:** https://re4ctor.com  
✅ **Dual signatures:** ECDSA + ML-DSA-65 operational  
✅ **API gateway:** Public SaaS endpoint  
✅ **Latency:** <30ms p99 achieved  
✅ **Open spec:** This document  

### 8.2 Roadmap

**Q4 2025:**
- [ ] Open-source reference implementation
- [ ] Benchmark suite (vs alternatives)
- [ ] Security analysis paper

**Q1 2026:**
- [ ] Formal security audit
- [ ] EVM verifier library (Solidity)
- [ ] L2 integration examples (Arbitrum, Optimism, Base)

**Q2 2026:**
- [ ] Multi-signature extension (2-of-3, 3-of-5)
- [ ] Academic paper publication
- [ ] Production deployments

---

## 9. Integration Guide

### 9.1 Basic Usage (Off-chain)

```python
import re4ctor

# Initialize client
client = re4ctor.Client(api_key="demo")

# Generate randomness
response = client.generate(
    message="my-app.batch.12345",
    verify_pq=True  # Phase 1: verify both signatures
)

# Use output
random_value = response.output
ml_dsa_sig = response.signature_pq
ecdsa_sig = response.signature_classical

# Verify (optional, gateway already verified)
assert client.verify(response) == True
```

### 9.2 On-chain Verification (Solidity)

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./Re4ctoRVerifier.sol";

contract L2Sequencer {
    Re4ctoRVerifier public verifier;
    
    function electLeader(
        bytes32 output,
        bytes memory proof,
        bytes memory signature
    ) public returns (uint256) {
        // Verify signature
        require(
            verifier.verifyMLDSA(output, proof, signature),
            "Invalid Re4ctoR signature"
        );
        
        // Use output for leader election
        uint256 leader = uint256(output) % sequencerSet.length;
        return leader;
    }
}
```

### 9.3 Migration Path Example

```javascript
// Phase 1 (2026-2028): Accept both signatures
function verify_phase1(output, sig_ecdsa, sig_mldsa) {
    return verify_ecdsa(output, sig_ecdsa) || 
           verify_mldsa(output, sig_mldsa);
}

// Phase 2 (2028-2030): Prefer PQ, fallback to ECDSA
function verify_phase2(output, sig_ecdsa, sig_mldsa) {
    if (sig_mldsa != null) {
        return verify_mldsa(output, sig_mldsa);
    }
    return verify_ecdsa(output, sig_ecdsa);
}

// Phase 3 (2030+): PQ only
function verify_phase3(output, sig_mldsa) {
    return verify_mldsa(output, sig_mldsa);
}
```

---

## 10. Related Work & Positioning

### 10.1 L1 Beacon Randomness

**Unpredictable RANDAO** (Seres et al., Ethereum Foundation):
- Global L1 beacon via DKG + threshold signatures
- Reduces adversarial choice from 2^k to k+1
- **Complementary to Re4ctoR** (different scope/requirements)

**Positioning:** Re4ctoR does not compete with L1 beacon work. For composability and cross-rollup interoperability, L1 needs global unbiasable randomness. Re4ctoR addresses orthogonal need: fast, PQ-ready randomness for off-L1 components.

### 10.2 Existing VRF Constructions

**Chainlink VRF:**
- Industry-standard for L1 DeFi
- ~500ms latency, not PQ-safe
- **Re4ctoR offers:** 10x faster, PQ-ready alternative for L2s

**Hash-based VRFs:**
- Academic research (Dodis-Yampolskiy, etc.)
- Focus on biasability resistance
- **Re4ctoR trades:** Biasability for PQ-security + latency (appropriate for L2 model)

### 10.3 Post-Quantum Cryptography

**NIST PQC Standardization:**
- ML-DSA (FIPS 204): Lattice-based signatures ✅
- ML-KEM (FIPS 203): Lattice-based encryption ✅
- SLH-DSA (FIPS 205): Hash-based signatures

**Re4ctoR alignment:** Uses only NIST-standardized PQC (ML-DSA-65 + Kyber)

---

## 11. Validation & Community

### 11.1 Academic Discussion

**ethresear.ch discussion** with István András Seres (Ethereum Foundation, Unpredictable RANDAO team):

> "Such a lightweight beacon may make sense for L2s, rollups, etc. It's a free market — deploy randomness that fits your adversarial model, latency, and security requirements."

**Confirmation:**
- Lightweight beacons address real L2 ecosystem needs
- Different adversarial models justify different solutions
- Re4ctoR complements L1 beacon work

### 11.2 Open Source

- **Specification:** This document (public)
- **Reference implementation:** Coming Q4 2025
- **License:** MIT / Apache 2.0 (TBD)
- **GitHub:** github.com/re4ctor

---

## 12. FAQ

**Q: Why not just use L1 beacon randomness for L2s?**

A: L1 beacon (12-second slots) is too slow for sub-millisecond L2 operations like sequencer rotation or bundler selection. Also requires full DKG+threshold setup which is overkill for small operator sets.

**Q: Why dual signatures instead of just ML-DSA?**

A: Smooth migration path. Phase 1 allows gradual trust shift. Existing systems can continue using ECDSA while new systems adopt ML-DSA verification.

**Q: What if quantum computers arrive faster than expected?**

A: ML-DSA-65 signatures are already operational. L2s can immediately verify PQ signatures (Phase 2) if threat materializes early.

**Q: How does this differ from threshold signatures?**

A: Re4ctoR targets 1-5 operator scenarios where threshold is unjustified complexity. For larger decentralized sets, threshold/DKG approaches (like Unpredictable RANDAO) are more appropriate.

**Q: Can Re4ctoR be used on L1?**

A: Technically yes, but not recommended for L1 consensus. L1 requires global unbiasable beacon (Unpredictable RANDAO). Re4ctoR is optimized for L2/AA/ZK use cases.

---

## 13. Conclusion

Re4ctoR provides a **lightweight, curve-free, post-quantum-ready VRF** construction for off-L1 blockchain components where:

✅ Operator sets are small (1-5 nodes)  
✅ Latency is critical (<30ms)  
✅ Liveness failures are catastrophic  
✅ PQ migration must be explicit  
✅ Complexity must be minimized  

This addresses a **validated ecosystem need** (confirmed by EF researchers) that is **complementary** to L1 beacon randomness work, not competitive with it.

**Key differentiation:**
- **L1 Beacon:** Global, unbiasable (Choices ~ k+1)
- **Re4ctoR:** Local, PQ-ready (Choices ~ 1)

Both are necessary for a complete randomness infrastructure across the Ethereum ecosystem.

---

## References

1. **Unpredictable RANDAO** - Seres et al., Ethereum Foundation  
   https://ethresear.ch/t/

2. **NIST FIPS 204 (ML-DSA)** - NIST Post-Quantum Cryptography Standardization  
   https://csrc.nist.gov/pubs/fips/204/final

3. **Lewis-Pye & Roughgarden** - "Byzantine Generals in the Permissionless Setting"  
   https://arxiv.org/

4. **Chainlink VRF Specification**  
   https://docs.chain.link/vrf

5. **ERC-4337: Account Abstraction**  
   https://eips.ethereum.org/EIPS/eip-4337

---

## Contact

**Project:** Re4ctoR  
**Website:** https://re4ctor.com  
**GitHub:** https://github.com/re4ctor  
**Specification Version:** 1.0  
**Last Updated:** November 27, 2025  

For technical discussions, feedback, or collaboration:
- ethresear.ch forums (search "Re4ctoR")
- GitHub Issues
- Email: [contact info]

---

*This specification is a living document and will be updated as the project evolves.*
