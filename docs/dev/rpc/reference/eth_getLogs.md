---
description: "eth_getLogs JSON-RPC reference for MegaETH."
---

# eth_getLogs

## Summary

Returns event logs emitted by smart contracts, filtered by block range, contract address, and/or topics.

The public MegaETH endpoint supports this method. The standard, node, and gateway layers below identify behavior that differs from a generic Ethereum endpoint.

## Parameters

**`filter`** object **REQUIRED**

Log filter.

- **`fromBlock`** string

  Inclusive start as a hex block number or tag.
  The default is `latest`.

- **`toBlock`** string

  Inclusive end as a hex block number or tag.
  The default is `latest`.

- **`blockHash`** Hash32

  Single-block mode; mutually exclusive with `fromBlock`/`toBlock`.

- **`address`** Address | Address[]

  Filter by emitting address(es).

- **`topics`** array

  Positional topic filter where positions are AND and values within a position are OR.
  Use `null` for wildcards.

## Result

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

## Comparison with Ethereum Standard JSON-RPC

### Ethereum Standard

The canonical Ethereum method uses the parameter and result contract documented above, including the stated `null`, `false`, or zero-value semantics where applicable.

### MegaETH Node Behavior

The node applies the standard address/topic filter and enforces canonical block-selector encoding. Backend retention can still affect historical ranges.

### MegaETH Public Gateway

The gateway places the method in the IO-heavy tier, routes older explicit ranges to its ClickHouse-backed log service when configured, streams the response, and caches only cache-safe filters. There is no gateway block-range cap, but backend row, time, or memory limits can still make very large queries incomplete or fail.

## Errors

The `| Scope |` column distinguishes method failures from gateway policy errors.

| Code     | Scope            | Message             | When it happens                                                        |
| -------- | ---------------- | ------------------- | ---------------------------------------------------------------------- |
| `-32602` | Request          | Invalid params      | Filter is malformed or combines `blockHash` with `fromBlock`/`toBlock` |
| `-32001` | Method           | Resource not found  | Provided `blockHash` cannot be resolved                                |
| `-32000` | Method           | Server error        | Query range is too large for the endpoint                              |
| `-32005` | Transport/policy | Rate limit exceeded | The caller exceeds the public gateway's IO-heavy read budget.          |
| `-32099` | Transport/policy | Payload too large   | The request body exceeds the 128 KiB public endpoint limit.            |

See also [Error Codes](../error-codes.md).

## Examples

Endpoint: `https://mainnet.megaeth.com/rpc`

Capture date: July 24, 2026

Outcome: success

```json
{
  "jsonrpc": "2.0",
  "id": 110,
  "method": "eth_getLogs",
  "params": [
    {
      "fromBlock": "0xb120c6",
      "toBlock": "0xb120c6",
      "address": "0xf818c8da51f9a712cfbcddd44d0c445fa1a104e6",
      "topics": [
        "0x994d1f10d7d73f3765b557bce9826b2fafd1bad3862fa6192211b39a12183815",
        "0x00000000000000000000000000000000000000000000000000000000000000d8"
      ]
    }
  ]
}
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

## Sources

- Spec: `git@github.com:ethereum/execution-apis.git @ d24f58b56dcd16ab0f0c70ec609bcc1c42750b51: src/eth/filter.yaml`
- Code: `git@github.com:megaeth-labs/mega-reth.git @ ab60376631228edab3a6df180f295280bad26e93: crates/rpc/rpc-eth-api/src/filter.rs`
- Code: `git@github.com:megaeth-labs/mega-rpc.git @ 06aa35aa95d569c227cc25d2aa12834eb0458aa0: workers/src/processors/eth-logs-processor.ts`
- Probe: MegaETH Mainnet public endpoint, July 24, 2026
