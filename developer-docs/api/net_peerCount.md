# net_peerCount

Returns the number of peers currently connected to the node.

## Parameters

None.

## Returns

| Field | Type | Notes |
|---|---|---|
| `result` | `Quantity` | Number of connected peers |

## Errors

Standard JSON-RPC errors only. See [Error reference](../errors.md).

## Example

```bash
curl -sS https://mainnet.megaeth.com/rpc \
  -H 'content-type: application/json' \
  --data '{"jsonrpc":"2.0","id":1,"method":"net_peerCount","params":[]}'
```

```json
{"jsonrpc":"2.0","id":1,"result":"0x4"}
```
