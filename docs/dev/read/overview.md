---
description: How to query state and data from MegaETH — JSON-RPC methods, rate limiting, subscriptions, and real-time queries.
---

# Read from MegaETH

## Realtime API

Standard Ethereum JSON-RPC was designed for chains with multi-second block times.
On those chains, a one-second delay between execution and queryability is normal — you poll `eth_getTransactionReceipt`, wait for the next block, and eventually get your result.

MegaETH produces [mini-blocks](../../mini-block.md) every ~10 milliseconds.
If the read API still operated on one-second EVM blocks, applications would wait 100× longer than necessary to see their results.
The Realtime API closes this gap: it queries against the most recent mini-block so that balances, receipts, logs, and state changes are visible within milliseconds of execution — not seconds.

Standard methods like `eth_getBalance`, `eth_call`, and `eth_getTransactionReceipt` already reflect mini-block state automatically when called with `latest` or `pending`.
On top of that, MegaETH exposes two public extension paths for lower-latency workflows:

- [`realtime_sendRawTransaction`](rpc/realtime_sendRawTransaction.md) — submit a transaction and get the receipt back in one call, no polling
- [`eth_subscribe`](rpc/eth_subscribe.md) — stream logs, state changes, mini-blocks, and block headers over WebSocket as they happen

For use-case-oriented guidance (which method to use for what), see the [Realtime API](realtime-api.md) page.

## Available Methods

{% hint style="info" %}
The table below reflects the public MegaETH Mainnet endpoint as verified on July 24, 2026.
"Unavailable" includes methods recognized by the gateway but disabled or unimplemented upstream.
Managed providers may expose additional methods.
{% endhint %}

