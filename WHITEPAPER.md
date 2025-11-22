R4 — Post-Quantum Verifiable Randomness & Entropy Engine
Whitepaper v0.1
1. Abstract

R4 is a post-quantum–resilient entropy and verifiable randomness system designed for blockchain consensus, smart contracts, cryptographic systems, and decentralised applications.
The system combines multi-source entropy, deterministic PQ-safe VRF logic, and dual-signature verification (ECDSA + ML-DSA-65), ensuring long-term auditability even in the presence of quantum adversaries.
R4 is engineered to be compatible with Ethereum AA, future PQ-EIPs, and verifiable on-chain systems.

2. Introduction

Modern blockchains rely heavily on randomness and signature verification, yet the majority of deployed systems are built on cryptography that will be broken by quantum computers.
This paper introduces R4 — a fully deterministic, hash-based, curve-free VRF & entropy pipeline that remains verifiable after the collapse of elliptic-curve cryptography.

Motivation:

Future-proof randomness for smart contracts and L2 ecosystems

PQ-resilient audit trail

Compatibility with ERC-4337 AA

No reliance on ECDSA or hash-to-curve logic

High-throughput, deterministic, verifiable generation

3. Architecture Overview
3.1 System Components

R4-Core sealed binary (proprietary entropy engine)

R4-API layer (FastAPI, Docker, RPC endpoints)

Dual signature engine (ECDSA + ML-DSA-65)

Hash-based deterministic VRF engine

Seed sealing via Kyber KEM

Entropy monitors: NIST SP800-22, Dieharder, PractRand, bit-plane analyzer

4. Entropy Design
4.1 Multi-Source Entropy

jitter noise

chaotic logistic maps

π-based irrational noise

hardware timing jitter

system entropy pools

memory variance sampling

4.2 Mixing Stages

Keccak-512

BLAKE2s

SHAKE128/256

Fisher-Yates

bit-plane flattening

long-run trimming

Each stage is quantum-safe since none rely on discrete-logarithm hardness assumptions.

5. Deterministic VRF Construction

R4 does not use elliptic curves.
The VRF is built on:

pure hashing

bitwise diffusion

deterministic seeded folding

collision-resistant commitments

This avoids any dependency on ECVRF / BLS VRF assumptions.

6. Post-Quantum Design (PQ Section)
(цей розділ я вже адаптував під whitepaper — вставляється без змін)
6.1 Curve-Free VRF Model

Unlike classical VRFs dependent on elliptic curves, R4’s VRF is built entirely on deterministic hash-based constructs, eliminating all discrete-logarithm vulnerabilities exploitable by Shor’s algorithm.

6.2 PQ-Safe Auditability

R4 ensures long-term verifiability of randomness outputs even after classical cryptographic schemes break:

ML-DSA-65 (Dilithium) signatures for forward-secure verification

Kyber KEM for sealing private entropy seeds

deterministic proofs that remain valid indefinitely

6.3 PQ-Safe Entropy Pipeline

R4's entropy channels use only PQ-resistant primitives:

Keccak-512

BLAKE2s

SHAKE

Hash-based mixing

No elliptic curves, no DH, no hash-to-curve

This removes the quantum attack surface entirely.

6.4 Upgrade Path for Ethereum

R4 is fully compatible with future PQ system extensions:

ERC-4337 PQ wallets

EIP-7701/7702 signature pipeline refactors

RIP-7560 PQ-hints

future PQ opcodes (e.g., FALCON_VERIFY, PQSIGVERIFY)

R4 is not ECVRF-compatible — it is future-native.

7. Security Model

collision-resistance

forward privacy

entropy unpredictability

reproducible deterministic VRF proofs

PQ-resilience assumption (hash-based)

dual-signing audit trail
7.1 Cryptographic Assumptions

No reliance on elliptic-curve assumptions

Security depends only on hash function collision resistance

PQ-secure signature layer provides auditability

All entropy mixing layers are non-invertible, quantum-safe

7.2 Threats Covered

quantum adversary breaking ECC

entropy prediction

replay/fault-injection

state compromise and seed leakage

long-term signature forgery

7.3 Guarantees

deterministic VRF outputs

forward privacy

unpredictable entropy

verifiable long-term audit trail

multi-source entropy safety

8. Performance
8.1 Randomness Throughput

