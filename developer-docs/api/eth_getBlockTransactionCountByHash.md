# eth_getBlockTransactionCountByHash

Returns the number of transactions in the block matching the given hash.

## Parameters

| Position | Name | Type | Required | Notes |
|---|---|---|---|---|
| `0` | `blockHash` | [`BlockHash`](../types.md#blockhash) | Yes | Target block hash |

## Returns

| Field | Type | Notes |
|---|---|---|
| `result` | [`Quantity`](../types.md#quantity) \| `null` | Transaction count; `null` when the block is not found |

## Errors

| Code | Cause | Fix |
|---|---|---|
| `-32602` | Block hash missing or malformed | Fix the request |

See also [Error reference](../errors.md).

## Example

```bash
curl -sS https://mainnet.megaeth.com/rpc \
  -H 'content-type: application/json' \
  --data '{"jsonrpc":"2.0","id":3,"method":"eth_getBlockTransactionCountByHash","params":["0xa97b8563203de36f0c8430709734438fbf7f2444b6de9f307853fc46b230de3e"]}'
```

```jsonc
{"jsonrpc":"2.0","id":3,"result":"0x18"}  // 24 transactions
```
