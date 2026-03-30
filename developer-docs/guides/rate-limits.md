# Handle Rate Limits And Large Queries

Use this guide when requests fail with HTTP `429`, JSON-RPC `-32005`, response-size failures, or unstable throughput under load.

This page is the client playbook. For the current public numbers and hard limits, read [Operations and Limits](../operations/limits.md).

## Start With The Failure Shape

| What you are seeing | What it usually means | First move |
|---|---|---|
| HTTP `429` or JSON-RPC `-32005` | You are over the current gateway budget for that workload | Back off and reduce burst size |
| `eth_getLogs` fails on wide ranges or huge responses | The query is too broad for one request | Page the range and narrow filters |
| Repeated `eth_call` or `eth_estimateGas` fails under load | You are pushing compute-heavy request patterns | Reduce loops and cache what you can |
| Historical backfill saturates the public endpoint | The workload needs smaller pages and tighter control of older-range reads | Split the work, page aggressively, and verify whether that endpoint serves the older range you need |

## The Order That Usually Works

1. Reduce request cost before raising retry count.
2. Page large historical and log workloads into smaller windows.
3. Retry with backoff and jitter instead of replaying the same burst immediately.
4. Separate real-time traffic from backfill traffic.
5. Separate heavy historical backfills from normal read traffic.

## Workload-Specific Moves

### Simple Reads

- cache immutable blocks, receipts, and historical code
- avoid repeating the same latest-state read in tight loops
- do not assume an old safe throughput still applies after changing method family

### Compute-Heavy Reads

- avoid repeated [`eth_estimateGas`](../api/eth_estimateGas.md) for near-identical requests
- collapse duplicate [`eth_call`](../api/eth_call.md) patterns where possible
- keep retries conservative when the request is expensive even before the retry

### Logs And Backfills

- keep block ranges explicit
- start with smaller windows and widen only after success
- narrow with `address` and `topics`
- checkpoint progress in your own system instead of retrying one giant range forever

## Retry Policy

- Back off before retrying the same request.
- Add jitter so many workers do not re-fire at the same boundary.
- Stop after a small number of unchanged retries if the same shape keeps failing.
- If the workload is clearly historical, re-check whether that endpoint serves the older range you need instead of only changing retry timing.

## Worked Example: Shrink The Query Before Retrying

This request shape is risky because it asks for a wide log range in one shot:

```json
{"jsonrpc":"2.0","id":1,"method":"eth_getLogs","params":[{"fromBlock":"0x100000","toBlock":"0x101000"}]}
```

A safer recovery path is:

1. Keep the same method and filter intent.
2. Split the range into smaller windows.
3. Retry each window with backoff instead of replaying the whole range immediately.
4. Checkpoint completed windows in your own system.

For example, start with:

```json
{"jsonrpc":"2.0","id":1,"method":"eth_getLogs","params":[{"fromBlock":"0x100000","toBlock":"0x100063"}]}
```

## What Not To Expect

- A smaller page matters more than simply moving the same oversized query around.
- Batching helps when the combined payload fits gateway limits. Within a batch, only cache misses count against rate-limit tiers, so requests that hit the cache do not consume tokens.
- More retries do not fix a query that is too wide or too expensive.
