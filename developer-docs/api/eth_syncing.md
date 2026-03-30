# eth_syncing

Returns whether the endpoint is still syncing.

`eth_syncing() -> false | SyncProgress` — no parameters.

## Response

| Shape | Meaning |
|---|---|
| `false` | The endpoint is not currently syncing |
| [`SyncProgress`](../types.md#syncprogress) | Sync progress with `startingBlock`, `currentBlock`, and `highestBlock` |

For error handling, see [Error reference](../errors.md).

## Examples

### Not syncing

```bash
curl -sS https://mainnet.megaeth.com/rpc \
  -H 'content-type: application/json' \
  --data '{"jsonrpc":"2.0","id":1,"method":"eth_syncing","params":[]}'
```

```json
{"jsonrpc":"2.0","id":1,"result":false}
```

### Syncing

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
