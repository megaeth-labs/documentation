# eth_getBlockReceipts

Returns all transaction receipts for a given block, or `null` if the block is not found.

## Parameters

| Position | Name | Type | Required | Notes |
|---|---|---|---|---|
| `0` | `block` | [`BlockNumberOrTagOrHash`](../types.md#blocknumberortagorhash) | Yes | Block number, tag (`earliest`, `latest`, `safe`, `finalized`, `pending`), block hash, or `{"blockHash":"0x…"}` selector object |

## Returns

`Receipt[] | null` — receipts for every transaction in the block. Returns `null` when the block is not found. Returns `[]` when the block exists but contains no transactions.

Each array element contains:

| Field | Type | Notes |
|---|---|---|
| `transactionHash` | `TransactionHash` | Transaction hash |
| `status` | `Quantity` | `0x1` success; `0x0` failure |
| `blockHash` | `BlockHash` | Containing block hash |
| `blockNumber` | `Quantity` | Containing block number |
| `from` | `Address` | Sender |
| `to` | `Address \| null` | Recipient; `null` for contract creation |
| `gasUsed` | `Quantity` | Gas consumed by this transaction |
| `effectiveGasPrice` | `Quantity` | Effective gas price |
| `contractAddress` | `Address \| null` | Created contract address when applicable |
| `logs` | [`Log[]`](../types.md#log) | Emitted log entries |
| ... | | See [`Receipt`](../types.md#receipt) for the complete field list |

## Errors

| Code | Cause | Fix |
|---|---|---|
| `-32602` | Malformed or unsupported block selector | Fix the request |
| `4444` | Historical block data unavailable on this endpoint | Verify historical-state availability for the endpoint |

See also [Error reference](../errors.md).

## Example

```bash
curl -sS https://mainnet.megaeth.com/rpc \
  -H 'content-type: application/json' \
  --data '{"jsonrpc":"2.0","id":16,"method":"eth_getBlockReceipts","params":[{"blockHash":"0x57804c21b747137075b29ce153b4f559345a3624273660c87e81bd57e7cbbc3d"}]}'
```

```jsonc
{
  "jsonrpc": "2.0",
  "id": 16,
  "result": [
    {
      "type": "0x7e",
      "status": "0x1",
      "cumulativeGasUsed": "0xb9d56c",
      "logs": [],
      "depositNonce": "0x0",
      "depositReceiptVersion": "0x1",
      "logsBloom": "0x0000...0000",
      "transactionHash": "0xecc262f36652019b75f4cb7315ff19f430fc92efd5a8048948400407d55fd904",
      "transactionIndex": "0x0",
      "blockHash": "0x57804c21b747137075b29ce153b4f559345a3624273660c87e81bd57e7cbbc3d",
      "blockNumber": "0x1",
      "gasUsed": "0xb9d56c",                // 12,211,564
      "effectiveGasPrice": "0x0",            // 0 — deposit transaction
      "from": "0xdeaddeaddeaddeaddeaddeaddeaddeaddead0001",
      "to": "0x4200000000000000000000000000000000000015",
      "contractAddress": null,
      "l1GasPrice": "0x22ba611d",            // 582,418,717 wei
      "l1GasUsed": "0x6e7",                 // 1,767
      "l1Fee": "0x0",
      "l1BaseFeeScalar": "0x558",            // 1,368
      "l1BlobBaseFee": "0x7",               // 7
      "l1BlobBaseFeeScalar": "0xc5fc5"      // 810,949
    }
  ]
}
```