900k ops/s in standalone mode

150–250k ops/s under API load

8.2 Verification Cost (benchmarked)

ECDSA: ~45k gas

ML-DSA-65: ~550k–700k gas (future precompile: <50k)

R4 VRF proof verification: ~190k gas

8.3 Latency

VRF generation: 0.05–0.3 ms

mixing pipeline: ~0.2–0.7 ms

8.4 Memory & CPU

Optimized for:

low memory footprint

high cache locality

vectorized mixing

10. Roadmap
Phase 1 — Public Beta

API release

VRF endpoints

attested node signatures

docs + SDKs

Phase 2 — PQ Expansion

ML-DSA-65 full integration

Kyber-sealed seeds

PQ verification demos on-chain

Ethereum AA PQ wallet example

Phase 3 — Full PQ Hardening

FALCON_VERIFY or PQSIGVERIFY RIP

on-chain VRF verification with PQ proofs

decentralized beacon mode (multi-node R4 beacon)

Phase 4 — Enterprise / Defense

long-term audit-proof mode

hardened entropy sealing

compliance (FIPS + SP800)

multi-region beacon clusters

11. Conclusion

R4 provides a next-generation verifiable randomness system — deterministic, hash-based, curve-free, quantum-resilient, and compatible with the future cryptographic landscape of Ethereum.

12. Appendix (optional)

test vectors

VRF examples

entropy metrics

benchmark logs
1. ASCII Diagram: High-Level R4 PQ Architecture
+---------------------------------------------------------------+
|                       R4 PQ Stack                             |
+---------------------------+-----------------------------------+
| Entropy Sources           |  Verification Layer               |
|---------------------------|-----------------------------------|
| • jitter                  |  • ECDSA (optional)               |
| • chaotic maps            |  • ML-DSA-65 (PQ signature)       |
| • π-noise                 |  • Kyber-sealed seeds             |
| • OS entropy pools        |                                   |
+---------------------------+-----------------------------------+
| Whitening & Mixing Layers                                     |
|---------------------------------------------------------------|
| • Keccak512 | BLAKE2s | SHAKE128/256 | Fisher–Yates shuffle  |
+---------------------------------------------------------------+
| Hash-Based Deterministic VRF                                 |
|---------------------------------------------------------------|
| • curve-free                                                 |
| • deterministic proof                                        |
| • no hash-to-curve                                           |
| • quantum-safe                                               |
+---------------------------------------------------------------+
| Output: VRF proof + dual signature + entropy metadata         |
+---------------------------------------------------------------+

2. SVG Diagram (готова до вставки у whitepaper або repo)
<svg width="920" height="520" xmlns="http://www.w3.org/2000/svg">
<rect x="10" y="10" width="900" height="500" fill="white" stroke="black" stroke-width="2"/>
<text x="330" y="40" font-size="26" font-family="monospace">R4 PQ Architecture</text>

<rect x="50" y="70" width="350" height="120" fill="#e6f7ff" stroke="black"/>
<text x="70" y="100" font-size="18">Entropy Sources</text>
<text x="80" y="125" font-size="14">• jitter • chaotic maps • π-noise</text>
<text x="80" y="145" font-size="14">• timers • OS entropy pools</text>

<rect x="520" y="70" width="350" height="120" fill="#fff2cc" stroke="black"/>
<text x="540" y="100" font-size="18">Verification Layer</text>
<text x="550" y="125" font-size="14">• ECDSA (compat)</text>
<text x="550" y="145" font-size="14">• ML-DSA-65 (PQ)</text>
<text x="550" y="165" font-size="14">• Kyber sealed seeds</text>

<rect x="50" y="210" width="820" height="110" fill="#eaffea" stroke="black"/>
<text x="70" y="240" font-size="18">Mixing Layers</text>
<text x="80" y="265" font-size="14">Keccak512 • BLAKE2s • SHAKE • Fisher–Yates</text>

<rect x="50" y="350" width="820" height="120" fill="#ffe6e6" stroke="black"/>
<text x="70" y="380" font-size="18">Hash-Based Deterministic VRF (Curve-Free)</text>
<text x="80" y="405" font-size="14">• no elliptic curves</text>
<text x="80" y="425" font-size="14">• deterministic proof generation</text>
<text x="80" y="445" font-size="14">• post-quantum–resilient</text>
</svg>

