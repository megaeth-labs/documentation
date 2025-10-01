---
title: RPC
owners: krabat
---

# Available Methods

| Method                                     | Availability | Additional Restrictions |
|--------------------------------------------|--------------|-------------------------|
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
| `eth_accounts`                             | Available    | |
| `eth_blockNumber`                          | Available    | | 
| `eth_call`                                 | Available    | Gas is limited to 10,000,000. |
| `eth_chainId`                              | Available    | |
| `eth_createAccessList`                     | Available    | Gas is limited to 10,000,000. |
| `eth_estimateGas`                          | Available    | Gas is limited to 10,000,000. |
| `eth_feeHistory`                           | Available    | Block range is limited to 10,000. |
| `eth_gasPrice`                             | Available    | |
| `eth_getBalance`                           | Available    | |
| `eth_getBlockByHash`                       | Available    | Full block is disabled. | 
| `eth_getBlockByNumber`                     | Available    | Full block is disabled. |
| `eth_getBlockReceipts`                     | Unavailable  | |
| `eth_getBlockTransactionCountByHash`       | Available    | |
| `eth_getBlockTransactionCountByNumber`     | Available    | |
| `eth_getCode`                              | Available    | |
| `eth_getFilterChanges`                     | Available    | |
| `eth_getFilterLogs`                        | Available    | |
| `eth_getLogs`                              | Available    | |
| `eth_getLogsWithCursor`                    | Available    | |
| `eth_getStorageAt`                         | Available    | |
| `eth_getTransactionByBlockHashAndIndex`    | Available    | |
| `eth_getTransactionByBlockNumberAndIndex`  | Available    | |
| `eth_getTransactionByHash`                 | Available    | |
| `eth_getTransactionCount`                  | Available    | |
| `eth_getTransactionReceipt`                | Available    | |
| `eth_getUncleByBlockHashAndIndex`          | Available    | |
| `eth_getUncleByBlockNumberAndIndex`        | Available    | |
| `eth_getUncleCountByBlockHash`             | Available    | |
| `eth_getUncleCountByBlockNumber`           | Available    | |
| `eth_maxPriorityFeePerGas`                 | Available    | |
| `eth_mining`                               | Available    | |
| `eth_newBlockFilter`                       | Available    | |
| `eth_newFilter`                            | Available    | |
| `eth_newPendingTransactionFilter`          | Available    | |
| `eth_protocolVersion`                      | Available    | |
| `eth_sendRawTransaction`                   | Available    | |
| `eth_sendTransaction`                      | Unavailable  | |
| `eth_sign`                                 | Unavailable  | |
| `eth_signTransaction`                      | Unavailable  | |
| `eth_signTypedData`                        | Unavailable  | |
| `eth_subscribe`                            | Unavailable  | |
| `eth_syncing`                              | Available    | |
| `eth_uninstallFilter`                      | Available    | |
| `eth_unsubscribe`                          | Available    | |
| `net_listening`                            | Available    | |
| `net_peerCount`                            | Available    | |
| `net_version`                              | Available    | |
| `realtime_sendRawTransaction`              | Available    | |
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
| `web3_clientVersion`                       | Available    | |

# Rate Limiting

All available methods are subject to rate limiting based on two criteria:

- **Compute Unit (CU) Limiting**: Limits the computational cost of requests based on the complexity of the requests.
- **Network Bandwidth Limiting**: Limits the network traffic based on response sizes.