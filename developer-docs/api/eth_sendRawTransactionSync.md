# eth_sendRawTransactionSync

Submits a signed transaction and returns a [`Receipt`](../types.md#receipt) once the transaction is included in a canonical block. Defined by draft EIP-7966; a returned receipt reflects inclusion at response time, not finality.

## Parameters

| Position | Name | Type | Required | Notes |
|---|---|---|---|---|
| `0` | `data` | [`Data`](../types.md#data) | Yes | Signed raw transaction bytes |
| `1` | `timeoutMs` | `number` | No | Positive client wait budget in milliseconds |

## Returns

| Field | Type | Notes |
|---|---|---|
| `transactionHash` | `TransactionHash` | Transaction hash |
| `status` | `Quantity` | `0x1` success; `0x0` failure (the transaction reverted but was included on-chain) |
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
| `-32602` | Raw transaction is malformed, undecodable, or `timeoutMs` is invalid | Fix the request |
| `-32000` | Receipt not available before the wait window expired, or the node rejected the transaction | Treat as inconclusive — the transaction may still land; inspect the error message |

See also [Error reference](../errors.md).

## Example

```bash
curl -sS https://mainnet.megaeth.com/rpc \
  -H 'content-type: application/json' \
  --data '{
    "jsonrpc": "2.0",
    "id": 91,
    "method": "eth_sendRawTransactionSync",
    "params": [
      "0xf86480830f424082ea6094cc4b43ab7230cc5913801a746c1834aa06c4e7e780808231b2a0b8126d2c41a6c7dbd0a9e219233497057bb391e7ee1d628370f9c1456f82b054a06663fde9daa2fae784c3dac1c9a5a973d538e3a12ec9c0e4d3cee9c70ba2b239",
      3000
    ]
  }'
```

```json
{
  "jsonrpc": "2.0",
  "id": 91,
  "result": {
    "type": "0x0",
    "status": "0x1",                    // (success)
    "transactionHash": "0x8d3b1e22e7a9026c8658b5d922293d59e4de7c3382bb832d6890e6ab23ad7ec7",
    "transactionIndex": "0x5",          // (5)
    "blockHash": "0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff",
    "blockNumber": "0xe7133c",          // (15,143,740)
    "from": "0xcc4b43ab7230cc5913801a746c1834aa06c4e7e7",
    "to": "0xcc4b43ab7230cc5913801a746c1834aa06c4e7e7",
    "gasUsed": "0xea60",                // (60,000)
    "effectiveGasPrice": "0xf4240",     // (1,000,000 wei)
    "cumulativeGasUsed": "0x143043",    // (1,323,075)
    "contractAddress": null,
    "logs": [],
    "logsBloom": "0x000...000",
    "l1GasPrice": "0x3216",             // (12,822 wei)
    "l1GasUsed": "0x640",              // (1,600)
    "l1Fee": "0x6da0",                 // (28,064 wei)
    "l1BaseFeeScalar": "0x558",        // (1,368)
    "l1BlobBaseFee": "0x1",            // (1)
    "l1BlobBaseFeeScalar": "0x0"       // (0)
  }
}
```
