# eth_getBlockTransactionCountByNumber

Returns the number of transactions in a block identified by block number or tag.

## Parameters

| Position | Name | Type | Required | Notes |
|---|---|---|---|---|
| `0` | `block` | [`BlockNumberOrTag`](../types.md#blocknumberortag) | Yes | Hex block number or tag (`earliest`, `latest`, `pending`, `safe`, `finalized`) |

## Returns

| Type | Notes |
|---|---|
| [`Quantity`](../types.md#quantity) \| `null` | Transaction count; `null` when the block is not found |

## Errors

| Code | Cause | Fix |
|---|---|---|
| `-32602` | Block selector is malformed, uses a decimal string, or uses an unsupported object form | Fix the request |

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
