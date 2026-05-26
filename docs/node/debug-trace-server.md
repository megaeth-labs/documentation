---
description: Self-host debug_* and trace_* RPC methods for MegaETH by replaying blocks with SALT witnesses — no archive node required.
---

# Debug trace server

The **debug-trace-server** provides `debug_*` and `trace_*` JSON-RPC methods for MegaETH.
It re-executes blocks against [SALT](https://github.com/megaeth-labs/salt) witness data instead of a full state database, so it needs no archive node and runs on commodity hardware.

Point it at any MegaETH RPC endpoint, and it can trace any block or transaction that endpoint serves.

## When to use this

Run your own debug-trace-server when you need a **self-hosted** trace endpoint — for example, to power a block explorer backend, an indexer, or high-volume trace queries that would exceed public RPC rate limits.

If you only need occasional traces, the public MegaETH RPC already serves `debug_traceTransaction` and related methods directly — see [Debugging Transactions](../dev/send-tx/debugging.md).

## Installation

The server is built from source alongside the [stateless validator](stateless-validation.md).

```bash
git clone https://github.com/megaeth-labs/stateless-validator.git
cd stateless-validator
cargo build --release --bin debug-trace-server
```

The binary is at `./target/release/debug-trace-server`.
The project pins a nightly Rust toolchain via `rust-toolchain.toml`; `cargo build` downloads it automatically on first run.

## Quick start

The server needs two upstream endpoints to operate:

| Flag                 | What it connects to                                               | Methods called                                                     |
| -------------------- | ----------------------------------------------------------------- | ------------------------------------------------------------------ |
| `--rpc-endpoint`     | A MegaETH JSON-RPC node that serves standard Ethereum block data. | `eth_getBlockByNumber`, `eth_getHeaderByHash`, `eth_getCodeByHash` |
| `--witness-endpoint` | A MegaETH endpoint that serves SALT block witnesses.              | [`mega_getBlockWitness`](witness.md)                               |

{% hint style="info" %}
Most external teams do not run their own witness generator.
Point `--witness-endpoint` at the MegaETH public RPC — it serves `mega_getBlockWitness` for all historical blocks.
In the common case both flags point to the same URL.
{% endhint %}

{% tabs %}
{% tab title="Mainnet" %}

```bash
./target/release/debug-trace-server \
  --rpc-endpoint https://mainnet.megaeth.com/rpc \
  --witness-endpoint https://mainnet.megaeth.com/rpc
```

{% endtab %}

{% tab title="Testnet" %}

```bash
./target/release/debug-trace-server \
  --rpc-endpoint https://carrot.megaeth.com/rpc \
  --witness-endpoint https://carrot.megaeth.com/rpc
```

{% endtab %}
{% endtabs %}

The server listens on `0.0.0.0:8545` by default.
Verify it is running:

```bash
curl -s http://localhost:8545 \
  -H 'Content-Type: application/json' \
  -d '{"jsonrpc":"2.0","method":"debug_traceBlockByNumber","params":["latest",{"tracer":"callTracer"}],"id":1}' \
  | head -c 200
```

### Production setup

For production traffic, add `--data-dir` to enable **local cache mode**.
The server starts a background pipeline that pre-fetches blocks and witnesses into a local database, so trace requests read locally instead of hitting upstream RPC on every call.

```bash
./target/release/debug-trace-server \
  --rpc-endpoint https://mainnet.megaeth.com/rpc \
  --witness-endpoint https://mainnet.megaeth.com/rpc \
  --data-dir ./dts-data \
  --blocks-to-keep 5000 \
  --response-cache-max-size 2GB \
  --metrics-enabled
```

| Flag                            | Effect                                                                                            |
| ------------------------------- | ------------------------------------------------------------------------------------------------- |
| `--data-dir ./dts-data`         | Enable local cache mode. Creates a `trace_server.redb` database and starts background block sync. |
| `--blocks-to-keep 5000`         | Retain the most recent 5 000 blocks; older blocks are pruned automatically.                       |
| `--response-cache-max-size 2GB` | Cache serialized trace responses in memory so repeated requests return instantly.                 |
| `--metrics-enabled`             | Expose a Prometheus `/metrics` endpoint on port 9090.                                             |

{% hint style="warning" %}
On the first start with `--data-dir`, the server fetches the latest block from upstream as an anchor and begins syncing forward.
To anchor at a specific block, pass `--start-block <BLOCK_HASH>` — this accepts a block **hash**, not a number.
{% endhint %}

## Supported RPC methods

### Geth-style (`debug_*`)

| Method                     | Description                                   |
| -------------------------- | --------------------------------------------- |
| `debug_traceBlockByNumber` | Trace all transactions in a block, by number. |
| `debug_traceBlockByHash`   | Trace all transactions in a block, by hash.   |
| `debug_traceTransaction`   | Trace a single transaction by hash.           |
| `debug_getCacheStatus`     | Query current response cache statistics.      |

The trace methods accept an optional second parameter with [Geth debug tracing options](https://geth.ethereum.org/docs/developers/evm-tracing/built-in-tracers):

```json
{
  "method": "debug_traceBlockByNumber",
  "params": ["latest", { "tracer": "callTracer" }]
}
```

Supported tracers:

| Tracer                  | `tracer` value     | Output                                                                        |
| ----------------------- | ------------------ | ----------------------------------------------------------------------------- |
| Default (struct logger) | _(omit)_           | Opcode-level trace with gas, stack, memory, storage at each step.             |
| Call tracer             | `"callTracer"`     | Nested call tree with inputs, outputs, gas per frame.                         |
| Prestate tracer         | `"prestateTracer"` | Account state before execution; add `"diffMode": true` for before/after diff. |
| 4-byte tracer           | `"4byteTracer"`    | Function selector frequency statistics.                                       |
| Flat call tracer        | `"flatCallTracer"` | Parity-style flat list of all internal calls.                                 |
| Noop tracer             | `"noopTracer"`     | No output — useful for benchmarking execution time.                           |
| Mux tracer              | `"muxTracer"`      | Run multiple tracers in a single pass.                                        |

Custom JavaScript tracers are also supported.

### Parity-style (`trace_*`)

| Method              | Description                                                                                                                                |
| ------------------- | ------------------------------------------------------------------------------------------------------------------------------------------ |
| `trace_block`       | Flat call traces for all transactions in a block.                                                                                          |
| `trace_transaction` | Flat call traces for a single transaction. Returns `null` (not an error) when the transaction is not found, matching `mega-reth` behavior. |

Every method also has a `timed_`-prefixed alias (e.g. `timed_debug_traceBlockByNumber`) with identical behavior, letting callers tag client-side metrics separately.

## Command-line reference

Every flag has an equivalent environment variable.
Command-line flags take precedence.

### Core flags

| Flag                 | Env variable                          | Required? | Description                                                                                                                                                                    |
| -------------------- | ------------------------------------- | --------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------ |
| `--addr`             | `DEBUG_TRACE_SERVER_ADDR`             | No        | Listen address. Default: `0.0.0.0:8545`.                                                                                                                                       |
| `--rpc-endpoint`     | `DEBUG_TRACE_SERVER_RPC_ENDPOINT`     | Yes       | MegaETH JSON-RPC endpoint(s) for block data. Comma-separated or repeated for failover (round-robin).                                                                           |
| `--witness-endpoint` | `DEBUG_TRACE_SERVER_WITNESS_ENDPOINT` | Yes       | MegaETH endpoint(s) serving [`mega_getBlockWitness`](witness.md). Comma-separated or repeated for failover (primary-failover: first endpoint takes all traffic while healthy). |
| `--genesis-file`     | `DEBUG_TRACE_SERVER_GENESIS_FILE`     | No        | Path to genesis JSON. Uses the built-in chain spec when unset.                                                                                                                 |

### Local cache

Omit `--data-dir` to run in stateless mode (no local storage).

| Flag                     | Env variable                              | Default   | Description                                                                                                       |
| ------------------------ | ----------------------------------------- | --------- | ----------------------------------------------------------------------------------------------------------------- |
| `--data-dir`             | `DEBUG_TRACE_SERVER_DATA_DIR`             | _(unset)_ | Directory for the local database. Enables local cache mode when set.                                              |
| `--start-block`          | `DEBUG_TRACE_SERVER_START_BLOCK`          | _(unset)_ | Block **hash** for the initial anchor. When unset, the server fetches the latest block. Only used on first start. |
| `--blocks-to-keep`       | `DEBUG_TRACE_SERVER_BLOCKS_TO_KEEP`       | `1000`    | Recent blocks to retain. Older blocks are pruned.                                                                 |
| `--db-max-size`          | `DEBUG_TRACE_SERVER_DB_MAX_SIZE`          | `0` (off) | Max database file size (e.g. `10GB`). Triggers extra pruning (100-block batches) when exceeded.                   |
| `--pruner-interval-secs` | `DEBUG_TRACE_SERVER_PRUNER_INTERVAL_SECS` | `300`     | Seconds between pruning cycles.                                                                                   |

### Timeout and concurrency

| Flag                                | Env variable                                         | Default   | Description                                                                                       |
| ----------------------------------- | ---------------------------------------------------- | --------- | ------------------------------------------------------------------------------------------------- |
| `--witness-timeout`                 | `DEBUG_TRACE_SERVER_WITNESS_TIMEOUT`                 | `8`       | Witness fetch timeout in seconds.                                                                 |
| `--block-fetch-timeout`             | `DEBUG_TRACE_SERVER_BLOCK_FETCH_TIMEOUT_SECS`        | `13`      | Total timeout in seconds for all data needed for one block (header + witness + body + contracts). |
| `--rpc-per-attempt-timeout-ms`      | `DEBUG_TRACE_SERVER_RPC_PER_ATTEMPT_TIMEOUT_MS`      | _(unset)_ | Per-attempt RPC timeout in milliseconds. Must be ≥ 100.                                           |
| `--data-max-concurrent-requests`    | `DEBUG_TRACE_SERVER_DATA_MAX_CONCURRENT_REQUESTS`    | unlimited | Cap on concurrent in-flight data requests (blocks, headers, code).                                |
| `--witness-max-concurrent-requests` | `DEBUG_TRACE_SERVER_WITNESS_MAX_CONCURRENT_REQUESTS` | unlimited | Cap on concurrent in-flight witness fetches, independent of the data cap.                         |

{% hint style="info" %}
The data and witness concurrency caps are independent semaphores — a burst on one path cannot starve the other.
When using the public RPC, setting both to `4` prevents HTTP 429 rate-limiting.
{% endhint %}

### Response cache

| Flag                               | Env variable                                        | Default | Description                                                             |
| ---------------------------------- | --------------------------------------------------- | ------- | ----------------------------------------------------------------------- |
| `--response-cache-max-size`        | `DEBUG_TRACE_SERVER_RESPONSE_CACHE_MAX_SIZE`        | `1GB`   | Maximum memory for cached responses. Accepts `KB`, `MB`, `GB` suffixes. |
| `--response-cache-estimated-items` | `DEBUG_TRACE_SERVER_RESPONSE_CACHE_ESTIMATED_ITEMS` | `1000`  | Initial capacity hint. Set to `0` to disable the cache entirely.        |

The cache stores pre-serialized JSON responses keyed by `(block_number, tracer_type)`.
Different tracers on the same block are cached independently.
Entries are invalidated automatically on chain reorganization.

### Monitoring

| Flag                | Env variable                         | Default | Description                             |
| ------------------- | ------------------------------------ | ------- | --------------------------------------- |
| `--metrics-enabled` | `DEBUG_TRACE_SERVER_METRICS_ENABLED` | `false` | Enable the Prometheus metrics endpoint. |
| `--metrics-port`    | `DEBUG_TRACE_SERVER_METRICS_PORT`    | `9090`  | Port for the metrics HTTP endpoint.     |

When enabled, scrape `http://<HOST>:9090/metrics`.

| Metric                                                            | Type      | What it tells you                                |
| ----------------------------------------------------------------- | --------- | ------------------------------------------------ |
| `debug_trace_rpc_requests_total`                                  | Counter   | Total RPC requests, labelled by method.          |
| `debug_trace_rpc_errors_total`                                    | Counter   | Total RPC errors, labelled by method.            |
| `debug_trace_request_duration_seconds`                            | Histogram | End-to-end request latency.                      |
| `debug_trace_inflight_requests`                                   | Gauge     | Currently in-flight requests.                    |
| `debug_trace_cache_hits_total` / `debug_trace_cache_misses_total` | Counter   | Response cache hit/miss.                         |
| `debug_trace_evm_execution_seconds`                               | Histogram | EVM trace execution time per request.            |
| `debug_trace_upstream_duration_seconds`                           | Histogram | Upstream RPC latency, labelled by method.        |
| `debug_trace_witness_bytes`                                       | Histogram | Witness payload size.                            |
| `debug_trace_local_chain_height`                                  | Gauge     | Latest block in the local database.              |
| `debug_trace_db_size_bytes`                                       | Gauge     | Database file size on disk.                      |
| `debug_trace_reorg_depth`                                         | Histogram | Chain reorg depth detected by the sync pipeline. |

### Logging

Logging shares the same `--log.*` flags and `STATELESS_LOG_*` environment variables as the [stateless validator](stateless-validation.md#logging-flags).
See that page for the full flag table.

Recommended production settings:

```bash
--log.stdout-format json \
--log.stdout-filter info \
--log.file-directory /var/log/dts \
--log.file-filter debug \
--log.file-max-size 500 \
--log.file-max-files 10
```

## Environment variables

All flags can be set via environment variables — convenient for container or orchestrator-based deployments:

```bash
DEBUG_TRACE_SERVER_ADDR=0.0.0.0:8545
DEBUG_TRACE_SERVER_RPC_ENDPOINT=https://mainnet.megaeth.com/rpc
DEBUG_TRACE_SERVER_WITNESS_ENDPOINT=https://mainnet.megaeth.com/rpc
DEBUG_TRACE_SERVER_DATA_DIR=/data/dts
DEBUG_TRACE_SERVER_BLOCKS_TO_KEEP=5000
DEBUG_TRACE_SERVER_RESPONSE_CACHE_MAX_SIZE=2GB
DEBUG_TRACE_SERVER_METRICS_ENABLED=true
STATELESS_LOG_STDOUT=info
STATELESS_LOG_STDOUT_FORMAT=json
```

## Troubleshooting

**Database needs a reset.**
Stop the service, delete `trace_server.redb` from the data directory, and restart.
The server re-syncs from the latest block automatically.

```bash
rm /data/dts/trace_server.redb
systemctl restart dts
```

**Upstream RPC is unreachable.**
The server retries with round-robin failover and exponential backoff.
While all endpoints are down, the sync pipeline stalls (it does not crash) and trace requests return error `-32001` after `--block-fetch-timeout` expires.
Service resumes automatically once any endpoint recovers.

**High memory usage.**
Lower `--response-cache-max-size` if the response cache is consuming too much memory.
The contract bytecode cache is process-lifetime — chains with many deployed contracts accumulate bytecode in memory over time.

**Slow trace requests.**
Use Prometheus metrics to isolate the bottleneck:

- `debug_trace_upstream_duration_seconds` high — upstream RPC is slow.
- `debug_trace_evm_execution_seconds` high — the block has many or complex transactions.
- `debug_trace_witness_bytes` large — witness payloads are large, causing slow fetches.

The server logs a warning (`slow stages detected`) for any request stage exceeding 1 second.

## Related pages

- [Debugging Transactions](../dev/send-tx/debugging.md) — trace via the public RPC or `mega-evme` without running your own server
- [Stateless Validation](stateless-validation.md) — the stateless validator that cryptographically verifies every block
- [Get Block Witness](witness.md) — `mega_getBlockWitness` RPC reference and witness data layout
- [debug-trace-server source](https://github.com/megaeth-labs/stateless-validator/tree/main/bin/debug-trace-server) — upstream Rust implementation
