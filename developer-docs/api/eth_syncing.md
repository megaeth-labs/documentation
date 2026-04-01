# eth_syncing

Returns whether the node is currently syncing.

## Parameters

None.

## Returns

| Value | Condition |
|---|---|
| `false` | Node is fully synced |
| `SyncProgress` object | Node is still syncing |

When syncing, the result contains:

| Field | Type | Notes |
|---|---|---|
| `startingBlock` | `Quantity` | Sync start point |
| `currentBlock` | `Quantity` | Current progress |
| `highestBlock` | `Quantity` | Target block |

## Errors

Standard JSON-RPC errors only. See [Error reference](../errors.md).

## Example

```bash
curl -sS https://mainnet.megaeth.com/rpc \
  -H 'content-type: application/json' \
  --data '{"jsonrpc":"2.0","id":1,"method":"eth_syncing","params":[]}'
```

```json
{
  "jsonrpc": "2.0",
  "id": 1,
  "result": false
}
```

When syncing:

```json
{
  "jsonrpc": "2.0",
  "id": 1,
  "result": {
    "startingBlock": "0x0",
    "currentBlock": "0xaeb3d0",
    "highestBlock": "0xaeb3d6"
  }
}
```
