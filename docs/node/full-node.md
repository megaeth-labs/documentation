---
description: Run a MegaETH full node — sync blocks and state from the sequencer stream and re-execute every block with the embedded stateless validator.
---

# Run a full node

A **full node** is a role of `mega-reth`, the MegaETH node client derived from [reth](https://github.com/paradigmxyz/reth).
Like a replica node, it syncs blocks and state from the sequencer stream and serves the full JSON-RPC surface.
In addition, it runs an embedded, asynchronous stateless validator that re-executes every committed block against a [SALT witness](witness.md) and halts on any state-root, receipts-root, logs-bloom, or gas mismatch produced by the sequencer.
Full nodes do not need to trust the sequencer's execution results.

For how full nodes fit into the network, see [Architecture](../architecture.md).
For the standalone validator binary that verifies blocks without holding any chain state, see [Stateless Validation](stateless-validation.md).

{% hint style="info" %}
The `mega-reth` repository and its node distributions are currently permissioned — the source and binaries are not generally available.
To run a full node, [contact the MegaETH team](https://megaeth.com) to request access, the network genesis file, and the current peer configuration.
{% endhint %}

## Node types

`mega-reth node` runs one of several roles, selected with `--node-type`:

| Value       | Role                                                                                                                    |
| ----------- | ----------------------------------------------------------------------------------------------------------------------- |
| `full-node` | Syncs blocks and state, serves JSON-RPC, and re-validates every block with the embedded stateless validator. This page. |
| `rpc-node`  | Replica node: syncs blocks and state and serves JSON-RPC without re-execution.                                          |
| `replayer`  | Re-executes blocks to generate witness data and serves `mega_getBlockWitness`.                                          |
| `sequencer` | The block producer. Default value — a full node must pass `--node-type full-node` explicitly.                           |

`full-node` and `rpc-node` share the same sync path and data directory layout; the only difference is the embedded validator pipeline that produces attestations.
Both types serve `mega_getValidatedChain`, but on an `rpc-node` it only reflects validated tips pushed by an upstream full node via `--validator.report-to`.

## Prerequisites

A full node needs four inputs beyond the binary itself:

1. **Genesis file** — the network's chain-spec JSON, passed via `--chain`.
   `mega-reth` bundles no Mainnet or Testnet chain spec; the file is distributed with node access and must match the network byte-for-byte.
2. **Sequencer public key** — the secp256k1 key the node uses to verify sequencer signatures on every header, mini-block, and stream fragment it ingests, passed via `--sequencer-public-key`.
3. **Trusted peers** — enode URLs of upstream nodes to sync from, passed via `--trusted-peers`.
   MegaETH publishes no bootnodes and block delivery is trusted-peer-only by default, so a node without trusted peers has no upstream and never starts syncing.
4. **Witness endpoint** — one or more RPC URLs serving [`mega_getBlockWitness`](witness.md), passed via `--validator.rpc-urls`.
   The endpoint needs no other JSON-RPC method: the validator reads blocks and bytecode from the node's own database and fetches only witnesses remotely.

Plan for a fast NVMe SSD and several hundred GB of storage — the MegaETH Mainnet data directory measures roughly 400 GB as of July 2026 and grows with chain history.
Validation throughput scales with CPU cores; the validator defaults to one worker per two physical cores.

## Quick start

### First run

Replace the placeholders and launch:

```bash
mega-reth node \
  --node-type full-node \
  --chain <PATH_TO_GENESIS_JSON> \
  --datadir <DATA_DIR> \
  --sequencer-public-key <SEQUENCER_PUBLIC_KEY> \
  --trusted-peers <ENODE_URL>,<ENODE_URL> \
  --disable-discovery \
  --max-load 100 \
  --validator.rpc-urls <WITNESS_RPC_URL> \
  --metrics 127.0.0.1:9001 \
  --log.file.directory <LOG_DIR>
```

- `--disable-discovery` is recommended: MegaETH has no public discovery network, and all sync traffic flows through the trusted peers anyway.
- `--max-load` caps how many downstream children this node serves in one streaming tree; it is required and has no default.
- `--metrics` binds the Prometheus endpoint; omit it to disable metrics.

To also serve JSON-RPC, add the standard reth server flags:

```bash
  --http --http.addr 0.0.0.0 --http.port 8545 \
  --http.api eth,net,web3,debug,trace,txpool,admin \
  --ws --ws.addr 0.0.0.0 --ws.port 8546
```

On start, the node:

1. Opens the data directory and runs crash-consistency recovery.
2. Initializes P2P networking and logs its own `enode` URL.
3. Handshakes with the trusted peers and starts state sync (`Committed block to engine` lines mark per-block progress).
4. Resolves the validator anchor and starts the validation pipeline.

Healthy startup output includes these lines:

```text
INFO Starting mega-reth version=...
INFO MegaETH P2P networking initialized enode=enode://...
INFO Committed block to engine block_number=... source=Fetcher
INFO validator: anchor resolved number=... action=SeedFresh
INFO megaeth validator pipeline started workers=8 in_flight_multiplier=2 rpc_endpoints=1 mode=delta
INFO validator: blocks validated and advanced from=... to=... count=...
```

### Subsequent runs

All flags shown above are operational, not persisted — re-supply them on every run.
The validator resumes from its persisted cursor automatically; only pass `--validator.start-block` when you deliberately want to re-anchor (see [Validator pipeline](#validator-pipeline)).

## Initial sync

`--bootstrap-policy` selects how an empty data directory reaches the chain tip:

- **`never` (default)** — fetch and apply every historical block from the trusted peers, starting at genesis.
  The node serves full chain history but initial sync replays the entire chain.
- **`required`** — fetch a snapshot of the current SALT state from peers instead of replaying history, then sync blocks forward from there.
  Bootstrap requires an empty data directory, and a full node additionally needs at least 256 recent blocks before the bootstrap can finish.
  A bootstrapped node cannot serve history from before its bootstrap block and cannot unwind below it.

{% hint style="warning" %}
An interrupted bootstrap can only resume if the node is fewer than 1,800 blocks behind the tip.
Beyond that, the node exits with `The last bootstrap is unfinished and it is too far behind to recover` — clear the data directory and restart the bootstrap.
{% endhint %}

The embedded validator anchors at the first synced head and validates forward only; blocks before the anchor are not re-attested.

## Command-line reference

Every flag in the tables below has an equivalent `MEGARETH_*` environment variable, convenient for service managers.
Command-line flags take precedence over environment variables.

### Core flags

| Flag                     | Env variable                    | Default          | Description                                                                                 |
| ------------------------ | ------------------------------- | ---------------- | ------------------------------------------------------------------------------------------- |
| `--node-type`            | `MEGARETH_NODE_TYPE`            | `sequencer`      | Node role. Pass `full-node`.                                                                |
| `--chain`                | `MEGARETH_CHAIN`                | `dev`            | Path to the network genesis JSON (`dev` is the only built-in chain).                        |
| `--datadir`              | `MEGARETH_DATA_DIR`             | OS data dir      | Data directory, used as-is when set. The OS default appends the chain ID as a subdirectory. |
| `--sequencer-public-key` | `MEGARETH_SEQUENCER_PUBLIC_KEY` | — (required)     | secp256k1 public key used to verify sequencer signatures on ingested headers and fragments. |
| `--max-load`             | `MEGARETH_MAX_LOAD`             | — (required)     | Maximum number of downstream children served in one streaming tree.                         |
| `--metrics`              | `MEGARETH_METRICS`              | unset (disabled) | Prometheus listen address (`HOST:PORT`).                                                    |

### Networking and state sync

| Flag                       | Env variable                      | Default   | Description                                                                                               |
| -------------------------- | --------------------------------- | --------- | --------------------------------------------------------------------------------------------------------- |
| `--trusted-peers`          | `MEGARETH_TRUSTED_PEERS`          | empty     | Comma-separated enode URLs of upstream peers. Effectively required — see [Prerequisites](#prerequisites). |
| `--subscribe-trusted-only` | `MEGARETH_SUBSCRIBE_TRUSTED_ONLY` | `true`    | Subscribe to block streams from trusted peers only.                                                       |
| `--disable-discovery`      | `MEGARETH_DISABLE_DISCOVERY`      | `false`   | Disable peer discovery. Recommended — MegaETH publishes no bootnodes.                                     |
| `--port`                   | `MEGARETH_PORT`                   | `30303`   | P2P listen port.                                                                                          |
| `--addr`                   | `MEGARETH_ADDR`                   | `0.0.0.0` | P2P listen address.                                                                                       |
| `--min-handshake-peers`    | `MEGARETH_MIN_HANDSHAKE_PEERS`    | `1`       | Peers that must complete the state-sync handshake before syncing starts.                                  |
| `--bootstrap-policy`       | `MEGARETH_BOOTSTRAP_POLICY`       | `never`   | `never` (replay from genesis) or `required` (state bootstrap). See [Initial sync](#initial-sync).         |

### Validator flags

Only consulted when `--node-type full-node`; other node types ignore them.

| Flag                                | Env variable                               | Default            | Description                                                                                                    |
| ----------------------------------- | ------------------------------------------ | ------------------ | -------------------------------------------------------------------------------------------------------------- |
| `--validator.rpc-urls`              | `MEGARETH_VALIDATOR_RPC_URLS`              | — (required)       | Witness RPC URLs (comma-separated, round-robin failover). Each must serve `mega_getBlockWitness`.              |
| `--validator.mode`                  | `MEGARETH_VALIDATOR_MODE`                  | `delta`            | Validation strategy: `delta` or `full`. See [Validation modes](#validation-modes).                             |
| `--validator.workers`               | `MEGARETH_VALIDATOR_WORKERS`               | physical cores / 2 | Parallel validation workers (minimum 1). Worker count mainly matters during catch-up.                          |
| `--validator.start-block`           | `MEGARETH_VALIDATOR_START_BLOCK`           | unset              | Trusted block hash to anchor at; validation begins at the next block. Overrides the persisted anchor.          |
| `--validator.start-block-wait-secs` | `MEGARETH_VALIDATOR_START_BLOCK_WAIT_SECS` | `0` (indefinite)   | How long to wait for the start block to appear locally before the pipeline halts.                              |
| `--validator.witness-wait-secs`     | `MEGARETH_VALIDATOR_WITNESS_WAIT_SECS`     | `60`               | Per-block witness-fetch deadline; on expiry the block is re-enqueued.                                          |
| `--validator.tip-buffer`            | `MEGARETH_VALIDATOR_TIP_BUFFER`            | `1`                | Blocks of headroom below the local tip before fetching a witness, giving the witness generator time to finish. |
| `--validator.channel-capacity`      | `MEGARETH_VALIDATOR_CHANNEL_CAPACITY`      | workers × 2        | Target total in-flight witness fetches; values below the worker count are clamped up.                          |
| `--validator.poll-interval-ms`      | `MEGARETH_VALIDATOR_POLL_INTERVAL_MS`      | `100`              | Tip-refresh interval when the validator is caught up.                                                          |
| `--validator.report-to`             | `MEGARETH_VALIDATOR_REPORT_TO`             | empty (disabled)   | RPC-node URLs that receive best-effort `mega_setValidatedBlocks` pushes of the validated tip.                  |

{% hint style="info" %}
When pointing `--validator.rpc-urls` at a rate-limited endpoint, lower `--validator.channel-capacity` to cap concurrent witness fetches — the default of two in-flight fetches per worker is tuned for a dedicated witness provider.
{% endhint %}

### Logging flags

| Flag                   | Env variable                  | Default                        | Description                                                   |
| ---------------------- | ----------------------------- | ------------------------------ | ------------------------------------------------------------- |
| `--log.stdout.filter`  | `MEGARETH_LOG_STDOUT_FILTER`  | unset (`info` via verbosity)   | Console log filter (`tracing` directive syntax, e.g. `info`). |
| `--log.stdout.format`  | `MEGARETH_LOG_STDOUT_FORMAT`  | `terminal`                     | Console format: `terminal`, `log-fmt`, or `json`.             |
| `--log.file.directory` | `MEGARETH_LOG_FILE_DIRECTORY` | OS cache dir (`.../reth/logs`) | Directory for rotated log files; the chain ID is appended.    |
| `--log.file.filter`    | `MEGARETH_LOG_FILE_FILTER`    | `debug`                        | Log filter for file output.                                   |
| `--log.file.max-size`  | `MEGARETH_LOG_FILE_MAX_SIZE`  | `200`                          | Max log file size (MB) before rotation.                       |
| `--log.file.max-files` | `MEGARETH_LOG_FILE_MAX_FILES` | `5`                            | Number of rotated log files to keep.                          |
| `--color`              | `MEGARETH_LOG_COLOR`          | `always`                       | ANSI color: `always`, `auto`, or `never`.                     |

## Validator pipeline

The embedded validator runs off the commit critical path: state sync commits blocks at full speed, and validation follows asynchronously.
A validator failure never tears down the node — RPC and sync keep running.

### Anchor

The anchor is the trusted block validation starts from; blocks are validated from `anchor + 1` onward.
At startup the validator resolves it in this order:

1. `--validator.start-block <BLOCK_HASH>` set — anchor at that block, overriding any persisted anchor and clearing the validated cursor.
   The node waits (bounded by `--validator.start-block-wait-secs`) for the hash to appear locally via state sync.
2. Flag unset, persisted anchor exists — resume from the persisted cursor.
3. Flag unset, fresh database — anchor at the last finalized block, or at the first synced canonical head if nothing is finalized yet.

The resolved anchor is persisted, so the choice survives restarts.
The `validator: anchor resolved` log line reports the outcome: `action=Skip` (anchor unchanged), `SeedFresh` (first anchor), or `OverrideWithRollback` (re-anchored via flag).

{% hint style="warning" %}
`--validator.start-block` takes a block **hash**, not a number, and re-anchoring clears the validated cursor — the range validated under the old anchor is no longer attested.
Once the anchor is persisted, restarts with the same flag are skipped without rewriting it, but remove the flag anyway so a copied unit file or later restart does not silently pin validation to an old block.
{% endhint %}

### Validation modes

Both modes IPA-verify the witness and re-execute the block with the `stateless-validator` library; they differ in how the replay result is bound to the block header:

- **`delta` (default)** — compare the replay-derived SALT changeset against the hash-verified changeset that state sync persisted for the same block, skipping the per-block SALT trie recompute.
  Blocks whose stored changeset is unavailable automatically fall back to `full` behavior (counted by `reth_megaeth_validator_changeset_fallback_full_total`).
- **`full`** — recompute the SALT trie root from the replay output and compare it with the header's state root.
  Slower, but independent of stored changesets.

### Mismatch handling

A deterministic validation failure — a state-root, receipts-root, logs-bloom, or gas mismatch, or a changeset mismatch — halts the validation pipeline.
The node logs `megaeth validator pipeline halted` at error level, sets the `reth_megaeth_validator_halted` gauge to 1, and keeps serving RPC and syncing.
The stalled validated height is the operator alert: it means the sequencer produced a block this node could not reproduce.

On a reorg, the validator restarts from its persisted cursor — it does not search for the divergence point — and re-validates forward on the new canonical chain; `reth_megaeth_validator_reorg_resets_total` counts these events.

## Monitoring

### Checking progress

With `--metrics` set, compare the sync tip against the validated cursor:

```bash
curl -s http://localhost:9001/metrics | grep -v '^#' | grep -E 'state_sync_backend_provider_local_block_height|megaeth_validator_cursor'
```

```text
reth_state_sync_backend_provider_local_block_height 6907400
reth_megaeth_validator_cursor 6907396
```

The difference is the validation lag in blocks.
A small, stable lag is normal; a growing lag means validation cannot keep pace (see [Troubleshooting](#troubleshooting)).

Full nodes also serve `mega_getValidatedChain`, which returns the anchor and the validated tip.
`mega_*` methods are merged into every enabled transport, so the namespace does not need to be listed in `--http.api`:

```bash
curl -sX POST http://localhost:8545 \
  -H 'Content-Type: application/json' \
  -d '{"jsonrpc":"2.0","method":"mega_getValidatedChain","params":[],"id":1}'
```

### Useful metrics

| Metric                                                           | Type      | What it tells you                                                                         |
| ---------------------------------------------------------------- | --------- | ----------------------------------------------------------------------------------------- |
| `reth_state_sync_backend_provider_local_block_height`            | Gauge     | Latest committed block — the sync tip.                                                    |
| `reth_megaeth_validator_cursor`                                  | Gauge     | Highest contiguously validated block.                                                     |
| `reth_megaeth_validator_halted`                                  | Gauge     | `1` when the pipeline halted — on a mismatch or any fatal validator error. Alert on this. |
| `reth_megaeth_validator_validated_blocks_total`                  | Counter   | Blocks re-executed and validated.                                                         |
| `reth_megaeth_validator_failures_validate_total`                 | Counter   | Deterministic validation failures.                                                        |
| `reth_megaeth_validator_changeset_fallback_full_total`           | Counter   | Delta-mode blocks that fell back to the full path. Steady growth is worth investigating.  |
| `reth_megaeth_validator_block_validation_duration_seconds`       | Histogram | End-to-end validation time per block.                                                     |
| `reth_megaeth_validator_validation_witness_verification_seconds` | Histogram | Witness IPA-proof verification time per block.                                            |
| `reth_megaeth_validator_validation_block_replay_seconds`         | Histogram | EVM replay time per block.                                                                |
| `reth_megaeth_validator_reorg_resets_total`                      | Counter   | Validator cursor rollbacks caused by reorgs.                                              |
| `reth_db_table_size{table=...}`                                  | Gauge     | On-disk size per database table — watch for disk planning.                                |

The duration metrics are exposed as Prometheus summaries (quantile series plus `_sum`/`_count`), not bucketed histograms.

### Key log lines

| Line                                       | Level | Meaning                                                                             |
| ------------------------------------------ | ----- | ----------------------------------------------------------------------------------- |
| `Committed block to engine`                | info  | A synced block was committed; the per-block liveness line.                          |
| `validator: anchor resolved`               | info  | Anchor decided at startup (`action` field says how).                                |
| `megaeth validator pipeline started`       | info  | Validator running; fields include `workers` and `mode`.                             |
| `validator: blocks validated and advanced` | info  | Validated cursor advanced (`from`, `to`, `count`).                                  |
| `megaeth validator pipeline halted`        | error | Validation stopped on a fatal error — most commonly a mismatch; node keeps serving. |

## Deployment

Run the node under a service manager in production.
A minimal systemd setup:

```ini
# /etc/megaeth/full-node.env
MEGARETH_NODE_TYPE=full-node
MEGARETH_CHAIN=/etc/megaeth/genesis.json
MEGARETH_DATA_DIR=/var/lib/megaeth/full-node
MEGARETH_SEQUENCER_PUBLIC_KEY=<SEQUENCER_PUBLIC_KEY>
MEGARETH_TRUSTED_PEERS=<ENODE_URL>,<ENODE_URL>
MEGARETH_DISABLE_DISCOVERY=true
MEGARETH_MAX_LOAD=100
MEGARETH_VALIDATOR_RPC_URLS=<WITNESS_RPC_URL>
MEGARETH_METRICS=127.0.0.1:9001
MEGARETH_LOG_FILE_DIRECTORY=/var/log/megaeth
```

```ini
# /etc/systemd/system/megaeth-full-node.service
[Unit]
Description=MegaETH full node
After=network-online.target
Wants=network-online.target

[Service]
User=megaeth
EnvironmentFile=/etc/megaeth/full-node.env
ExecStart=/usr/local/bin/mega-reth node
Restart=on-failure
RestartSec=5
LimitNOFILE=1048576
TimeoutStopSec=120

[Install]
WantedBy=multi-user.target
```

`TimeoutStopSec=120` matters: on shutdown the node flushes its databases, and a clean stop can take tens of seconds (5 s for ordinary tasks and 30 s total for critical tasks by default; `MEGARETH_CRITICAL_WAIT_SECS=N` replaces the critical budget with 5 s + N s).

## Data directory and maintenance

An explicitly passed `--datadir` is used as-is (the OS default adds a `<CHAIN_ID>/` level) and contains:

| Path               | Contents                                                                                       |
| ------------------ | ---------------------------------------------------------------------------------------------- |
| `db/main_db/`      | RocksDB instance holding headers, transactions, receipts, SALT state and trie, and changesets. |
| `db/index_db/`     | RocksDB instance holding history indexes and transaction lookups (full and rpc nodes only).    |
| `known-peers.json` | Persisted peer set, written on shutdown.                                                       |
| `jwt.hex`          | Auto-generated Engine API JWT secret.                                                          |
| `discovery-secret` | P2P identity key.                                                                              |

The data directory layout is tied to the node type — reuse a data directory only with a node type that shares its layout (`full-node` and `rpc-node` do; a `sequencer` data directory does not).

### Graceful shutdown and backups

Stop the node with SIGTERM or SIGINT and wait for the process to exit before touching the data directory.

{% hint style="warning" %}
Never SIGKILL the node or copy the data directory while it runs.
`mega-reth` writes RocksDB with the write-ahead log disabled: memtable contents are lost on a hard kill, and `main_db` and `index_db` flush independently, so a live copy captures the two databases at different heights.
The node repairs an inconsistent directory in place on the next start, but a backup taken from a running or killed node bakes the inconsistency in.
{% endhint %}

To back up: stop the node, copy the data directory, and verify the copy:

```bash
mega-reth tables-height \
  --datadir <DATA_DIR_COPY> \
  --chain <PATH_TO_GENESIS_JSON> \
  --node-type full-node
# Expect: "tables height is consistent true at block height: <N>"
```

### Unwinding to an earlier block

`mega-reth recovery` rewinds the database to a target block after verifying consistency:

```bash
mega-reth recovery \
  --datadir <DATA_DIR> \
  --chain <PATH_TO_GENESIS_JSON> \
  --node-type full-node \
  --target_block_number <BLOCK_NUMBER>
```

{% hint style="warning" %}
`recovery` rewrites the database destructively — back up the data directory first.
Maintenance subcommands (`tables-height`, `recovery`, `db`) do not raise the process file-descriptor limit the way `node` does; raise it yourself (`ulimit -n 1048576`) before running them against a large database.
{% endhint %}

## Trust model

A full node removes the sequencer's execution from its trusted computing base in two layers:

- **Stream integrity** — every header, mini-block, and stream fragment ingested via state sync must carry a valid signature from `--sequencer-public-key`, so a compromised peer cannot inject fabricated data.
- **Execution correctness** — the embedded validator re-executes every block and halts loudly on any mismatch, so the node never silently serves state the sequencer computed incorrectly.

The witness endpoint does not need to be trusted for correctness: witness contents are cryptographically verified, so a faulty endpoint can only stall validation, not produce a false attestation.

Like the standalone stateless validator, a full node validates the block sequence its peers feed it — it does not derive the canonical chain from L1, and it does not check consistency with the rollup batches posted to L1.
On a full node, the `safe` and `finalized` block tags advance only when an external consensus client drives `engine_forkchoiceUpdated`; sequencer-provided finality markers are ignored.

## Troubleshooting

**The node starts but never syncs.**
State sync waits for at least `--min-handshake-peers` trusted peers to complete the handshake.
Check that `--trusted-peers` is set, the enode URLs are current, and the peers are reachable on their P2P ports.

**Startup fails with `--node-type full requires at least one --validator.rpc-urls`.**
Full nodes cannot start without a witness endpoint.
Pass `--validator.rpc-urls` (see [Prerequisites](#prerequisites)).

**`megaeth validator pipeline halted` and `reth_megaeth_validator_halted` is 1.**
The validator hit a deterministic mismatch: this node could not reproduce a block the sequencer committed.
The node keeps syncing and serving RPC, but blocks past the stalled cursor are unattested.
Preserve the logs around the halt and report the block number to the MegaETH team.

**The lag between the sync tip and the validator cursor keeps growing.**
Either witness fetches are stalling (witness endpoint slow, rate-limited, or persistently behind the local tip — consider raising `--validator.tip-buffer`) or validation is CPU-bound (raise `--validator.workers` up to the physical core count).
The `block_validation_duration_seconds`, `validation_witness_verification_seconds`, and `validation_block_replay_seconds` histograms show where the time goes.

**`reth_megaeth_validator_changeset_fallback_full_total` climbs steadily.**
Delta mode cannot find stored changesets for current blocks, so every block takes the slower full path.
Validation results remain correct; expect reduced throughput.
On a database whose recent blocks were synced by a current build, steady growth is unexpected and worth reporting.

**Startup fails with `Bootstrap is required, but the database is not empty`.**
`--bootstrap-policy required` only works on an empty data directory.
Either clear the data directory to bootstrap, or drop the flag to keep the existing database.

## Related pages

- [Stateless Validation](stateless-validation.md) — the standalone validator binary and its trust model
- [Validator Architecture](validator-architecture.md) — how witness-based block validation works
- [Get Block Witness](witness.md) — `mega_getBlockWitness` reference and witness data layout
- [Architecture](../architecture.md) — sequencer, replica nodes, and full nodes in the network
