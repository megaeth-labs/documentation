# eth_getLogs

Returns log entries that match a filter.

## Ethereum Standard

`eth_getLogs(filter) -> Log[]`

## MegaETH Differences

- Matching log objects can include an optional `blockTimestamp`.
- MegaETH can accept positional `[]` topic wildcards, but portable clients should prefer `null`.

## Request

Send `params` as `[filter]`.

| Position | Type | Required | Notes |
|---|---|---|---|
| `0` | [`LogFilter`](../types.md#logfilter) | Yes | Range filter or single-block filter |

Reader notes:

- Use either `blockHash` or `fromBlock` / `toBlock`, never both.
- Block ranges are inclusive of both endpoints.
- `address` can be a single address or an array of addresses.
- Topic matching is position-sensitive. Use `null` as a wildcard.
- On public endpoints, keep ranges explicit and small.

## Response

| Field | Type | Notes |
|---|---|---|
| `result` | [`Log`](../types.md#log)`[]` | Matching log objects |

- `blockTimestamp` is a MegaETH extension; not present on other providers.

## Common Errors

| Code | When it usually happens | What to do |
|---|---|---|
| `-32602` | The filter is malformed or combines `blockHash` with `fromBlock` or `toBlock` | Fix the filter before retrying |
| `-32001` | The provided `blockHash` cannot be resolved | Check the block hash and retry only if you expect it to become available |
| `-32000` | The query is too large for the endpoint | Reduce the range, narrow the filter, and paginate |
| `-32005` | The public endpoint rate-limited the request | Back off and retry later |

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
