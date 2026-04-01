# eth_accounts

Returns a list of addresses controlled by the RPC node.

## Parameters

None.

## Returns

| Field | Type | Notes |
|---|---|---|
| `result` | `Address[]` | Accounts controlled by the RPC node; always empty on public endpoints |

## Errors

Standard JSON-RPC errors only. See [Error reference](../errors.md).

## Example

```bash
curl -sS https://mainnet.megaeth.com/rpc \
  -H 'content-type: application/json' \
  --data '{"jsonrpc":"2.0","id":41,"method":"eth_accounts","params":[]}'
```

```json
{"jsonrpc":"2.0","id":41,"result":[]}
```
