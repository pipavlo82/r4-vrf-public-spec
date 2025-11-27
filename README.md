<div align="center">

```
╔══════════════════════════════════════════════════════════════════════════════╗
║                                                                              ║
║           ██████╗ ██╗  ██╗    ██╗   ██╗██████╗ ███████╗                     ║
║           ██╔══██╗██║  ██║    ██║   ██║██╔══██╗██╔════╝                     ║
║           ██████╔╝███████║    ██║   ██║██████╔╝█████╗                       ║
║           ██╔══██╗╚════██║    ╚██╗ ██╔╝██╔══██╗██╔══╝                       ║
║           ██║  ██║     ██║     ╚████╔╝ ██║  ██║██║                          ║
║           ╚═╝  ╚═╝     ╚═╝      ╚═══╝  ╚═╝  ╚═╝╚═╝                          ║
║                                                                              ║
║              VERIFIABLE RANDOM FUNCTION — PUBLIC SPECIFICATION              ║
║                                                                              ║
║        Open • Permissionless • Auditable • Post-Quantum Ready               ║
║                                                                              ║
╚══════════════════════════════════════════════════════════════════════════════╝
```

</div>

# R4 VRF — Public Specification (v0)

A **minimal, auditable** verifiable randomness primitive aligned with Ethereum's long-term cryptographic roadmap.

This repository provides an **open specification**, minimal Solidity verifier, and reference test suite for validating randomness produced by an R4 entropy node.

It does **not** contain sealed entropy core code or any proprietary components — only the open verification layer intended for Ethereum and EVM chains.

---

## 🎯 Goal

Create the simplest possible verifiable randomness flow that:

- ✅ is easy to audit
- ✅ is compatible with ECDSA today
- ✅ has explicit PQ-upgrade paths
- ✅ integrates cleanly into L2 sequencers, AA, RANDAO, and MEV-resistant pipelines

**R4 VRF is intentionally minimal** — no oracle networks, no committees, no trust assumptions beyond a single verifiable signer.

---

## 📐 High-Level Verification Flow

<div align="center">

<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 800 500" style="background:#0d1117">
  <!-- Title -->
  <text x="400" y="40" font-family="monospace" font-size="18" fill="#58a6ff" text-anchor="middle" font-weight="bold">
    R4 VRF VERIFICATION FLOW
  </text>
  
  <!-- Off-chain section -->
  <rect x="50" y="80" width="700" height="160" fill="#161b22" stroke="#30363d" stroke-width="2" rx="8"/>
  <text x="70" y="110" font-family="monospace" font-size="14" fill="#7ee787" font-weight="bold">Off-chain R4 node:</text>
  
  <!-- Step 1 -->
  <text x="90" y="140" font-family="monospace" font-size="12" fill="#c9d1d9">1. Generate 256-bit randomness</text>
  <line x1="320" y1="135" x2="420" y2="135" stroke="#58a6ff" stroke-width="2" marker-end="url(#arrowblue)"/>
  <text x="440" y="140" font-family="monospace" font-size="12" fill="#ffa657" font-weight="bold">R</text>
  
  <!-- Step 2 -->
  <text x="90" y="170" font-family="monospace" font-size="12" fill="#c9d1d9">2. Compute keccak256(R)</text>
  <line x1="320" y1="165" x2="420" y2="165" stroke="#58a6ff" stroke-width="2" marker-end="url(#arrowblue)"/>
  <text x="440" y="170" font-family="monospace" font-size="12" fill="#ffa657" font-weight="bold">hash</text>
  
  <!-- Step 3 -->
  <text x="90" y="200" font-family="monospace" font-size="12" fill="#c9d1d9">3. Sign hash with secp256k1</text>
  <line x1="320" y1="195" x2="420" y2="195" stroke="#58a6ff" stroke-width="2" marker-end="url(#arrowblue)"/>
  <text x="440" y="200" font-family="monospace" font-size="12" fill="#ffa657" font-weight="bold">(v, r, s)</text>
  
  <!-- On-chain section -->
  <rect x="50" y="270" width="700" height="190" fill="#161b22" stroke="#30363d" stroke-width="2" rx="8"/>
  <text x="70" y="300" font-family="monospace" font-size="14" fill="#7ee787" font-weight="bold">Smart contract:</text>
  
  <!-- Step 4 -->
  <text x="90" y="330" font-family="monospace" font-size="12" fill="#c9d1d9">4. Recompute keccak256(R)</text>
  <line x1="320" y1="325" x2="420" y2="325" stroke="#58a6ff" stroke-width="2" marker-end="url(#arrowblue)"/>
  <text x="440" y="330" font-family="monospace" font-size="12" fill="#ffa657" font-weight="bold">hash</text>
  
  <!-- Step 5 -->
  <text x="90" y="360" font-family="monospace" font-size="12" fill="#c9d1d9">5. Recover signer via ecrecover</text>
  <line x1="320" y1="355" x2="420" y2="355" stroke="#58a6ff" stroke-width="2" marker-end="url(#arrowblue)"/>
  <text x="440" y="360" font-family="monospace" font-size="12" fill="#ffa657" font-weight="bold">recovered</text>
  
  <!-- Step 6 -->
  <text x="90" y="390" font-family="monospace" font-size="12" fill="#c9d1d9">6. Compare to trusted address</text>
  <line x1="320" y1="385" x2="420" y2="385" stroke="#58a6ff" stroke-width="2" marker-end="url(#arrowblue)"/>
  <text x="440" y="390" font-family="monospace" font-size="12" fill="#7ee787" font-weight="bold">✓ ok</text>
  <text x="500" y="390" font-family="monospace" font-size="12" fill="#f85149">/</text>
  <text x="520" y="390" font-family="monospace" font-size="12" fill="#f85149" font-weight="bold">✗ fail</text>
  
  <!-- Step 7 -->
  <text x="90" y="420" font-family="monospace" font-size="12" fill="#c9d1d9">7. Use R as verified entropy</text>
  <line x1="320" y1="415" x2="420" y2="415" stroke="#7ee787" stroke-width="2" marker-end="url(#arrowgreen)"/>
  <text x="440" y="420" font-family="monospace" font-size="12" fill="#7ee787" font-weight="bold">fair randomness</text>
  
  <!-- Arrow markers -->
  <defs>
    <marker id="arrowblue" markerWidth="10" markerHeight="10" refX="9" refY="3" orient="auto" markerUnits="strokeWidth">
      <path d="M0,0 L0,6 L9,3 z" fill="#58a6ff"/>
    </marker>
    <marker id="arrowgreen" markerWidth="10" markerHeight="10" refX="9" refY="3" orient="auto" markerUnits="strokeWidth">
      <path d="M0,0 L0,6 L9,3 z" fill="#7ee787"/>
    </marker>
  </defs>
