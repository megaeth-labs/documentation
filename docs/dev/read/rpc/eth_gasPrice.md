---
description: "eth_gasPrice JSON-RPC reference for MegaETH."
---

# eth_gasPrice

Returns the current gas price in wei.
Under MegaETH's current fee policy, this method returns `0xf4240` (1,000,000 wei = 0.001 gwei).

## Parameters

None.

## Returns

**`result`** Quantity

Gas price in wei.

## Errors

Standard JSON-RPC errors only.
See [Error reference](error-codes.md).

## Example

```bash
curl -sS https://mainnet.megaeth.com/rpc \
  -H 'content-type: application/json' \
  --data '{"jsonrpc":"2.0","id":1,"method":"eth_gasPrice","params":[]}'
```

```jsonc
{ "jsonrpc": "2.0", "id": 1, "result": "0xf4240" } // 1,000,000 wei
```
