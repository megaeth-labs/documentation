# eth_blockNumber

Returns the latest block number.

## Parameters

None.

## Returns

| Field | Type | Notes |
|---|---|---|
| `result` | `Quantity` | Current head block number; advances with each new block |

## Errors

Standard JSON-RPC errors only. See [Error reference](../errors.md).

## Example

```bash
curl -sS https://mainnet.megaeth.com/rpc \
  -H 'content-type: application/json' \
  --data '{"jsonrpc":"2.0","id":21,"method":"eth_blockNumber","params":[]}'
```

```jsonc
{"jsonrpc":"2.0","id":21,"result":"0xaeb3d6"}  // block 11,449,302
```
