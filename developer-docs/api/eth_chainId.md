# eth_chainId

Returns the chain ID of the connected network.

## Parameters

None.

## Returns

**`result`** Quantity

The chain ID for the connected network.

## Errors

Standard JSON-RPC errors only. See [Error reference](../errors.md).

## Example

```bash
curl -sS https://mainnet.megaeth.com/rpc \
  -H 'content-type: application/json' \
  --data '{"jsonrpc":"2.0","id":31,"method":"eth_chainId","params":[]}'
```

```jsonc
{"jsonrpc":"2.0","id":31,"result":"0x10e6"}  // 4326 (Mainnet)
```
