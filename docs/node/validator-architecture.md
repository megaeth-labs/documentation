---
description: Architecture and implementation guide for building a MegaETH-compatible stateless validator.
---

# Validator architecture

This page describes the reference architecture of MegaETH's stateless validator and the per-block validation pipeline it runs.
It is written for engineers building a compatible validator from scratch — in another language or against a different EVM stack.

The reference implementation lives at [`megaeth-labs/stateless-validator`](https://github.com/megaeth-labs/stateless-validator) and is used throughout this page as the source of truth.
For day-to-day operation of that client, see [Stateless Validation](stateless-validation.md).
For the wire format of the witness, see [Get Block Witness](witness.md).

## What a stateless validator does

A stateless validator independently re-executes every MegaETH block against a compact cryptographic witness, then checks that every commitment in the block header matches the resulting post-state.
It holds **no chain state of its own** — a fresh witness arrives with each block and supplies just the slice of state that block touches.

| Aspect | Detail                                                                                                             |
| ------ | ------------------------------------------------------------------------------------------------------------------ |
| Input  | A `(block, witness)` pair fetched per height. The witness is the response of [`mega_getBlockWitness`](witness.md). |
| Output | A locally-persisted record that the block validates.                                                               |

The validator's only startup trust input is a **genesis JSON** (chain ID + hardfork schedule) and an **anchor block hash** that the next validated block must extend.
Both are detailed in [Genesis configuration](#genesis-configuration) below.

**Non-goal:** picking the canonical fork.
The validator validates whatever block sequence it is fed; pair it with a consensus client (e.g. `op-node`) to derive canonicality.

## Genesis configuration

The genesis JSON is the validator's primary configuration anchor.
Misconfigure it and every subsequent fork-conditional check silently runs against the wrong rules — the validator will produce mismatched state roots with no "wrong chain" error to point you at the cause.
Treat it like a chain-identity contract: load it once, persist it, and never edit it by hand.
**Pull a fresh copy of the canonical mainnet genesis whenever a new hardfork is scheduled.**
For the file layout (not a runtime artifact), see the schema-shaped sample at [`test_data/mainnet/genesis.json`](https://github.com/megaeth-labs/stateless-validator/blob/main/test_data/mainnet/genesis.json) — `alloc` is stripped to keep the repo small.

{% hint style="info" %}
**Reference impl.** Loads genesis via `--genesis-file` on first run, stores it in the local database with [`store_genesis`](https://github.com/megaeth-labs/stateless-validator/blob/main/bin/stateless-validator/src/validator_db.rs#L88), and re-reads the stored copy on every subsequent boot.
{% endhint %}

Despite the file carrying the full Genesis schema (allocations, gas limit, timestamp, base fee, ...), the validator consumes only two pieces of state from it:

| Derived value     | Source in `config`                    | Use during validation                                                                                                                                                                                                      |
| ----------------- | ------------------------------------- | -------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| Chain ID          | `chainId`                             | Drives the EVM `CHAINID` opcode and EIP-155 transaction-signature checks.                                                                                                                                                  |
| Hardfork schedule | `<fork>Block` and `<fork>Time` fields | Activates Ethereum (Cancun, Shanghai, ...), OP-Stack (Ecotone, Granite, Holocene, Isthmus, ...), and MegaETH (MiniRex, MiniRex1, MiniRex2, Rex, Rex1, Rex2, Rex3, Rex4) at their pre-declared block numbers or timestamps. |

The genesis `alloc`, `gasLimit`, `baseFeePerGas`, and other initial-state fields are **not** consumed — once the chain has produced a single block, initial state is served by the witness, not by the genesis file.

{% hint style="info" %}
**Reference impl.** [`ChainSpec::from_genesis`](https://github.com/megaeth-labs/stateless-validator/blob/main/crates/stateless-core/src/chain_spec.rs#L59) reads `genesis.config.chain_id` directly, hands the full `Genesis` to `OpChainSpec::from_genesis` to extract Ethereum and OP-Stack fork conditions, and pulls MegaETH-specific forks via [`MegaethGenesisHardforks::extract_from`](https://github.com/megaeth-labs/stateless-validator/blob/main/crates/stateless-core/src/chain_spec.rs#L123).
The three sets are merged into a single ordered hardfork schedule that drives every fork-conditional code path: opcode availability, gas-cost tables, system-contract pre/post-block hooks, and resource limits.
{% endhint %}

{% hint style="warning" %}
All replicas of the chain MUST use byte-identical genesis JSON.
A divergence in any single hardfork timestamp produces a fork that the rest of the network will reject — and because the divergence only manifests as a `state_root` mismatch on the first affected block, it is hard to attribute after the fact.
{% endhint %}

## Reference architecture

The current implementation of the stateless validator is a three-stage async pipeline.
Each `(block, witness)` pair flows through the same stages; only the validator workers run in parallel.

```text
                ┌─────────────────┐
  RPC ────────► │  Block fetcher  │
                └────────┬────────┘
                         │  (block, witness)
                  ┌──────┴──────┐
                  ▼             ▼
              ┌──────────┐ ┌──────────┐ ... N workers
              │ Worker 1 │ │ Worker 2 │
              └─────┬────┘ └─────┬────┘
                    └─────┬──────┘
                          │  ValidatedBlock
                ┌─────────▼─────────┐
                │  Chain advancer   │ ────► local chain store
                └───────────────────┘
```

| Component        | Role                                                                                                | Reference                                                                                                                                                                      |
| ---------------- | --------------------------------------------------------------------------------------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------ |
| Block fetcher    | Streams `(block, witness)` pairs from RPC. Independent semaphores cap data and witness concurrency. | [`crates/stateless-common/src/rpc_client.rs`](https://github.com/megaeth-labs/stateless-validator/blob/main/crates/stateless-common/src/rpc_client.rs)                         |
| Validator worker | Verifies the witness, replays the block, computes post-state, compares against the header.          | [`crates/stateless-core/src/executor.rs:411`](https://github.com/megaeth-labs/stateless-validator/blob/main/crates/stateless-core/src/executor.rs#L411) (`validate_block`)     |
| Chain advancer   | Reorders out-of-order results, detects reorgs by parent-hash mismatch, persists in height order.    | [`crates/stateless-core/src/pipeline/mod.rs:44`](https://github.com/megaeth-labs/stateless-validator/blob/main/crates/stateless-core/src/pipeline/mod.rs#L44) (`run_pipeline`) |
| Contract cache   | Resolves contract bytecode by code hash with three tiers: in-memory → disk (redb) → RPC.            | [`crates/stateless-db/`](https://github.com/megaeth-labs/stateless-validator/tree/main/crates/stateless-db)                                                                    |

Workers do not coordinate.
A custom implementation can collapse the pipeline into a single sequential loop without changing correctness — parallelism is purely a throughput choice.

## Validation pipeline

The per-block sequence below is what `validate_block` performs.
A different implementation MUST run every numbered step.
Reorderings are allowed only when they preserve the data dependencies between steps — most importantly, the SALT proof MUST verify (step 3) before any state is read (steps 4+), bytecode MUST be hash-verified before being installed in the cache, and each header recompute MUST include all the state changes it commits to.

{% stepper %}

{% step %}

### Fetch the block and witness

Call `eth_getBlockByHash` (or `eth_getBlockByNumber`) for the block, and [`mega_getBlockWitness`](witness.md) for the witness.
Pin the witness call to `(blockNumber, blockHash)`; a `blockNumber`-only call is non-deterministic across forks.

{% hint style="info" %}
**Reference impl.** Fetches both in parallel from independent RPC pools — see [`get_block`](https://github.com/megaeth-labs/stateless-validator/blob/main/crates/stateless-common/src/rpc_client.rs#L430) and [`get_witness`](https://github.com/megaeth-labs/stateless-validator/blob/main/crates/stateless-common/src/rpc_client.rs#L558).
{% endhint %}

{% endstep %}

{% step %}

### Decode the witness payload

Strip the `v0:` prefix, base64-decode, Zstd-decompress, and bincode-deserialize (legacy config) into `(SaltWitness, MptWitness)`.
The exact pipeline and a Rust reference snippet live on [Get Block Witness](witness.md#decoding-pipeline).

{% endstep %}

{% step %}

### Verify the SALT proof against the previous state root

The `SaltProof` inside `SaltWitness` is a multi-point IPA opening on the Banderwagon curve.
Run the verifier against the **previous block's** `state_root` (taken from the parent header, or from the trusted anchor on the very first block).

If the proof does not verify, **reject the block immediately** — every subsequent step assumes the witnessed key-value pairs are authenticated.

For the proof's mathematical structure, see the [SALT repository](https://github.com/megaeth-labs/salt).

{% endstep %}

{% step %}

### Build a state-read backend over the witness

Treat `SaltWitness.kvs` as the only source of state for the duration of replay.
Every account or storage read during execution falls through to a lookup in this map and resolves to one of three outcomes:

| Witness entry               | Verifier behavior                                                                 |
| --------------------------- | --------------------------------------------------------------------------------- |
| `Some(value)` — present     | Return the decoded account or slot.                                               |
| `Some(None)` — proven empty | Return the EVM "empty" sentinel (zero balance / nonce, no code; `0` for storage). |
| Key absent from `kvs`       | **Error.** Halt validation immediately.                                           |

{% hint style="warning" %}
The third case is what blocks witness omission attacks.
A malicious witness producer that left a key out (rather than proving it empty) would otherwise let the verifier silently treat real state as zero.
The verifier MUST treat "absent from `kvs`" as a fatal error, not as "empty".
{% endhint %}

A custom implementation needs the equivalent surface for whatever EVM it embeds.

{% hint style="info" %}
**Reference impl.** This backend is [`WitnessDatabase`](https://github.com/megaeth-labs/stateless-validator/blob/main/crates/stateless-core/src/evm_database.rs#L64), which implements [`revm::DatabaseRef`](https://docs.rs/revm/latest/revm/trait.DatabaseRef.html).
{% endhint %}

{% endstep %}

{% step %}

### Resolve contract bytecode by hash

Account entries in the witness carry the `codehash`, not the bytecode itself.
This is intentional — bytecode is large, changes infrequently, and is content-addressed, so the witness only references it.

Maintain a local cache keyed by `codehash`.
On a miss, fetch via [`eth_getCodeByHash`](https://github.com/megaeth-labs/stateless-validator/blob/main/crates/stateless-common/src/rpc_client.rs#L398) — a MegaETH RPC extension that takes a code hash and returns the bytecode whose `keccak256` equals that hash — and **verify** that `keccak256(code) == codehash` before using it.
If the endpoint does not support `eth_getCodeByHash`, fall back to `eth_getCode` against a known holder address, and **always pin the call to the exact block at which the witness anchors** (the parent block's number).
Apply the same `keccak256(code) == codehash` verification to the result.
A miss that cannot be resolved is a fatal error for the block being validated.

{% endstep %}

{% step %}

### Apply pre-execution system updates

Before the first transaction, apply hardfork-conditional system calls.
Two layers run in order:

1. **OP-Stack base hooks** (always active on MegaETH, since Isthmus is the floor):
   - EIP-2935 history-storage contract update.
   - EIP-4788 beacon root contract update.

2. **MegaEVM system-contract deployments / updates**, gated by the active MegaETH hardfork:
   - **MiniRex** — deploy the oracle contract and the high-precision timestamp oracle contract.
   - **Rex2** — deploy the keyless-deploy contract.
   - **Rex4** — deploy the access-control contract and the `MegaLimitControl` contract.
   - **MiniRex1, MiniRex2, Rex, Rex1, Rex3** — no new system-contract deployments.
     The fork still gates EVM behavior changes; the pre-execution hook list is just empty.

The L1-attributes deposit is **not** a pre-block hook: it is the block's first transaction and runs in the regular tx loop in step 7.

The exact hook set is fixed by the active hardfork — see [System Contracts](https://docs.megaeth.com/spec/system-contracts/overview) for the canonical addresses and behaviors.

{% hint style="info" %}
**Reference impl.** [`apply_pre_execution_changes`](https://github.com/megaeth-labs/stateless-validator/blob/main/crates/stateless-core/src/executor.rs#L364) inside [`replay_block`](https://github.com/megaeth-labs/stateless-validator/blob/main/crates/stateless-core/src/executor.rs#L252) delegates to mega-evm's [`pre_execution_changes`](https://github.com/megaeth-labs/mega-evm/blob/main/crates/mega-evm/src/block/executor.rs#L172), which runs the OP-Stack base hooks followed by the MegaEVM-specific system-contract deployments listed above.
{% endhint %}

{% endstep %}

{% step %}

### Replay the block's transactions

Execute every transaction with the chain's hardfork rules and accumulate state changes, receipts, and the cumulative gas counter.

A custom EVM must match MegaEVM's semantics exactly — see [Re-execution requirements](#re-execution-requirements).

Re-implementers can either link `mega-evm` directly or build a compatible EVM from the [MegaEVM specification — Dual Gas Model](https://docs.megaeth.com/spec/megaevm/dual-gas-model) and the related spec pages linked under [Re-execution requirements](#re-execution-requirements).

{% hint style="info" %}
**Reference impl.** Wires this through [`MegaBlockExecutorFactory` and `MegaEvmFactory`](https://github.com/megaeth-labs/stateless-validator/blob/main/crates/stateless-core/src/executor.rs#L273) from the [`mega-evm`](https://github.com/megaeth-labs/mega-evm) crate, which extends `revm` rather than forking it.
{% endhint %}

The `BLOCKHASH` opcode is served from the witnessed [EIP-2935](https://eips.ethereum.org/EIPS/eip-2935) history-storage contract entries — see [`evm_database.rs:149`](https://github.com/megaeth-labs/stateless-validator/blob/main/crates/stateless-core/src/evm_database.rs#L149).
There is no separate "ancestor headers" field in the witness.

{% endstep %}

{% step %}

### Apply post-execution system updates

After the last transaction, apply hardfork-conditional post-block system calls — including primarily EIP-7002 withdrawal-request and EIP-7251 consolidation-request processing on Isthmus+.
The `withdrawals_root` is **not** computed here: it is recomputed separately in step 9 against the L1 message-passer storage trie.
As with pre-execution, the exact hook set is fixed by the active hardfork.

{% hint style="info" %}
**Reference impl.** [`apply_post_execution_changes`](https://github.com/megaeth-labs/stateless-validator/blob/main/crates/stateless-core/src/executor.rs#L373) inside [`replay_block`](https://github.com/megaeth-labs/stateless-validator/blob/main/crates/stateless-core/src/executor.rs#L252) delegates to op-reth's `BlockExecutor` for the canonical hook list.
{% endhint %}

{% endstep %}

{% step %}

### Update the withdrawals MPT and recompute `withdrawals_root`

`MptWitness` carries the storage trie of the L2-to-L1 message-passer contract (`0x4200000000000000000000000000000000000016`) as RLP-encoded MPT nodes plus its pre-state root.

Apply the block's withdrawal-message writes against this trie, then recompute the root.
This must match `block.withdrawals_root`.

{% hint style="info" %}
**Reference impl.** [`MptWitness::verify`](https://github.com/megaeth-labs/stateless-validator/blob/main/crates/stateless-core/src/withdrawals.rs#L80).
{% endhint %}

{% endstep %}

{% step %}

### Apply state changes to SALT and recompute `state_root`

Flatten the EVM's collected state changes into `(SaltKey, SaltValue)` pairs.

{% hint style="info" %}
**Reference impl.** Uses two intermediate types — `PlainKey` (account address or `address ++ slot`) and `PlainValue` (encoded account or 32-byte slot) — defined in [`crates/stateless-core/src/data_types.rs`](https://github.com/megaeth-labs/stateless-validator/blob/main/crates/stateless-core/src/data_types.rs).
{% endhint %}

Encoding rules (mirrored on [Get Block Witness](witness.md#saltvalue) for the reverse direction):

| Update           | `key_len` | `value_len` | Layout                                                                              |
| ---------------- | --------- | ----------- | ----------------------------------------------------------------------------------- |
| EOA account      | 20        | 40          | 8-byte big-endian nonce ‖ 32-byte big-endian balance.                               |
| Contract account | 20        | 72          | 8-byte big-endian nonce ‖ 32-byte big-endian balance ‖ 32-byte keccak256 code hash. |
| Storage slot     | 52        | 32          | Key is `address(20) ‖ slot(32)`; value is the 32-byte big-endian U256.              |

Apply these updates to the SALT trie in canonical (sorted) key order and recompute the root.
This must match `block.state_root`.

{% endstep %}

{% step %}

### Compare every header commitment

The block validates only if **every** check below passes:

| Field              | Source                                                             |
| ------------------ | ------------------------------------------------------------------ |
| `state_root`       | Recomputed SALT root from the previous step.                       |
| `withdrawals_root` | Recomputed MPT root from step 9.                                   |
| `receipts_root`    | Merkle root of the transactions' receipts collected during replay. |
| `logs_bloom`       | Aggregated 256-byte bloom filter over emitted logs.                |
| `gas_used`         | Cumulative gas counter from replay.                                |

A single mismatch is a fatal error for the block — do **not** advance the local chain.

{% hint style="info" %}
**Reference impl.** Comparisons are at [`executor.rs:534-559`](https://github.com/megaeth-labs/stateless-validator/blob/main/crates/stateless-core/src/executor.rs#L534).
{% endhint %}

{% endstep %}

{% step %}

### Advance the local chain

If all checks pass, persist the block as the new tip.

If the validated block's `parent_hash` does not match the previous tip, treat it as a reorg: walk back to the divergence and re-validate forward along the new branch.

{% endstep %}

{% endstepper %}

## Re-execution requirements

A custom EVM must implement [OP-Stack Isthmus](https://docs.megaeth.com/spec/overview) semantics — MegaETH's baseline, inherited unless explicitly overridden — **plus** the MegaEVM-specific extensions below.
Each link points to the normative specification.

| Topic             | Reference                                                                                                                                                                                          |
| ----------------- | -------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| Dual gas model    | [Dual Gas Model](https://docs.megaeth.com/spec/megaevm/dual-gas-model) — compute gas vs. storage gas accounting per opcode.                                                                        |
| Resource limits   | [Resource Limits](https://docs.megaeth.com/spec/megaevm/resource-limits) — per-block and per-transaction caps.                                                                                     |
| System contracts  | [System Contracts](https://docs.megaeth.com/spec/system-contracts/overview) — addresses and behaviors that MUST be replicated.                                                                     |
| Precompiles       | OP-Stack Isthmus set, with MegaETH gas-cost overrides at a few standard addresses. See [Precompiles](https://docs.megaeth.com/spec/megaevm/precompiles) for the full list and per-address details. |
| Volatile data     | [Volatile Data Access](../dev/execution/volatile-data.md) — non-deterministic reads and how they are handled at re-execution.                                                                      |
| Hardfork schedule | The genesis JSON the validator is started with. Mirror the same schedule in your own client.                                                                                                       |

{% hint style="info" %}
**Reference impl.** If `block_replay_time_seconds` exceeds the chain's block period, you are not real-time — diagnose with the per-stage histograms in [Stateless Validation](stateless-validation.md#useful-metrics).
{% endhint %}

## Trust model and reorgs

The validator has two trust inputs, both supplied at startup:

- The **genesis JSON** — supplies the chain ID and hardfork schedule (see [Genesis configuration](#genesis-configuration)).
  Persisted on first run; reused thereafter.
- The **anchor block hash** — pins the chain head.
  The next validated block's `parent_hash` must equal this value.

Everything downstream is verified:

- The witness is verified cryptographically against the parent's state root before replay.
- Bytecode is verified by recomputing `keccak256(code)` on every cache miss.
- The post-state is verified by recomputing every header commitment.

The validator does **not** verify:

- **Block canonicity.** The validator validates whatever block sequence is fed to it; it does not decide which fork is canonical.
  To derive canonicality from L1 instead of trusting the upstream RPC, pair the validator with `op-node`, which derives the canonical block sequence directly from L1, and the replica feeds those blocks to the validator.

Reorgs are detected when a freshly validated block's `parent_hash` does not match the local tip.
The chain advancer truncates back to the divergence height and re-validates the new branch from there; the canonical-chain row cap (`canonical-chain-max-length`) bounds how far back this can reach.

## Reference implementation

The reference client is a Cargo workspace.
The crates below are the entry points a re-implementation will most often want to mirror:

| Crate                 | Path                                                                                                                | Role                                                                           |
| --------------------- | ------------------------------------------------------------------------------------------------------------------- | ------------------------------------------------------------------------------ |
| `stateless-core`      | [`crates/stateless-core/`](https://github.com/megaeth-labs/stateless-validator/tree/main/crates/stateless-core)     | Validation pipeline, witness-backed `revm` database, SALT update path.         |
| `stateless-common`    | [`crates/stateless-common/`](https://github.com/megaeth-labs/stateless-validator/tree/main/crates/stateless-common) | Multi-endpoint RPC client with retry/backoff and independent concurrency caps. |
| `stateless-db`        | [`crates/stateless-db/`](https://github.com/megaeth-labs/stateless-validator/tree/main/crates/stateless-db)         | redb-backed chain store, contract cache, table layout.                         |
| `stateless-validator` | [`bin/stateless-validator/`](https://github.com/megaeth-labs/stateless-validator/tree/main/bin/stateless-validator) | CLI, configuration, metrics endpoint, signal handling.                         |

Companion repositories:

- [`megaeth-labs/salt`](https://github.com/megaeth-labs/salt) — the authenticated key-value store and IPA proof system.
  Defines [`SaltWitness`](https://github.com/megaeth-labs/salt/blob/main/salt/src/proof/salt_witness.rs#L46), [`SaltKey`](https://github.com/megaeth-labs/salt/blob/main/salt/src/types.rs#L198), [`SaltValue`](https://github.com/megaeth-labs/salt/blob/main/salt/src/types.rs#L274), and [`SaltProof`](https://github.com/megaeth-labs/salt/blob/main/salt/src/proof/prover.rs#L103).
- [`megaeth-labs/mega-evm`](https://github.com/megaeth-labs/mega-evm) — the MegaEVM execution layer, layered on top of `revm`.

## Related pages

- [Get Block Witness](witness.md) — wire format, decoding pipeline, and field-by-field type definitions for the witness payload.
- [Stateless Validation](stateless-validation.md) — operator guide for running the reference client (CLI, metrics, anchoring, troubleshooting).
- [Architecture](../architecture.md) — how transactions move through MegaETH and where validators fit in.
- [MegaEVM specification — Dual Gas Model](https://docs.megaeth.com/spec/megaevm/dual-gas-model) — normative MegaEVM behavior; entry point into the spec space.
