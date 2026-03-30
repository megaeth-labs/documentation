# eth_subscribe

Creates a subscription that pushes events to the client over a WebSocket connection.

## Ethereum Standard

`eth_subscribe(subscriptionType, params?) -> subscriptionId`

This method requires a persistent WebSocket connection. It is not available over HTTP.

## MegaETH Differences

- MegaETH supports two additional subscription types: `miniBlocks` (sub-block updates at ~10 ms granularity) and `stateChanges` (per-mini-block account and storage diffs with optional address filtering).
- Each connection supports a maximum of 5 concurrent subscriptions.
- The connection idles out after 60 seconds without activity. Send an `eth_chainId` request at least every 30 seconds as a keepalive.
- Duplicate subscriptions of the same type on the same connection are rejected.
- Only `eth_subscribe`, `eth_unsubscribe`, `eth_sendRawTransaction`, `eth_sendRawTransactionSync`, and `eth_chainId` are available over WebSocket. Other methods require HTTP.
- Per-IP connection limit is 5. Message rate limit is 5 messages per second per connection.

## Request

Send `params` as `[subscriptionType]` or `[subscriptionType, filter]`.

| Position | Type | Required | Notes |
|---|---|---|---|
| `0` | `string` | Yes | Subscription type; see supported values below |
| `1` | `Object` or `Data[]` | No | Filter object for `logs`; address array for `stateChanges` |

**Supported subscription types:**

| Type | MegaETH-specific | Filter param | Description |
|---|---|---|---|
| `newHeads` | No | — | New block headers as blocks are sealed |
| `logs` | No | Yes | Log entries matching an optional address and topic filter |
| `newPendingTransactions` | No | Optional `bool` | Pending transaction hashes (`false` / omitted) or full objects (`true`) |
| `syncing` | No | — | Sync status changes |
| `miniBlocks` | Yes | — | Sub-block updates at ~10 ms granularity |
| `stateChanges` | Yes | Optional `Data[]` | Per-mini-block account and storage diffs; pass an address array to filter, or omit for all |

**`logs` filter fields:**

| Field | Type | Required | Notes |
|---|---|---|---|
| `address` | `Data` or `Data[]` | No | One address or up to 20 addresses to match |
| `topics` | `(Data \| Data[] \| null)[]` | No | Up to 4 topic positions; `null` matches any value at that position |

## Response

**On subscribe** — returns a subscription ID:

| Field | Type | Notes |
|---|---|---|
| `result` | [`Data`](../types.md#data) | Subscription ID used to identify pushed events |

**Pushed events** — delivered as `eth_subscription` notifications:

```json
{
  "jsonrpc": "2.0",
  "method": "eth_subscription",
  "params": {
    "subscription": "<subscriptionId>",
    "result": { }
  }
}
```

The shape of `result` depends on the subscription type: a block header for `newHeads`, a log object for `logs`, a transaction hash or object for `newPendingTransactions`, a boolean or sync object for `syncing`, a mini-block object for `miniBlocks`, and a state-change object for `stateChanges`.

Reader notes:

- `newHeads` results include MegaETH-specific fields `miniBlockCount` and `miniBlockOffset` alongside the standard block header fields.
- `miniBlocks` results use `snake_case` field names (e.g. `block_number`, `mini_block_number`), not the `camelCase` convention used by standard Ethereum subscriptions.

## Common Errors

| Code | When it usually happens | What to do |
|---|---|---|
| `-32602` | Unknown or disabled subscription type, or an invalid `logs` filter | Fix the subscription type or filter before retrying |
| `-32600` | A subscription of the same type (or same `logs` filter) already exists on this connection | Unsubscribe first with `eth_unsubscribe`, then resubscribe |
| `-32005` | The per-connection subscription limit (5) or the server-side capacity limit has been reached | Unsubscribe from unused subscriptions before adding new ones |

See also [Error reference](../errors.md).

## Example

### newHeads

```bash
wscat -c wss://mainnet.megaeth.com/ws \
# wait for connection
{"jsonrpc":"2.0","id":1,"method":"eth_subscribe","params":["newHeads"]}
```

```json
{"jsonrpc":"2.0","id":1,"result":"0xaec58cfc2dc41f873fc37d6c871230c1"}
```

Pushed events arrive as `eth_subscription` notifications:

```json
{
  "jsonrpc": "2.0",
  "method": "eth_subscription",
  "params": {
    "subscription": "0xaec58cfc2dc41f873fc37d6c871230c1",
    "result": {
      "number": "0xb80319",
      "hash": "0x1318d1123d8ea6a86c8f7b231bc844c747d494cd338848108ea78cbf3361d7bd",
      "parentHash": "0x4d763feda26e3dcd6b249e16e1b348772b8b069e12bff7af16ba11862306db72",
      "miner": "0x4200000000000000000000000000000000000011",
      "timestamp": "0x69ca28ec",
      "gasLimit": "0x2540be400",
      "gasUsed": "0x66b213",
      "baseFeePerGas": "0xf4240",
      "stateRoot": "0x3af0ce356d69e532bb42b711626ee718301a422d06e8ffb562e18d49420c7001",
      "receiptsRoot": "0x1d0e59dbd9ef816cd9fff882f75a0b6ceff6bd1c13aff6afe371744ca1b506bf",
      "transactionsRoot": "0x590f1a7433a7b7ff894414155bbdccb7ac95d72ba6def182ec19be5bd2a23a36",
      "withdrawalsRoot": "0xddd6dcaf75eeb81fb4701c2a39b3132bd60bf9602e2fcbe5852f5d07e14c8084",
      "miniBlockCount": "0x64",
      "miniBlockOffset": "0x456f4f30",
      "size": "0x3ad2"
    }
  }
}
```

### miniBlocks

```bash
wscat -c wss://mainnet.megaeth.com/ws \
# wait for connection
{"jsonrpc":"2.0","id":1,"method":"eth_subscribe","params":["miniBlocks"]}
```

```json
{"jsonrpc":"2.0","id":1,"result":"0x356680421a092c5664549df8c6c8cb80"}
```

Pushed events arrive as `eth_subscription` notifications:

```json
{
  "jsonrpc": "2.0",
  "method": "eth_subscription",
  "params": {
    "subscription": "0x356680421a092c5664549df8c6c8cb80",
    "result": {
      "block_number": "0xb80336",
      "block_timestamp": "0x69ca2909",
      "index": "0xb",
      "mini_block_number": "0x456f5a6b",
      "mini_block_timestamp": "0x64e38f8980f50",
      "gas_used": "0x0",
      "transactions": [],
      "receipts": []
    }
  }
}
```

### stateChanges

Subscribe to state changes for specific addresses (or omit the filter for all):

```bash
wscat -c wss://mainnet.megaeth.com/ws \
# wait for connection
{"jsonrpc":"2.0","id":1,"method":"eth_subscribe","params":["stateChanges",["0xaa000000000000000000000000000000000000aa"]]}
```

```json
{"jsonrpc":"2.0","id":1,"result":"0x9ce59a13059e417087c02d3236a0b1cc"}
```

Each pushed event contains the updated nonce, balance, and any changed storage slots for one account:

```json
{
  "jsonrpc": "2.0",
  "method": "eth_subscription",
  "params": {
    "subscription": "0x9ce59a13059e417087c02d3236a0b1cc",
    "result": {
      "address": "0xaa000000000000000000000000000000000000aa",
      "nonce": "0x5",
      "balance": "0xde0b6b3a7640000",
      "storage": {}
    }
  }
}
```
