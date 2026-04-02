# eth_maxPriorityFeePerGas

Returns the recommended priority fee per gas in wei. Returns `0x0` — MegaETH blocks have enough capacity that priority fees are not needed.

## Parameters

None.

## Returns

**`result`** Quantity

Always `0x0`.

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
