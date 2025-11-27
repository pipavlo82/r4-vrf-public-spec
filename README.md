# R4 VRF — Public Specification

**Minimal, auditable verifiable randomness for Ethereum L2s and account abstraction**

R4 VRF provides deterministic on-chain verification of randomness from a trusted entropy source. Designed for L2 sequencers, AA bundlers, ZK prover selection, and private rollups where operational simplicity and low latency matter more than decentralization.

---

## Why R4 VRF?

**Performance:**
- 14 ms median latency (production tested)
- ~3,100 gas for on-chain verification
- 4,000x faster than oracle networks

**Simplicity:**
- Single Solidity contract, no dependencies
- Pure EVM verification (ecrecover + keccak256)
- ~50 lines of auditable code

**Future-proof:**
- Explicit post-quantum migration path
- Compatible with ML-DSA-65 (NIST FIPS 204)
- No protocol redesign needed for PQ transition

---

## Verification Flow

```
Off-chain entropy node:
  1. Generate 256-bit randomness R
  2. Compute hash = keccak256(R)
  3. Sign hash with secp256k1 → (v, r, s)

Smart contract:
  4. Recompute hash' = keccak256(R)
  5. Recover signer = ecrecover(hash', v, r, s)
  6. Verify signer == trustedSigner
  7. Use R as verified randomness
```

**Properties:**
- Deterministic verification
- Signature binds to exact randomness value
- No external oracle dependencies

---

## Quick Start

### Installation

```bash
npm install @r4/vrf-contracts
```

### Basic Integration

```solidity
import "@r4/vrf-contracts/R4VRFVerifier.sol";

contract MyLottery {
    R4VRFVerifier public verifier;
    address[] public participants;

    constructor(address _verifier) {
        verifier = R4VRFVerifier(_verifier);
    }

    function drawWinner(
        bytes32 randomness,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external {
        require(
            verifier.verify(randomness, v, r, s),
            "Invalid VRF signature"
        );

        uint256 winnerIndex = uint256(randomness) % participants.length;
        payable(participants[winnerIndex]).transfer(prize);
    }
}
```

---

## Performance Benchmarks

### Latency

Measured on production VPS (end-to-end `/v1/vrf?sig=ecdsa`):

| Metric | Latency |
|--------|---------|
| Median (p50) | **14 ms** |
| Average | 16 ms |
| p95 | 23 ms |
| p99 | <30 ms |

*Based on 100+ sequential requests. Network-dependent.*

### Gas Cost

```solidity
function verify(bytes32 randomness, uint8 v, bytes32 r, bytes32 s) 
    public view returns (bool) 
{
    bytes32 digest = keccak256(abi.encodePacked(randomness));
    address recovered = ecrecover(digest, v, r, s);
    return recovered == trustedSigner;
}
```

**Gas breakdown:**
- keccak256: ~36 gas
- ecrecover: ~3,000 gas
- Comparison: ~3 gas
- **Total: ~3,100 gas**

### Comparison

| Solution | Latency | Gas Cost | Decentralization |
|----------|---------|----------|------------------|
| R4 VRF | 14 ms | ~3,100 | Single signer |
| Chainlink VRF | 60-180 sec | ~200,000 | Oracle network |
| RANDAO | 12 sec | Native | Validator set |
| drand | 30 sec | ~150,000 | Threshold |

---

## Use Cases

### L2 Sequencer Rotation

```solidity
contract SequencerRotation {
    R4VRFVerifier public vrf;
    address[] public sequencers;

    function rotateSequencer(
        bytes32 randomness,
        uint8 v, bytes32 r, bytes32 s
    ) external {
        require(vrf.verify(randomness, v, r, s));
        
        uint256 index = uint256(randomness) % sequencers.length;
        currentSequencer = sequencers[index];
    }
}
```

### Account Abstraction Bundler Selection

```solidity
contract AABundlerPool {
    R4VRFVerifier public vrf;
    mapping(uint256 => address) public bundlers;

    function assignBundler(
        UserOperation calldata op,
        bytes32 randomness,
        uint8 v, bytes32 r, bytes32 s
    ) external returns (address) {
        require(vrf.verify(randomness, v, r, s));
        
        uint256 seed = uint256(keccak256(abi.encodePacked(
            randomness,
            op.sender,
            block.number
        )));
        
        return bundlers[seed % bundlerCount];
    }
}
```

