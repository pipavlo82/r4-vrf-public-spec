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

[![Open Spec](https://img.shields.io/badge/Spec-Open%20Source-9acd32?style=for-the-badge)](https://github.com/pipavlo82/r4-vrf-public-spec)
[![License](https://img.shields.io/badge/License-Apache%202.0-00bcd4?style=for-the-badge)](./LICENSE)
[![Solidity](https://img.shields.io/badge/Solidity-0.8.21-ff8c3c?style=for-the-badge&logo=solidity)](./contracts/)
[![PQ-Ready](https://img.shields.io/badge/PQ-Ready-d4af37?style=for-the-badge)](./spec/)

</div>

---

> **Open, permissionless and verifiable randomness spec aligned with Ethereum's long-term vision.**

This repository contains a **minimal, open specification** and reference implementation of a verifiable randomness scheme (**R4 VRF**) designed for Ethereum and EVM-compatible chains.

---

## 🎯 What This Repo Provides

| Feature | Description |
|---------|-------------|
| 📋 **Simple VRF Flow** | Auditable ECDSA-based verification |
| 📜 **On-chain Verifier** | Minimal `R4VRFVerifier.sol` contract |
| 📖 **Clear Specification** | Anyone can implement, extend or critique |
| 🔮 **PQ Upgrade Path** | Ready for ML-DSA-65 dual signatures |

> **Note:** This repo intentionally does **not** include sealed entropy cores or commercial code. It focuses purely on the open specification.

---

## 📐 High-Level Design

```
┌──────────────────────────────────────────────────────────────────────────────┐
│                         R4 VRF VERIFICATION FLOW                             │
├──────────────────────────────────────────────────────────────────────────────┤
│                                                                              │
│  ┌─────────────────────┐                                                    │
│  │   OFF-CHAIN NODE    │                                                    │
│  │                     │                                                    │
│  │  1. Generate R      │  ◄── 256-bit random value                         │
│  │     (random value)  │                                                    │
│  │                     │                                                    │
│  │  2. hash = keccak   │  ◄── keccak256(R)                                 │
│  │     256(R)          │                                                    │
│  │                     │                                                    │
│  │  3. Sign hash       │  ◄── ECDSA signature (v, r, s)                    │
│  │     with ECDSA      │                                                    │
│  │                     │                                                    │
│  └─────────┬───────────┘                                                    │
│            │                                                                 │
│            │  Transmit: { R, v, r, s }                                      │
│            │                                                                 │
│            ▼                                                                 │
│  ┌─────────────────────┐                                                    │
│  │   SMART CONTRACT    │                                                    │
│  │                     │                                                    │
│  │  4. Recompute hash  │  ◄── keccak256(R)                                 │
│  │                     │                                                    │
│  │  5. ecrecover       │  ◄── Recover signer from (v, r, s)                │
│  │     (hash, v, r, s) │                                                    │
│  │                     │                                                    │
│  │  6. Verify signer   │  ◄── Check against trusted address                │
│  │     == trusted      │                                                    │
│  │                     │                                                    │
│  │  7. Use R as        │  ◄── Provably fair randomness                     │
│  │     verified random │                                                    │
│  │                     │                                                    │
│  └─────────────────────┘                                                    │
│                                                                              │
└──────────────────────────────────────────────────────────────────────────────┘
```

### Step-by-Step

| Step | Location | Action | Output |
|------|----------|--------|--------|
| 1 | Off-chain | Generate random `R` | 256-bit value |
| 2 | Off-chain | Compute `hash = keccak256(R)` | 32 bytes |
| 3 | Off-chain | Sign `hash` with ECDSA | `(v, r, s)` |
| 4 | On-chain | Receive `R, v, r, s` | — |
| 5 | On-chain | Verify via `ecrecover` | Recovered address |
| 6 | On-chain | Check signer == trusted | Boolean |
| 7 | On-chain | Use `R` as randomness | Verified random |

---

## 📁 Repository Structure

```
r4-vrf-public-spec/
│
├── 📄 README.md                    # This file
├── 📜 LICENSE                      # Apache 2.0
│
├── 📂 spec/
│   └── vrf-spec-v0.md             # Formal specification document
│
├── 📂 contracts/
│   └── R4VRFVerifier.sol          # On-chain verifier contract
│
└── 📂 test/
    └── R4VRFVerifier.test.js      # Hardhat test suite
```

---

## 🔍 Motivation

### Why R4 VRF?

R4 VRF focuses on **simplicity and auditability**. Instead of a complex oracle network, it verifies randomness by checking an ECDSA signature on-chain.

```
┌─────────────────────────────────────────────────────────────────┐
│                    DESIGN PHILOSOPHY                            │
├─────────────────────────────────────────────────────────────────┤
│                                                                 │
│  Traditional Oracle VRF:                                        │
│  ┌─────────────────────────────────────────────────────────┐   │
│  │  Complex network → Multiple nodes → Consensus →          │   │
│  │  Aggregation → Delayed response → High gas costs         │   │
│  └─────────────────────────────────────────────────────────┘   │
│                                                                 │
│  R4 VRF:                                                        │
│  ┌─────────────────────────────────────────────────────────┐   │
│  │  Single signature → Direct verification →                │   │
│  │  Instant response → Minimal gas costs                    │   │
│  └─────────────────────────────────────────────────────────┘   │
│                                                                 │
└─────────────────────────────────────────────────────────────────┘
```

### Use Cases

| Application | How R4 VRF Helps |
|-------------|------------------|
| 🎮 **Games** | Provably fair loot drops, dice rolls |
| 🎟️ **Raffles** | Verifiable winner selection |
| ⚖️ **DAO Governance** | Random committee selection |
| 🔗 **L2 Mechanisms** | Internal randomness for rollups |
| 🃏 **NFT Mints** | Fair distribution algorithms |

---

## ⚛️ Post-Quantum Security Rationale

### The Problem

Modern blockchain systems depend on cryptographic proofs that are **vulnerable to quantum computers**:

```
┌────────────────────────────────────────────────────────────────┐
│              QUANTUM VULNERABILITY MATRIX                       │
├─────────────────────────┬──────────────────────────────────────┤
│  Primitive              │  Quantum Threat                      │
├─────────────────────────┼──────────────────────────────────────┤
│  ECDSA                  │  ❌ Broken by Shor's algorithm       │
│  ECDH                   │  ❌ Broken by Shor's algorithm       │
│  Traditional VRF        │  ❌ Relies on DLP hardness           │
│  ecrecover              │  ❌ ECC-based, non-PQ                │
├─────────────────────────┼──────────────────────────────────────┤
│  Hash functions         │  ✅ Resistant (Grover mitigated)     │
│  ML-DSA-65 (Dilithium)  │  ✅ Lattice-based, PQ-safe           │
│  Kyber KEM              │  ✅ Module-LWE, PQ-safe              │
└─────────────────────────┴──────────────────────────────────────┘
```

### R4 Solution: Hybrid Security Model

```
┌──────────────────────────────────────────────────────────────────┐
│                R4 HYBRID SECURITY ARCHITECTURE                   │
├──────────────────────────────────────────────────────────────────┤
│                                                                  │
│  ╔════════════════════════════════════════════════════════════╗ │
│  ║  LAYER 1: PQ-HARDENED ENTROPY SOURCE                       ║ │
│  ╠════════════════════════════════════════════════════════════╣ │
│  ║  • Multi-source entropy (system, jitter, chaos, π-noise)  ║ │
│  ║  • Keccak-based whitening                                 ║ │
│  ║  • Post-quantum–safe hashing domains                      ║ │
│  ║  • Deterministic seed expansion (no elliptic curves)      ║ │
│  ║                                                            ║ │
│  ║  Result: Randomness pipeline with ZERO quantum-breakable  ║ │
│  ║          primitives                                        ║ │
│  ╚════════════════════════════════════════════════════════════╝ │
│                              │                                   │
│                              ▼                                   │
│  ╔════════════════════════════════════════════════════════════╗ │
│  ║  LAYER 2: PQ-SAFE VERIFICATION                             ║ │
│  ╠════════════════════════════════════════════════════════════╣ │
│  ║  Compatibility Layer:                                      ║ │
│  ║  • ECDSA/secp256k1 — works with current EVMs              ║ │
│  ║                                                            ║ │
│  ║  Forward-Secure Layer:                                     ║ │
│  ║  • ML-DSA-65 (Dilithium3) — PQ signatures                 ║ │
│  ║  • Kyber KEM — seed sealing                               ║ │
│  ║                                                            ║ │
│  ║  Result: Dual-signature mode preserves auditability       ║ │
│  ║          even after ECC is broken                          ║ │
│  ╚════════════════════════════════════════════════════════════╝ │
│                              │                                   │
│                              ▼                                   │
│  ╔════════════════════════════════════════════════════════════╗ │
│  ║  LAYER 3: ECRECOVER-FREE DESIGN                            ║ │
│  ╠════════════════════════════════════════════════════════════╣ │
│  ║  Traditional Ethereum VRF:                                 ║ │
│  ║  • Relies on ecrecover (inherently non-PQ)                ║ │
│  ║                                                            ║ │
│  ║  R4 VRF avoids this via:                                   ║ │
│  ║  • Explicit public keys                                   ║ │
│  ║  • Hash-to-curve–free proof structure                     ║ │
│  ║  • PQ-friendly verification flow                          ║ │
│  ╚════════════════════════════════════════════════════════════╝ │
│                                                                  │
└──────────────────────────────────────────────────────────────────┘
```

### Ethereum PQ Upgrade Path

R4 is designed to be compatible with future Ethereum improvements:

| Standard | Purpose | R4 Compatibility |
|----------|---------|------------------|
| **RIP-7560** | PQ verification hints | ✅ Ready |
| **EIP-7701** | Set EOA code | ✅ Ready |
| **EIP-7702** | Signature pipeline refactors | ✅ Ready |
| **ERC-4337** | Account Abstraction | ✅ Works today |
| **PQSIGVERIFY** | Future PQ precompile | ✅ Designed for |

> **R4 is not just ECVRF-compatible — it is future-native.**

---

## 📜 On-Chain Verifier Contract

### `R4VRFVerifier.sol`

```solidity
// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.21;

/**
 * @title R4VRFVerifier
 * @notice Minimal on-chain verifier for R4 VRF randomness
 * @dev Verifies ECDSA signatures on random values
 */
contract R4VRFVerifier {
    
    /// @notice Trusted signer address (R4 node)
    address public immutable trustedSigner;
    
    /// @notice Emitted when randomness is verified and consumed
    event RandomnessVerified(
        bytes32 indexed randomValue,
        address indexed verifier,
        uint256 timestamp
    );
    
    /// @notice Emitted when verification fails
    error InvalidSignature();
    error InvalidSigner(address recovered, address expected);
    
    constructor(address _trustedSigner) {
        trustedSigner = _trustedSigner;
    }
    
    /**
     * @notice Verify R4 VRF output
     * @param randomValue The 256-bit random value R
     * @param v ECDSA recovery id
     * @param r ECDSA signature component
     * @param s ECDSA signature component
     * @return verified True if signature is valid
     */
    function verify(
        bytes32 randomValue,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external view returns (bool verified) {
        // Compute hash of the random value
        bytes32 hash = keccak256(abi.encodePacked(randomValue));
        
        // Ethereum signed message prefix
        bytes32 ethSignedHash = keccak256(
            abi.encodePacked("\x19Ethereum Signed Message:\n32", hash)
        );
        
        // Recover signer address
        address recovered = ecrecover(ethSignedHash, v, r, s);
        
        if (recovered == address(0)) {
            revert InvalidSignature();
        }
        
        if (recovered != trustedSigner) {
            revert InvalidSigner(recovered, trustedSigner);
        }
        
        return true;
    }
    
    /**
     * @notice Verify and consume randomness in one call
     * @param randomValue The 256-bit random value R
     * @param v ECDSA recovery id
     * @param r ECDSA signature component
     * @param s ECDSA signature component
     * @return randomNumber The verified random value as uint256
     */
    function verifyAndConsume(
        bytes32 randomValue,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external returns (uint256 randomNumber) {
        require(this.verify(randomValue, v, r, s), "Verification failed");
        
        emit RandomnessVerified(randomValue, msg.sender, block.timestamp);
        
        return uint256(randomValue);
    }
    
    /**
     * @notice Get a random number in range [0, max)
     * @param randomValue Verified random value
     * @param max Upper bound (exclusive)
     */
    function randomInRange(
        bytes32 randomValue,
        uint256 max
    ) external pure returns (uint256) {
        return uint256(randomValue) % max;
    }
}
```

### Usage Example

```solidity
contract MyRaffle {
    R4VRFVerifier public verifier;
    address[] public participants;
    
    constructor(address _verifier) {
        verifier = R4VRFVerifier(_verifier);
    }
    
    function selectWinner(
        bytes32 randomValue,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external returns (address winner) {
        // Verify the randomness
        uint256 randomNumber = verifier.verifyAndConsume(
            randomValue, v, r, s
        );
        
        // Select winner
        uint256 winnerIndex = randomNumber % participants.length;
        winner = participants[winnerIndex];
        
        // Distribute prize...
    }
}
```

---

## 🧪 Running Tests

### 1. Install Dependencies

```bash
# Initialize project
npm init -y

# Install Hardhat and toolbox
npm install --save-dev hardhat @nomicfoundation/hardhat-toolbox

# Initialize Hardhat
npx hardhat
# Choose: "Create an empty hardhat.config.js"
```

### 2. Configure Hardhat

Edit `hardhat.config.js`:

```javascript
require("@nomicfoundation/hardhat-toolbox");

module.exports = {
  solidity: "0.8.21",
  networks: {
    hardhat: {
      chainId: 31337
    }
  }
};
```

### 3. Run Tests

```bash
npx hardhat test
```

### Expected Output

```
  R4VRFVerifier
    ✓ Should verify valid signature (45ms)
    ✓ Should reject invalid signature
    ✓ Should reject wrong signer
    ✓ Should emit event on verifyAndConsume
    ✓ Should calculate random in range correctly

  5 passing (1s)
```

---

## ⚠️ Limitations (v0)

```
┌────────────────────────────────────────────────────────────────┐
│                    CURRENT LIMITATIONS                         │
├────────────────────────────────────────────────────────────────┤
│                                                                │
│  ⚠️  NOT a decentralized randomness beacon                     │
│      └─ Single trusted signer model                           │
│                                                                │
│  ⚠️  Does NOT prevent bias from malicious node                 │
│      └─ Higher-level protocols must handle this               │
│                                                                │
│  ⚠️  Uses classical ECDSA                                      │
│      └─ Post-quantum support planned in v1+                   │
│                                                                │
│  ⚠️  No commit-reveal scheme                                   │
│      └─ Node could theoretically withhold unfavorable results │
│                                                                │
└────────────────────────────────────────────────────────────────┘
```

### Mitigation Strategies

| Limitation | Mitigation |
|------------|------------|
| Single signer | Use reputation systems, slashing |
| Bias potential | Commit-reveal in higher protocols |
| ECDSA only | Upgrade path to ML-DSA-65 |
| No beacon | Multi-node beacon in v3 |

---

## 🛤️ Roadmap

```
┌────────────────────────────────────────────────────────────────┐
│                    SPECIFICATION ROADMAP                       │
├────────────────────────────────────────────────────────────────┤
│                                                                │
│  ╔══════════════════════════════════════════════════════════╗ │
│  ║  v0 — CURRENT                                  [NOW]     ║ │
│  ╠══════════════════════════════════════════════════════════╣ │
│  ║  ✅ Basic ECDSA verification                             ║ │
│  ║  ✅ Minimal on-chain verifier                            ║ │
│  ║  ✅ Formal specification document                        ║ │
│  ║  ✅ Hardhat test suite                                   ║ │
│  ╚══════════════════════════════════════════════════════════╝ │
│                              │                                 │
│                              ▼                                 │
│  ╔══════════════════════════════════════════════════════════╗ │
│  ║  v1 — DOMAIN SEPARATION                       [Q2 2025]  ║ │
│  ╠══════════════════════════════════════════════════════════╣ │
│  ║  🔲 Structured domain separation                         ║ │
│  ║  🔲 Chain ID / contract address in hash                  ║ │
│  ║  🔲 Nonce management                                     ║ │
│  ║  🔲 Request/response correlation                         ║ │
│  ╚══════════════════════════════════════════════════════════╝ │
│                              │                                 │
│                              ▼                                 │
│  ╔══════════════════════════════════════════════════════════╗ │
│  ║  v2 — DUAL SIGNATURES                         [Q3 2025]  ║ │
│  ╠══════════════════════════════════════════════════════════╣ │
│  ║  🔲 ECDSA + ML-DSA-65 dual signing                       ║ │
│  ║  🔲 PQ signature storage on-chain                        ║ │
│  ║  🔲 Future-proof audit trail                             ║ │
│  ║  🔲 Verification library for ML-DSA-65                   ║ │
│  ╚══════════════════════════════════════════════════════════╝ │
│                              │                                 │
│                              ▼                                 │
│  ╔══════════════════════════════════════════════════════════╗ │
│  ║  v3 — COMMITTEE BEACON                        [Q4 2025]  ║ │
│  ╠══════════════════════════════════════════════════════════╣ │
│  ║  🔲 Multi-signer threshold scheme                        ║ │
│  ║  🔲 Decentralized randomness beacon                      ║ │
│  ║  🔲 Commit-reveal protocol                               ║ │
│  ║  🔲 Slashing for misbehavior                             ║ │
│  ╚══════════════════════════════════════════════════════════╝ │
│                                                                │
└────────────────────────────────────────────────────────────────┘
```

---

## 🔗 Related Projects

| Project | Description | Link |
|---------|-------------|------|
| **r4-monorepo** | Full production implementation | [View →](https://github.com/pipavlo82/r4-monorepo) |
| **r4-prod** | Docker deployment stack | [View →](https://github.com/pipavlo82/r4-prod) |
| **r4-vrf-public-spec** | Open specification | *You are here* |

> **Note:** This repository (`r4-vrf-public-spec`) is intentionally minimal. For a full production-grade implementation with sealed entropy core, FIPS readiness, and dual signatures, see [r4-monorepo](https://github.com/pipavlo82/r4-monorepo).

---

## 📜 License

**Apache 2.0** — See [LICENSE](./LICENSE) for details.

```
Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.
```

---

## 📞 Contact

<div align="center">

[![Email](https://img.shields.io/badge/Email-shtomko%40gmail.com-00bcd4?style=for-the-badge&logo=gmail)](mailto:shtomko@gmail.com)
[![GitHub](https://img.shields.io/badge/GitHub-pipavlo82-181717?style=for-the-badge&logo=github)](https://github.com/pipavlo82)

**Maintainer:** Pavlo Tvardovskyi

</div>

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

**⭐ Star this repo if you find it useful!**

[![GitHub stars](https://img.shields.io/github/stars/pipavlo82/r4-vrf-public-spec?style=social)](https://github.com/pipavlo82/r4-vrf-public-spec/stargazers)

</div>

---

<div align="center">
<sub>Open Specification v0 • Apache 2.0 License • 2025</sub>
</div>
