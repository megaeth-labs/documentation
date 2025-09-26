---
title: Public RPC
owners: krabat
---

# Available Methods

| Method                                     | Rate Limit (reqs/s) | Additional Restrictions |
|--------------------------------------------|---------------------|-------------------------|
| `debug_getRawBlock`                        | Unavailable  | |
| `debug_getRawHeader`                       | Unavailable  | |
| `debug_getRawReceipts`                     | Unavailable  | |
| `debug_getRawTransaction`                  | Unavailable  | |
| `debug_replyBlock`                         | Unavailable  | |
| `debug_traceBlock`                         | Unavailable  | |
| `debug_traceBlockByHash`                   | Unavailable  | |
| `debug_traceBlockByNumber`                 | Unavailable  | |
| `debug_traceCall`                          | Unavailable  | |
| `debug_traceCallMany`                      | Unavailable  | |
| `debug_traceTransaction`                   | Unavailable  | |
| `eth_accounts`                             | 5        | |
| `eth_blockNumber`                          | 5        | | 
| `eth_call`                                 | 15       | Gas is limited to 10,000,000. |
| `eth_chainId`                              | 5        | |
| `eth_createAccessList`                     | 5        | |
| `eth_estimateGas`                          | 5        | Gas is limited to 10,000,000. |
| `eth_feeHistory`                           | 5        | |
| `eth_gasPrice`                             | 5        | |
| `eth_getBalance`                           | 15       | |
| `eth_getBlockByHash`                       | 5        | | 
| `eth_getBlockByNumber`                     | 5        | |
| `eth_getBlockReceipts`                     | Unavailable  | |
| `eth_getBlockTransactionCountByHash`       | 5        | |
| `eth_getBlockTransactionCountByNumber`     | 15       | |
| `eth_getCode`                              | 5        | |
| `eth_getFilterChanges`                     | 5        | |
| `eth_getFilterLogs`                        | 5        | |
| `eth_getLogs`                              | 5        | |
| `eth_getLogsWithCursor`                    | Unavailable  | |
| `eth_getStorageAt`                         | 5        | |
| `eth_getTransactionByBlockHashAndIndex`    | 5        | |
| `eth_getTransactionByBlockNumberAndIndex`  | 5        | |
| `eth_getTransactionByHash`                 | 5        | |
| `eth_getTransactionCount`                  | 5        | |
| `eth_getTransactionReceipt`                | 5        | |
| `eth_getUncleByBlockHashAndIndex`          | Unavailable  | |
| `eth_getUncleByBlockNumberAndIndex`        | Unavailable  | |
| `eth_getUncleCountByBlockHash`             | 5        | |
| `eth_getUncleCountByBlockNumber`           | 5        | |
| `eth_maxPriorityFeePerGas`                 | 5        | |
| `eth_mining`                               | Unavailable  | |
| `eth_newBlockFilter`                       | 5        | |
| `eth_newFilter`                            | 5        | |
| `eth_newPendingTransactionFilter`          | 5        | |
| `eth_protocolVersion`                      | 30       | |
| `eth_sendRawTransaction`                   | 30       | |
| `eth_sendTransaction`                      | Unavailable  | |
| `eth_sign`                                 | Unavailable  | |
| `eth_signTransaction`                      | Unavailable  | |
| `eth_signTypedData`                        | Unavailable  | |
| `eth_subscribe`                            | 5        | Only available over WebSocket. |
| `eth_syncing`                              | 5        | |
| `eth_uninstallFilter`                      | 5        | |
| `eth_unsubscribe`                          | 5        | |
| `net_listening`                            | 30       | |
| `net_peerCount`                            | 30       | |
| `net_version`                              | 30       | |
| `realtime_sendRawTransaction`              | 30       | |
| `trace_block`                              | Unavailable  | |
| `trace_call`                               | Unavailable  | |
| `trace_callMany`                           | Unavailable  | |
| `trace_get`                                | Unavailable  | |
| `trace_rawTransaction`                     | Unavailable  | |
| `trace_replayBlockTransactions`            | Unavailable  | |
| `trace_replayTransaction`                  | Unavailable  | |
| `trace_transaction`                        | Unavailable  | |
| `txpool_content`                           | Unavailable  | |
| `txpool_contentFrom`                       | Unavailable  | |
| `txpool_inspect`                           | Unavailable  | |
| `txpool_status`                            | Unavailable  | |
| `web3_clientVersion`                       | 5        | |

