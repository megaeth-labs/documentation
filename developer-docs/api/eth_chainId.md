# eth_chainId

Returns the chain ID reported by the endpoint.

`eth_chainId() -> Quantity` — no parameters.

## Response

| Field | Type | Notes |
|---|---|---|
| `result` | [`Quantity`](../types.md#quantity) | Chain ID for the connected network |

| Network | Chain ID (hex) | Chain ID (decimal) |
|---|---|---|
| Mainnet | `0x10e6` | 4326 |
| Testnet | `0x18c7` | 6343 |

For error handling, see [Error reference](../errors.md).

## Example

```bash
curl -sS https://mainnet.megaeth.com/rpc \
  -H 'content-type: application/json' \
  --data '{"jsonrpc":"2.0","id":31,"method":"eth_chainId","params":[]}'
```

```json
{"jsonrpc":"2.0","id":31,"result":"0x10e6"}
```
