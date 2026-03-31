---
description: eth_getLogsWithCursor — paginated log queries using a cursor for incremental retrieval of large datasets.
---

# eth\_getLogsWithCursor

Returns event logs with cursor-based pagination.
Accepts the same filter parameters as `eth_getLogs`, with an additional optional `cursor`.
When a query exceeds server-side resource limits, the server returns a partial result and a cursor marking where it left off.

## Parameters

Pass a single filter object as `params[0]`.

| Field | Type | Required | Notes |
| ----- | ---- | -------- | ----- |
| `fromBlock` | `BlockTag` | No | Start of range (inclusive) |
| `toBlock` | `BlockTag` | No | End of range (inclusive) |
| `blockHash` | `Data` (32 bytes) | No | Single block to query. Cannot be combined with `fromBlock` / `toBlock` |
| `address` | `Data` \| `Data[]` | No | Contract address(es) to match |
| `topics` | `Data[]` | No | Position-sensitive topic filter. Use `null` as a wildcard |
| `cursor` | `String` | No | Opaque cursor from a previous response. Omit for the initial request |

## Returns

| Field | Type | Notes |
| ----- | ---- | ----- |
| `logs` | `Log[]` | Matching log objects (same schema as `eth_getLogs`) |
| `cursor` | `String` | Present when more results remain. Absent when the query is complete |

The cursor is derived from the block number and log index of the last log in the batch, but clients should treat it as an opaque string.

## Errors

| Code | Cause | Fix |
| ---- | ----- | --- |
| `-32602` | Malformed filter, or `blockHash` combined with `fromBlock` / `toBlock` | Fix the filter |
| `-32000` | Query too large for the endpoint | Narrow the filter or reduce the range |

See also [Error reference](error-codes.md).

## Example

### Initial request

```bash
curl -sS https://mainnet.megaeth.com/rpc \
  -X POST -H "Content-Type: application/json" \
  -d '{
    "jsonrpc": "2.0",
    "id": 1,
    "method": "eth_getLogsWithCursor",
    "params": [{
      "fromBlock": "0x100",
      "toBlock": "0x200",
      "address": "0x1234567890abcdef1234567890abcdef12345678",
      "topics": ["0xddf252ad..."]
    }]
  }'
```

Partial response (has cursor — more results remain):

```json
{
  "jsonrpc": "2.0",
  "id": 1,
  "result": {
    "logs": [
      {
        "address": "0x1234567890abcdef1234567890abcdef12345678",
        "blockNumber": "0x101",
        "logIndex": "0x0",
        "topics": ["0xddf252ad..."],
        "data": "0x...",
        "transactionHash": "0x...",
        "transactionIndex": "0x0",
        "blockHash": "0x...",
        "removed": false
      }
    ],
    "cursor": "0x0000010100000000"
  }
}
```

Continuation request — pass the `cursor` from the previous response to resume:

```bash
curl -sS https://mainnet.megaeth.com/rpc \
  -X POST -H "Content-Type: application/json" \
  -d '{
    "jsonrpc": "2.0",
    "id": 2,
    "method": "eth_getLogsWithCursor",
    "params": [{
      "fromBlock": "0x100",
      "toBlock": "0x200",
      "address": "0x1234567890abcdef1234567890abcdef12345678",
      "topics": ["0xddf252ad..."],
      "cursor": "0x0000010100000000"
    }]
  }'
```

Complete response (no cursor — all results retrieved):

```json
{
  "jsonrpc": "2.0",
  "id": 2,
  "result": {
    "logs": [
      {
        "address": "0x1234567890abcdef1234567890abcdef12345678",
        "blockNumber": "0x102",
        "logIndex": "0x3",
        "topics": ["0xddf252ad..."],
        "data": "0x...",
        "transactionHash": "0x...",
        "transactionIndex": "0x2",
        "blockHash": "0x...",
        "removed": false
      }
    ]
  }
}
```
