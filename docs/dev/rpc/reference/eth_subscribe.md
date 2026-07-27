---
description: eth_subscribe — WebSocket subscriptions for block headers, logs, pending transactions, sync status, mini-blocks, and state changes.
---

# eth_subscribe

## Summary

Creates a WebSocket subscription and returns a connection-scoped subscription ID.
MegaETH supports four common Ethereum subscription types and adds `miniBlocks` and `stateChanges`.

Use [`eth_unsubscribe`](./eth_unsubscribe.md) on the same connection when the subscription is no longer needed.
Notifications are not replayed after a connection closes, so reconnecting clients must recreate subscriptions and reconcile missed data.

## Parameters

| Position | Name           | Type                            | Required | Description                                                                                      |
| -------- | -------------- | ------------------------------- | -------- | ------------------------------------------------------------------------------------------------ |
| `0`      | `subscription` | string                          | Yes      | One of `newHeads`, `logs`, `newPendingTransactions`, `syncing`, `miniBlocks`, or `stateChanges`. |
| `1`      | `options`      | object, boolean, or `Address[]` | No       | Shape depends on the subscription type.                                                          |

### `newHeads`

No options are accepted.
Notifications are emitted for sealed EVM block headers.

### `logs`

The optional filter object accepts:

| Field       | Type                     | Required | Description                                                             |
| ----------- | ------------------------ | -------- | ----------------------------------------------------------------------- |
| `fromBlock` | block number or tag      | No       | Set to `pending` or `latest` to receive mini-block log updates.         |
| `toBlock`   | block number or tag      | No       | Upper bound for the filter.                                             |
| `blockHash` | `Hash32`                 | No       | Selects one block and cannot be combined with `fromBlock` or `toBlock`. |
| `address`   | `Address` or `Address[]` | No       | Matches emitting contracts.                                             |
| `topics`    | array                    | No       | Position-sensitive topic filter with OR arrays at individual positions. |

The public gateway accepts at most 20 addresses and four topic positions in one log subscription.
For real-time mini-block logs, set both `fromBlock` and `toBlock` to `pending`.

### `newPendingTransactions`

The optional second parameter is a boolean.
Omit it or pass `false` to receive transaction hashes, or pass `true` to receive full transaction objects.

### `syncing`

No options are accepted.
Notifications report changes in node synchronization status.

### `miniBlocks`

No options are accepted.
Notifications contain transactions and receipts as each mini-block is produced.

### `stateChanges`

The optional second parameter is an array of account addresses.
Omitting the array or passing an empty array subscribes to all changed accounts.
The node defaults to a maximum of 256 addresses in one subscription.

## Result

The initial response returns a subscription ID as `Data`.
Later messages use the `eth_subscription` notification envelope:

```json
{
  "jsonrpc": "2.0",
  "method": "eth_subscription",
  "params": {
    "subscription": "0x...",
    "result": {}
  }
}
```

The `result` shape depends on the subscription type.

### `newHeads` result

The result contains the standard Ethereum block-header fields documented by [`eth_getBlockByNumber`](./eth_getBlockByNumber.md).
When block metadata is available, MegaETH also includes:

| Field             | Type       | Description                                    |
| ----------------- | ---------- | ---------------------------------------------- |
| `txOffset`        | `Quantity` | Transaction offset recorded for the block.     |
| `miniBlockOffset` | `Quantity` | Global offset of the block's first mini-block. |
| `miniBlockCount`  | `Quantity` | Number of mini-blocks in the EVM block.        |
| `signature`       | `Data`     | Sequencer signature recorded for the block.    |

### `logs` result

The result uses the log object documented by [`eth_getLogs`](./eth_getLogs.md).
Mini-block log notifications can contain streaming placeholders until the enclosing EVM block is sealed.

### `newPendingTransactions` result

The result is a transaction `Hash32` by default.
When the second parameter is `true`, the result is the full transaction object documented by [`eth_getTransactionByHash`](./eth_getTransactionByHash.md).

### `syncing` result

The result is `false` when the node is not syncing.
While syncing, it is the progress object documented by [`eth_syncing`](./eth_syncing.md).

### `miniBlocks` result

Mini-block payloads use `snake_case` field names.

