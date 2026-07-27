---
description: eth_subscribe — WebSocket subscriptions for real-time logs, state changes, mini-blocks, and block headers on MegaETH.
---

# eth_subscribe

## Summary

Creates a WebSocket subscription and returns a subscription ID.
MegaETH supports standard log and head subscriptions plus `stateChanges` and `miniBlocks` for real-time mini-block data.

The public method is WebSocket-only. Use [`eth_unsubscribe`](./eth_unsubscribe.md) on the same connection when the subscription is no longer needed.

## Parameters

| Position | Name           | Type            | Required | Description                                                        |
| -------- | -------------- | --------------- | -------- | ------------------------------------------------------------------ |
| `0`      | `subscription` | string          | Yes      | One of `logs`, `stateChanges`, `miniBlocks`, or `newHeads`.        |
| `1`      | `options`      | object or array | Depends  | Filter options for `logs`, or an address array for `stateChanges`. |

### `logs`

The optional filter object accepts:

| Field       | Type                 | Required | Description                                                           |
| ----------- | -------------------- | -------- | --------------------------------------------------------------------- |
| `fromBlock` | block tag            | No       | Set to `pending` with `toBlock` for real-time mini-block logs.        |
| `toBlock`   | block tag            | No       | Set to `pending` with `fromBlock` for real-time mini-block logs.      |
| `address`   | address or address[] | No       | Emitting contract address or addresses.                               |
| `topics`    | array                | No       | Position-sensitive topic filter; nested arrays express OR conditions. |

### `stateChanges`

The second parameter is a required array of account addresses to monitor.

### `miniBlocks`

No second parameter is required.

### `newHeads`

No second parameter is required.

## Result

The initial response contains a connection-scoped subscription ID as `DATA`.
Subsequent notifications use `eth_subscription` and include that ID plus a `result` payload.

Payloads depend on the subscription type:

- `logs` uses the same log object schema as [`eth_getLogs`](./eth_getLogs.md).
- `stateChanges` returns an account address, numeric nonce, balance quantity, and changed storage slots.
- `miniBlocks` returns the EVM block number and timestamp, mini-block index and global height, microsecond timestamp, gas used, transactions, receipts, roots, and the sequencer signature when available.
- `newHeads` returns a block header and includes MegaETH's additional `miniBlockCount` field.

Notifications are not replayed automatically after a connection closes. Reconnect and create a new subscription when continuity is required.

## MegaETH Behavior

### Ethereum Standard

Ethereum WebSocket providers commonly implement `eth_subscribe` for `logs` and `newHeads`, although subscriptions are transport extensions rather than HTTP execution-API methods.
Subscription IDs and delivery are scoped to the WebSocket connection.

### MegaETH Node Behavior

MegaETH adds `stateChanges` and `miniBlocks`.
These expose state and receipt data as mini-blocks are produced, while `newHeads` follows sealed EVM blocks and adds `miniBlockCount`.
For real-time log delivery, both log-range tags should be `pending`.

### MegaETH Public Gateway

The public gateway accepts this method only over `wss://mainnet.megaeth.com/ws`.
It supports `logs`, `stateChanges`, `miniBlocks`, and `newHeads`, tracks ownership per connection, and requires periodic client activity; sending a lightweight request such as `eth_chainId` at least every 30 seconds prevents idle closure.

## Errors

The `| Scope |` column distinguishes method failures from gateway policy errors.

| Code     | Scope            | Message                       | When it happens                                                       |
| -------- | ---------------- | ----------------------------- | --------------------------------------------------------------------- |
| `-32602` | Method           | Invalid params                | The subscription type or its filter/options are malformed.            |
| `-32000` | Transport/policy | WebSocket connection required | The method is sent over HTTP instead of a WebSocket connection.       |
| `-32601` | Transport/policy | Method not found              | The requested subscription type is not enabled by the public gateway. |

See also [Error Codes](./error-codes.md).

## Examples

Endpoint: `wss://mainnet.megaeth.com/ws` (WebSocket)

Capture date: July 24, 2026

Outcome: success

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

## Sources

- Spec: EIP-1474 for JSON-RPC framing; subscriptions are a WebSocket transport extension.
- Code: `git@github.com:megaeth-labs/mega-reth.git @ ab60376631228edab3a6df180f295280bad26e93: crates/megaeth/rpc/src/pubsub.rs`
- Code: `git@github.com:megaeth-labs/mega-rpc.git @ 06aa35aa95d569c227cc25d2aa12834eb0458aa0: workers/src/rpc-gateway/websocket-session.ts`
- Probe: MegaETH Mainnet public WebSocket endpoint, July 24, 2026