</svg>

</div>

<details>
<summary>Text-based flow diagram</summary>

```
┌──────────────────────────────────────────────────────────────────────────────┐
│                         R4 VRF VERIFICATION FLOW                             │
├──────────────────────────────────────────────────────────────────────────────┤
│                                                                              │
│  Off-chain R4 node:                                                          │
│   1. Generate 256-bit randomness  ───────────────►   R                       │
│   2. Compute keccak256(R)         ───────────────►   hash                    │
│   3. Sign hash with secp256k1     ───────────────►   (v, r, s)               │
│                                                                              │
│  Smart contract:                                                             │
│   4. Recompute keccak256(R)      ───────────────►   hash                     │
│   5. Recover signer via ecrecover ──────────────►   recovered                │
│   6. Compare to trusted address   ──────────────►   ok / fail                │
│   7. Use R as verified entropy    ──────────────►   fair randomness          │
│                                                                              │
└──────────────────────────────────────────────────────────────────────────────┘
```

</details>

---

## 📁 Repository Structure

```
r4-vrf-public-spec/
│
├── README.md                     ← You are here
├── LICENSE                       ← Apache 2.0
├── PQ-NOTES.md                   ← Post-quantum readiness notes
│
├── contracts/
│   ├── R4VRFVerifier.sol         ← Minimal ECDSA verifier
│   └── R4VRFVerifierCanonical.sol← Canonical live-node verifier
│
├── spec/
│   └── vrf-spec-v0.md            ← Formal specification
│
└── test/
    ├── verify_raw_digest.js      ← Verifies keccak256(R)
    └── verify_live.js            ← Verifies a real R4 output
```

---

## 🧩 Minimal Verifier Contract

**`R4VRFVerifier.sol`**

A fully auditable, dependency-free ECDSA verifier:

- ✅ 1 solidity file
- ✅ no inheritance
- ✅ no inline assembly
- ✅ no curve operations beyond `ecrecover`

**A reviewer should be able to fully audit it in ~10 minutes.**

### Usage Example

```solidity
import "./R4VRFVerifier.sol";

contract MyLottery {
    R4VRFVerifier verifier;
    
    function selectWinner(
        bytes32 randomness,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external {
        require(verifier.verify(randomness, v, r, s), "Invalid VRF");
        
        uint256 winnerIndex = uint256(randomness) % participants.length;
        payable(participants[winnerIndex]).transfer(prize);
    }
}
```

---

## ⚛️ Post-Quantum Roadmap

R4 VRF is designed with compatibility for the post-quantum transition:

| Layer | PQ-Safety | Notes |
|-------|-----------|-------|
| **Hashing** | ✅ `keccak256` | PQ-resistant (Grover-bounded) |
| **Entropy pipeline** | ✅ No ECC | Chaos + system + PQ-safe domains |
| **Verification** | ⚠️ ECDSA today | To be replaced with ML-DSA-65 |
| **Upgrade path** | ✅ Dual signatures | ECDSA + ML-DSA-65 hybrid |

**Future Ethereum precompiles** (e.g., `PQSIGVERIFY`) will drop-in replace verification logic without changing the R4 protocol.

See **[PQ-NOTES.md](./PQ-NOTES.md)** for detailed migration strategy.

---

## 🧩 Integration Examples

### Account Abstraction (ERC-4337)

**Use cases:**
- Entropy for session keys
- Anti-sybil request throttling
- Random AA policies

