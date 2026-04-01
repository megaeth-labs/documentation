# eth_getTransactionReceipt

Returns the receipt for a transaction that has been included in a block, or `null` if the transaction is unknown or pending.

## Parameters

| Position | Name | Type | Required | Notes |
|---|---|---|---|---|
| `0` | `transactionHash` | `Hash32` | Yes | Hash of the target transaction |

## Returns

`Receipt | null` — `null` when the transaction is unknown or not yet mined.

| Field | Type | Notes |
|---|---|---|
| `transactionHash` | `Hash32` | Transaction hash |
| `status` | `Quantity` | `0x1` success; `0x0` failure |
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
| `-32602` | Transaction hash is missing or malformed | Fix the request |

See also [Error reference](../errors.md).

## Example

```bash
curl -sS https://mainnet.megaeth.com/rpc \
  -H 'content-type: application/json' \
  --data '{"jsonrpc":"2.0","id":120,"method":"eth_getTransactionReceipt","params":["0xf3473347041eb4ccc045ee58e6c79c80d98ee4aa783d49e49c69d0a0e50d8ed6"]}'
```

```json
{
  "jsonrpc": "2.0",
  "id": 120,
  "result": {
    "type": "0x2",
    "status": "0x1",
    "transactionHash": "0xf3473347041eb4ccc045ee58e6c79c80d98ee4aa783d49e49c69d0a0e50d8ed6",
    "blockHash": "0xf773491fd24617452b30c3ed626bf440b5846b9c818ec7d8d7f71c9a02993c8b",
    "blockNumber": "0xb120c6",
    "gasUsed": "0x215ec",
    "effectiveGasPrice": "0xf4241",
    "from": "0xa344fb2d117501ee379d2ea9c0c016959ad94f1e",
    "to": "0x5e3ae52eba0f9740364bd5dd39738e1336086a8b",
    "contractAddress": null,
    "l1Fee": "0x4ab5901"
  }
}
```
