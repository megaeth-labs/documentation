---
description: Run a MegaETH full node — sync blocks and state from the sequencer stream and re-execute every block with the embedded stateless validator.
---

# Run a full node

A **full node** is a role of `mega-reth`, the MegaETH node client.
Like a replica node, it syncs blocks and state from the sequencer stream and serves the full JSON-RPC surface.
In addition, it runs an embedded, asynchronous stateless validator that re-executes every committed block against a [SALT witness](witness.md) and halts on any state-root, receipts-root, logs-bloom, or gas mismatch produced by the sequencer.
Full nodes do not need to trust the sequencer's execution results.

For how full nodes and replica nodes fit into the network, see [RPC Nodes](../architecture.md#rpc-nodes) in the architecture overview.
For the standalone validator binary that verifies blocks without holding any chain state, see [Stateless Validation](stateless-validation.md).

{% hint style="info" %}
The `mega-reth` repository and its node distributions are currently permissioned — the source and binaries are not generally available.
To run a full node, [contact the MegaETH team](https://megaeth.com) to request access, the network genesis file, and the current peer configuration.
{% endhint %}

## Node types

`mega-reth node` selects its role with `--node-type`.
The roles available to external operators are:

| Value       | Role                                                                                                                    |
| ----------- | ----------------------------------------------------------------------------------------------------------------------- |
| `full-node` | Syncs blocks and state, serves JSON-RPC, and re-validates every block with the embedded stateless validator. This page. |
| `rpc-node`  | Replica node: syncs blocks and state and serves JSON-RPC without re-execution.                                          |
| `sequencer` | The block producer. Default value — a full node must pass `--node-type full-node` explicitly.                           |

`full-node` and `rpc-node` share the same sync path and data directory layout; the only difference is the embedded validator pipeline that produces attestations.
Both types serve `mega_getValidatedChain`, but on an `rpc-node` it only reflects validated tips pushed by an upstream full node via `--validator.report-to` — that node validated nothing itself, and its `anchor` always reads `null`.
An `rpc-node` accepts those pushes only when started with `--rpc.accept-validated-blocks` (env `MEGARETH_RPC_ACCEPT_VALIDATED_BLOCKS`, default `false`).
The flag opens an unauthenticated write path — any client that can reach the RPC port can push validated tips — so enable it only on nodes whose RPC surface is private.
To see where attestation actually starts, query the full node that produced the tips.

## Prerequisites

A full node needs four inputs beyond the binary itself:

1. **Genesis file** — the network's chain-spec JSON, passed via `--chain`.
   `mega-reth` bundles no Mainnet or Testnet chain spec; the file is distributed with node access and must match the network byte-for-byte.
2. **Sequencer public key** — the secp256k1 key the node uses to verify sequencer signatures on every header, mini-block, and stream fragment it ingests, passed via `--sequencer-public-key`.
3. **Trusted peers** — enode URLs of upstream nodes to sync from, passed via `--trusted-peers`.
   MegaETH publishes no bootnodes and block delivery is trusted-peer-only by default, so a node without trusted peers has no upstream and never starts syncing.
4. **Witness endpoint** — one or more RPC URLs serving [`mega_getBlockWitness`](witness.md), passed via `--validator.rpc-urls`.
   The endpoint needs no other JSON-RPC method: the validator reads blocks and bytecode from the node's own database and fetches only witnesses remotely.

Plan for a fast NVMe SSD, sized by how the node syncs — the two paths differ by an order of magnitude.
A node bootstrapped at the tip (see [Initial sync](#initial-sync)) holds only the SALT state at its bootstrap block and everything after: budget at least 500 GB, and size the volume for months of growth rather than for the footprint just after bootstrap.
A node that replays from genesis keeps the chain un-pruned, which on MegaETH Mainnet is roughly 3 TB as of July 2026 (Testnet is roughly 1.6 TB) — provision 4 TB.
Budget for logs separately: they are written outside the data directory and rotate at `--log.file.max-size` × `--log.file.max-files`.
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
  --bootstrap-policy required \
  --max-load 100 \
  --validator.rpc-urls <WITNESS_RPC_URL> \
  --metrics 127.0.0.1:9001 \
  --log.file.directory <LOG_DIR>
```

- `--bootstrap-policy required` starts the node at the current chain tip: it fetches a snapshot of the SALT state from the trusted peers and syncs forward from there.
  The flag defaults to `never`, and a node started without it begins at block 1 and replays the entire chain — see [Initial sync](#initial-sync) for the trade-off.
- `--disable-discovery` is recommended: MegaETH has no public discovery network, and all sync traffic flows through the trusted peers anyway.
- `--max-load` caps how many downstream children this node serves in one streaming tree; it is required and has no default.
- `--validator.rpc-urls` must be quoted when the URL carries query parameters — an unquoted `&` splits the command in the shell and the node starts with a truncated URL.
- `--metrics` binds the Prometheus endpoint; omit it to disable metrics.

{% hint style="warning" %}
`--bootstrap-policy required` needs an empty `--datadir`.
Pointing it at a directory that already holds a chain synced from genesis exits with `Bootstrap is required, but the database is not empty`.
{% endhint %}

To also serve JSON-RPC, add the standard server flags:

```bash
  --http --http.addr 127.0.0.1 --http.port 8545 \
  --http.api eth,net,web3 \
  --ws --ws.addr 127.0.0.1 --ws.port 8546
```

The `mega_*` methods are not part of this selection — they are merged into every enabled transport regardless of `--http.api`, so `mega_getValidatedChain` works with the namespace set above.

{% hint style="warning" %}
Bind to `127.0.0.1` unless the node is deliberately a public RPC endpoint.
Serving `0.0.0.0` with `admin`, `debug`, `trace`, or `txpool` enabled exposes `admin_addPeer` (unauthenticated peer manipulation), `debug_trace*` (unmetered remote CPU and memory), and `txpool_content` (pending-transaction leakage) to anyone who can reach the port.
To serve traffic publicly, keep the node on loopback and put a reverse proxy in front of it that terminates TLS, rate-limits, and forwards only the namespaces you intend to expose.
{% endhint %}

On start, the node:

1. Opens the data directory and runs crash-consistency recovery.
2. Initializes P2P networking and logs its own `enode` URL.
3. Handshakes with the trusted peers and reports what it found (`Loaded local state`), then — on the first run only — fetches the SALT state at the tip and rebuilds the state trie.
4. Starts state sync (`Committed block to engine` lines mark per-block progress).
5. Resolves the validator anchor and starts the validation pipeline.

Healthy startup output includes these lines:

```text
INFO Starting mega-reth version=...
INFO MegaETH P2P networking initialized enode=enode://...
INFO Loaded local state local_block=0 known_block=... bootstrap_status=NotOccurred
INFO Rebuilding trie block_number=...
INFO Rebuilt salt and withdrawal tries salt_elapsed=... withdrawal_elapsed=...
INFO Committed block to engine block_number=... source=Fetcher
INFO validator: anchor resolved number=... action=SeedFresh
INFO megaeth validator pipeline started workers=8 in_flight_multiplier=2 rpc_endpoints=1 mode=delta
INFO validator: blocks validated and advanced from=... to=... count=...
```

`known_block` in the `Loaded local state` line is the tip the trusted peers reported — with `--bootstrap-policy required` that is where the node lands, so `Committed block to engine` should start near it, not at block 1.

### Subsequent runs

All flags shown above are operational, not persisted — re-supply them on every run.

Keep `--bootstrap-policy required` in place.
Once a bootstrap has finished the flag is a no-op on restart, and leaving it set means a data directory that is ever cleared bootstraps again instead of quietly replaying from genesis.
An interrupted bootstrap resumes on the next start on its own, whatever the flag says.

The validator resumes from its persisted cursor automatically; only pass `--validator.start-block` when you deliberately want to re-anchor (see [Validator pipeline](#validator-pipeline)).

## Initial sync

`--bootstrap-policy` selects how an empty data directory reaches the chain tip:

- **`required`** — fetch a snapshot of the current SALT state from the trusted peers instead of replaying history, then sync blocks forward from there.
  The node bootstraps at the tip its peers report at startup, so it is caught up and serving current state without replaying the chain.
  Bootstrap requires an empty data directory, and on a full node it does not complete until the node has also applied the next 256 blocks past that base block.
  A bootstrapped node cannot serve history from before its bootstrap block and cannot unwind below it.
- **`never` (default)** — fetch and apply every historical block from the trusted peers, starting at genesis.
  The node serves full chain history, but initial sync replays the entire chain.

Pass `required` unless the node has to answer queries about blocks and state that predate its own start.
The flag defaults to `never`, so omitting it is what makes a fresh node start at block 1.

Bootstrapped state is verified, not taken on trust: when the fetched buckets are complete the node rebuilds the SALT and withdrawal tries from scratch and compares the recomputed state root against the header's, failing the bootstrap on a mismatch.
The rebuild is CPU-bound and can take a while on a large state.

{% hint style="warning" %}
An interrupted bootstrap can only resume if the node is fewer than 1,800 blocks behind the tip.
Beyond that, the node exits with `The last bootstrap is unfinished and it is too far behind to recover` — clear the data directory and restart the bootstrap.
{% endhint %}

Either way the embedded validator validates forward only, from the anchor it resolves at startup (see [Anchor](#anchor)); blocks before that point are not re-attested.
On a bootstrapped node both candidates sit at or near the bootstrap block, so attestation begins there rather than at genesis.

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

| Flag                       | Env variable                      | Default   | Description                                                                                                            |
| -------------------------- | --------------------------------- | --------- | ---------------------------------------------------------------------------------------------------------------------- |
| `--trusted-peers`          | `MEGARETH_TRUSTED_PEERS`          | empty     | Comma-separated enode URLs of upstream peers. Effectively required — see [Prerequisites](#prerequisites).              |
| `--subscribe-trusted-only` | `MEGARETH_SUBSCRIBE_TRUSTED_ONLY` | `true`    | Subscribe to block streams from trusted peers only. The bare flag only sets `true`; pass `false` via the env variable. |
| `--disable-discovery`      | `MEGARETH_DISABLE_DISCOVERY`      | `false`   | Disable peer discovery. Recommended — MegaETH publishes no bootnodes.                                                  |
| `--port`                   | `MEGARETH_PORT`                   | `30303`   | P2P listen port.                                                                                                       |
| `--addr`                   | `MEGARETH_ADDR`                   | `0.0.0.0` | P2P listen address.                                                                                                    |
| `--min-handshake-peers`    | `MEGARETH_MIN_HANDSHAKE_PEERS`    | `1`       | Peers that must complete the state-sync handshake before syncing starts.                                               |
| `--bootstrap-policy`       | `MEGARETH_BOOTSTRAP_POLICY`       | `never`   | `never` (replay from genesis) or `required` (state bootstrap at the current tip). See [Initial sync](#initial-sync).   |

### Validator flags

Only consulted when `--node-type full-node`; other node types ignore them.

| Flag                                | Env variable                               | Default            | Description                                                                                                                                     |
| ----------------------------------- | ------------------------------------------ | ------------------ | ----------------------------------------------------------------------------------------------------------------------------------------------- |
| `--validator.rpc-urls`              | `MEGARETH_VALIDATOR_RPC_URLS`              | — (required)       | Witness RPC URLs (comma-separated, round-robin failover). Each must serve `mega_getBlockWitness`.                                               |
| `--validator.mode`                  | `MEGARETH_VALIDATOR_MODE`                  | `delta`            | Validation strategy: `delta` or `full`. See [Validation modes](#validation-modes).                                                              |
| `--validator.workers`               | `MEGARETH_VALIDATOR_WORKERS`               | physical cores / 2 | Parallel validation workers (minimum 1). Worker count mainly matters during catch-up.                                                           |
| `--validator.start-block`           | `MEGARETH_VALIDATOR_START_BLOCK`           | unset              | Trusted block hash to anchor at; validation begins at the next block. Overrides the persisted anchor.                                           |
| `--validator.start-block-wait-secs` | `MEGARETH_VALIDATOR_START_BLOCK_WAIT_SECS` | `0` (indefinite)   | How long to wait for the start block to appear locally before the pipeline halts.                                                               |
| `--validator.witness-wait-secs`     | `MEGARETH_VALIDATOR_WITNESS_WAIT_SECS`     | `60`               | Per-block witness-fetch deadline; on expiry the block is re-enqueued.                                                                           |
| `--validator.tip-buffer`            | `MEGARETH_VALIDATOR_TIP_BUFFER`            | `1`                | Blocks of headroom below the local tip before fetching a witness, giving the witness generator time to finish.                                  |
| `--validator.channel-capacity`      | `MEGARETH_VALIDATOR_CHANNEL_CAPACITY`      | workers × 2        | Target total in-flight witness fetches; values below the worker count are clamped up.                                                           |
| `--validator.poll-interval-ms`      | `MEGARETH_VALIDATOR_POLL_INTERVAL_MS`      | `100`              | Tip-refresh interval when the validator is caught up.                                                                                           |
| `--validator.report-to`             | `MEGARETH_VALIDATOR_REPORT_TO`             | empty (disabled)   | RPC-node URLs that receive best-effort `mega_setValidatedBlocks` pushes of the validated tip. Targets must run `--rpc.accept-validated-blocks`. |

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
The `validator: anchor resolved` log line reports the outcome: `action=Skip` (anchor unchanged), `SeedFresh` (first anchor, flag unset), or `OverrideWithRollback` (re-anchored via flag).

{% hint style="warning" %}
`--validator.start-block` takes a block **hash**, not a number, and re-anchoring clears the validated cursor — the range validated under the old anchor is no longer attested.
Once the anchor is persisted, restarts with the same flag are skipped without rewriting it, but remove the flag anyway so a copied unit file or later restart does not silently pin validation to an old block.
{% endhint %}

### Validation modes

Both modes IPA-verify the witness and re-execute the block with the `stateless-validator` library; they differ in how the replay result is bound to the block header:

- **`delta` (default)** — verify the witness against a pre-state anchored to the parent header, then compare the replay-derived SALT changeset against the hash-verified changeset that state sync persisted for the same block, skipping the per-block SALT trie recompute.
- **`full`** — recompute the SALT trie root from the replay output and compare it with the header's state root.
  Slower, but independent of stored changesets and parent anchors.

Delta mode never runs unanchored: a block falls back to `full` behavior for that block alone when either input is missing, and each cause has its own counter.

| Missing input                                                    | Counter                                                |
| ---------------------------------------------------------------- | ------------------------------------------------------ |
| Stored changeset row                                             | `reth_megaeth_validator_changeset_fallback_full_total` |
| Parent-anchor pair (reorg mid-fetch, or a pruned/bootstrap edge) | `reth_megaeth_validator_anchor_fallback_full_total`    |

Both are counted once per validated block, not per fetch attempt.
Validation results are identical either way — only throughput differs.

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

Full nodes also serve `mega_getValidatedChain`, which returns the anchor and the validated tip — available on any enabled transport, whatever `--http.api` selects:

```bash
curl -sX POST http://localhost:8545 \
  -H 'Content-Type: application/json' \
  -d '{"jsonrpc":"2.0","method":"mega_getValidatedChain","params":[],"id":1}'
```

`(anchor, tip]` is the range this node has re-executed and validated itself.
`tip` reads `null` until the first attestation lands after a fresh start or a re-anchor, so treat a null tip on a freshly started node as "not yet", not as a failure.

### Useful metrics

| Metric                                                           | Type    | What it tells you                                                                         |
| ---------------------------------------------------------------- | ------- | ----------------------------------------------------------------------------------------- |
| `reth_state_sync_backend_provider_local_block_height`            | Gauge   | Latest committed block — the sync tip.                                                    |
| `reth_megaeth_validator_cursor`                                  | Gauge   | Highest contiguously validated block.                                                     |
| `reth_megaeth_validator_halted`                                  | Gauge   | `1` when the pipeline halted — on a mismatch or any fatal validator error. Alert on this. |
| `reth_megaeth_validator_validated_blocks_total`                  | Counter | Blocks re-executed and validated.                                                         |
| `reth_megaeth_validator_failures_validate_total`                 | Counter | Deterministic validation failures.                                                        |
| `reth_megaeth_validator_failures_panic_total`                    | Counter | Panics inside the validation closure. Any non-zero value is a bug — report it.            |
| `reth_megaeth_validator_changeset_fallback_full_total`           | Counter | Delta-mode blocks that fell back for a missing changeset row.                             |
| `reth_megaeth_validator_anchor_fallback_full_total`              | Counter | Delta-mode blocks that fell back for a missing parent anchor.                             |
| `reth_megaeth_validator_block_validation_duration_seconds`       | Summary | End-to-end validation time per block.                                                     |
| `reth_megaeth_validator_validation_witness_verification_seconds` | Summary | Witness IPA-proof verification time per block.                                            |
| `reth_megaeth_validator_validation_block_replay_seconds`         | Summary | EVM replay time per block.                                                                |
| `reth_megaeth_validator_validation_salt_update_seconds`          | Summary | SALT stage time — trie recompute in `full`, changeset compare in `delta`.                 |
| `reth_megaeth_validator_canonical_lag_seconds`                   | Summary | Wall time from dispatch to persist, a per-block lag proxy.                                |
| `reth_megaeth_validator_reorg_resets_total`                      | Counter | Validator cursor rollbacks caused by reorgs.                                              |
| `reth_db_table_size{table=<TABLE>}`                              | Gauge   | On-disk size per database table — watch for disk planning.                                |

Two more track the validated-block publisher:

| Metric                                                      | Type    | What it tells you                                                                                                      |
| ----------------------------------------------------------- | ------- | ---------------------------------------------------------------------------------------------------------------------- |
| `reth_megaeth_validator_publisher_active`                   | Gauge   | `1` while the publisher loop is running. Exported on every full node; stays `0` unless `--validator.report-to` is set. |
| `reth_megaeth_validator_publish_failures_total{peer=<URL>}` | Counter | Failed `mega_setValidatedBlocks` pushes per peer. The per-peer series appears after that peer's first failure.         |

A peer that is reachable but refuses a report is not counted as a failure — only transport errors, timeouts, RPC-layer errors, and publish-client panics are.
The `peer` label is the configured URL after `Url` normalization, so `http://rpc-a:8545` appears as `http://rpc-a:8545/` and Prometheus matchers must use the trailing-slash form.

The `_seconds` metrics are recorded as histograms internally but exported as Prometheus **summaries** — pre-computed quantile series plus `_sum` and `_count`, with no `_bucket` series.
Read the quantiles directly (`reth_megaeth_validator_block_validation_duration_seconds{quantile="0.99"}`); `histogram_quantile()` returns nothing for them.

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
MEGARETH_BOOTSTRAP_POLICY=required
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
If you raise `MEGARETH_CRITICAL_WAIT_SECS`, raise `TimeoutStopSec` to stay above 5 s + N s — when the stop timeout expires first, systemd escalates to SIGKILL, the hard kill the backup rules below warn against.

`MEGARETH_BOOTSTRAP_POLICY=required` belongs in the env file permanently.
It applies only to an empty data directory and is ignored once the bootstrap has finished, so it costs nothing on restart and keeps a future re-sync from replaying the chain from genesis.
Adding it to a data directory that was already synced from genesis is the one case that fails — see [Troubleshooting](#troubleshooting).

## Data directory and maintenance

An explicitly passed `--datadir` is used as-is (the OS default adds a `<CHAIN_ID>/` level) and contains, among other entries:

| Path               | Contents                                                                                                                      |
| ------------------ | ----------------------------------------------------------------------------------------------------------------------------- |
| `db/main_db/`      | RocksDB instance holding headers, transactions, receipts, transaction-hash lookups, and the SALT state, trie, and changesets. |
| `db/index_db/`     | RocksDB instance holding history indexes and account/storage changesets (created for `full-node` and `rpc-node`).             |
| `known-peers.json` | Persisted peer set, written on shutdown.                                                                                      |
| `jwt.hex`          | Auto-generated Engine API JWT secret.                                                                                         |
| `discovery-secret` | P2P identity key.                                                                                                             |

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

Maintenance subcommands (`tables-height`, `db`) do not raise the process file-descriptor limit the way `node` does — raise it yourself (`ulimit -n 1048576`) before running them against a large database.

## Trust model

A full node removes the sequencer's execution from its trusted computing base in two layers:

- **Stream integrity** — every header, mini-block, and stream fragment ingested via state sync must carry a valid signature from `--sequencer-public-key`, so a compromised peer cannot inject fabricated data.
- **Execution correctness** — the embedded validator re-executes every block and halts loudly on any mismatch, so the node never silently serves state the sequencer computed incorrectly.

The witness endpoint does not need to be trusted for correctness: witness contents are cryptographically verified, so a faulty endpoint can only stall validation, not produce a false attestation.

Like the standalone stateless validator, a full node validates the block sequence its peers feed it — it does not derive the canonical chain from L1, and it does not check consistency with the rollup batches posted to L1.
Once syncing, a full node ignores the sequencer's `safe` and `finalized` markers in block metadata: those tags advance only when an external consensus client drives `engine_forkchoiceUpdated`.
The exception is bootstrap — blocks applied by the bootstrapper persist the sequencer's markers, so a node that has bootstrapped starts its next run with `safe` and `finalized` seeded from the sequencer's view rather than from a consensus client.

## Troubleshooting

**The node starts but never syncs.**
State sync waits for at least `--min-handshake-peers` trusted peers to complete the handshake.
Check that `--trusted-peers` is set, the enode URLs are current, and the peers are reachable on their P2P ports.

**Startup fails with `--node-type full requires at least one --validator.rpc-urls`.**
Full nodes cannot start without a witness endpoint.
Pass `--validator.rpc-urls` (see [Prerequisites](#prerequisites)).
The `--node-type full` in that message is a stale spelling in the error text itself — the value the flag accepts is `full-node`.

**`megaeth validator pipeline halted` and `reth_megaeth_validator_halted` is 1.**
The validator hit a deterministic mismatch: this node could not reproduce a block the sequencer committed.
The node keeps syncing and serving RPC, but blocks past the stalled cursor are unattested.
Preserve the logs around the halt and report the block number to the MegaETH team.

**The lag between the sync tip and the validator cursor keeps growing.**
Either witness fetches are stalling (witness endpoint slow, rate-limited, or persistently behind the local tip — consider raising `--validator.tip-buffer`) or validation is CPU-bound (raise `--validator.workers` up to the physical core count).
The `validation_witness_verification_seconds`, `validation_block_replay_seconds`, and `validation_salt_update_seconds` quantiles break the per-block cost into fetch-verify, replay, and SALT stages; `block_validation_duration_seconds` is the total.

**A fallback counter climbs steadily.**
Delta mode is degrading to the slower full path on most blocks.
Validation results remain correct; expect reduced throughput.
Which counter is moving says why:

- `reth_megaeth_validator_changeset_fallback_full_total` — the stored changeset row is missing.
  On a database whose recent blocks were synced by a current build this is unexpected and worth reporting.
- `reth_megaeth_validator_anchor_fallback_full_total` — the parent-anchor pair is missing.
  A burst around a reorg is normal; sustained growth points at a pruned or bootstrap-edge datadir.

Switching to `--validator.mode full` removes the fallback churn but not the underlying cost.

**Startup fails with `Bootstrap is required, but the database is not empty`.**
`--bootstrap-policy required` only works on an empty data directory.
Either clear the data directory to bootstrap, or drop the flag to keep the existing database.

## Related pages

- [Stateless Validation](stateless-validation.md) — the standalone validator binary and its trust model
- [Validator Architecture](validator-architecture.md) — how witness-based block validation works
- [Get Block Witness](witness.md) — `mega_getBlockWitness` reference and witness data layout
- [Architecture](../architecture.md) — sequencer, replica nodes, and full nodes in the network
