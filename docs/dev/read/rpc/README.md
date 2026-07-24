---
description: "Complete reference for the 50 JSON-RPC methods available through MegaETH's public HTTP and WebSocket endpoints."
---

# RPC Reference

The public MegaETH gateway exposes 48 HTTP methods and two WebSocket subscription methods.
This reference is based on the gateway registry, node implementation, and public Mainnet behavior verified on July 24, 2026.

Use the [availability table](../overview.md#available-methods) for recognized methods that are disabled on the public endpoint and for methods offered only by managed providers.
See [Error Codes](./error-codes.md) for shared JSON-RPC and gateway errors.

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
