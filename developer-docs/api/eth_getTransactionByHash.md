# eth_getTransactionByHash

Returns the transaction with the given hash, or `null` if no matching transaction is found.

## Parameters

**`transactionHash`** Hash32 **REQUIRED**

Target transaction hash.

## Returns

`Transaction | null` — `null` when the transaction cannot be found.

- **`hash`** Hash32

  Transaction hash.

- **`type`** Quantity

  Transaction type identifier.

- **`from`** Address

  Sender.

- **`to`** Address | null

  Recipient; `null` for contract creation.

- **`value`** Quantity

  Transfer value in wei.

- **`nonce`** Quantity

  Sender nonce.

- **`gas`** Quantity

  Gas limit.

- **`input`** Data

  Calldata.

- **`blockHash`** Hash32 | null

  `null` for pending transactions.

- **`blockNumber`** Quantity | null

  `null` for pending transactions.

- **`transactionIndex`** Quantity | null

  `null` for pending transactions.

Additional fields vary by transaction type (`gasPrice`, `maxFeePerGas`, `accessList`, `chainId`, `v`, `r`, `s`, etc.).

## Errors

| Code | Cause | Fix |
|---|---|---|
| `-32602` | Transaction hash is missing or malformed | Fix the request |

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
