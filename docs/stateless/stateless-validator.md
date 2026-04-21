---
description: Run a stateless validator to independently verify every MegaETH block on commodity hardware using SALT witnesses.
---

# Stateless validator

The **stateless validator** is a Rust client that independently verifies every MegaETH block without maintaining full chain state.
Instead of replaying blocks against a locally-stored state trie, it re-executes each block against a compact cryptographic witness supplied by the network, then checks that the resulting post-state matches the commitments in the block header.

This design enables independent verification of sequencer execution on commodity hardware — a laptop-class machine can verify MegaETH Mainnet in real time.
For how validators fit into the broader network, see [Architecture](../architecture.md).

## Why run a stateless validator

- **Independent verification** — you re-execute the state transition function (STF) of every block yourself, rather than trusting an RPC provider to tell you the truth.
- **Low hardware cost** — thanks to [SALT (Small Authentication Large Trie)](https://github.com/megaeth-labs/salt) witnesses, proof data per block is significantly smaller than traditional Merkle Patricia Trie or Verkle tree approaches, so validators do not need sequencer-class hardware.
- **Parallel-friendly** — validation workers are embarrassingly parallel; throughput scales linearly with CPU cores.
- **Auditable TCB** — the validator is built on a vanilla revm interpreter with an in-memory backend, keeping the trusted computing base small and reviewable.

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
   The validator begins verification from this anchor and walks forward.
   For a quick test you can use MegaETH Mainnet block [`0xc0ffee`](https://mega.etherscan.io/block/12648430) (hash `0xff061a29416ffe4486924a5e8e0df95de5db5d77589ab4d58fb00e3b6ddb8b40`); in production, pick a recent block hash you've independently verified on an explorer.

```bash
./target/release/stateless-validator \
  --data-dir ./validator-data \
  --rpc-endpoint https://mainnet.megaeth.com/rpc \
  --witness-endpoint https://mainnet.megaeth.com/rpc \
  --genesis-file ./test_data/mainnet/genesis.json \
  --start-block 0xff061a29416ffe4486924a5e8e0df95de5db5d77589ab4d58fb00e3b6ddb8b40
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
```

If the remote chain has reorged past your local tip, the validator detects the divergence, rolls back to the common ancestor, and continues from there.

{% hint style="warning" %}
The validator keeps only the most recent **1000 blocks** of canonical chain history (`DEFAULT_MAX_CHAIN_LENGTH`); older entries are pruned inline as the chain advances.
A reorg deeper than the retained history can't find a common ancestor locally — the validator halts with a `Catastrophic reorg: earliest local block ... hash mismatch` error and requires manual restart with a fresh `--start-block` past the reorg.
{% endhint %}

### Multiple RPC endpoints

Both `--rpc-endpoint` and `--witness-endpoint` accept multiple endpoints as repeated flags or a comma-separated list.
Data endpoints are load-balanced round-robin with per-provider exponential backoff, cycling to the next provider after retries exhaust.
Witness endpoints are tried front-to-back on each request, returning on the first success.

```bash
# Repeated flags
--rpc-endpoint https://a.example/rpc --rpc-endpoint https://b.example/rpc

# Comma-separated (also accepted by the env var)
--rpc-endpoint https://a.example/rpc,https://b.example/rpc
```

## Command-line options

Every flag has an equivalent environment variable, convenient for systemd units and Docker.
Command-line flags take precedence over environment variables.
Boolean flags (e.g. `--metrics-enabled`) accept `true` or `false` via their env var — set `STATELESS_VALIDATOR_METRICS_ENABLED=true` to turn the endpoint on from a unit file.

### Core flags

| Flag                                | Env variable                                          | Required? | Description                                                                                                                             |
| ----------------------------------- | ----------------------------------------------------- | --------- | --------------------------------------------------------------------------------------------------------------------------------------- |
| `--data-dir`                        | `STATELESS_VALIDATOR_DATA_DIR`                        | Yes       | Directory holding the validator database and any cached data.                                                                           |
| `--rpc-endpoint`                    | `STATELESS_VALIDATOR_RPC_ENDPOINT`                    | Yes       | JSON-RPC endpoint(s) for block headers and bodies. Repeat the flag or pass a comma-separated list.                                      |
| `--witness-endpoint`                | `STATELESS_VALIDATOR_WITNESS_ENDPOINT`                | Yes       | MegaETH JSON-RPC endpoint(s) for SALT witnesses (`mega_getBlockWitness`). Multiple endpoints accepted.                                  |
| `--genesis-file`                    | `STATELESS_VALIDATOR_GENESIS_FILE`                    | First run | Path to the genesis JSON. Stored in the database after the first run.                                                                   |
| `--start-block`                     | `STATELESS_VALIDATOR_START_BLOCK`                     | First run | Trusted block hash used as the validation anchor.                                                                                       |
| `--report-validation-endpoint`      | `STATELESS_VALIDATOR_REPORT_VALIDATION_ENDPOINT`      | No        | RPC endpoint that receives `mega_setValidatedBlocks` callbacks for validated blocks. If not provided, validation reporting is disabled. |
| `--metrics-enabled`                 | `STATELESS_VALIDATOR_METRICS_ENABLED`                 | No        | Expose a Prometheus `/metrics` endpoint.                                                                                                |
| `--metrics-port`                    | `STATELESS_VALIDATOR_METRICS_PORT`                    | No        | Port for the metrics endpoint. Default: `9090`.                                                                                         |
| `--data-max-concurrent-requests`    | `STATELESS_VALIDATOR_DATA_MAX_CONCURRENT_REQUESTS`    | No        | Cap on concurrent in-flight data requests (blocks, headers, code, tx). Omit for unlimited.                                              |
| `--witness-max-concurrent-requests` | `STATELESS_VALIDATOR_WITNESS_MAX_CONCURRENT_REQUESTS` | No        | Cap on concurrent in-flight witness fetches, independent of the data cap. Omit for unlimited.                                           |

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

For long-lived deployments, run the validator under **systemd** — it gives you automatic restarts on crash, clean journal logs, and process isolation.
Do the [First run](#first-run) step manually once to set the anchor, then hand off to systemd for ongoing operation.

### 1. Create a dedicated user and directories

```bash
sudo useradd --system --home /home/blockchain --shell /usr/sbin/nologin blockchain
sudo mkdir -p /home/blockchain/stateless-validator/logs
sudo install -m 755 ./target/release/stateless-validator /usr/local/bin/
sudo install -m 644 -o blockchain -g blockchain ./test_data/mainnet/genesis.json /home/blockchain/stateless-validator/genesis.json
sudo chown -R blockchain:blockchain /home/blockchain
```

### 2. Bootstrap the anchor (first run only)

The systemd env file intentionally omits `STATELESS_VALIDATOR_START_BLOCK` — the validator re-anchors the database whenever `--start-block` is set, so leaving it for systemd would wipe validated state on every restart.
Run the validator manually once as the `blockchain` user to write the initial anchor, then stop it:

```bash
sudo -u blockchain /usr/local/bin/stateless-validator \
  --data-dir /home/blockchain/stateless-validator \
  --rpc-endpoint https://mainnet.megaeth.com/rpc \
  --witness-endpoint https://mainnet.megaeth.com/rpc \
  --genesis-file /home/blockchain/stateless-validator/genesis.json \
  --start-block 0xff061a29416ffe4486924a5e8e0df95de5db5d77589ab4d58fb00e3b6ddb8b40
```

Wait for the log line `[Main] Successfully initialized from start block`, then press **Ctrl+C** to stop.
This creates `/home/blockchain/stateless-validator/validator.redb`, a [redb](https://github.com/cberner/redb) database holding the trusted anchor, the recent canonical chain, cached contract bytecode, and the genesis config.
Every subsequent run — manual or under systemd — resumes from this file, which is why `--start-block` must stay out of the systemd env (re-supplying it would wipe the db).
Re-supplying `--genesis-file` is harmless — the validator just re-stores the same config — so the env file below keeps it as a belt-and-suspenders fallback if the db is ever rebuilt.

### 3. Write the environment file

Store all configuration in `/etc/stateless-validator.env` so the service unit stays generic:

```bash
# /etc/stateless-validator.env
STATELESS_VALIDATOR_DATA_DIR=/home/blockchain/stateless-validator
STATELESS_VALIDATOR_RPC_ENDPOINT=https://mainnet.megaeth.com/rpc
STATELESS_VALIDATOR_WITNESS_ENDPOINT=https://mainnet.megaeth.com/rpc
STATELESS_VALIDATOR_GENESIS_FILE=/home/blockchain/stateless-validator/genesis.json
STATELESS_VALIDATOR_METRICS_ENABLED=true
STATELESS_VALIDATOR_METRICS_PORT=9090
STATELESS_LOG_FILE_DIRECTORY=/home/blockchain/stateless-validator/logs
STATELESS_LOG_FILE=debug
STATELESS_LOG_STDOUT=info
```

Lock it down:

```bash
sudo chmod 600 /etc/stateless-validator.env
sudo chown root:root /etc/stateless-validator.env
```

### 4. Install the service unit

`/etc/systemd/system/stateless-validator.service`:

```ini
[Unit]
Description=MegaETH stateless validator
After=network-online.target
Wants=network-online.target

[Service]
Type=simple
User=blockchain
Group=blockchain
EnvironmentFile=/etc/stateless-validator.env
ExecStart=/usr/local/bin/stateless-validator
Restart=on-failure
RestartSec=5s
LimitNOFILE=65535

NoNewPrivileges=true
PrivateTmp=true
ProtectSystem=strict
ProtectHome=read-only
ReadWritePaths=/home/blockchain/stateless-validator

[Install]
WantedBy=multi-user.target
```

### 5. Enable and start

```bash
sudo systemctl daemon-reload
sudo systemctl enable --now stateless-validator
sudo systemctl status stateless-validator
```

Common operations:

```bash
sudo systemctl restart stateless-validator      # restart after config change
sudo systemctl stop stateless-validator         # stop cleanly
sudo journalctl -u stateless-validator -f       # follow journal (stdout + stderr)
tail -f /home/blockchain/stateless-validator/logs/stateless-validator.log
```

### Uninstall

To tear down the deployment — useful for clean-room testing or decommissioning a host:

```bash
sudo systemctl disable --now stateless-validator
sudo rm /etc/systemd/system/stateless-validator.service
sudo rm /etc/stateless-validator.env
sudo rm /usr/local/bin/stateless-validator
sudo systemctl daemon-reload
sudo userdel -r blockchain    # removes the user and /home/blockchain (validator DB, logs, genesis)
```

## Monitoring

### Checking validation progress

With metrics enabled, the validator binds a Prometheus endpoint on `0.0.0.0:9090` (reachable as `http://<host>:9090/metrics`, or `http://localhost:9090/metrics` from the same machine).
Three gauges tell you whether the validator is keeping up:

```bash
curl -s http://localhost:9090/metrics | grep -E 'chain_height|validation_lag'
stateless_validator_local_chain_height   12649974
stateless_validator_remote_chain_height  13977051
stateless_validator_validation_lag       1327077
```

`validation_lag` is the number of blocks the validator is behind the remote tip (`remote_chain_height − local_chain_height`).
Interpret it in two phases:

- **During initial catch-up**, `validation_lag` starts large and shrinks over time — a validator anchored at block 12.6M with remote tip at 14M begins at ~1.4M blocks behind and walks forward at its throughput rate. A large lag here is expected, not a symptom.
- **Once caught up**, the gauge hovers near zero and briefly spikes during bursty periods. Persistent non-zero lag at this point means the validator can't keep pace with the sequencer — investigate per the [Troubleshooting](#troubleshooting) section.

The [`scripts/validator-status.sh`](https://github.com/megaeth-labs/stateless-validator/blob/main/scripts/validator-status.sh) helper in the repo renders these metrics as a formatted dashboard.

### Useful metrics

| Metric                                                     | Type      | What it tells you                                                  |
| ---------------------------------------------------------- | --------- | ------------------------------------------------------------------ |
| `stateless_validator_local_chain_height`                   | Gauge     | Local chain tip.                                                   |
| `stateless_validator_remote_chain_height`                  | Gauge     | Remote chain tip reported by the RPC endpoint.                     |
| `stateless_validator_validation_lag`                       | Gauge     | Blocks behind the remote tip (target: ≈ 0).                        |
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

**`Catastrophic reorg: earliest local block … hash mismatch`.**
The reorg exceeds the 1000-block canonical history the validator keeps, so no common ancestor is reachable in the local db.
Restart with `--start-block <NEW_HASH>`, picking a recent trusted block past the reorg — this re-anchors the db to that block.

## Related Pages

- [Architecture](../architecture.md) — how transactions flow through MegaETH and where validators fit in
- [stateless-validator source](https://github.com/megaeth-labs/stateless-validator) — Rust client source code
- [SALT](https://github.com/megaeth-labs/salt) — MegaETH's state trie and witness format
