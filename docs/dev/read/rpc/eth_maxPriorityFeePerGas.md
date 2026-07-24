---
description: "eth_maxPriorityFeePerGas JSON-RPC reference for MegaETH."
---

# eth_maxPriorityFeePerGas

Returns the recommended priority fee per gas in wei.
MegaETH returns `0x0` because priority fees are not needed under the current fee policy.

## Parameters

None.

## Returns

**`result`** Quantity

Always `0x0`.

## Errors

Standard JSON-RPC errors only.
See [Error reference](error-codes.md).

## Example

```bash
curl -sS https://mainnet.megaeth.com/rpc \
  -H 'content-type: application/json' \
  --data '{"jsonrpc":"2.0","id":1,"method":"eth_maxPriorityFeePerGas","params":[]}'
```

```json
{ "jsonrpc": "2.0", "id": 1, "result": "0x0" }
```
