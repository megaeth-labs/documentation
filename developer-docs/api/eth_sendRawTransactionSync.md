# eth_sendRawTransactionSync

Submits a signed transaction and returns a receipt once the transaction is included in a block.

## Parameters

| Position | Name | Type | Required | Notes |
|---|---|---|---|---|
| `0` | `data` | `Data` | Yes | Signed raw transaction bytes |
| `1` | `timeoutMs` | `number` | No | Client wait budget in milliseconds. Default: `10000` (10 s) |

## Returns

| Field | Type | Notes |
|---|---|---|
| `transactionHash` | `Hash32` | Transaction hash |
| `status` | `Quantity` | `0x1` success; `0x0` failure (the transaction reverted but was included on-chain) |
| `blockHash` | `Hash32` | Containing block hash |
| `blockNumber` | `Quantity` | Containing block number |
| `from` | `Address` | Sender |
| `to` | `Address \| null` | Recipient; `null` for contract creation |
| `gasUsed` | `Quantity` | Gas consumed by this transaction |
| `effectiveGasPrice` | `Quantity` | Effective gas price |
| `contractAddress` | `Address \| null` | Created contract address when applicable |
| `logs` | `Log[]` | Emitted log entries |

Additional fields include `cumulativeGasUsed`, `logsBloom`, `type`, and L1 fee fields (`l1Fee`, `l1GasPrice`, `l1GasUsed`, etc.).

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

```jsonc
{
  "jsonrpc": "2.0",
  "id": 91,
  "result": {
    "type": "0x0",
    "status": "0x1",
    "transactionHash": "0x8d3b1e22e7a9026c8658b5d922293d59e4de7c3382bb832d6890e6ab23ad7ec7",
    "transactionIndex": "0x5",
    "blockHash": "0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff",
    "blockNumber": "0xe7133c",          // 15,143,740
    "from": "0xcc4b43ab7230cc5913801a746c1834aa06c4e7e7",
    "to": "0xcc4b43ab7230cc5913801a746c1834aa06c4e7e7",
    "gasUsed": "0xea60",                // 60,000
    "effectiveGasPrice": "0xf4240",     // 1,000,000 wei
    "cumulativeGasUsed": "0x143043",
    "contractAddress": null,
    "logs": [],
    "l1GasPrice": "0x3216",
    "l1GasUsed": "0x640",
    "l1Fee": "0x6da0",
    "l1BaseFeeScalar": "0x558",
    "l1BlobBaseFee": "0x1",
    "l1BlobBaseFeeScalar": "0x0"
  }
}
```
