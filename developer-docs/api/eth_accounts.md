# eth_accounts

Returns the accounts controlled by the RPC node.

`eth_accounts() -> Address[]` — no parameters.

## MegaETH Differences

- On public MegaETH endpoints, this always returns `[]`.

## Response

| Field | Type | Notes |
|---|---|---|
| `result` | [`Address`](../types.md#address)`[]` | Accounts controlled by the RPC node |

For error handling, see [Error reference](../errors.md).

## Example

```bash
curl -sS https://mainnet.megaeth.com/rpc \
  -H 'content-type: application/json' \
  --data '{"jsonrpc":"2.0","id":41,"method":"eth_accounts","params":[]}'
```

```json
{"jsonrpc":"2.0","id":41,"result":[]}
```
