# eth_getHeaderByHash

Returns the block header for the given block hash, or `null` if no block matches.

## Parameters

**`blockHash`** Hash32 **REQUIRED**

Target block hash.

## Returns

`Header | null` — `null` when the hash does not match any known block.

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

  Gas consumed.

Additional standard header fields (`stateRoot`, `logsBloom`, `transactionsRoot`, `receiptsRoot`, `baseFeePerGas`, …) are also included.

## Errors

| Code | Cause | Fix |
|---|---|---|
| `-32602` | Block hash is missing or malformed | Fix the request |

See also [Error reference](../errors.md).

## Example

```bash
curl -sS https://mainnet.megaeth.com/rpc \
  -H 'content-type: application/json' \
  --data '{"jsonrpc":"2.0","id":26,"method":"eth_getHeaderByHash","params":["0x6f3fcff78eefe9591d2ad590b8a78738b8ad80d9646eccd302618cd9198b73e0"]}'
```

```jsonc
{
  "jsonrpc": "2.0",
  "id": 26,
  "result": {
    "hash": "0x6f3fcff78eefe9591d2ad590b8a78738b8ad80d9646eccd302618cd9198b73e0",
    "parentHash": "0x6b6b52368c21dcdba7348fa37edae3e945013627a83a96b64d55217696899d30",
    "stateRoot": "0xf328fa2752aea1c211a73067d17c25d09a416b4b6a7785441f39bcc930028717",
    "number": "0xb10f64",        // 11,603,812
    "timestamp": "0x69c33537",   // 1,774,400,823
    "baseFeePerGas": "0xf4240"   // 1,000,000 wei
  }
}
```