| Field                  | Type       | Description                                                                        |
| ---------------------- | ---------- | ---------------------------------------------------------------------------------- |
| `block_number`         | `Quantity` | Number of the enclosing EVM block.                                                 |
| `block_timestamp`      | `Quantity` | Unix timestamp of the enclosing EVM block in seconds.                              |
| `index`                | `Quantity` | Mini-block index within the EVM block.                                             |
| `mini_block_number`    | `Quantity` | Global mini-block number.                                                          |
| `mini_block_timestamp` | `Quantity` | Mini-block Unix timestamp in microseconds.                                         |
| `gas_used`             | `Quantity` | Gas consumed by the mini-block.                                                    |
| `transactions`         | object[]   | Included transaction objects.                                                      |
| `receipts`             | object[]   | Corresponding transaction receipts.                                                |
| `transaction_root`     | `Hash32`   | Transaction trie root for the mini-block.                                          |
| `receipt_root`         | `Hash32`   | Receipt trie root for the mini-block.                                              |
| `signature`            | `Data`     | Sequencer signature, omitted for mini-blocks produced before the signing hardfork. |

### `stateChanges` result

Each notification describes one changed account.

| Field     | Type       | Description                                      |
| --------- | ---------- | ------------------------------------------------ |
| `address` | `Address`  | Changed account.                                 |
| `nonce`   | `Quantity` | Current account nonce.                           |
| `balance` | `Quantity` | Current account balance.                         |
| `storage` | object     | Changed storage slots as `{ key: value }` pairs. |

`storage` contains only slots changed in that mini-block.
An empty object means that the account's nonce or balance changed without a storage change.

## Comparison with Ethereum Standard JSON-RPC

### Ethereum Standard

`eth_subscribe` is a WebSocket transport extension rather than an HTTP Execution API method.
Ethereum clients commonly support `newHeads`, `logs`, `newPendingTransactions`, and `syncing`, with subscription IDs scoped to one connection.

### MegaETH Node Behavior

MegaETH adds `miniBlocks` and `stateChanges` for updates at mini-block granularity.
It enriches `newHeads` with transaction-offset, mini-block, and sequencer-signature metadata.
Setting a log subscription's `fromBlock` to `pending` or `latest` selects the mini-block event stream.

### MegaETH Public Gateway

Use `wss://mainnet.megaeth.com/ws` for Mainnet or `wss://carrot.megaeth.com/ws` for Testnet.
The public gateway allows all six subscription types and limits each connection to five active subscriptions.
Send `eth_chainId` at least every 30 seconds to keep an otherwise idle connection active.
See [Operations and limits](../operations-and-limits.md#websocket-limits) for the remaining WebSocket limits.

## Errors

| Code     | Scope             | When it happens                                                                                        | Action                                                                 |
| -------- | ----------------- | ------------------------------------------------------------------------------------------------------ | ---------------------------------------------------------------------- |
| `-32602` | Method            | The subscription type or options are invalid, or a `stateChanges` address list exceeds the node limit. | Correct the type, option shape, filter, or address count.              |
| `-32005` | Gateway or server | The connection subscription cap or server capacity is exhausted.                                       | Unsubscribe from unused streams or reconnect with fewer subscriptions. |

Calling `eth_subscribe` over HTTP does not create a subscription.
Use a WebSocket connection and inspect the returned JSON-RPC error if a client sends the method to the wrong transport.

See also [Error reference](../error-codes.md).

## Examples

Connect to the Mainnet WebSocket endpoint and subscribe to block headers:

```bash
wscat -c wss://mainnet.megaeth.com/ws
```

```json
{
  "jsonrpc": "2.0",
  "id": 1,
  "method": "eth_subscribe",
  "params": ["newHeads"]
}
```

```json
{
  "jsonrpc": "2.0",
  "id": 1,
  "result": "0xaec58cfc2dc41f873fc37d6c871230c1"
}
```

Subscribe to pending transaction hashes:

```json
{
  "jsonrpc": "2.0",
  "id": 2,
  "method": "eth_subscribe",
  "params": ["newPendingTransactions"]
}
```

Subscribe to all state changes:

```json
{
  "jsonrpc": "2.0",
  "id": 3,
  "method": "eth_subscribe",
  "params": ["stateChanges"]
}
```

Filter state changes by account:

```json
{
  "jsonrpc": "2.0",
  "id": 4,
  "method": "eth_subscribe",
  "params": ["stateChanges", ["0xaa000000000000000000000000000000000000aa"]]
}
```

## Sources

- Spec: [EIP-1474](https://eips.ethereum.org/EIPS/eip-1474) for JSON-RPC framing.
- Code: `git@github.com:megaeth-labs/mega-reth.git @ ab60376631228edab3a6df180f295280bad26e93: crates/megaeth/rpc/src/pubsub.rs`
- Code: `git@github.com:megaeth-labs/mega-rpc.git @ 06aa35aa95d569c227cc25d2aa12834eb0458aa0: workers/src/rpc-gateway/websocket/constants.ts`
- Probe: MegaETH Mainnet public WebSocket endpoint, July 27, 2026.
