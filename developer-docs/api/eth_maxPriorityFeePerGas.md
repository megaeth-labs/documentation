# eth_maxPriorityFeePerGas

Returns a suggested max priority fee per gas in wei.

`eth_maxPriorityFeePerGas() -> Quantity` — no parameters.

## MegaETH Differences

- Public MegaETH endpoints always return `0x0`. Do not rely on this value for dynamic fee estimation.

## Response

| Field | Type | Notes |
|---|---|---|
| `result` | [`Quantity`](../types.md#quantity) | Suggested max priority fee per gas in wei |

For error handling, see [Error reference](../errors.md).

## Example

```bash
curl -sS https://mainnet.megaeth.com/rpc \
  -H 'content-type: application/json' \
  --data '{"jsonrpc":"2.0","id":1,"method":"eth_maxPriorityFeePerGas","params":[]}'
```

```json
{"jsonrpc":"2.0","id":1,"result":"0x0"}
```
