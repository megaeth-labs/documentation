# eth_getLogs

Returns event logs emitted by smart contracts, filtered by block range, contract address, and/or topics.

## Parameters

Pass a single [`LogFilter`](../types.md#logfilter) object as `params[0]`.

| Field | Type | Required | Notes |
|---|---|---|---|
| `fromBlock` | [`BlockTag`](../types.md#blocktag) | No | Start of range (inclusive) |
| `toBlock` | [`BlockTag`](../types.md#blocktag) | No | End of range (inclusive) |
| `blockHash` | `Data` (32 bytes) | No | Single block to query. Cannot be combined with `fromBlock` / `toBlock` |
| `address` | `Data` \| `Data[]` | No | Contract address(es) to match |
| `topics` | `Data[]` | No | Position-sensitive topic filter. Use `null` as a wildcard. MegaETH also accepts `[]`, but portable clients should prefer `null` |

## Returns

An array of [`Log`](../types.md#log) objects. Each object contains:

| Field | Type | Notes |
|---|---|---|
| `address` | `Data` (20 bytes) | Contract that emitted the log |
| `topics` | `Data[]` | Indexed event parameters (0–4 entries) |
| `data` | `Data` | ABI-encoded non-indexed event parameters |
| `blockNumber` | `Quantity` | Block containing the log |
| `transactionHash` | `Data` (32 bytes) | Transaction that emitted the log |
| `transactionIndex` | `Quantity` | Transaction position in the block |
| `logIndex` | `Quantity` | Log position in the block |
| `removed` | `Boolean` | `true` if removed during a reorg |
| `blockTimestamp` | `Quantity` | Block timestamp. MegaETH extension — not present on other networks |

## Errors

| Code | Cause | Fix |
|---|---|---|
| `-32602` | Malformed filter, or `blockHash` combined with `fromBlock` / `toBlock` | Fix the filter |
| `-32001` | `blockHash` cannot be resolved | Verify the block hash |
| `-32000` | Query too large for the endpoint | Narrow the filter or reduce the range |

See also [Error reference](../errors.md) and [Handle Rate Limits And Large Queries](../guides/rate-limits.md).

## Example

```bash
curl -sS https://mainnet.megaeth.com/rpc \
  -H 'content-type: application/json' \
  --data '{"jsonrpc":"2.0","id":110,"method":"eth_getLogs","params":[{"fromBlock":"0xb120c6","toBlock":"0xb120c6","address":"0xf818c8da51f9a712cfbcddd44d0c445fa1a104e6","topics":["0x994d1f10d7d73f3765b557bce9826b2fafd1bad3862fa6192211b39a12183815","0x00000000000000000000000000000000000000000000000000000000000000d8"]}]}'
```

```json
{
  "jsonrpc": "2.0",
  "id": 110,
  "result": [
    {
      "address": "0xf818c8da51f9a712cfbcddd44d0c445fa1a104e6",
      "topics": [
        "0x994d1f10d7d73f3765b557bce9826b2fafd1bad3862fa6192211b39a12183815",
        "0x00000000000000000000000000000000000000000000000000000000000000d8"
      ],
      "data": "0x0000000000000000000954150000002f000000000000d6d800000000006ec9a2",
      "blockNumber": "0xb120c6",
      "blockTimestamp": "0x69c34699",
      "transactionHash": "0xf3473347041eb4ccc045ee58e6c79c80d98ee4aa783d49e49c69d0a0e50d8ed6",
      "logIndex": "0x24",
      "removed": false
    }
  ]
}
```
