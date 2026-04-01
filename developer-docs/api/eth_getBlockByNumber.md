# eth_getBlockByNumber

Returns a block by block number or tag.

## Parameters

| Position | Type | Required | Notes |
|---|---|---|---|
| `0` | [`BlockNumberOrTag`](../types.md#blocknumberortag) | Yes | `earliest`, `latest`, `pending`, `safe`, `finalized`, or a hex block number |
| `1` | `Boolean` | No | `false` returns transaction hashes; `true` returns full transaction objects. Default: `false` |

## Returns

A [`Block`](../types.md#block) object, or `null` if the block does not exist or has not been produced yet. The object contains:

| Field | Type | Notes |
|---|---|---|
| `hash` | `Data` (32 bytes) | Block hash |
| `number` | `Quantity` | Block number |
| `parentHash` | `Data` (32 bytes) | Parent block hash |
| `timestamp` | `Quantity` | Unix timestamp |
| `gasLimit` | `Quantity` | Gas limit for the block |
| `gasUsed` | `Quantity` | Total gas used by all transactions |
| `miner` | `Data` (20 bytes) | Block producer address |
| `transactions` | `Data[]` \| [`Transaction`](../types.md#transaction)`[]` | Transaction hashes when `fullTransactions = false`; full transaction objects when `true` |
| `logsBloom` | `Data` (256 bytes) | Bloom filter for log lookups |
| ... | | See [`Block`](../types.md#block) for the complete field list |

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
