# eth_getTransactionByHash

Returns a transaction selected by transaction hash.

## Ethereum Standard

`eth_getTransactionByHash(transactionHash) -> Transaction | null`

## Request

Send `params` as `[transactionHash]`.

| Position | Type | Required | Notes |
|---|---|---|---|
| `0` | [`TransactionHash`](../types.md#transactionhash) | Yes | Target transaction hash |

- Some non-canonical short hashes have returned `null` on public MegaETH endpoints; do not rely on server-side validation alone.

## Response

| Field | Type | Notes |
|---|---|---|
| `result` | [`Transaction`](../types.md#transaction) or `null` | Selected transaction object |

- `result: null` when the transaction cannot be found.
- For pending transactions, `blockHash`, `blockNumber`, and `transactionIndex` can be `null`.
- `to` is `null` for contract-creation transactions.

## Common Errors

| Code | When it usually happens | What to do |
|---|---|---|
| `-32602` | The transaction hash is missing or malformed | Fix the request before retrying |
| `-32005` | The public endpoint rate-limited the request | Back off and retry later |

See also [Error reference](../errors.md).

## Example

```bash
curl -sS https://mainnet.megaeth.com/rpc \
  -H 'content-type: application/json' \
  --data '{"jsonrpc":"2.0","id":79,"method":"eth_getTransactionByHash","params":["0x89f0ccba20d5bbbe1cb6b44fb8d1f9a9e14b620a0b947a3de81cff684462f60c"]}'
```

```json
{
  "jsonrpc": "2.0",
  "id": 79,
  "result": {
    "type": "0x0",
    "hash": "0x89f0ccba20d5bbbe1cb6b44fb8d1f9a9e14b620a0b947a3de81cff684462f60c",
    "from": "0xa887dcb9d5f39ef79272801d05abdf707cfbbd1d",
    "to": "0x6342000000000000000000000000000000000001",
    "nonce": "0x597ac57",
    "gas": "0x3d5720",
    "value": "0x0",
    "blockHash": "0xf773491fd24617452b30c3ed626bf440b5846b9c818ec7d8d7f71c9a02993c8b",
    "blockNumber": "0xb120c6",
    "transactionIndex": "0x1"
  }
}
```
