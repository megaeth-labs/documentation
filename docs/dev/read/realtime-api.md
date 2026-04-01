---
description: MegaETH Realtime API — how to use MegaETH's low-latency extensions to Ethereum JSON-RPC for real-time data access.
---

# Realtime API

MegaETH executes transactions as soon as they arrive at the sequencer and emits execution results within ~10 milliseconds.
The Realtime API exposes these results through extensions to Ethereum JSON-RPC, so your application can react to on-chain events with minimal latency.

On a standard EVM chain, query methods like `eth_getBalance` or `eth_getTransactionReceipt` reflect state as of the most recent block — produced every few seconds.
On MegaETH, these same methods reflect state as of the most recent [mini-block](../../mini-block.md) — produced every ~10ms.
No special parameters are needed; using `latest` or `pending` as the block tag automatically queries against the most recent mini-block.

{% hint style="info" %}
The Realtime API is an evolving standard.
Additional functionality will be added based on feedback.
{% endhint %}

## Available Methods

| Method | What it does | Reference |
| ------ | ------------ | --------- |
| [`eth_subscribe`](rpc/eth_subscribe.md) | Stream logs, state changes, mini-blocks, and block headers over WebSocket | [Full reference](rpc/eth_subscribe.md) |
| [`realtime_sendRawTransaction`](rpc/realtime_sendRawTransaction.md) | Submit a transaction and get the receipt back in one call — no polling | [Full reference](rpc/realtime_sendRawTransaction.md) |
| [`eth_callAfter`](rpc/eth_callAfter.md) | Run `eth_call` after a prior transaction confirms (nonce-gated) | [Full reference](rpc/eth_callAfter.md) |
| [`eth_getLogsWithCursor`](rpc/eth_getLogsWithCursor.md) | Paginated log queries for large result sets | [Full reference](rpc/eth_getLogsWithCursor.md) |

The following standard Ethereum methods also return real-time results on MegaETH — they query against the latest mini-block automatically when called with `latest` or `pending`:

| Method | What it does |
| ------ | ------------ |
| `eth_getBalance` | Account balance |
| `eth_getStorageAt` | Contract storage slot |
| `eth_getTransactionCount` | Account nonce |
| `eth_getCode` | Contract bytecode |
| `eth_call` | Simulate a call |
| `eth_callMany` | Simulate multiple calls |
| `eth_createAccessList` | Generate an access list |
| `eth_estimateGas` | Estimate gas |
| `eth_getTransactionByHash` | Transaction by hash |
| `eth_getTransactionReceipt` | Transaction receipt |

## Use Cases

### Instant transaction confirmation

**Problem:** Your dapp submits a transaction and needs the receipt immediately — polling `eth_getTransactionReceipt` adds latency and complexity.

**Solution:** Use [`realtime_sendRawTransaction`](rpc/realtime_sendRawTransaction.md).
It submits the transaction and blocks until the receipt is available (up to 10 seconds), returning it in a single round-trip.
Drop-in replacement for `eth_sendRawTransaction`.

### Streaming events for a live UI

**Problem:** Your frontend needs to update in real time as swaps, transfers, or game actions happen on-chain.

**Solution:** Subscribe to [`logs`](rpc/eth_subscribe.md#logs) over WebSocket with `fromBlock` and `toBlock` set to `"pending"`.
Logs arrive within ~10ms of execution — fast enough for live trading dashboards, game UIs, and notification systems.
Filter by contract address and topics to receive only the events you care about.

### Monitoring account state changes

**Problem:** You need to track balance or storage changes for specific accounts in real time (e.g., a liquidation bot watching collateral ratios).

**Solution:** Subscribe to [`stateChanges`](rpc/eth_subscribe.md#statechanges) with the account addresses you want to monitor.
Each notification includes the updated balance, nonce, and any storage slots that changed.

### Building a block explorer or indexer

**Problem:** You need every transaction and receipt as soon as it's executed, not when the next EVM block is sealed.

**Solution:** Subscribe to [`miniBlocks`](rpc/eth_subscribe.md#miniblocks).
Each notification contains the full set of transactions and receipts for that mini-block.

### Chaining dependent transactions

**Problem:** You send an approval transaction and then need to simulate the follow-up swap — but `eth_call` might execute before the approval confirms.

**Solution:** Use [`eth_callAfter`](rpc/eth_callAfter.md).
It waits for the sender's nonce to reach a target value (indicating the prior transaction has confirmed), then executes the call.
This avoids race conditions between approval and swap simulation.

### Querying large log ranges

**Problem:** `eth_getLogs` fails or times out when the block range is too large.

**Solution:** Use [`eth_getLogsWithCursor`](rpc/eth_getLogsWithCursor.md).
When the server hits its resource limit, it returns a partial result with a cursor.
Pass the cursor in the next request to continue from where you left off.

## How It Works

On standard EVM chains, query methods reflect state as of the most recent EVM block (produced every ~1 second on MegaETH, longer on other chains).
On MegaETH, the Realtime API queries against the most recent mini-block instead — produced every ~10ms.

This means `eth_getBalance`, `eth_getTransactionReceipt`, `eth_call`, and other read methods return up-to-date results without any special parameters.
Use `latest` or `pending` as the block tag and you get mini-block-level freshness automatically.

Mini-blocks carry the same preconfirmation guarantee as EVM blocks.
The sequencer treats them identically — results returned by the Realtime API are not "tentative" or "unconfirmed."

### Example: real-time balance query

At time T, Alice has 10 ETH.
At T+100ms, she sends 1 ETH to Bob — the transaction is packaged into a mini-block at T+110ms.

- Bob calls `eth_getBalance(alice, "latest")` at T+110ms → **9 ETH** (reflects the mini-block).
- Charlie calls `eth_getBalance(alice, "0x64")` (a specific EVM block number) → **10 ETH** (the EVM block hasn't been sealed yet).

## Related Pages

- [Mini-Blocks](../../mini-block.md) — understanding the two block types
- [RPC Reference](overview.md) — full method availability table and rate limiting
