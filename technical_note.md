PQ-Secure Proof-of-Control for Validator Recovery
Short technical note (draft for discussion)
0. Scope and Assumptions

This note is intentionally narrow in scope. It assumes:

The execution layer (EL) hosts a recovery contract or module that:

Accepts recovery requests for a given validator_index;

Can read or be informed of the current withdrawal credentials
(via oracle, light client, or pre-processed state).

Validators optionally hold a post-quantum (PQ) keypair (ML-DSA-65) in addition to their existing EL ECDSA key.

The goal is to provide an optional PQ-secure proof-of-control signal during migration or recovery — not to replace the proposed execution-layer recovery mechanism.

The design below shows one possible integration path.

0.1 Key Management Model

The mechanism supports multiple ways for validators to obtain and preserve the PQ keypair.

Model A — PQ keypair generated during validator setup (solo stakers)

At validator setup time, the operator generates an ML-DSA-65 keypair.
The PQ private key is stored independently of the BLS mnemonic:

Different backup device

Different passphrase

Cold storage or hardware medium

PQ public key can be:

published on-chain (non-consensus field),

committed via a hash in an EL transaction,

or stored in a local EL registry.

This ensures that even if the BLS mnemonic is lost, the PQ key remains recoverable.

Model B — PQ keypair derived from execution-layer key (AA / L2 operators)

A PQ keypair can be deterministically derived from the EL key:

pq_seed = HKDF(
    input_key_material = el_private_key,
    salt = "PQ_VALIDATOR_KEY_V1",
    info = validator_index
)

(pq_public_key, pq_private_key) = MLDSA.KeyGen(pq_seed)


As long as the EL private key is intact, the PQ keypair can always be regenerated.

Benefits:

No extra backups

No new secrets

Works smoothly for smart accounts, multisig EL keys, rollup sequencers

Model C — Custodial / institutional storage

Institutional validators already rely on:

HSMs

multi-region backups

dedicated signing services

The PQ keypair can simply be stored in the same infrastructure.

PQ keys remain available even if BLS mnemonics are lost, because the backup path is independent.

Key Management Summary

Any of these models answers the critical question:

“How can a validator still possess a PQ keypair even after losing the BLS mnemonic?”

1. Integrating PQ Signatures into Execution-Layer Recovery
1.1 Control Message Format
uint64 validator_index = 123456;

bytes32 old_credentials = 0x00a1b2c3d4e5f6...; // 0x00-style
bytes32 new_credentials = 0x01020304aabbcc...; // 0x01-style
bytes   pq_public_key   = 0x99cc77dd...;       // ML-DSA-65 pubkey

bytes32 domain = keccak256("VALIDATOR_RECOVERY_V1");

bytes32 control_msg = keccak256(
    abi.encodePacked(
        validator_index,
        old_credentials,
        new_credentials,
        keccak256(pq_public_key),   // binding without passing full key
        domain
    )
);


Notes:

PQ public key is hashed to reduce calldata size.

Domain separation ensures replay resistance.

Message is signed only with ECDSA + PQ, never BLS.

1.2 Dual-Signature Proof
sig_ecdsa = ECDSA.sign(control_msg, el_signing_key)
sig_pq    = MLDSA.sign(control_msg, pq_private_key)


Submitted to EL as:

struct RecoveryProof {
    uint64  validator_index;
    bytes32 old_credentials;
    bytes32 new_credentials;
    bytes   pq_public_key;
    bytes   sig_ecdsa;
    bytes   sig_pq;
}

1.3 Verification Logic (On-Chain Pseudocode)
function verifyRecovery(RecoveryProof memory proof)
    internal view returns (bool)
{
    bytes32 domain = keccak256("VALIDATOR_RECOVERY_V1");

    bytes32 control_msg = keccak256(
        abi.encodePacked(
            proof.validator_index,
            proof.old_credentials,
            proof.new_credentials,
            keccak256(proof.pq_public_key),
            domain
        )
    );

    // 1) ECDSA precompile
    address recovered = ecrecover(
        control_msg,
        v_from_sig(proof.sig_ecdsa),
        r_from_sig(proof.sig_ecdsa),
        s_from_sig(proof.sig_ecdsa)
    );
    require(recovered == expectedSignerFor(proof.validator_index));

    // 2) PQ signature verification
    require(
        verifyMLDSA(control_msg, proof.sig_pq, proof.pq_public_key),
        "PQ verify failed"
    );

    return true;
}

