---
description: eth_subscribe — WebSocket subscriptions for real-time logs, state changes, mini-blocks, and block headers on MegaETH.
---

# eth\_subscribe

Creates a WebSocket subscription that streams data as mini-blocks are produced.
This is the lowest-latency way to receive transaction results — logs, state changes, and block contents arrive within ~10ms of execution.

Call `eth_unsubscribe` with the subscription ID when a subscription is no longer needed.

{% hint style="info" %}
WebSocket connections require periodic client activity to remain open.
Send `eth_chainId` at least once every 30 seconds to keep the connection alive.
Idle connections may be closed by the server.
{% endhint %}

## Subscription Types

### `logs`

Streams event logs as transactions are packaged into mini-blocks.
Set both `fromBlock` and `toBlock` to `"pending"` for real-time delivery.

**Parameters:**

| Field | Type | Required | Notes |
| ----- | ---- | -------- | ----- |
| `fromBlock` | `BlockTag` | No | Set to `"pending"` for real-time logs |
| `toBlock` | `BlockTag` | No | Set to `"pending"` for real-time logs |
| `address` | `Data` \| `Data[]` | No | Contract address(es) to filter |
| `topics` | `Data[]` | No | Position-sensitive topic filter |

**Example:**

```json
{
  "jsonrpc": "2.0",
  "id": 1,
  "method": "eth_subscribe",
  "params": [
    "logs",
    {
      "address": "0x8320fe7702b96808f7bbc0d4a888ed1468216cfd",
      "topics": ["0xd78a0cb8bb633d06981248b816e7bd33c2a35a6089241d099fa519e361cab902"],
      "fromBlock": "pending",
      "toBlock": "pending"
    }
  ]
}
```

Each notification uses the same schema as `eth_getLogs`.

### `stateChanges`

Streams account state changes as transactions are packaged into mini-blocks.
Takes a list of account addresses to monitor.

**Parameters:**

| Position | Type | Required | Notes |
| -------- | ---- | -------- | ----- |
| `0` | `Data[]` | Yes | List of account addresses to monitor |

**Example:**

```json
{
  "jsonrpc": "2.0",
  "id": 1,
  "method": "eth_subscribe",
  "params": [
    "stateChanges",
    ["0x2ef038991d64c72646d4f06ba78d93f4f1654e3f"]
  ]
}
```

**Notification schema:**

| Field | Type | Notes |
| ----- | ---- | ----- |
| `address` | `Data` (20 bytes) | Account address |
| `nonce` | `Number` | Latest nonce |
| `balance` | `Quantity` | Latest balance |
| `storage` | `Object` | Changed storage slots (slot → value) |

**Example notification:**

```json
{
  "address": "0x2ef038991d64c72646d4f06ba78d93f4f1654e3f",
  "nonce": 1,
  "balance": "0x16345785d8a0000",
  "storage": {
    "0xb6318d15e99499c465cc5e3d630975bf37b5641a8beb2614b018219310f4ea12": "0x68836e425f5",
    "0xbf0f571b7368c19b53ab5ef0ff767ed8e0aef55a462778a6119b7871b017ce8f": "0x71094412456b0"
  }
}
```

### `miniBlocks`

Streams mini-blocks as they are produced by the sequencer.

**Parameters:** None.

**Example:**

```json
{
  "jsonrpc": "2.0",
  "id": 1,
  "method": "eth_subscribe",
  "params": ["miniBlocks"]
}
```

**Notification schema:**

| Field | Type | Notes |
| ----- | ---- | ----- |
| `block_number` | `Quantity` | EVM block number that this mini-block belongs to |
| `block_timestamp` | `Quantity` | EVM block timestamp |
| `index` | `Quantity` | Index of this mini-block within the EVM block |
| `mini_block_number` | `Quantity` | Global mini-block height |
| `mini_block_timestamp` | `Quantity` | Creation timestamp (Unix microseconds) |
| `gas_used` | `Quantity` | Gas consumed in this mini-block |
| `transactions` | `Transaction[]` | Transactions (same schema as `eth_getTransactionByHash`) |
| `receipts` | `Receipt[]` | Receipts (same schema as `eth_getTransactionReceipt`) |

### `newHeads`

Streams EVM block headers as they are sealed.
Standard Ethereum subscription — works the same as on other EVM chains.
On MegaETH, headers include an additional `miniBlockCount` field.

**Parameters:** None.

**Example:**

```json
{
  "jsonrpc": "2.0",
  "id": 1,
  "method": "eth_subscribe",
  "params": ["newHeads"]
}
```

## Errors

| Code | Cause | Fix |
| ---- | ----- | --- |
| `-32602` | Invalid subscription type or malformed parameters | Fix the request |
| `-32000` | WebSocket connection required | Use a WebSocket endpoint, not HTTP |

See also [Error reference](error-codes.md).
