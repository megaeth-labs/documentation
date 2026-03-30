# Realtime Development Guide

Use this guide when you want to take advantage of MegaETH's sub-second state updates in your application.

On most EVM chains, state advances once per block (2–12 seconds). On MegaETH, state advances every **mini-block (~10 ms)**. This changes how you read state, confirm transactions, and react to on-chain events.

This guide covers:

1. [Why MegaETH Is Realtime](#1-why-megaeth-is-realtime)
2. [Realtime State Reads (HTTP)](#2-realtime-state-reads-http)
3. [Realtime Transaction Confirmation](#3-realtime-transaction-confirmation)
4. [Realtime Event Streaming (WebSocket)](#4-realtime-event-streaming-websocket)
5. [Choosing The Right Realtime Pattern](#5-choosing-the-right-realtime-pattern)

## 1. Why MegaETH Is Realtime

### Blocks And Mini-Blocks

Traditional EVM chains produce one block every few seconds. Between blocks, the chain state does not change. Any read you make returns the state as of the last sealed block.

MegaETH introduces **mini-blocks**. A mini-block is the smallest unit of state advancement on MegaETH:

- The sequencer produces a new mini-block roughly every **10 ms**.
- Each mini-block contains zero or more transactions and their state effects.
- A sealed block (~every 250 ms) aggregates multiple mini-blocks into one Ethereum-compatible block.

```
Block N (sealed, ~250 ms)
├── mini-block 0   ← state updated, immediately queryable
├── mini-block 1   ← state updated, immediately queryable
├── mini-block 2   ← ...
│   ...
└── block sealed   ← standard Ethereum block available
```

### Streaming State

MegaETH keeps the current block's state in memory as a **streaming state overlay**. Every time a mini-block is produced, this overlay is updated.

When you call a standard RPC method such as `eth_getBalance` with `"latest"`, MegaETH reads from this in-memory overlay — not from disk. The result reflects the state as of the most recent mini-block (~10 ms ago), not the most recent sealed block.

This is the core of MegaETH's realtime model: **standard Ethereum RPC methods already return millisecond-fresh state without any special API or WebSocket connection.**

### What This Means For Developers

| On traditional chains | On MegaETH |
|---|---|
| `eth_getBalance("latest")` returns state from the last block (seconds old) | Returns state from the last mini-block (~10 ms old) |
| You poll or subscribe to wait for state changes | State is already fresh when you read it |
| Transaction confirmation takes seconds to minutes | `eth_sendRawTransactionSync` returns a receipt in ~10–100 ms |
| Realtime behavior requires WebSocket subscriptions | HTTP reads are already realtime; WebSocket adds push delivery |

You do not need to rewrite your application to benefit. If you already use standard Ethereum RPC methods, your reads are automatically fresher on MegaETH.

## 2. Realtime State Reads (HTTP)

### Every Standard Method Is Already Realtime

When you call any state-reading method with `"latest"` or `"pending"`, MegaETH resolves it against the in-memory streaming state. This includes:

- [`eth_getBalance`](../api/eth_getBalance.md)
- [`eth_getTransactionCount`](../api/eth_getTransactionCount.md)
- [`eth_getCode`](../api/eth_getCode.md)
- [`eth_getStorageAt`](../api/eth_getStorageAt.md)
- [`eth_call`](../api/eth_call.md)
- [`eth_estimateGas`](../api/eth_estimateGas.md)

There is no special flag or header to enable this. It is the default behavior.

**State freshness by block tag:**

| Block tag | State source | Freshness |
|---|---|---|
| `"latest"` | In-memory streaming state | ~10 ms |
| `"pending"` | In-memory streaming state | ~10 ms |
| `"safe"` | Database | Depends on L1 finality |
| `"finalized"` | Database | Depends on L1 finality |
| Concrete block number | Database | Historical |

### What This Enables

On traditional chains, polling `eth_getBalance` faster than the block time is wasteful — the value cannot change between blocks. On MegaETH, each read returns genuinely fresh state because mini-blocks advance the state every ~10 ms.

This means:

- A wallet can display a balance that is never more than milliseconds stale.
- A DeFi frontend calling `eth_call` to read pool reserves gets the latest reserves, not reserves from seconds ago.
- High-frequency polling is a valid realtime strategy on MegaETH, not a waste of requests.

If you prefer to avoid polling entirely, use the [`stateChanges` WebSocket subscription](#statechanges-account-and-storage-diffs) instead.

### latest vs pending vs Historical

On MegaETH, `"latest"` and `"pending"` both resolve to the streaming state and return the same freshness. Use either for realtime reads.

`"safe"`, `"finalized"`, and concrete block numbers resolve against the database and return historical state. Their freshness depends on L1 finality timing.

## 3. Realtime Transaction Confirmation

### The Traditional Flow

On most EVM chains, confirming a transaction requires multiple steps:

1. Sign and send the transaction with `eth_sendRawTransaction` → get a transaction hash.
2. Poll `eth_getTransactionReceipt` with the hash until it returns a receipt.
3. The receipt arrives after the transaction is included in a sealed block (seconds to minutes).

### The MegaETH Flow

MegaETH offers [`eth_sendRawTransactionSync`](../api/eth_sendRawTransactionSync.md), which combines sending and waiting into one call:

1. Sign and send the transaction with `eth_sendRawTransactionSync`.
2. The call blocks until the transaction is included in a mini-block.
3. The receipt is returned directly — typically in **10–100 ms**.

No polling. No separate receipt lookup. One request, one response.

You can also use the standard `eth_sendRawTransaction` if you prefer the asynchronous pattern. Both are available.

### How To Use It

`eth_sendRawTransactionSync` is a JSON-RPC method. Call it the same way you would call any other RPC method:

```bash
curl -sS https://mainnet.megaeth.com/rpc \
  -H 'content-type: application/json' \
  --data '{
    "jsonrpc": "2.0",
    "id": 1,
    "method": "eth_sendRawTransactionSync",
    "params": ["0xSignedRawTransaction"]
  }'
```

The response contains a full receipt object (status, gas used, logs, block number) instead of a transaction hash. See the [`eth_sendRawTransactionSync` reference](../api/eth_sendRawTransactionSync.md) for the complete response shape and examples.

SDK support varies. Some libraries (such as ethers.js) do not natively support non-standard RPC methods that return a receipt instead of a hash. If your SDK does not support it directly, use a raw `provider.send()` call or a plain HTTP request.

### Timeout Handling

`eth_sendRawTransactionSync` accepts an optional timeout in milliseconds:

```json
{"jsonrpc":"2.0","id":1,"method":"eth_sendRawTransactionSync","params":["0xSignedTx", 3000]}
```

If the transaction is not included before the timeout:

- The call returns an error (code `-32000`).
- **The transaction is not cancelled.** It may still be included in a later mini-block.
- To check, call [`eth_getTransactionReceipt`](../api/eth_getTransactionReceipt.md) with the transaction hash.

Precompute and store the transaction hash before sending so you can always look up the result, regardless of timeout.

## 4. Realtime Event Streaming (WebSocket)

The HTTP methods in section 2 are already realtime: every read returns state from the latest mini-block. WebSocket subscriptions add **push delivery** — the server sends you data the moment it changes, without you having to ask.

Use WebSocket when:

- You need instant notification of changes (not just fresh reads on demand).
- You want to avoid polling entirely.
- You are building a live feed, dashboard, or streaming pipeline.

### Connection Setup

**Endpoints:**

WebSocket uses the same endpoint as HTTP. The gateway routes by the `Upgrade: websocket` header, not by path.

- Mainnet: `wss://mainnet.megaeth.com/rpc`
- Testnet: `wss://carrot.megaeth.com/rpc`

**Limits:**

| Limit | Value |
|---|---|
| Connections per IP | 5 |
| Subscriptions per connection | 5 |
| Idle timeout | 60 seconds |
| Message rate | 5 messages/second/connection |

**Keepalive:** Send an `eth_chainId` request at least every 30 seconds to prevent idle disconnection.

**Available over WebSocket only:** `eth_subscribe`, `eth_unsubscribe`, `eth_sendRawTransaction`, `eth_sendRawTransactionSync`, `eth_chainId`. All other methods require HTTP.

### miniBlocks: Sub-Block Transaction Stream

Subscribes to mini-block updates at ~10 ms granularity. Each pushed event contains the transactions and receipts for one mini-block.

**When to use:** realtime explorer, activity feed, transaction monitoring, TPS tracking.

**Subscribe:**

```json
{"jsonrpc":"2.0","id":1,"method":"eth_subscribe","params":["miniBlocks"]}
```

**Pushed event shape:**

```json
{
  "block_number": "0xb80336",
  "block_timestamp": "0x69ca2909",
  "index": "0xb",
  "mini_block_number": "0x456f5a6b",
  "mini_block_timestamp": "0x64e38f8980f50",
  "gas_used": "0x0",
  "transactions": [],
  "receipts": []
}
```

Note: field names use `snake_case`, not the `camelCase` convention used by standard Ethereum subscriptions.

See the [`eth_subscribe` reference](../api/eth_subscribe.md) for complete examples.

### stateChanges: Account And Storage Diffs

Subscribes to per-mini-block state changes. Each pushed event contains the updated nonce, balance, and changed storage slots for one account.

**When to use:** realtime balance tracking, DEX price feed, contract state monitoring — any time you need to know the moment a specific account's state changes.

**Subscribe (filtered by address):**

```json
{"jsonrpc":"2.0","id":1,"method":"eth_subscribe","params":["stateChanges",["0xAddress1","0xAddress2"]]}
```

**Subscribe (all changes):**

```json
{"jsonrpc":"2.0","id":1,"method":"eth_subscribe","params":["stateChanges"]}
```

**Pushed event shape:**

```json
{
  "address": "0xaa000000000000000000000000000000000000aa",
  "nonce": "0x5",
  "balance": "0xde0b6b3a7640000",
  "storage": {}
}
```

The `storage` object contains only the slots that changed in this mini-block, not the full storage. An empty `storage` object means no storage slots changed (but nonce or balance may have).

See the [`eth_subscribe` reference](../api/eth_subscribe.md) for complete examples.

### logs: Realtime Log Delivery

The standard `logs` subscription works on MegaETH, but events are delivered at mini-block granularity (~10 ms) instead of block granularity.

This means your existing `logs` subscription code works unchanged — it is just faster on MegaETH.

### newHeads: Block-Level Updates

The standard `newHeads` subscription fires when a sealed block is committed (~every 250 ms). On MegaETH, the pushed header includes two additional fields:

- `miniBlockCount` — number of mini-blocks in this block.
- `miniBlockOffset` — global offset of the first mini-block in this block.

Use `newHeads` when you need block-level checkpoints rather than mini-block-level granularity.

### stateChanges vs logs

| | stateChanges | logs |
|---|---|---|
| Granularity | Raw state diffs (nonce, balance, storage slots) | Contract-emitted events |
| Filtering | By address | By address and topics |
| Decoding | You must know the storage layout | Events are ABI-encoded |
| Use when | You need to see all state mutations, including internal ones that don't emit events | You want structured, semantic events |

## 5. Choosing The Right Realtime Pattern

| Scenario | Recommended pattern | Why |
|---|---|---|
| Display a balance in a wallet | HTTP `eth_getBalance` | Already returns ~10 ms fresh state; simplest approach |
| Notify when a balance changes | WebSocket `stateChanges` | Push avoids polling; immediate notification |
| Read DEX pool reserves on demand | HTTP `eth_call` | Each call returns the latest reserves |
| Stream DEX price updates | WebSocket `stateChanges` on pool address | Push-based; captures every reserve change |
| Send a transaction and wait for result | HTTP `eth_sendRawTransactionSync` | One call, one receipt, ~10–100 ms |
| Send a transaction (fire and forget) | HTTP or WS `eth_sendRawTransaction` | Standard async pattern, poll receipt later |
| Live transaction feed | WebSocket `miniBlocks` | Every transaction at ~10 ms granularity |
| React to contract events | WebSocket `logs` | Standard pattern, but delivered at mini-block speed |
| Realtime dashboard | WebSocket `miniBlocks` + `stateChanges` | Full picture of activity and state |
| Block-level checkpoints | WebSocket `newHeads` | Standard Ethereum pattern, fires every ~250 ms |

**Rules of thumb:**

- Start with HTTP. On MegaETH, standard reads are already realtime.
- Add WebSocket subscriptions when you need push delivery or want to avoid polling.
- Use `eth_sendRawTransactionSync` when your user is waiting for a transaction result.
- Use `miniBlocks` when you need the full transaction stream. Use `stateChanges` when you only care about specific accounts.
