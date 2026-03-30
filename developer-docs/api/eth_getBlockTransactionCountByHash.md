# eth_getBlockTransactionCountByHash

Returns the number of transactions in a block selected by block hash.

## Ethereum Standard

`eth_getBlockTransactionCountByHash(blockHash) -> Quantity | null`

## Request

Send `params` as `[blockHash]`.

| Position | Type | Required | Notes |
|---|---|---|---|
| `0` | [`BlockHash`](../types.md#blockhash) | Yes | Target block hash |

- Block tags such as `latest` or `pending` do not apply here.

## Response

| Field | Type | Notes |
|---|---|---|
| `result` | [`Quantity`](../types.md#quantity) or `null` | Transaction count for the selected block |

- `0x0` means zero transactions; `null` means the block was not found. Treat them differently.

## Common Errors

| Code | When it usually happens | What to do |
|---|---|---|
| `-32602` | The block hash is missing or malformed | Fix the request before retrying |
| `-32005` | The public endpoint rate-limited the request | Back off and retry later |

See also [Error reference](../errors.md).

## Example

```bash
curl -sS https://mainnet.megaeth.com/rpc \
  -H 'content-type: application/json' \
  --data '{"jsonrpc":"2.0","id":3,"method":"eth_getBlockTransactionCountByHash","params":["0xa97b8563203de36f0c8430709734438fbf7f2444b6de9f307853fc46b230de3e"]}'
```

```json
{"jsonrpc":"2.0","id":3,"result":"0x18"}
```
