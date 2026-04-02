# eth_gasPrice

Returns the current gas price in wei. Always `0xf4240` (1,000,000 wei).

## Parameters

None.

## Returns

**`result`** Quantity

Gas price in wei.

## Errors

Standard JSON-RPC errors only. See [Error reference](../errors.md).

## Example

```bash
curl -sS https://mainnet.megaeth.com/rpc \
  -H 'content-type: application/json' \
  --data '{"jsonrpc":"2.0","id":1,"method":"eth_gasPrice","params":[]}'
```

```jsonc
{"jsonrpc":"2.0","id":1,"result":"0xf4240"}  // 1,000,000 wei
```
