# debug_getHistoryTransactionCount

Returns the chain-wide cumulative transaction count up to and including a given block.

## Parameters

**`block`** string **REQUIRED**

Hex block number or tag (`earliest`, `latest`, `safe`, `finalized`). `pending` is not supported.

## Returns

**`result`** Quantity

Cumulative transaction count across all blocks up to the selected block. Consecutive blocks with no transactions return the same value.

## Errors

| Code | Cause | Fix |
|---|---|---|
| `-32001` | Block selector cannot be resolved or unsupported tag such as `pending` was used | Fix the request |
| `-32602` | Invalid parameter shape | Fix the request |

See also [Error reference](../errors.md).

## Example

```bash
curl -sS https://mainnet.megaeth.com/rpc \
  -H 'content-type: application/json' \
  --data '{"jsonrpc":"2.0","id":1,"method":"debug_getHistoryTransactionCount","params":["0x12a05f"]}'
```

```jsonc
{"jsonrpc":"2.0","id":1,"result":"0x12cbab"}  // 1,231,787 total transactions through block 1,220,703
```
