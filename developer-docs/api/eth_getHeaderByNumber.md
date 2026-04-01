# eth_getHeaderByNumber

Returns a header-only view of a block by number or block tag.

## Parameters

| Position | Name | Type | Required | Notes |
|---|---|---|---|---|
| `0` | `block` | `string` | Yes | Hex block number or tag: `latest`, `safe`, `finalized`, `earliest`, `pending` |

## Returns

`Header | null` — `null` when the block is not found.

| Field | Type | Notes |
|---|---|---|
| `number` | `Quantity` | Block number |
| `hash` | `Hash32` | Block hash |
| `parentHash` | `Hash32` | Parent block hash |
| `timestamp` | `Quantity` | Block timestamp |
| `miner` | `Address` | Fee recipient / coinbase |
| `gasLimit` | `Quantity` | Block gas limit |
| `gasUsed` | `Quantity` | Gas consumed |

Additional standard header fields (`stateRoot`, `logsBloom`, `transactionsRoot`, `receiptsRoot`, `baseFeePerGas`, …) are also included.

## Errors

| Code | Cause | Fix |
|---|---|---|
| `-32602` | Malformed selector, decimal string, or unsupported object form | Fix the request |

See also [Error reference](../errors.md).

## Example

```bash
curl -sS https://mainnet.megaeth.com/rpc \
  -H 'content-type: application/json' \
  --data '{"jsonrpc":"2.0","id":27,"method":"eth_getHeaderByNumber","params":["0xb11048"]}'
```

```jsonc
{
  "jsonrpc": "2.0",
  "id": 27,
  "result": {
    "hash": "0x235d80b5e91125a1a1d6da6776c6a9ee087d1818c494f71736b09bed61b1411e",
    "parentHash": "0x6fc0412abfba89bbfab17b2d8bd36cb1c214c1d53ed213fa8958439d0c4f9c18",
    "stateRoot": "0x301d7b77a74893451bd76e5d1672aaaa493cd78c06d59e885218d48917a35c03",
    "number": "0xb11048",        // 11,604,040
    "timestamp": "0x69c3361b",   // 1,774,401,051
    "baseFeePerGas": "0xf4240"   // 1,000,000 wei
  }
}
```
