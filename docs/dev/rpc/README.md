---
description: "Complete reference for the 51 JSON-RPC methods available through MegaETH's public HTTP and WebSocket endpoints."
---

# RPC Reference

The public MegaETH gateway exposes 49 HTTP methods and two WebSocket subscription methods.
See [Error Codes](./error-codes.md) for shared JSON-RPC and gateway errors.

## Available Methods

{% hint style="info" %}
The table below reflects the public MegaETH Mainnet endpoint.
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
| `eth_createAccessList`                    | Available      | Routed to the compute pool; no separate 60M compute override is added.                          |
| `eth_estimateGas`                         | Available      | Uses an internal CPU-time limit; the source default is 0.5 seconds.                             |
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
- A rate-limited request is rejected with HTTP `429` and RPC error `-32005` (`Rate limit exceeded`) — see [Error Codes](./error-codes.md). Reduce request frequency, or use batching or WebSocket subscriptions to lower the request count.

## Request Body Limits

The public RPC endpoint caps the size of the request body, and the cap depends on the method being called:

| Method class                                                                                                   | Maximum body size |
| -------------------------------------------------------------------------------------------------------------- | ----------------- |
| Transaction submission (`eth_sendRawTransaction`, `eth_sendRawTransactionSync`, `realtime_sendRawTransaction`) | 2.5 MiB           |
| Large reads and simulations (`eth_call`, `eth_callMany`, `eth_createAccessList`, `eth_estimateGas`)            | 1.5 MiB           |
| All other methods                                                                                              | 128 KiB           |

The higher limits for simulation methods let you estimate gas for or simulate large contract deployments, whose initcode can exceed the 128 KiB default.
A request whose body exceeds the applicable limit is rejected with HTTP `413` and RPC error `-32099` (`payload too large`) — see [Error Codes](./error-codes.md).

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

## Method Reference

## State and simulation

- [`eth_accounts`](./eth_accounts.md)
- [`eth_call`](./eth_call.md)
- [`eth_callMany`](./eth_callMany.md)
- [`eth_createAccessList`](./eth_createAccessList.md)
- [`eth_estimateGas`](./eth_estimateGas.md)
- [`eth_getBalance`](./eth_getBalance.md)
- [`eth_getCode`](./eth_getCode.md)
- [`eth_getCodeByHash`](./eth_getCodeByHash.md)
- [`eth_getStorageAt`](./eth_getStorageAt.md)
- [`eth_getTransactionCount`](./eth_getTransactionCount.md)

## Blocks, transactions, and receipts

- [`eth_blockNumber`](./eth_blockNumber.md)
- [`eth_getBlockByHash`](./eth_getBlockByHash.md)
- [`eth_getBlockByNumber`](./eth_getBlockByNumber.md)
- [`eth_getBlockReceipts`](./eth_getBlockReceipts.md)
- [`eth_getBlockTransactionCountByHash`](./eth_getBlockTransactionCountByHash.md)
- [`eth_getBlockTransactionCountByNumber`](./eth_getBlockTransactionCountByNumber.md)
- [`eth_getHeaderByHash`](./eth_getHeaderByHash.md)
- [`eth_getHeaderByNumber`](./eth_getHeaderByNumber.md)
- [`eth_getTransactionByHash`](./eth_getTransactionByHash.md)
- [`eth_getTransactionReceipt`](./eth_getTransactionReceipt.md)
- [`eth_getUncleByBlockHashAndIndex`](./eth_getUncleByBlockHashAndIndex.md)
- [`eth_getUncleByBlockNumberAndIndex`](./eth_getUncleByBlockNumberAndIndex.md)
- [`eth_getUncleCountByBlockHash`](./eth_getUncleCountByBlockHash.md)
- [`eth_getUncleCountByBlockNumber`](./eth_getUncleCountByBlockNumber.md)
- [`eth_syncing`](./eth_syncing.md)

## Logs and subscriptions

- [`eth_getLogs`](./eth_getLogs.md)
- [`eth_subscribe`](./eth_subscribe.md) — WebSocket only
- [`eth_uninstallFilter`](./eth_uninstallFilter.md)
- [`eth_unsubscribe`](./eth_unsubscribe.md) — WebSocket only

## Fees and transaction submission

- [`eth_feeHistory`](./eth_feeHistory.md)
- [`eth_gasPrice`](./eth_gasPrice.md)
- [`eth_maxPriorityFeePerGas`](./eth_maxPriorityFeePerGas.md)
- [`eth_sendRawTransaction`](./eth_sendRawTransaction.md)
- [`eth_sendRawTransactionSync`](./eth_sendRawTransactionSync.md)
- [`realtime_sendRawTransaction`](./realtime_sendRawTransaction.md)

## Debug methods

- [`debug_getHistoryTransactionCount`](./debug_getHistoryTransactionCount.md)
- [`debug_getRawHeader`](./debug_getRawHeader.md)
- [`debug_traceBlockByHash`](./debug_traceBlockByHash.md)
- [`debug_traceBlockByNumber`](./debug_traceBlockByNumber.md)
- [`debug_traceTransaction`](./debug_traceTransaction.md)

## MegaETH and OP Stack methods

- [`eth_getWithdrawalProof`](./eth_getWithdrawalProof.md)
- [`mega_getBlockWitness`](./mega_getBlockWitness.md)
- [`mega_getWithdrawalProof`](./mega_getWithdrawalProof.md)
- [`mega_outputAtBlock`](./mega_outputAtBlock.md)
- [`optimism_outputAtBlock`](./optimism_outputAtBlock.md)

## Network and client information

- [`eth_chainId`](./eth_chainId.md)
- [`eth_protocolVersion`](./eth_protocolVersion.md)
- [`net_listening`](./net_listening.md)
- [`net_peerCount`](./net_peerCount.md)
- [`net_version`](./net_version.md)
- [`web3_clientVersion`](./web3_clientVersion.md)
