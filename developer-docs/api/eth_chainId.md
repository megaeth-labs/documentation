# eth_chainId

Returns the chain ID of the connected network.

## Parameters

None.

## Returns

`Quantity` — the chain ID for the connected network.

| Network | Chain ID (hex) | Chain ID (decimal) |
|---|---|---|
| Mainnet | `0x10e6` | 4326 |
| Testnet | `0x18c7` | 6343 |

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