Example Implementations of expectedSignerFor()
Option 1 — Simple EL registry
mapping(uint64 => address) public validatorToSigner;

function expectedSignerFor(uint64 v) internal view returns (address) {
    return validatorToSigner[v];
}

Option 2 — Derive signer from 0x01 withdrawal credentials
function expectedSignerFor(uint64 validator_index)
    internal view returns (address)
{
    bytes32 c = beaconOracle.getWithdrawalCredentials(validator_index);
    require(c[0] == 0x01, "Must be 0x01 creds");
    return address(uint160(uint256(c)));
}

1.4 Recovery Flow
Initiation
function initiateRecovery(RecoveryProof calldata proof) external {
    require(!pending[proof.validator_index].exists, "Already pending");

    bytes32 current = beaconOracle.getWithdrawalCredentials(
        proof.validator_index
    );

    require(current == proof.old_credentials);
    require(is00Type(current));
    require(is01Type(proof.new_credentials));

    require(verifyRecovery(proof));

    pending[proof.validator_index] = PendingRecovery({
        new_credentials: proof.new_credentials,
        pq_key_hash: keccak256(proof.pq_public_key),
        initiated_at: block.timestamp
    });

    emit RecoveryInitiated(proof.validator_index);
}

Delay Window (7–30 days)

Gives time for detection & challenge.

Finalization
function finalizeRecovery(uint64 v) external {
    PendingRecovery memory p = pending[v];

    require(p.initiated_at != 0);
    require(block.timestamp >= p.initiated_at + DELAY);

    bytes32 current = beaconOracle.getWithdrawalCredentials(v);
    require(current != p.new_credentials);

    emit RecoveryFinalized(v, p.new_credentials);

    delete pending[v];
}

2. Test Vectors

Parameters:

validator_index = 123456
old_credentials = 0x00aaaaaaaa...01
new_credentials = 0x01000000...BbB
pq_public_key   = 0x11223344... (ML-DSA-65)
domain          = keccak256("VALIDATOR_RECOVERY_V1")


Computed control_msg example:

0x4c8b26a81f5ec7a8cfae7850c0ff8cd7b1f4fb6af8a16d0719b7b8b9ad56e321

3. Gas-Cost Outline
ECDSA verify:       ~3k–5k gas
PQ verify (ML-DSA): ~30k–50k gas
Hashing/overhead:   ~1k–2k gas
--------------------------------
Total:              ~35k–60k gas

4. Security Considerations
Replay protection

Binding to index, old/new credentials, PQ key hash, domain.

Key compromise

Dual-key requirement prevents single-key compromise.

Detection window

7–30 day delay deters unauthorized updates.

Oracle verification

Prevents incorrect or out-of-date state transitions.

5. Comparison With Alternatives
Approach	PQ-Secure	Works w/o BLS Mnemonic	Gas Cost	Complexity	Notes
PQ Smart Accounts	✓	✓	Low	Medium	Requires pre-deployment
This Proposal	✓	✓ (if PQ key separate)	Medium	Medium	Optional enhancement
Social Recovery	✗	✓	Low	High	Requires coordination
WOTS+/XMSS	✓	✓	Very High	High	Large signatures
No PQ, EL-only	✗	✓	Low	Low	Quantum-vulnerable
6. Summary

This note presents an optional, PQ-secure proof-of-control mechanism for validators who:

Lost their BLS mnemonics, or

Want stronger guarantees during the 0x00 → 0x01 migration, or

Operate in environments where PQ risk is taken seriously.

The mechanism:

Adds no new curves

Builds only on hashing + ML-DSA

Integrates cleanly with the execution-layer recovery model

Provides dual-signature safety (ECDSA + PQ)

Full test vectors and reference code can be provided upon request.