### ZK Prover Assignment

```solidity
contract ProverSelection {
    R4VRFVerifier public vrf;
    address[] public provers;

    function selectProver(
        uint256 batchId,
        bytes32 randomness,
        uint8 v, bytes32 r, bytes32 s
    ) external returns (address) {
        require(vrf.verify(randomness, v, r, s));
        
        uint256 seed = uint256(keccak256(abi.encodePacked(
            randomness,
            batchId
        )));
        
        return provers[seed % provers.length];
    }
}
```

---

## Post-Quantum Migration

R4 VRF includes a staged migration path to quantum-resistant cryptography:

| Phase | Off-chain | On-chain | Status |
|-------|-----------|----------|--------|
| **Phase 0** | ECDSA | ECDSA | ✅ Production |
| **Phase 1** | ECDSA + ML-DSA-65 | ECDSA | 🔄 Dual-sign audit |
| **Phase 2** | ECDSA + ML-DSA-65 | Both | ⏳ Precompile wait |
| **Phase 3** | ML-DSA-65 | ML-DSA-65 | 🔮 Post-quantum |

**ML-DSA-65** (NIST FIPS 204) provides:
- Standardized post-quantum signature scheme
- Module-LWE security basis
- Reasonable signature sizes (~2.4 KB)
- Audit-friendly implementation

See [PQ-NOTES.md](./PQ-NOTES.md) for detailed migration strategy.

---

## Security Model

### What R4 VRF Guarantees

✅ **Authenticity**: Only trusted signer can produce valid signatures  
✅ **Integrity**: Signature binds to exact randomness value  
✅ **Determinism**: Same (R, σ) always verifies identically  
✅ **Auditability**: Minimal code surface, no hidden complexity  

### What R4 VRF Does NOT Guarantee

❌ **Decentralization**: Single signer model (by design)  
❌ **Unbiasability**: Signer can choose favorable randomness  
❌ **Liveness**: Offline signer means no randomness  
❌ **Commit-reveal**: One-shot response, no hiding phase  

### Appropriate Use Cases

**Good fit:**
- L2 sequencers (operator already trusted)
- Private/consortium rollups
- AA bundler pools (operator-controlled)
- Enterprise applications with SLAs
- Gaming with operator accountability

**Poor fit:**
- L1 consensus randomness
- Trustless lotteries requiring unbiasability
- Systems requiring 100% uptime guarantees
- Applications needing decentralization

---

## Repository Structure

```
r4-vrf-public-spec/
├── README.md                     # This file
├── LICENSE                       # Apache 2.0
├── PQ-NOTES.md                   # Post-quantum migration details
│
├── contracts/
│   ├── R4VRFVerifier.sol         # Minimal ECDSA verifier
│   └── R4VRFVerifierCanonical.sol# Production verifier
│
├── spec/
│   └── vrf-spec-v0.md            # Formal specification
│
└── test/
    ├── verify_raw_digest.js      # Unit tests
    └── verify_live.js            # Integration tests
```

---

## Testing

### Setup

```bash
npm install
npx hardhat node --hostname 0.0.0.0
```

### Run Tests

```bash
npx hardhat test --network localhost
```

**Test coverage:**
- Valid signature acceptance
- Invalid signature rejection
- Tampered message detection
- Wrong signer rejection
- Live node integration

---

## Integration Guide

### 1. Deploy Verifier Contract

```solidity
R4VRFVerifier verifier = new R4VRFVerifier(trustedSignerAddress);
```

### 2. Request Randomness

```bash
curl https://vrf.re4ctor.com/v1/vrf?sig=ecdsa
```

Response:
```json
{
  "randomness": "0x1a2b3c...",
  "signature": {
    "v": 27,
    "r": "0x4d5e6f...",
    "s": "0x7g8h9i..."
  }
}
```

### 3. Verify On-Chain

```solidity
bool valid = verifier.verify(
    randomness,
    signature.v,
    signature.r,
    signature.s
);
```

---

## Advanced Configuration

### Custom Verifier

