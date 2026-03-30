# net_listening

Returns whether the node is accepting incoming connections.

## Ethereum Standard

`net_listening() -> bool`

## MegaETH Differences

- Always returns `true` on the public endpoint regardless of actual peer connectivity.

## Request

No parameters.

## Response

| Field | Type | Notes |
|---|---|---|
| `result` | `bool` | Fixed value `true` |

## Example

```bash
curl -sS https://mainnet.megaeth.com/rpc \
  -H 'content-type: application/json' \
  --data '{"jsonrpc":"2.0","id":1,"method":"net_listening","params":[]}'
```

```json
{"jsonrpc":"2.0","id":1,"result":true}
```