| Method                                    | Availability   | Additional restrictions or behavior                                                             |
| ----------------------------------------- | -------------- | ----------------------------------------------------------------------------------------------- |
| `debug_getHistoryTransactionCount`        | Available      | MegaETH-specific.                                                                               |
| `debug_getRawHeader`                      | Available      |                                                                                                 |
| `debug_traceBlockByHash`                  | Available      | Large responses are streamed.                                                                   |
| `debug_traceBlockByNumber`                | Available      | Large responses are streamed.                                                                   |
| `debug_traceCall`                         | Unavailable    | The public endpoint returns `-32601`.                                                           |
| `debug_traceTransaction`                  | Available      | Large responses are streamed.                                                                   |
| `eth_accounts`                            | Available      | Returns an empty array because the gateway does not manage user keys.                           |
| `eth_blockNumber`                         | Available      |                                                                                                 |
| `eth_call`                                | Available      | Compute gas limited to 60,000,000.                                                              |
| `eth_callAfter`                           | Unavailable    | The public endpoint returns `-32601`.                                                           |
| `eth_callMany`                            | Available      | 100 bundles and 100 total calls; 60,000,000 compute gas per call; timeout capped at 25 seconds. |
| `eth_chainId`                             | Available      |                                                                                                 |
| `eth_createAccessList`                    | Available      | Compute gas limited to 60,000,000.                                                              |
| `eth_estimateGas`                         | Available      | Compute gas limited to 60,000,000.                                                              |
| `eth_feeHistory`                          | Available      | Block range limited to 256.                                                                     |
| `eth_gasPrice`                            | Available      |                                                                                                 |
| `eth_getBalance`                          | Available      |                                                                                                 |
| `eth_getBlockByHash`                      | Available      |                                                                                                 |
| `eth_getBlockByNumber`                    | Available      |                                                                                                 |
| `eth_getBlockReceipts`                    | Available      |                                                                                                 |
| `eth_getBlockTransactionCountByHash`      | Available      |                                                                                                 |
| `eth_getBlockTransactionCountByNumber`    | Available      |                                                                                                 |
| `eth_getCode`                             | Available      |                                                                                                 |
| `eth_getCodeByHash`                       | Available      | MegaETH-specific.                                                                               |
| `eth_getFilterChanges`                    | Unavailable    | The public endpoint returns `-32601`.                                                           |
| `eth_getFilterLogs`                       | Unavailable    | The public endpoint returns `-32601`.                                                           |
| `eth_getHeaderByHash`                     | Available      | MegaETH-specific.                                                                               |
| `eth_getHeaderByNumber`                   | Available      | MegaETH-specific.                                                                               |
| `eth_getLogs`                             | Available      |                                                                                                 |
| `eth_getLogsWithCursor`                   | Unavailable    | The public endpoint returns `-32601`.                                                           |
| `eth_getStorageAt`                        | Available      |                                                                                                 |
| `eth_getTransactionByBlockHashAndIndex`   | Unavailable    | The public endpoint returns `-32601`.                                                           |
| `eth_getTransactionByBlockNumberAndIndex` | Unavailable    | The public endpoint returns `-32601`.                                                           |
| `eth_getTransactionByHash`                | Available      |                                                                                                 |
| `eth_getTransactionCount`                 | Available      |                                                                                                 |
| `eth_getTransactionReceipt`               | Available      |                                                                                                 |
| `eth_getUncleByBlockHashAndIndex`         | Available      | Returns `null` for valid MegaETH blocks.                                                        |
| `eth_getUncleByBlockNumberAndIndex`       | Available      | Returns `null` for valid MegaETH blocks.                                                        |
| `eth_getUncleCountByBlockHash`            | Available      | Returns `0x0` for valid MegaETH blocks.                                                         |
| `eth_getUncleCountByBlockNumber`          | Available      | Returns `0x0` for valid MegaETH blocks.                                                         |
| `eth_getWithdrawalProof`                  | Available      | OP Stack withdrawal proof method.                                                               |
| `eth_maxPriorityFeePerGas`                | Available      |                                                                                                 |
| `eth_mining`                              | Unavailable    | The node reports the method as unimplemented.                                                   |
| `eth_newBlockFilter`                      | Unavailable    | The public endpoint returns `-32601`.                                                           |
| `eth_newFilter`                           | Unavailable    | The public endpoint returns `-32601`.                                                           |
| `eth_newPendingTransactionFilter`         | Unavailable    | The public endpoint returns `-32601`.                                                           |
| `eth_protocolVersion`                     | Available      | Legacy compatibility method.                                                                    |
| `eth_sendRawTransaction`                  | Available      |                                                                                                 |
| `eth_sendRawTransactionSync`              | Available      | MegaETH-specific synchronous receipt method.                                                    |
| `eth_subscribe`                           | WebSocket only | Supports `logs`, `stateChanges`, `miniBlocks`, and `newHeads`.                                  |
| `eth_syncing`                             | Available      |                                                                                                 |
| `eth_uninstallFilter`                     | Available      | Returns `false` when the filter ID does not exist.                                              |
| `eth_unsubscribe`                         | WebSocket only |                                                                                                 |
| `mega_getBlockWitness`                    | Available      | MegaETH-specific.                                                                               |
| `mega_getWithdrawalProof`                 | Available      | Alias routed to `eth_getWithdrawalProof`.                                                       |
| `mega_outputAtBlock`                      | Available      | OP Stack output-root method.                                                                    |
| `net_listening`                           | Available      |                                                                                                 |
| `net_peerCount`                           | Available      |                                                                                                 |
| `net_version`                             | Available      |                                                                                                 |
| `optimism_outputAtBlock`                  | Available      | Alias of `mega_outputAtBlock`.                                                                  |
| `realtime_sendRawTransaction`             | Available      | MegaETH-specific synchronous receipt method.                                                    |
| `trace_block`                             | Unavailable    | The public endpoint returns `-32601`.                                                           |
| `trace_call`                              | Unavailable    | The public endpoint returns `-32601`.                                                           |
| `trace_transaction`                       | Unavailable    | The public endpoint returns `-32601`.                                                           |
| `web3_clientVersion`                      | Available      |                                                                                                 |

