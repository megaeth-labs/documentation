

# eth_maxPriorityFeePerGas

Returns a suggested max priority fee per gas in wei. On MegaETH, this always returns `0x0`.

## Parameters

None.

## Returns

| Type | Notes |
|---|---|
| [`Quantity`](../types.md#quantity) | Suggested max priority fee per gas in wei |

## Errors

Standard JSON-RPC errors only. See [Error reference](../errors.md).

## Example

```bash
curl -sS https://mainnet.megaeth.com/rpc \
  -H 'content-type: application/json' \
  --data '{"jsonrpc":"2.0","id":1,"method":"eth_maxPriorityFeePerGas","params":[]}'
```

```json
{"jsonrpc":"2.0","id":1,"result":"0x0"}
```