**Integration:**
```solidity
contract AABundler {
    R4VRFVerifier verifier;
    
    function shouldBundle(uint256 slot, bytes32 vrf, ...) external view returns (bool) {
        require(verifier.verify(vrf, v, r, s), "Invalid VRF");
        return uint256(vrf) % totalBundlers == myIndex;
    }
}
```

### L2 Sequencers

**Requirements:**
- Unpredictable ordering
- Fair batch rotation
- MEV randomization

**Performance:**
- Off-chain: <1ms (signing)
- On-chain: ~500 gas (verification)

### RANDAO Compatibility

R4 VRF can serve as:
- Source for validator randomness
- Fallback if RANDAO is empty
- Entropy for L2 prover seeds

---

## 🧪 Testing

### Setup

```bash
# Install dependencies
npm install

# Run local Ethereum node
npx hardhat node --hostname 0.0.0.0
```

### Run Tests

```bash
npx hardhat test --network localhost
```

**Expected output:**
```
  R4 VRF Verifier
    ✓ should verify valid signature (142ms)
    ✓ should reject invalid signature (98ms)
    ✓ should reject wrong signer (75ms)
    ✓ should produce deterministic randomness (56ms)
    ✓ should verify live R4 output (112ms)
    ✓ should handle edge cases (89ms)

  6 passing (523ms)
```

### Test Coverage

- ✅ Raw digest recovery
- ✅ Canonical live-node signature
- ✅ Invalid signature rejection
- ✅ Deterministic fairness
- ✅ Signer mismatch detection
- ✅ Edge case handling

---

## ⚠️ Limitations (by design)

```
┌──────────────────────────────────────────────────────────┐
│                Current intentional limitations            │
├──────────────────────────────────────────────────────────┤
│  • Single trusted signer                                 │
│  • No commit-reveal                                       │
│  • No beacon or MPC                                       │
│  • PQ-verification not enabled by default                 │
└──────────────────────────────────────────────────────────┘
```

These are addressed in future versions:

| Version | Upgrade |
|---------|---------|
| **v1** | Domain separation, nonce binding |
| **v2** | Dual signatures (ECDSA + ML-DSA-65) |
| **v3** | Committee randomness beacon |

---

## 📚 Documentation

**Full technical documentation** (enterprise-grade):
- [Re4ctoR Whitepaper](https://github.com/pipavlo82/r4-monorepo/blob/main/WHITEPAPER.md)
- [Post-Quantum Design](https://github.com/pipavlo82/r4-monorepo/blob/main/POST_QUANTUM.md)
- [Ethereum Integration Guide](https://github.com/pipavlo82/r4-monorepo/blob/main/ETH_INTEGRATION.md)

**Statistical validation**:
- [Core stream validation](https://github.com/pipavlo82/r4-monorepo/tree/main/packages/core/proof)
- [VRF stream validation](https://github.com/pipavlo82/r4-monorepo/tree/main/packages/vrf-spec/components/r4-cs/rng_reports)

---

## 🧬 Statistical Validation

Both the sealed core and VRF-facing streams have been validated with industry-standard test batteries:

**TestU01:**
- BigCrush (core): 160/160 tests passed
- Crush (VRF): 144/144 statistics passed

**Dieharder 3.31.1:**
- All tests passed (core + VRF)
- No WEAK / FAILED results

**PractRand v0.95:**
- Core: 4 GiB, no anomalies
- VRF: 2 GiB, no anomalies

**NIST SP 800-22:**
- VRF stream: full pass
- All thresholds exceeded

📊 **Detailed reports**: See [r4-monorepo documentation](https://github.com/pipavlo82/r4-monorepo)

---

## 📞 Maintainer

<div align="center">

**Pavlo Tvardovskyi** — R4 Architect

📧 [Email](mailto:pavlo@re4ctor.com) • 🐦 [Twitter](https://twitter.com/pipavlo82) • 💼 [GitHub](https://github.com/pipavlo82)

</div>

---

## 🤝 Contributing

Contributions welcome! Please:

1. Open an issue first to discuss changes
2. Follow existing code style
3. Add tests for new features
4. Update documentation

**Security disclosures:** security@re4ctor.com (GPG key available)

---

## 📄 License

Apache 2.0 — See [LICENSE](./LICENSE) for details.

**Summary:**
- ✅ Commercial use allowed
- ✅ Modification allowed
- ✅ Distribution allowed
- ⚠️ Trademark use not granted
- ⚠️ No warranty provided

---

<div align="center">

```
╔══════════════════════════════════════════════════════════════╗
║                                                              ║
║                 ⚛️  R4 VRF PUBLIC SPECIFICATION             ║
║                                                              ║
║           Open • Permissionless • Verifiable • PQ-Ready     ║
║                                                              ║
║     "Simple enough to audit. Secure enough for production." ║
║                                                              ║
╚══════════════════════════════════════════════════════════════╝
```

⭐ **If this helps Ethereum's research ecosystem — consider starring the repo.**

[![GitHub stars](https://img.shields.io/github/stars/pipavlo82/r4-vrf-public-spec?style=social)](https://github.com/pipavlo82/r4-vrf-public-spec)

</div>
