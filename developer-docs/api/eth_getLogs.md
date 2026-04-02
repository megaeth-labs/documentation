# eth_getLogs

Returns event logs emitted by smart contracts, filtered by block range, contract address, and/or topics.

## Parameters

**`filter`** object **REQUIRED**

Log filter.

- **`fromBlock`** string

  Inclusive start; hex block number or tag. Default: `latest`.

- **`toBlock`** string

  Inclusive end; hex block number or tag. Default: `latest`.

- **`blockHash`** Hash32

  Single-block mode; mutually exclusive with `fromBlock`/`toBlock`.

- **`address`** Address | Address[]

  Filter by emitting address(es).

- **`topics`** array

  Positional topic filter; positions are AND, values within a position are OR. Use `null` for wildcards.

## Returns

`Log[]` — array of matching log entries.

- **`address`** Address

  Emitting contract.

- **`topics`** Hash32[]

  Indexed topics.

- **`data`** Data

  Unindexed payload.

- **`blockNumber`** Quantity | null

  Containing block number.

- **`transactionHash`** Hash32 | null

  Containing transaction hash.

- **`transactionIndex`** Quantity | null

  Transaction position in block.

- **`logIndex`** Quantity | null

  Log position in block.

- **`removed`** boolean

  `true` if removed during reorg.

- **`blockTimestamp`** Quantity

  Block timestamp.

## Errors

| Code | Cause | Fix |
|---|---|---|
| `-32602` | Filter is malformed or combines `blockHash` with `fromBlock`/`toBlock` | Fix the filter |
| `-32001` | Provided `blockHash` cannot be resolved | Verify the block hash |
| `-32000` | Query range is too large for the endpoint | Narrow the range or paginate |

See also [Error reference](../errors.md).

## Example

```bash
curl -sS https://mainnet.megaeth.com/rpc \
  -H 'content-type: application/json' \
  --data '{"jsonrpc":"2.0","id":110,"method":"eth_getLogs","params":[{"fromBlock":"0xb120c6","toBlock":"0xb120c6","address":"0xf818c8da51f9a712cfbcddd44d0c445fa1a104e6","topics":["0x994d1f10d7d73f3765b557bce9826b2fafd1bad3862fa6192211b39a12183815","0x00000000000000000000000000000000000000000000000000000000000000d8"]}]}'
```

```jsonc
{
  "jsonrpc": "2.0",
  "id": 110,
  "result": [
    {
      "address": "0xf818c8da51f9a712cfbcddd44d0c445fa1a104e6",
      "topics": [
        "0x994d1f10d7d73f3765b557bce9826b2fafd1bad3862fa6192211b39a12183815",
        "0x00000000000000000000000000000000000000000000000000000000000000d8" // 216
      ],
      "data": "0x0000000000000000000954150000002f000000000000d6d800000000006ec9a2",
      "blockNumber": "0xb120c6", // 11,608,262
      "blockTimestamp": "0x69c34699",
      "transactionHash": "0xf3473347041eb4ccc045ee58e6c79c80d98ee4aa783d49e49c69d0a0e50d8ed6",
      "logIndex": "0x24", // 36
      "removed": false
    }
  ]
}
```