## Rate Limiting

Read methods on the public RPC endpoint are rate-limited **per IP address** in **fixed 10-second windows**.
Each method belongs to one of four categories, and each category has its own request budget:

| Category | Limit (per 10 s) | Methods                                                                                                                     |
| -------- | ---------------- | --------------------------------------------------------------------------------------------------------------------------- |
| Instant  | 2,000            | `eth_chainId`, `eth_blockNumber`, `net_version`, `eth_accounts`, `web3_clientVersion`, `eth_getBalance`, `eth_getStorageAt` |
| Simple   | 500              | Block/transaction queries and all other read methods not listed in another category                                         |
| Compute  | 200              | `eth_call`, `eth_callMany`, `eth_estimateGas`, `eth_createAccessList`, `debug_trace*`, `trace_*`                            |
| IO-heavy | 200              | `eth_getLogs`, `eth_getBlockReceipts`                                                                                       |

Additional notes:

- Transaction submission methods (`eth_sendRawTransaction`, `eth_sendRawTransactionSync`, `realtime_sendRawTransaction`) are not subject to these read rate limits.
- Cache hits still consume the method's per-category budget.
- `eth_callMany` consumes one Compute-category request per inner transaction, not one per HTTP request.
- A rate-limited request is rejected with HTTP `429` and RPC error `-32005` (`Rate limit exceeded`) — see [Error Codes](rpc/error-codes.md). Reduce request frequency, or use batching or WebSocket subscriptions to lower the request count.

## Request Body Limits

The public RPC endpoint caps the size of the request body, and the cap depends on the method being called:

| Method class                                                                                                   | Maximum body size |
| -------------------------------------------------------------------------------------------------------------- | ----------------- |
| Transaction submission (`eth_sendRawTransaction`, `eth_sendRawTransactionSync`, `realtime_sendRawTransaction`) | 2.5 MiB           |
| Large reads and simulations (`eth_call`, `eth_callMany`, `eth_createAccessList`, `eth_estimateGas`)            | 1.5 MiB           |
| All other methods                                                                                              | 128 KiB           |

The higher limits for simulation methods let you estimate gas for or simulate large contract deployments, whose initcode can exceed the 128 KiB default.
A request whose body exceeds the applicable limit is rejected with HTTP `413` and RPC error `-32099` (`payload too large`) — see [Error Codes](rpc/error-codes.md).

## Response Caching

The public RPC gateway may serve read methods from an internal server-side cache rather than forwarding every request to a node.
Eligibility and lifetime are method-specific: immutable block numbers and hashes can use longer-lived entries, while methods that follow the chain head either use a short-lived cache or bypass it.
Do not assume that two different methods or block tags have the same cache policy.

Two headers on the response are relevant:

- **`Cache-Control: no-store`** — every public response carries this header.
  It is a directive to caches _downstream_ of the gateway (browsers, proxies, CDNs): do not store this response.
  It does not mean the gateway itself computed the response from scratch — the gateway's internal cache is part of the origin, not a downstream cache, so serving from it does not conflict with `no-store`.
- **`X-Workers-Cache-Status`** — reports whether the gateway's internal cache was hit (`HIT`, `MISS`, or other [Cloudflare cache statuses](https://developers.cloudflare.com/cache/concepts/cache-responses/)).
  Use it to understand where a response came from; it has no effect on correctness.

Sending `Cache-Control: no-store` or `no-cache` as a _request_ header does not bypass the internal cache — request cache directives address intermediary caches, not the origin's own caching.
The gateway does not provide a request option that bypasses its internal cache.

## Related Pages

- [Realtime API](realtime-api.md) — use-case guide for streaming data and instant receipts
- [Error Codes](rpc/error-codes.md) — HTTP and RPC error codes with mitigations
