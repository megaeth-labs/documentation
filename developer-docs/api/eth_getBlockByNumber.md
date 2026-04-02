# eth_getBlockByNumber

Returns a block by its block number or block tag, or `null` if the block is not available.

## Parameters

**`block`** string **REQUIRED**

Hex block number or tag: `latest`, `safe`, `finalized`, `earliest`, `pending`.

---

**`fullTransactions`** boolean **REQUIRED**

`false` returns transaction hashes; `true` returns full transaction objects.

## Returns

`Block | null` — `null` when the requested block does not exist or is not yet available.

- **`number`** Quantity

  Block number.

- **`hash`** Hash32

  Block hash.

- **`parentHash`** Hash32

  Parent block hash.

- **`timestamp`** Quantity

  Block timestamp.

- **`miner`** Address

  Fee recipient / coinbase.

- **`gasLimit`** Quantity

  Block gas limit.

- **`gasUsed`** Quantity

  Gas consumed by the block.

- **`transactions`** Hash32[] | Transaction[]

  Hashes when `fullTransactions = false`; full objects when `true`.

Additional standard fields (`stateRoot`, `logsBloom`, `transactionsRoot`, `receiptsRoot`, `baseFeePerGas`, …) are also included.

## Errors

| Code | Cause | Fix |
|---|---|---|
| `-32602` | Malformed block selector or `fullTransactions` is not a boolean | Fix the request |
| `4444` | Requested historical block is not available on this endpoint | Verify historical-state availability for the endpoint |

See also [Error reference](../errors.md).

## Example

```bash
curl -sS https://mainnet.megaeth.com/rpc \
  -H 'content-type: application/json' \
  --data '{"jsonrpc":"2.0","id":81,"method":"eth_getBlockByNumber","params":["0x100000",false]}'
```

```json
{
  "jsonrpc": "2.0",
  "id": 81,
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
