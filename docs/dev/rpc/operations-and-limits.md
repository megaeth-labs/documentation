---
description: Public MegaETH JSON-RPC rate limits, payload limits, method caps, caching behavior, and WebSocket limits.
---

# Operations and limits

This page describes limits applied by the public MegaETH gateway.
Method pages define the underlying request and response contracts.

## HTTP request and response limits

| Limit                                  | Value        |
| -------------------------------------- | ------------ |
| Default request body                   | 128 KiB      |
| Transaction-submission request body    | 2.5 MiB      |
| Simulation and large-read request body | 1.5 MiB      |
| Batch size                             | 100 requests |
| Batch subrequest budget                | 950          |
| Response size                          | 50 MiB       |

The 2.5 MiB body limit applies to `eth_sendRawTransaction`, `eth_sendRawTransactionSync`, and `realtime_sendRawTransaction`.
The 1.5 MiB body limit applies to `eth_call`, `eth_callMany`, `eth_createAccessList`, and `eth_estimateGas`.
A body that exceeds its limit is rejected with HTTP `413` and JSON-RPC code `-32099`.

The batch subrequest budget counts expanded work rather than only top-level batch items.
For example, the calls inside `eth_callMany` contribute to that budget.

## Method-specific limits

| Method            | Public gateway behavior                                                                                                                           |
| ----------------- | ------------------------------------------------------------------------------------------------------------------------------------------------- |
| `eth_call`        | Compute gas is capped at 60,000,000.                                                                                                              |
| `eth_callMany`    | At most 100 bundles and 100 total calls, 60,000,000 compute gas per call, and a 25-second timeout.                                                |
| `eth_estimateGas` | The node applies a CPU-time limit whose current default is 0.5 seconds.                                                                           |
| `eth_feeHistory`  | `blockCount` is capped at 256.                                                                                                                    |
| `eth_getLogs`     | The public indexed path does not impose a gateway block-range cap, but backend row, execution-time, memory, and response-size limits still apply. |

Use bounded ranges and pagination for log scans and historical backfills.
Do not assume that removing a block-range cap makes an unbounded query safe.

## Read rate limits

Read requests are limited per client IP in fixed 10-second windows.

| Category | Requests per 10 seconds | Typical methods                                                                                                             |
| -------- | ----------------------- | --------------------------------------------------------------------------------------------------------------------------- |
| Instant  | 2,000                   | `eth_chainId`, `eth_blockNumber`, `net_version`, `eth_accounts`, `web3_clientVersion`, `eth_getBalance`, `eth_getStorageAt` |
| Simple   | 500                     | Basic block and transaction reads not assigned to another category                                                          |
| Compute  | 200                     | `eth_call`, `eth_callMany`, `eth_estimateGas`, `eth_createAccessList`, and debug trace methods                              |
| IO-heavy | 200                     | `eth_getLogs` and `eth_getBlockReceipts`                                                                                    |

Transaction-submission methods are exempt from these read limits.
`eth_callMany` is charged by its inner calls rather than as one unit.
A rate-limited request returns HTTP `429` with JSON-RPC code `-32005`.

Use exponential backoff with jitter for retryable throttling.
Reduce concurrency and query size before increasing retry frequency.

## Gateway caching

The public gateway has several internal caches.
Their eligibility and lifetime depend on the method and selector: immutable block numbers and hashes can use longer-lived entries, while head-following reads use shorter policies or bypass a cache layer.
See each method's reference page for its method-specific behavior.

The gateway's Workers read-cache layer is limited to:

- `eth_getBlockByNumber`
- `eth_getBlockReceipts`
- `eth_getHeaderByNumber`
- `web3_clientVersion`

For the block-selecting methods in this layer, only an explicit historical block number, a block hash, or `earliest` is eligible.
The `latest`, `pending`, `safe`, and `finalized` tags bypass this layer.
Other gateway cache layers can still apply method-specific short-lived policies to head-following reads.

Rate-limit accounting differs by request shape:

- A single read is rate-limited before cache lookup, so a cache hit consumes its category budget.
- A read batch checks the cache first and charges only cache misses against the read-rate budget.

Every public response includes `Cache-Control: no-store` for downstream caches.
This header does not disable the gateway's internal cache.
For methods eligible for the Workers read-cache layer, `X-Workers-Cache-Status` indicates whether that layer returned the response.

The gateway does not expose a request header or parameter that bypasses its internal cache.

## WebSocket limits

| Limit                              | Value                                |
| ---------------------------------- | ------------------------------------ |
| Connections per IP                 | 5                                    |
| Subscriptions per connection       | 5                                    |
| Client message rate                | 5 messages per second per connection |
| Idle timeout                       | 60 seconds                           |
| Maximum message size               | 64 KiB                               |
| Addresses in a `logs` filter       | 20                                   |
| Topic positions in a `logs` filter | 4                                    |

Use `wss://mainnet.megaeth.com/ws` for Mainnet and `wss://carrot.megaeth.com/ws` for Testnet.
Send a lightweight request such as `eth_chainId` at least every 30 seconds to prevent idle disconnection.
Reconnect, recreate subscriptions, and reconcile any missed data after a disconnect because notifications are not replayed automatically.

The public WebSocket endpoint accepts:

- `eth_subscribe`
- `eth_unsubscribe`
- `eth_sendRawTransaction`
- `eth_sendRawTransactionSync`
- `realtime_sendRawTransaction`
- `eth_chainId`

## Related pages

- [Error reference](./error-codes.md)
- [`eth_subscribe`](./reference/eth_subscribe.md)
- [`eth_getLogs`](./reference/eth_getLogs.md)
