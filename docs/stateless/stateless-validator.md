---
description: Run a stateless validator to independently verify every MegaETH block on commodity hardware using SALT witnesses.
---

# Stateless validator

The **stateless validator** is a Rust client that independently verifies every MegaETH block without maintaining full chain state.
Instead of replaying blocks against a locally-stored state trie, it re-executes each block against a compact cryptographic witness supplied by the network, then checks that the resulting post-state matches the commitments in the block header.

This design lets you keep the sequencer honest on commodity hardware — a laptop-class machine can verify MegaETH Mainnet in real time.
For how validators fit into the broader network, see [Architecture](../architecture.md).

## Why run a stateless validator

- **Independent verification** — you re-execute the state transition function (STF) of every block yourself, rather than trusting an RPC provider to tell you the truth.
- **Low hardware cost** — thanks to [SALT (Small Authentication Large Trie)](https://github.com/megaeth-labs/salt) witnesses, per-block proof data is compact (tens of KB) — small enough to validate on a commodity server.
- **Parallel-friendly** — validation workers are embarrassingly parallel; throughput scales with CPU cores.
- **Auditable TCB** — the validator is built on a vanilla Revm interpreter with an in-memory backend, keeping the trusted computing base small and reviewable.

## System requirements

| Resource | Minimum         | Recommended           |
| -------- | --------------- | --------------------- |
| CPU      | 4 cores         | 16+ cores             |
| RAM      | 8 GB            | 16 GB                 |
| Disk     | 20 GB SSD       | 100 GB SSD            |
| Network  | 50 Mbps, stable | 100+ Mbps, low jitter |
| OS       | Linux / macOS   | Linux (Ubuntu 22.04+) |

Witness data is small but arrives continuously, so network stability matters more than raw bandwidth.
Disk usage is dominated by the canonical chain index and the contract bytecode cache.

## Installation

The validator is distributed as source.
Install the Rust toolchain and build the release binary:

```bash
# Install rustup (if you don't already have it)
curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh

# Clone and build
git clone https://github.com/megaeth-labs/stateless-validator.git
cd stateless-validator
cargo build --release --bin stateless-validator
```

The compiled binary lives at `./target/release/stateless-validator`.
Copy it onto your `PATH` if you plan to invoke it directly.

The project pins a specific nightly Rust toolchain via `rust-toolchain.toml`, so `cargo build` downloads it automatically on first run.

## Quick start

### First run

On the first launch, the validator needs two pieces of bootstrap information:

1. **`--genesis-file`** — the MegaETH genesis JSON, which encodes the chain ID and hardfork activation schedule.
   Obtain it from the [MegaETH repository](https://github.com/megaeth-labs) or the docs release page.
2. **`--start-block`** — a **trusted block hash** that anchors your local chain.
   Pick any recent block hash you trust (e.g. copied from a known explorer or from another operator already running the validator).
   The validator begins verification from this anchor and walks forward.

```bash
stateless-validator \
  --data-dir ./validator-data \
  --rpc-endpoint https://mainnet.megaeth.com/rpc \
  --witness-endpoint https://mainnet.megaeth.com/rpc \
  --genesis-file ./genesis.json \
  --start-block 0x1234567890abcdef... \
  --metrics-enabled
```

On start, the validator:

1. Persists the genesis config to its database.
2. Fetches the header for `--start-block` and installs it as the trusted anchor.
3. Begins the fetch → process → advance pipeline, verifying every new block.

### Subsequent runs

Once the database is initialized, omit `--genesis-file` and `--start-block` — the validator resumes from the last validated block:

```bash
stateless-validator \
  --data-dir ./validator-data \
  --rpc-endpoint https://mainnet.megaeth.com/rpc \
  --witness-endpoint https://mainnet.megaeth.com/rpc \
  --metrics-enabled
```

If the remote chain has reorged past your local tip, the validator detects the divergence, rolls back to the common ancestor, and continues from there.

### Multiple RPC endpoints

Both `--rpc-endpoint` and `--witness-endpoint` accept multiple endpoints as repeated flags or a comma-separated list — the validator tries them in order on failure, with retry-and-backoff per provider.

```bash
# Repeated flags
--rpc-endpoint https://a.example/rpc --rpc-endpoint https://b.example/rpc

# Comma-separated (also accepted by the env var)
--rpc-endpoint https://a.example/rpc,https://b.example/rpc
```

## Command-line options

Every flag has an equivalent environment variable, convenient for systemd units and Docker.
Command-line flags take precedence over environment variables.

### Core flags

| Flag                               | Env variable                                        | Required? | Description                                                                                            |
| ---------------------------------- | --------------------------------------------------- | --------- | ------------------------------------------------------------------------------------------------------ |
| `--data-dir`                       | `STATELESS_VALIDATOR_DATA_DIR`                      | Yes       | Directory holding the validator database and any cached data.                                          |
| `--rpc-endpoint`                   | `STATELESS_VALIDATOR_RPC_ENDPOINT`                  | Yes       | JSON-RPC endpoint(s) for block headers and bodies. Repeat the flag or pass a comma-separated list.     |
| `--witness-endpoint`               | `STATELESS_VALIDATOR_WITNESS_ENDPOINT`              | Yes       | MegaETH JSON-RPC endpoint(s) for SALT witnesses (`mega_getBlockWitness`). Multiple endpoints accepted. |
| `--genesis-file`                   | `STATELESS_VALIDATOR_GENESIS_FILE`                  | First run | Path to the genesis JSON. Stored in the database after the first run.                                  |
| `--start-block`                    | `STATELESS_VALIDATOR_START_BLOCK`                   | First run | Trusted block hash used as the validation anchor.                                                      |
| `--report-validation-endpoint`     | `STATELESS_VALIDATOR_REPORT_VALIDATION_ENDPOINT`    | No        | RPC endpoint that receives `mega_setValidatedBlocks` callbacks for validated blocks.                   |
| `--metrics-enabled`                | `STATELESS_VALIDATOR_METRICS_ENABLED`               | No        | Expose a Prometheus `/metrics` endpoint.                                                               |
| `--metrics-port`                   | `STATELESS_VALIDATOR_METRICS_PORT`                  | No        | Port for the metrics endpoint. Default: `9090`.                                                        |
| `--data-max-concurrent-requests`   | `STATELESS_VALIDATOR_DATA_MAX_CONCURRENT_REQUESTS`  | No        | Cap on concurrent in-flight data requests (blocks, headers, code, tx). Omit for unlimited.             |
| `--witness-max-concurrent-requests` | `STATELESS_VALIDATOR_WITNESS_MAX_CONCURRENT_REQUESTS` | No      | Cap on concurrent in-flight witness fetches, independent of the data cap. Omit for unlimited.          |

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

{% hint style="info" %}
Legacy `STATELESS_VALIDATOR_LOG_*` env vars are migrated to `STATELESS_LOG_*` automatically at startup for backwards compatibility.
{% endhint %}

## Running in the background

For long-lived deployments, run the validator under a supervisor (systemd, Docker, or a PID-file script).
The snippet below is a minimal `start_validator.sh` you can drop next to the binary:

```bash
#!/bin/bash
# start_validator.sh — launch stateless-validator in the background
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
BINARY="$SCRIPT_DIR/stateless-validator"
PID_FILE="$SCRIPT_DIR/stateless-validator.pid"

DATA_DIR="${DATA_DIR:-$HOME/megaeth/validator}"
RPC_ENDPOINT="${RPC_ENDPOINT:-https://mainnet.megaeth.com/rpc}"
WITNESS_ENDPOINT="${WITNESS_ENDPOINT:-https://mainnet.megaeth.com/rpc}"
GENESIS_FILE="${GENESIS_FILE:-$DATA_DIR/genesis.json}"
LOG_DIR="${LOG_DIR:-$DATA_DIR/logs}"

if [ -f "$PID_FILE" ] && kill -0 "$(cat "$PID_FILE")" 2>/dev/null; then
    echo "validator already running (pid $(cat "$PID_FILE"))"
    exit 1
fi

mkdir -p "$DATA_DIR" "$LOG_DIR"

nohup "$BINARY" \
    --data-dir "$DATA_DIR" \
    --rpc-endpoint "$RPC_ENDPOINT" \
    --witness-endpoint "$WITNESS_ENDPOINT" \
    --genesis-file "$GENESIS_FILE" \
    --log.file-directory "$LOG_DIR" \
    --log.file-filter "debug" \
    --log.stdout-filter "info" \
    --metrics-enabled \
    >/dev/null 2>&1 &

echo $! > "$PID_FILE"
echo "started (pid $(cat "$PID_FILE"))"
```

Stop the validator with:

```bash
kill "$(cat stateless-validator.pid)" && rm stateless-validator.pid
```

{% hint style="info" %}
For production, prefer a proper service manager.
A systemd unit that invokes the binary directly (no `nohup`) gives you automatic restarts and clean journal logs.
{% endhint %}

## Monitoring

### Checking validation progress

With metrics enabled, the validator exposes a Prometheus endpoint at `http://0.0.0.0:9090/metrics`.
Three gauges tell you whether the validator is keeping up:

```bash
curl -s http://localhost:9090/metrics | grep -E 'chain_height|validation_lag'
# stateless_validator_local_chain_height   13592258
# stateless_validator_remote_chain_height  13592262
# stateless_validator_validation_lag       4
```

`validation_lag` is the number of blocks the validator is behind the remote tip.
A healthy validator hovers near zero and briefly spikes during bursty periods.

The [`scripts/validator-status.sh`](https://github.com/megaeth-labs/stateless-validator/blob/main/scripts/validator-status.sh) helper in the repo renders these metrics as a formatted dashboard.

### Useful metrics

| Metric                                                  | Type      | What it tells you                                    |
| ------------------------------------------------------- | --------- | ---------------------------------------------------- |
| `stateless_validator_local_chain_height`                | Gauge     | Local chain tip.                                     |
| `stateless_validator_remote_chain_height`               | Gauge     | Remote chain tip reported by the RPC endpoint.       |
| `stateless_validator_validation_lag`                    | Gauge     | Blocks behind the remote tip (target: ≈ 0).          |
| `stateless_validator_block_validation_time_seconds`     | Histogram | End-to-end time to validate a block.                 |
| `stateless_validator_witness_verification_time_seconds` | Histogram | Time spent verifying SALT witnesses.                 |
| `stateless_validator_block_replay_time_seconds`         | Histogram | EVM execution time per block.                        |
| `stateless_validator_salt_update_time_seconds`          | Histogram | Time to apply post-state deltas to the SALT trie.    |
| `stateless_validator_transactions_total`                | Counter   | Total transactions validated.                        |
| `stateless_validator_gas_used_total`                    | Counter   | Total gas used in validated blocks.                  |
| `stateless_validator_reorgs_detected_total`             | Counter   | Number of reorgs handled.                            |
| `stateless_validator_reorg_depth`                       | Histogram | Depth of chain reorganizations.                      |
| `stateless_validator_rpc_requests_total{method=...}`    | Counter   | RPC requests made, labelled by method.               |
| `stateless_validator_rpc_errors_total{method=...}`      | Counter   | RPC failures, labelled by method.                    |
| `stateless_validator_contract_cache_hits_total`         | Counter   | Bytecode served from the local cache.                |
| `stateless_validator_contract_cache_misses_total`       | Counter   | Bytecode fetched from RPC on miss.                   |
| `stateless_validator_worker_tasks_completed_total`      | Counter   | Tasks completed per worker (label: `worker_id`).     |
| `stateless_validator_worker_tasks_failed_total`         | Counter   | Tasks failed per worker (label: `worker_id`).        |

### Logs

When `--log.file-directory` is set, the validator writes rotated log files to that directory.
Rotation is size-based (`--log.file-max-size`, default 200 MB), keeping `--log.file-max-files` rotated files (default 5).
Console output honors `--log.stdout-filter`.

```bash
tail -f "$LOG_DIR/stateless-validator.log"
```

## Trust model

The stateless validator is an **execution client**: it verifies that every block's state transition was applied correctly and that commitments in the block header match the resulting post-state.
It does **not** decide which chain is canonical — it validates whatever sequence of blocks you feed it.

If you trust the RPC endpoint you point it at, the validator gives you strong guarantees that the sequencer is executing blocks correctly.

For a fully trust-minimized setup, pair the stateless validator with:

- **`op-node`** to derive the canonical L2 chain from L1 and the data availability layer.
- **A MegaETH replica node** that follows the derived chain and serves blocks locally.

In that configuration, you rely only on L1's security and your own software — no external RPC is in the trusted path.

## Troubleshooting

**The validator can't find the start block.**
Check that `--rpc-endpoint` is reachable and that the block hash in `--start-block` exists on that endpoint.
The validator retries fetch failures automatically, so you will see warnings in the log before it succeeds.

**`validation_lag` keeps growing.**
Either the remote RPC is throttling witness fetches (look for `mega_getBlockWitness` errors in `stateless_validator_rpc_errors_total`) or the machine is under-provisioned.
Histograms like `block_validation_time_seconds` break down where time is being spent.

**Reorg loops.**
A handful of reorgs per day is normal on any L2.
If `reorgs_detected_total` climbs fast, double-check that your RPC endpoint is following the canonical chain — a misconfigured provider may be serving a stale fork.

## Related Pages

- [Architecture](../architecture.md) — how transactions flow through MegaETH and where validators fit in
- [Mini-Blocks](../mini-block.md) — the two block types the validator re-executes
- [stateless-validator source](https://github.com/megaeth-labs/stateless-validator) — Rust client source code
- [SALT](https://github.com/megaeth-labs/salt) — MegaETH's state trie and witness format
