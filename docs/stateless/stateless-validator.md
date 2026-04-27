---
description: Run a stateless validator to independently verify every MegaETH block on commodity hardware using SALT witnesses.
---

# Stateless Validation

The **stateless validator** is a Rust client that independently verifies every MegaETH block without maintaining full chain state.
Instead of replaying blocks against a locally-stored state trie, it re-executes each block against a compact cryptographic witness supplied by the network, then checks that the resulting post-state matches the commitments in the block header.

This design enables independent verification of sequencer execution on commodity hardware — a laptop-class machine can verify MegaETH Mainnet in real time.
For how validators fit into the broader network, see [Architecture](../architecture.md).

## Why run a stateless validator

- **Independent verification** — you re-execute the state transition function (STF) of every block yourself, rather than trusting an RPC provider to tell you the truth.
- **Low hardware cost** — thanks to [SALT (Small Authentication Large Trie)](https://github.com/megaeth-labs/salt) witnesses, proof data per block is significantly smaller than Merkle Patricia Trie witnesses, so validators do not need sequencer-class hardware.
- **Parallel-friendly** — validation workers are embarrassingly parallel; throughput scales linearly with CPU cores.
- **Auditable trusted computing base (TCB)** — the validator is built on the upstream Rust EVM interpreter [revm](https://github.com/bluealloy/revm) with an in-memory backend, keeping the TCB small and reviewable.

## Installation

The validator is distributed as source only — there are no prebuilt binaries today.
Install the Rust toolchain and build the release binary:

```bash
# Install rustup (if you don't already have it)
curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh

# Clone and build
git clone https://github.com/megaeth-labs/stateless-validator.git
cd stateless-validator
cargo build --release --bin stateless-validator
```

The project pins a specific nightly Rust toolchain via `rust-toolchain.toml`, so `cargo build` downloads it automatically on first run.

The compiled binary lives at `./target/release/stateless-validator`.
Copy it onto your `PATH` if you plan to invoke it directly.

## Quick start

### First run

On the first launch, the validator needs two pieces of bootstrap information:

1. **`--genesis-file`** — the MegaETH genesis JSON, which encodes the chain ID and hardfork activation schedule.
   Use [`test_data/mainnet/genesis.json`](https://github.com/megaeth-labs/stateless-validator/blob/main/test_data/mainnet/genesis.json) from the stateless-validator repo.
   The `alloc` list is stripped from this file — the validator never reads initial balances, so only the chain config is needed.
2. **`--start-block`** — a **trusted block hash** that anchors your local chain.
   The validator fetches this block's header and stores its `block_number`, `block_hash`, `state_root`, and `withdrawals_root` as the anchor.
   The anchor itself is **not** re-executed; its values are taken on faith.
   Verification starts from the **next** block, which must satisfy both invariants below or the pipeline halts:
   - `parent_hash` equals the anchor's `block_hash`.
   - witness `pre_state_root` / `pre_withdrawals_root` match the anchor's `state_root` / `withdrawals_root`.

   The simplest way to get a usable anchor is to fetch the latest **finalized** header from the same RPC you'll point the validator at, then cross-check the returned hash against an independent source (a block explorer, a second RPC provider):

   ```bash
   curl -sX POST https://mainnet.megaeth.com/rpc \
     -H 'Content-Type: application/json' \
     -d '{"jsonrpc":"2.0","method":"eth_getHeaderByNumber","params":["finalized"],"id":1}' \
     | jq -r '.result.hash'
   # Output: a 0x-prefixed 64-hex-char string.
   ```

   Pass that hash to `--start-block`.
   An older anchor is also valid, but the validator must then re-check every block between the anchor and the tip before going live.

   {% hint style="warning" %}
   `--start-block` takes a block **hash** (`0x` + 64 hex chars), not a block number. Always verify the hash against at least one independent source before passing it — the anchor is the single point of trust the rest of the chain hangs from.
   {% endhint %}

Replace `<ANCHOR_HASH_FROM_CURL_ABOVE>` below with the hash returned by the `curl` command above, then launch from the cloned `stateless-validator` directory (so `./target/release/...` and `./test_data/...` resolve):

```bash
./target/release/stateless-validator \
  --data-dir ./validator-data \
  --rpc-endpoint https://mainnet.megaeth.com/rpc \
  --witness-endpoint https://mainnet.megaeth.com/rpc \
  --genesis-file ./test_data/mainnet/genesis.json \
  --start-block <ANCHOR_HASH_FROM_CURL_ABOVE> \
  --log.file-directory ./validator-data \
  --data-max-concurrent-requests 4 \
  --witness-max-concurrent-requests 4
```

{% hint style="info" %}
`--data-max-concurrent-requests` and `--witness-max-concurrent-requests` are independent semaphores guarding the data path (`eth_get*`) and the witness path (`mega_getBlockWitness`) respectively — keeping them separate prevents a burst on one path from starving the other.
The values shown (`4` / `4`) are tuned for the public mainnet RPC at `mainnet.megaeth.com/rpc`: unbounded concurrency may trigger HTTP 429 rate-limiting and stall the validator's forward progress.
{% endhint %}

On start, the validator:

1. Persists the genesis config to its database.
2. Fetches the header for `--start-block` and installs it as the trusted anchor.
3. Begins the fetch → process → advance pipeline, verifying every new block.

`--log.file-directory` writes a rotated `stateless-validator.log` into the directory you pass it (`./validator-data` in the example above).
Tail it from another terminal to watch the pipeline make progress:

```bash
tail -f ./validator-data/stateless-validator.log
```

Healthy output looks like this — `Replay block`, `Successfully validated block`, and `Chain advanced` lines marching forward:

```text
DEBUG stateless_core::executor: Replay block: block_number=14471126, block_hash=0xfda1cc..., hardfork=Some(Rex4)
DEBUG stateless_validator::chain_sync: Successfully validated block block_number=14471126
DEBUG stateless_core::pipeline::advancer: Chain advanced tip=14471126 advanced=1 buffered=0
```

File logs are at `debug` level by default; console output stays at `info`.
See [Logging flags](#logging-flags) to tune levels, formats, and rotation.

### Subsequent runs

Once the database is initialized, omit `--genesis-file` and `--start-block` — the validator resumes from the last validated block.
All other operational flags (logging, concurrency caps) are **not** persisted to the database, so re-supply them on every run:

```bash
./target/release/stateless-validator \
  --data-dir ./validator-data \
  --rpc-endpoint https://mainnet.megaeth.com/rpc \
  --witness-endpoint https://mainnet.megaeth.com/rpc \
  --log.file-directory ./validator-data \
  --data-max-concurrent-requests 4 \
  --witness-max-concurrent-requests 4
```

### Multiple RPC endpoints

Both `--rpc-endpoint` and `--witness-endpoint` accept multiple endpoints as repeated flags or a comma-separated list.
Both share the same retry primitive: each "round" attempts every provider once in order (no inter-provider sleep), and only when an entire round has failed does the client sleep for **round-level** exponential backoff (initial → 2× → 4× …, capped at `--rpc-max-backoff-ms`, with up to 50% jitter) before starting the next round.
There is no global retry cap — rounds repeat indefinitely until a request succeeds.
The two paths only differ in which provider each round starts at:

- **`--rpc-endpoint` (data: blocks / headers / code / tx)** — round-robin load balancing.
  The starting provider rotates per call via an atomic counter, so healthy endpoints share traffic evenly; within a round the order is fixed (`start → start+1 → …`).
- **`--witness-endpoint`** — primary-failover.
  Every round starts from provider 0, so the first endpoint takes all traffic while healthy and later endpoints only see traffic when the primary is failing.
  This keeps the primary cache-hot.

The two paths have independent concurrency caps (`--data-max-concurrent-requests`, `--witness-max-concurrent-requests`) so a burst on one cannot starve the other.

```bash
# Repeated flags
--rpc-endpoint https://a.example/rpc --rpc-endpoint https://b.example/rpc

# Comma-separated (the env var also accepts this form)
--rpc-endpoint https://a.example/rpc,https://b.example/rpc
```

## Command-line options

Every flag has an equivalent environment variable, convenient for service managers and containerized deployments.
Command-line flags take precedence over environment variables.
Boolean flags (e.g., `--metrics-enabled`) accept `true` or `false` via their env var — set `STATELESS_VALIDATOR_METRICS_ENABLED=true` to turn the endpoint on without command-line arguments.

### Core flags

| Flag                           | Env variable                                     | Required? | Description                                                                                                                             |
| ------------------------------ | ------------------------------------------------ | --------- | --------------------------------------------------------------------------------------------------------------------------------------- |
| `--data-dir`                   | `STATELESS_VALIDATOR_DATA_DIR`                   | Yes       | Directory holding the validator database and any cached data.                                                                           |
| `--rpc-endpoint`               | `STATELESS_VALIDATOR_RPC_ENDPOINT`               | Yes       | JSON-RPC endpoint(s) for block headers and bodies. Repeat the flag or pass a comma-separated list.                                      |
| `--witness-endpoint`           | `STATELESS_VALIDATOR_WITNESS_ENDPOINT`           | Yes       | MegaETH JSON-RPC endpoint(s) for SALT witnesses (`mega_getBlockWitness`). Multiple endpoints accepted.                                  |
| `--genesis-file`               | `STATELESS_VALIDATOR_GENESIS_FILE`               | First run | Path to the genesis JSON. Stored in the database after the first run.                                                                   |
| `--start-block`                | `STATELESS_VALIDATOR_START_BLOCK`                | First run | Trusted block hash used as the validation anchor.                                                                                       |
| `--report-validation-endpoint` | `STATELESS_VALIDATOR_REPORT_VALIDATION_ENDPOINT` | No        | RPC endpoint that receives `mega_setValidatedBlocks` callbacks for validated blocks. If not provided, validation reporting is disabled. |
| `--metrics-enabled`            | `STATELESS_VALIDATOR_METRICS_ENABLED`            | No        | Expose a Prometheus `/metrics` endpoint. Default: `false` (endpoint not bound).                                                         |
| `--metrics-port`               | `STATELESS_VALIDATOR_METRICS_PORT`               | No        | Port for the metrics endpoint. Default: `9090`.                                                                                         |

### Advanced tuning

These flags override pipeline and RPC retry defaults — most operators can leave them unset.

| Flag                                | Env variable                                          | Default   | Description                                                                                                                                   |
| ----------------------------------- | ----------------------------------------------------- | --------- | --------------------------------------------------------------------------------------------------------------------------------------------- |
| `--data-max-concurrent-requests`    | `STATELESS_VALIDATOR_DATA_MAX_CONCURRENT_REQUESTS`    | unlimited | Cap on concurrent in-flight data requests (blocks, headers, code, tx). Omit for unlimited.                                                    |
| `--witness-max-concurrent-requests` | `STATELESS_VALIDATOR_WITNESS_MAX_CONCURRENT_REQUESTS` | unlimited | Cap on concurrent in-flight witness fetches, independent of the data cap. Omit for unlimited.                                                 |
| `--poll-interval-ms`                | `STATELESS_VALIDATOR_POLL_INTERVAL_MS`                | `100`     | Fetcher caught-up poll interval (ms). Also rate-limits `eth_blockNumber`. Lower values reduce tip-following lag.                              |
| `--error-restart-delay-ms`          | `STATELESS_VALIDATOR_ERROR_RESTART_DELAY_MS`          | `1000`    | Pipeline restart delay (ms) after a transient cycle error.                                                                                    |
| `--rpc-initial-backoff-ms`          | `STATELESS_VALIDATOR_RPC_INITIAL_BACKOFF_MS`          | `500`     | Initial round-level RPC retry backoff (ms). Applied after every provider in a round has failed; doubles each round.                           |
| `--rpc-max-backoff-ms`              | `STATELESS_VALIDATOR_RPC_MAX_BACKOFF_MS`              | `30000`   | Cap on round-level RPC retry backoff (ms).                                                                                                    |
| `--canonical-chain-max-length`      | `STATELESS_VALIDATOR_CANONICAL_CHAIN_MAX_LENGTH`      | `1000`    | Soft cap on canonical-chain rows retained locally. Larger values widen the reorg-lookup window; smaller values reduce db growth. Must be ≥ 1. |

### Logging flags

Logging is configured via `--log.*` flags, mirrored by `STATELESS_LOG_*` environment variables.

| Flag                   | Env variable                   | Default                   | Description                                                        |
| ---------------------- | ------------------------------ | ------------------------- | ------------------------------------------------------------------ |
| `--log.stdout-filter`  | `STATELESS_LOG_STDOUT`         | `info`                    | Console log level (`trace` / `debug` / `info` / `warn` / `error`). |
| `--log.stdout-format`  | `STATELESS_LOG_STDOUT_FORMAT`  | `terminal`                | Console format: `terminal` or `json`.                              |
| `--log.color`          | `STATELESS_LOG_COLOR`          | `auto`                    | ANSI color: `auto`, `always`, or `never`.                          |
| `--log.file-directory` | `STATELESS_LOG_FILE_DIRECTORY` | (unset)                   | Directory for rotated log files. File logging is off when unset.   |
| `--log.file-name`      | `STATELESS_LOG_FILE_NAME`      | `stateless-validator.log` | Base name of the active log file.                                  |
| `--log.file-filter`    | `STATELESS_LOG_FILE`           | `debug`                   | Log level for file output.                                         |
| `--log.file-format`    | `STATELESS_LOG_FILE_FORMAT`    | `terminal`                | File format: `terminal` or `json`.                                 |
| `--log.file-max-size`  | `STATELESS_LOG_FILE_MAX_SIZE`  | `200`                     | Max log file size (MB) before rotation.                            |
| `--log.file-max-files` | `STATELESS_LOG_FILE_MAX_FILES` | `5`                       | Number of rotated log files to keep.                               |

## Monitoring

### Checking validation progress

With metrics enabled, the validator binds a Prometheus endpoint on `0.0.0.0:9090` (reachable as `http://<host>:9090/metrics`, or `http://localhost:9090/metrics` from the same machine).
Three gauges tell you whether the validator is keeping up:

```bash
curl -s http://localhost:9090/metrics | grep -v '^#' | grep -E 'chain_height|validation_lag'
```

```text
stateless_validator_remote_chain_height 14479507
stateless_validator_local_chain_height  14479502
stateless_validator_validation_lag      5
```

`validation_lag` is the number of blocks the validator is behind the remote tip (`remote_chain_height − local_chain_height`).
Interpret it in two phases:

- **During initial catch-up** (only if you anchored at an older block), `validation_lag` starts large and shrinks as the validator replays history to reach the tip.
  A large lag here is expected, not a symptom.
- **Once caught up**, the gauge sits around `3–5` and briefly spikes during bursty periods.
  This floor is intentional: the validator currently buffers 3 blocks below the remote tip, refusing to fetch any block within that window so the upstream witness generator has headroom to finish.
  Factor in the 100 ms poll cadence and one RPC round-trip, and a steady-state lag of a few blocks is expected — not a symptom.
  Persistent lag much above that range means the validator can't keep pace with the sequencer — investigate per the [Troubleshooting](#troubleshooting) section.

The [`scripts/validator-status.sh`](https://github.com/megaeth-labs/stateless-validator/blob/main/scripts/validator-status.sh) helper in the repo renders these metrics as a formatted dashboard.

### Useful metrics

| Metric                                                     | Type      | What it tells you                                                  |
| ---------------------------------------------------------- | --------- | ------------------------------------------------------------------ |
| `stateless_validator_local_chain_height`                   | Gauge     | Local chain tip.                                                   |
| `stateless_validator_remote_chain_height`                  | Gauge     | Remote chain tip reported by the RPC endpoint.                     |
| `stateless_validator_validation_lag`                       | Gauge     | Blocks behind the remote tip (steady-state floor ≈ 3–5).           |
| `stateless_validator_block_validation_time_seconds`        | Histogram | End-to-end time to validate a block.                               |
| `stateless_validator_witness_verification_time_seconds`    | Histogram | Time spent verifying SALT witnesses.                               |
| `stateless_validator_block_replay_time_seconds`            | Histogram | EVM execution time per block.                                      |
| `stateless_validator_salt_update_time_seconds`             | Histogram | Time to apply post-state deltas to the SALT trie.                  |
| `stateless_validator_block_state_reads`                    | Histogram | KV reads per block (diagnoses I/O-bound slowdown).                 |
| `stateless_validator_block_state_writes`                   | Histogram | KV writes per block.                                               |
| `stateless_validator_transactions_total`                   | Counter   | Total transactions validated.                                      |
| `stateless_validator_gas_used_total`                       | Counter   | Total gas used in validated blocks.                                |
| `stateless_validator_reorgs_detected_total`                | Counter   | Number of reorgs handled.                                          |
| `stateless_validator_reorg_depth`                          | Histogram | Depth of chain reorganizations.                                    |
| `stateless_validator_rpc_requests_total{method=...}`       | Counter   | RPC requests made (one per logical call), labelled by method.      |
| `stateless_validator_rpc_errors_total{method=...}`         | Counter   | RPC final failures (not retried attempts), labelled by method.     |
| `stateless_validator_rpc_retry_attempts_total{method=...}` | Counter   | Transient retry attempts before final outcome, labelled by method. |
| `stateless_validator_block_fetch_time_seconds`             | Histogram | Per-call `eth_getBlockByNumber` / `eth_getBlockByHash` latency.    |
| `stateless_validator_code_fetch_time_seconds`              | Histogram | Per-call `eth_getCodeByHash` latency.                              |
| `stateless_validator_witness_fetch_rpc_time_seconds`       | Histogram | Per-call `mega_getBlockWitness` latency.                           |
| `stateless_validator_contract_cache_hits_total`            | Counter   | Bytecode served from the local cache.                              |
| `stateless_validator_contract_cache_misses_total`          | Counter   | Bytecode fetched from RPC on miss.                                 |
| `stateless_validator_salt_witness_size_bytes`              | Histogram | Serialized SALT witness size per block.                            |
| `stateless_validator_salt_witness_keys`                    | Histogram | Key count in each SALT witness.                                    |
| `stateless_validator_salt_witness_kvs_size_bytes`          | Histogram | KV payload size inside each SALT witness.                          |
| `stateless_validator_mpt_witness_size_bytes`               | Histogram | Serialized MPT withdrawals-witness size per block.                 |
| `stateless_validator_worker_tasks_completed_total`         | Counter   | Tasks completed per worker (label: `worker_id`).                   |
| `stateless_validator_worker_tasks_failed_total`            | Counter   | Tasks failed per worker (label: `worker_id`).                      |

For the complete list, see [`metrics.rs`](https://github.com/megaeth-labs/stateless-validator/blob/main/bin/stateless-validator/src/metrics.rs) in the upstream repo.

### Logs

When `--log.file-directory` is set, the validator writes rotated log files to that directory.
Rotation is size-based (`--log.file-max-size`, default 200 MB), keeping `--log.file-max-files` rotated files (default 5).
Console output honors `--log.stdout-filter`.

```bash
tail -f "$STATELESS_LOG_FILE_DIRECTORY/stateless-validator.log"
```

## Trust model

The stateless validator is an **execution client**: it verifies that every block's state transition was applied correctly and that commitments in the block header match the resulting post-state.
It does **not** decide which chain is canonical — it validates whatever sequence of blocks you feed it.

If you trust the data endpoint (`--rpc-endpoint`) to serve the canonical block sequence the sequencer produced, the validator detects any block whose post-state does not match the header commitments — including any execution mistake by the sequencer.
The witness endpoint (`--witness-endpoint`) does not need to be trusted for correctness: witness contents are cryptographically verified against the previous block's state root, so a faulty or malicious witness endpoint can only stall progress, not produce a false validation.

{% hint style="warning" %}
The stateless validator currently does **not** check that the blocks it validates are consistent with the L2 rollup batch posted to L1.
A sequencer that posts a different sequence of blocks to L1 than it serves over RPC would not be detected by the validator alone.
End-to-end batch-consistency checking is work in progress.
{% endhint %}

For a fully trust-minimized setup, pair the stateless validator with:

- **`op-node`** to derive the canonical L2 chain from L1 and the data availability layer.
- **A MegaETH replica node** that follows the derived chain and serves blocks locally.

In that configuration, you rely only on L1's security and your own software — no external RPC is in the trusted path.

{% hint style="info" %}
The MegaETH replica node is currently permissioned — the binary is not generally available.
If you want to run a replica alongside the stateless validator, [contact the MegaETH team](https://megaeth.com) to request access.
{% endhint %}

## Troubleshooting

**The validator can't find the start block.**
You will see warnings like `WARN ...: failed to fetch start block ...` repeating in the log.
Check that `--rpc-endpoint` is reachable and that the block hash in `--start-block` exists on that endpoint.
The validator retries fetch failures automatically, so the warnings clear once the RPC starts responding.

**`validation_lag` keeps growing.**
Either the remote RPC is throttling witness fetches (look for `mega_getBlockWitness` errors in `stateless_validator_rpc_errors_total`) or the machine is under-provisioned.
Compare `stateless_validator_block_validation_time_seconds` p99 against the chain's block period — if validation time exceeds the period, the validator cannot keep pace at all and you need either faster hardware or fewer worker tasks.
Histograms like `block_validation_time_seconds`, `witness_verification_time_seconds`, and `block_replay_time_seconds` break down where time is being spent.

## Related pages

- [Architecture](../architecture.md) — how transactions flow through MegaETH and where validators fit in
- [stateless-validator source](https://github.com/megaeth-labs/stateless-validator) — Rust client source code
- [SALT](https://github.com/megaeth-labs/salt) — MegaETH's state trie and witness format
