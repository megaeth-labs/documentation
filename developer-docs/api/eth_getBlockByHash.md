# eth_getBlockByHash

Returns a block selected by block hash.

## Ethereum Standard

`eth_getBlockByHash(blockHash, fullTransactions) -> Block | null`

## MegaETH Differences

- The public MegaETH endpoint currently accepts an omitted `fullTransactions` parameter and treats it as `false`.
- That omitted-boolean behavior is a MegaETH convenience, not portable Ethereum JSON-RPC behavior.
- If you only need header fields, prefer [`eth_getHeaderByHash`](./eth_getHeaderByHash.md).

## Request

Send `params` as `[blockHash, fullTransactions]`.

| Position | Type | Required | Notes |
|---|---|---|---|
| `0` | [`BlockHash`](../types.md#blockhash) | Yes | Target block hash |
| `1` | `boolean` | Yes for portable clients | `false` returns transaction hashes; `true` returns full transaction objects |

Reader notes:

- Send `fullTransactions` explicitly if you want portable client behavior.
- Block tags such as `latest` or `pending` do not apply here.
- Keep `fullTransactions = false` unless you actually need full transaction objects.

## Response

| Field | Type | Notes |
|---|---|---|
| `result` | [`Block`](../types.md#block) or `null` | Selected block object |

Reader notes:

- With `fullTransactions = false`, `result.transactions` is an array of [`TransactionHash`](../types.md#transactionhash) values.
- With `fullTransactions = true`, `result.transactions` is an array of [`Transaction`](../types.md#transaction) objects.
- `result: null` is a normal outcome when the hash is well-formed but does not resolve to a block.

## Common Errors

| Code | When it usually happens | What to do |
|---|---|---|
| `-32602` | The block hash is malformed or `fullTransactions` is not a boolean | Fix the request before retrying |
| `4444` | The endpoint cannot serve the requested historical block data | Keep the request unchanged and verify historical-state availability for that endpoint |
| `-32005` | The public endpoint rate-limited the request | Back off and retry later |

See also [Error reference](../errors.md).

## Example

```bash
curl -sS https://mainnet.megaeth.com/rpc \
  -H 'content-type: application/json' \
  --data '{"jsonrpc":"2.0","id":74,"method":"eth_getBlockByHash","params":["0xe0b5b2b8222c00dcbe9f359fc917a9190127bd1b958e11b6caa2035dd03952f1",false]}'
```

```json
{
  "jsonrpc": "2.0",
  "id": 74,
  "result": {
    "hash": "0xe0b5b2b8222c00dcbe9f359fc917a9190127bd1b958e11b6caa2035dd03952f1",
    "number": "0x100000",
    "timestamp": "0x692225d3",
    "transactions": [
      "0x243d39c7f6cd74a9a081a6fe4bdfce37ac6136b9454691aeeb9ed77998450cbc"
    ]
  }
}
```