```solidity
contract CustomVRF {
    R4VRFVerifier public vrf;
    uint256 public nonce;

    function verifyWithNonce(
        bytes32 randomness,
        uint8 v, bytes32 r, bytes32 s
    ) external {
        require(vrf.verify(randomness, v, r, s));
        
        // Add application-specific validation
        bytes32 expected = keccak256(abi.encodePacked(
            randomness,
            nonce,
            msg.sender
        ));
        
        require(expected == userCommitment[msg.sender]);
        nonce++;
    }
}
```

### Multi-Signature Verification

```solidity
contract MultiSigVRF {
    R4VRFVerifier[] public verifiers;
    uint256 public threshold;

    function verifyThreshold(
        bytes32 randomness,
        Signature[] calldata sigs
    ) external view returns (bool) {
        require(sigs.length >= threshold);
        
        uint256 validCount = 0;
        for (uint256 i = 0; i < sigs.length; i++) {
            if (verifiers[i].verify(
                randomness, 
                sigs[i].v, 
                sigs[i].r, 
                sigs[i].s
            )) {
                validCount++;
            }
        }
        
        return validCount >= threshold;
    }
}
```

---

## FAQ

### Why single-signer instead of threshold VRF?

**Simplicity and latency.** Threshold VRF requires:
- DKG coordination (setup complexity)
- Multiple network round-trips (latency)
- Threshold signature aggregation (gas costs)
- Liveness assumptions on multiple parties

For L2 sequencers and AA bundlers, the operator already controls critical infrastructure. Adding cryptographic decentralization without operational decentralization provides minimal security benefit while significantly increasing complexity.

### How is this different from Chainlink VRF?

| Aspect | R4 VRF | Chainlink VRF |
|--------|--------|---------------|
| Architecture | Single signer | Oracle network |
| Latency | 14 ms | 60-180 seconds |
| Gas cost | ~3,100 | ~200,000 |
| Code complexity | ~50 lines | ~1,000+ lines |
| Trust model | Operator | Committee |
| Best for | L2s, AA, private chains | L1, trustless apps |

### Is single-signer VRF secure enough?

**It depends on your threat model.**

If your application:
- Runs on operator-controlled infrastructure (L2 sequencer)
- Requires sub-second latency
- Benefits from operational accountability
- Can accept trusted signer model

Then R4 VRF is appropriate.

If your application:
- Requires trustless randomness
- Can tolerate 1-3 minute latency
- Needs unbiasability guarantees
- Must be censorship-resistant

Then use Chainlink VRF or RANDAO instead.

### What about quantum computers?

R4 VRF includes explicit PQ migration:

1. **Today**: ECDSA (quantum-vulnerable but practical)
2. **Transition**: Dual ECDSA + ML-DSA-65 signatures
3. **Future**: Pure ML-DSA-65 after EVM precompiles available

Migration requires no contract redesign—just parameter updates.

### Can I use this in production?

**Current status**: v0 specification, suitable for:
- Testnets ✅
- Private/consortium rollups ✅
- Controlled mainnet deployments with risk acceptance ✅

**Not recommended for**:
- High-value L1 contracts without external audit
- Trustless applications requiring unbiasability
- Critical infrastructure without operational monitoring

**Security audit**: Pending (contact shtomko@gmail.com)

---

## Contributing

Contributions welcome! Please:

1. Open an issue to discuss changes
2. Keep verifier contract minimal
3. Add tests for behavioral changes
4. Update specification docs
5. Follow existing code style

**Security disclosures**: shtomko@gmail.com (GPG available on request)

---

## Resources

- **Specification**: [spec/vrf-spec-v0.md](./spec/vrf-spec-v0.md)
- **PQ Migration**: [PQ-NOTES.md](./PQ-NOTES.md)
- **Live Demo**: https://re4ctor.com/api/ 


---

## License

Apache 2.0 — see [LICENSE](./LICENSE)

**Commercial use**: ✅ Allowed  
**Modification**: ✅ Allowed  
**Patent grant**: ✅ Included  
**Trademark**: ❌ Not granted  
**Warranty**: ❌ Provided "as is"  

---

## Contact

**Pavlo Tvardovskyi**  
R4 Project Lead  

📧 shtomko@gmail.com  
🐙 GitHub: [@pipavlo82](https://github.com/pipavlo82)  
🌐 Web: [re4ctor.com](https://re4ctor.com)  

---

<div align="center">

**R4 VRF: Simple enough to audit. Fast enough for production.**

⭐ Star this repo if you find it useful for your L2/AA infrastructure

</div>
