---
description: How to read current state, historical data, transactions, logs, and real-time updates from MegaETH.
---

# Read from MegaETH

MegaETH supports standard Ethereum JSON-RPC reads for accounts, contracts, blocks, transactions, receipts, and logs.
Existing Ethereum libraries work without a MegaETH-specific read API.

The main difference is freshness.
Requests using `latest` or `pending` read from MegaETH's streaming state, which advances as mini-blocks are produced.
You can therefore read state updated within milliseconds without waiting for the next EVM block.

## Choose a read pattern

| Pattern                  | Use it for                                                                           | Starting point                                    |
| ------------------------ | ------------------------------------------------------------------------------------ | ------------------------------------------------- |
| HTTP JSON-RPC            | One-time reads, contract calls, simulations, and historical queries                  | [JSON-RPC](../rpc/README.md)                      |
| WebSocket subscriptions  | Push-based logs, pending transactions, block headers, mini-blocks, and state changes | [Realtime API](realtime-api.md)                   |
| Concrete block selectors | Reproducible reads against a specific EVM block                                      | [Type reference](../rpc/types.md#block-selectors) |

Use HTTP for request-and-response workflows.
Use WebSocket subscriptions when your application needs updates as they happen or wants to avoid polling.

## State freshness and block tags

| Selector                 | Data source                | Behavior                                                             |
| ------------------------ | -------------------------- | -------------------------------------------------------------------- |
| `latest`                 | Streaming state            | Includes state committed by the latest mini-block.                   |
| `pending`                | Streaming state            | Uses the same real-time state view as `latest`.                      |
| `safe`                   | EVM block state            | Reads the latest block considered safe.                              |
| `finalized`              | EVM block state            | Reads the latest finalized block.                                    |
| Hexadecimal block number | Historical EVM block state | Repeats the state view for that block when retained by the endpoint. |

No additional flag or header is required for real-time reads.
Pass `latest` or `pending` to methods that accept a block selector.

Historical availability depends on the serving endpoint's retention.
If an old state query returns code `4444`, see the [Error reference](../rpc/error-codes.md#historical-state-unavailable).

## Public gateway behavior

The public MegaETH endpoint applies operational policies in addition to each method's JSON-RPC contract.
Account for these policies when choosing query size, concurrency, and retry behavior.

| Behavior                    | What to expect                                                                                                                                                                  | Details                                                                                              |
| --------------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | ---------------------------------------------------------------------------------------------------- |
| Rate limiting               | Read methods use per-IP tiers with fixed 10-second windows. A limited request returns HTTP `429` with JSON-RPC code `-32005`.                                                   | [Read rate limits](../rpc/operations-and-limits.md#read-rate-limits)                                 |
| Request and response limits | The default request-body limit is 128 KiB, large reads and simulations allow up to 1.5 MiB, batches contain at most 100 requests, and responses are limited to 50 MiB.          | [HTTP request and response limits](../rpc/operations-and-limits.md#http-request-and-response-limits) |
| Method-specific limits      | Expensive methods such as `eth_call`, `eth_callMany`, `eth_feeHistory`, and `eth_getLogs` have additional execution or result constraints.                                      | [Method-specific limits](../rpc/operations-and-limits.md#method-specific-limits)                     |
| Gateway caching             | Eligible reads may be served from the gateway's internal cache. Cache policy depends on the method and selector, and `Cache-Control: no-store` only controls downstream caches. | [Gateway caching](../rpc/operations-and-limits.md#gateway-caching)                                   |

Use bounded ranges and pagination for large log or historical queries.
Retry `-32005` failures with exponential backoff and jitter instead of immediate repetition.
Inspect `X-Workers-Cache-Status` when you need to determine whether an eligible response came from the gateway cache.

## Common tasks

- Read an account balance with [`eth_getBalance`](../rpc/reference/eth_getBalance.md).
- Read contract storage with [`eth_getStorageAt`](../rpc/reference/eth_getStorageAt.md).
- Execute a read-only contract call with [`eth_call`](../rpc/reference/eth_call.md).
- Look up a transaction or receipt with [`eth_getTransactionByHash`](../rpc/reference/eth_getTransactionByHash.md) and [`eth_getTransactionReceipt`](../rpc/reference/eth_getTransactionReceipt.md).
- Query emitted events with [`eth_getLogs`](../rpc/reference/eth_getLogs.md).
- Stream real-time updates with [`eth_subscribe`](../rpc/reference/eth_subscribe.md).

## Next steps

- [JSON-RPC](../rpc/README.md) explains request framing, shared types, errors, and public gateway limits.
- [RPC Reference](../rpc/reference/README.md) lists method availability and the complete method documentation.
- [Realtime API](realtime-api.md) explains mini-block-level reads and WebSocket subscriptions.
- [Operations and limits](../rpc/operations-and-limits.md) documents rate limits, request limits, caching, and WebSocket limits.
