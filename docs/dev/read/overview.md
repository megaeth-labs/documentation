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
On top of that, MegaETH introduces four extension methods for even lower-latency workflows:

- [`realtime_sendRawTransaction`](rpc/realtime_sendRawTransaction.md) — submit a transaction and get the receipt back in one call, no polling
- [`eth_subscribe`](rpc/eth_subscribe.md) — stream logs, state changes, mini-blocks, and block headers over WebSocket as they happen
- [`eth_callAfter`](rpc/eth_callAfter.md) — simulate a transaction after a prior one confirms (nonce-gated)
- [`eth_getLogsWithCursor`](rpc/eth_getLogsWithCursor.md) — paginated log queries for large result sets

For use-case-oriented guidance (which method to use for what), see the [Realtime API](realtime-api.md) page.

## Available Methods

{% hint style="info" %}
The table below reflects the **public MegaETH RPC endpoint**.
Methods marked "Managed only" are unavailable on the public endpoint but supported by managed RPC providers such as [Alchemy](https://www.alchemy.com/).
See [Debugging Transactions](../send-tx/debugging.md) for usage of debug methods, and [Tooling](../tooling.md#rpc-providers) for provider options.
{% endhint %}

| Method                                    | Availability   | Additional Restrictions                                           |
| ----------------------------------------- | -------------- | ----------------------------------------------------------------- |
| `debug_getRawBlock`                       | Managed only   |                                                                   |
| `debug_getRawHeader`                      | Managed only   |                                                                   |
| `debug_getRawReceipts`                    | Managed only   |                                                                   |
| `debug_getRawTransaction`                 | Managed only   |                                                                   |
| `debug_replayBlock`                       | Managed only   |                                                                   |
| `debug_traceBlock`                        | Managed only   |                                                                   |
| `debug_traceBlockByHash`                  | Available      |                                                                   |
| `debug_traceBlockByNumber`                | Available      |                                                                   |
| `debug_traceCall`                         | Managed only   |                                                                   |
| `debug_traceCallMany`                     | Managed only   |                                                                   |
| `debug_traceTransaction`                  | Available      |                                                                   |
| `eth_accounts`                            | Available      |                                                                   |
| `eth_blockNumber`                         | Available      |                                                                   |
| `eth_call`                                | Available      | Compute gas limited to 60,000,000.                                |
| `eth_callAfter`                           | Available      | Compute gas limited to 60,000,000. Timeout limited to 60 seconds. |
| `eth_callMany`                            | Available      | Compute gas limited to 60,000,000 per call.                       |
| `eth_chainId`                             | Available      |                                                                   |
| `eth_createAccessList`                    | Available      | Compute gas limited to 60,000,000.                                |
| `eth_estimateGas`                         | Available      | Compute gas limited to 60,000,000.                                |
| `eth_feeHistory`                          | Available      | Block range limited to 256.                                       |
| `eth_gasPrice`                            | Available      |                                                                   |
| `eth_getBalance`                          | Available      |                                                                   |
| `eth_getBlockByHash`                      | Available      |                                                                   |
| `eth_getBlockByNumber`                    | Available      |                                                                   |
| `eth_getBlockReceipts`                    | Available      |                                                                   |
| `eth_getBlockTransactionCountByHash`      | Available      |                                                                   |
| `eth_getBlockTransactionCountByNumber`    | Available      |                                                                   |
| `eth_getCode`                             | Available      |                                                                   |
| `eth_getFilterChanges`                    | Unavailable    |                                                                   |
| `eth_getFilterLogs`                       | Unavailable    |                                                                   |
| `eth_getLogs`                             | Available      |                                                                   |
| `eth_getLogsWithCursor`                   | Managed only   |                                                                   |
| `eth_getStorageAt`                        | Available      |                                                                   |
| `eth_getTransactionByBlockHashAndIndex`   | Available      |                                                                   |
| `eth_getTransactionByBlockNumberAndIndex` | Available      |                                                                   |
| `eth_getTransactionByHash`                | Available      |                                                                   |
| `eth_getTransactionCount`                 | Available      |                                                                   |
| `eth_getTransactionReceipt`               | Available      |                                                                   |
| `eth_getUncleByBlockHashAndIndex`         | Available      |                                                                   |
| `eth_getUncleByBlockNumberAndIndex`       | Available      |                                                                   |
| `eth_getUncleCountByBlockHash`            | Available      |                                                                   |
| `eth_getUncleCountByBlockNumber`          | Available      |                                                                   |
| `eth_maxPriorityFeePerGas`                | Available      |                                                                   |
| `eth_mining`                              | Available      |                                                                   |
| `eth_newBlockFilter`                      | Available      |                                                                   |
| `eth_newFilter`                           | Available      |                                                                   |
| `eth_newPendingTransactionFilter`         | Available      |                                                                   |
| `eth_protocolVersion`                     | Available      |                                                                   |
| `eth_sendRawTransaction`                  | Available      |                                                                   |
| `eth_sendTransaction`                     | Unavailable    | Use `eth_sendRawTransaction` with a signed transaction.           |
| `eth_sign`                                | Unavailable    | Sign client-side.                                                 |
| `eth_signTransaction`                     | Unavailable    | Sign client-side.                                                 |
| `eth_signTypedData`                       | Unavailable    | Sign client-side.                                                 |
| `eth_subscribe`                           | WebSocket only |                                                                   |
| `eth_syncing`                             | Available      |                                                                   |
| `eth_uninstallFilter`                     | Available      |                                                                   |
| `eth_unsubscribe`                         | WebSocket only |                                                                   |
| `net_listening`                           | Available      |                                                                   |
| `net_peerCount`                           | Available      |                                                                   |
| `net_version`                             | Available      |                                                                   |
| `realtime_sendRawTransaction`             | Available      |                                                                   |
| `trace_block`                             | Managed only   |                                                                   |
| `trace_call`                              | Managed only   |                                                                   |
| `trace_callMany`                          | Managed only   |                                                                   |
| `trace_get`                               | Managed only   |                                                                   |
| `trace_rawTransaction`                    | Managed only   |                                                                   |
| `trace_replayBlockTransactions`           | Managed only   |                                                                   |
| `trace_replayTransaction`                 | Managed only   |                                                                   |
| `trace_transaction`                       | Managed only   |                                                                   |
| `txpool_content`                          | Unavailable    |                                                                   |
| `txpool_contentFrom`                      | Unavailable    |                                                                   |
| `txpool_inspect`                          | Unavailable    |                                                                   |
| `txpool_status`                           | Unavailable    |                                                                   |
| `web3_clientVersion`                      | Available      |                                                                   |

## Rate Limiting

All available methods are subject to rate limiting based on two criteria:

- **Compute Unit (CU) Limiting** — limits the computational cost of requests based on their complexity.
- **Network Bandwidth Limiting** — limits the network traffic based on response sizes.

User limits are dynamically updated in response to individual behavior.

## Related Pages

- [Realtime API](realtime-api.md) — use-case guide for streaming data and instant receipts
- [Error Codes](rpc/error-codes.md) — HTTP and RPC error codes with mitigations
