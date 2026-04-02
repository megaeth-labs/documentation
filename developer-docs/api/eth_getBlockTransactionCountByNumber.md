# eth_getBlockTransactionCountByNumber

Returns the number of transactions in a block identified by block number or tag.

## Parameters

**`block`** string **REQUIRED**

Hex block number or tag: `latest`, `safe`, `finalized`, `earliest`, `pending`.

## Returns

**`result`** Quantity | null

Transaction count; `null` when the block is not found.

## Errors

| Code | Cause | Fix |
|---|---|---|
| `-32602` | Block selector is malformed | Fix the request |

See also [Error reference](../errors.md).

## Example

```bash
curl -sS https://mainnet.megaeth.com/rpc \
  -H 'content-type: application/json' \
  --data '{"jsonrpc":"2.0","id":4,"method":"eth_getBlockTransactionCountByNumber","params":["0xb11362"]}'
```

```jsonc
{"jsonrpc":"2.0","id":4,"result":"0x17"}  // 23 transactions (block 11,604,834)
```
