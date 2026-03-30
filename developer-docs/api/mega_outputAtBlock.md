# mega_outputAtBlock

Returns output data for a specific MegaETH block.

## Ethereum Standard

This method is not part of the standard Ethereum JSON-RPC method set.

## MegaETH Differences

- This is a MegaETH-specific method.
- `optimism_outputAtBlock` currently behaves as an alias.
- The request requires a concrete hex block number. Block tags such as `latest` are not accepted.
- Numeric members inside `blockRef` and observed `syncStatus` fields are JSON numbers, not Ethereum [`Quantity`](../types.md#quantity) strings.

## Request

Send `params` as `[blockNumber]`.

| Position | Type | Required | Notes |
|---|---|---|---|
| `0` | [`Quantity`](../types.md#quantity) | Yes | Concrete hex block number only |


## Response

| Field | Type | Notes |
|---|---|---|
| `result` | [`OutputAtBlockResult`](../types.md#outputatblockresult) | Output object for the requested block |

Reader notes:

- `version` can be omitted on cache-hit paths.
- `blockRef.number` and `blockRef.timestamp` are JSON numbers, not `Quantity` strings.
- `syncStatus` is always present. It is a live backend snapshot and can change between repeated calls for the same block.

### `syncStatus` Shape

| Field | Type | Required | Notes |
|---|---|---|---|
| `current_l1` | `L1BlockRef` | Yes | Current L1 head tracked by the backend |
| `current_l1_finalized` | `L1BlockRef` | Yes | Current L1 finalized block |
| `head_l1` | `L1BlockRef` | Yes | Head L1 block |
| `safe_l1` | `L1BlockRef` | Yes | Safe L1 block |
| `finalized_l1` | `L1BlockRef` | Yes | Finalized L1 block |
| `unsafe_l2` | `L2BlockRef` | Yes | Unsafe L2 block |
| `safe_l2` | `L2BlockRef` | Yes | Safe L2 block |
| `finalized_l2` | `L2BlockRef` | Yes | Finalized L2 block |
| `pending_safe_l2` | `L2BlockRef` | No | Pending safe L2 block when present |
| `queued_unsafe_l2` | `L2BlockRef` | No | Queued unsafe L2 block when present |

`L1BlockRef`: `{ hash, number, parentHash, timestamp }` — all numeric fields are JSON numbers, not `Quantity` strings. Field names use `snake_case`.

`L2BlockRef`: `{ hash, number, parentHash, timestamp, l1origin: { hash, number }, sequenceNumber }` — same encoding rules as `L1BlockRef`.

## Common Errors

| Code | When it usually happens | What to do |
|---|---|---|
| `-32602` | The request is missing the block number, uses the wrong parameter count, or sends a block tag instead of a hex block number | Fix the request before retrying |
| `-32603` | The backend cannot produce output data for that request | Retry transient failures and inspect the message for backend details |
| `-32005` | The public endpoint rate-limited the request | Back off and retry later |

See also [Error reference](../errors.md).

## Examples

### Successful response

```bash
curl -sS https://mainnet.megaeth.com/rpc \
  -H 'content-type: application/json' \
  --data '{"jsonrpc":"2.0","id":301,"method":"mega_outputAtBlock","params":["0x100"]}'
```

```json
{
  "jsonrpc": "2.0",
  "id": 301,
  "result": {
    "version": "0x0000000000000000000000000000000000000000000000000000000000000000",
    "outputRoot": "0xe41251ac90623f6a303572f9abea7d48a259fdb5812d36fdc3102abc69a62f97",
    "blockRef": {
      "hash": "0x716a59d9fa50a9c225cbd4319bde1f1eccb9e8c3cacee8d7bda0dec17e1d9b34",
      "number": 256,
      "parentHash": "0xa1b2c3d4e5f60718293a4b5c6d7e8f9001122334455667788990aabbccddeeff",
      "timestamp": 1762797267,
      "l1origin": {
        "hash": "0x0011223344556677889900aabbccddeeff0011223344556677889900aabbccdd",
        "number": 21000000
      },
      "sequenceNumber": 0
    },
    "syncStatus": {
      "current_l1": {
        "hash": "0xaabbccdd00112233445566778899aabbccddeeff00112233445566778899aabb",
        "number": 24732192,
        "parentHash": "0x1122334455667788990011223344556677889900aabbccddeeff00112233aabb",
        "timestamp": 1774413083
      },
      "current_l1_finalized": {
        "hash": "0x2233445566778899aabbccddeeff001122334455667788990011223344556677",
        "number": 24732100,
        "parentHash": "0x3344556677889900aabbccddeeff00112233445566778899001122334455aabb",
        "timestamp": 1774411979
      },
      "head_l1": {
        "hash": "0xaabbccdd00112233445566778899aabbccddeeff00112233445566778899aabb",
        "number": 24732192,
        "parentHash": "0x1122334455667788990011223344556677889900aabbccddeeff00112233aabb",
        "timestamp": 1774413083
      },
      "safe_l1": {
        "hash": "0x4455667788990011223344556677889900aabbccddeeff001122334455667788",
        "number": 24732150,
        "parentHash": "0x5566778899001122334455667788990011223344aabbccddeeff001122334455",
        "timestamp": 1774412579
      },
      "finalized_l1": {
        "hash": "0x2233445566778899aabbccddeeff001122334455667788990011223344556677",
        "number": 24732100,
        "parentHash": "0x3344556677889900aabbccddeeff00112233445566778899001122334455aabb",
        "timestamp": 1774411979
      },
      "unsafe_l2": {
        "hash": "0x8899aabbccddeeff00112233445566778899001122334455667788990011aabb",
        "number": 11615881,
        "parentHash": "0x9900aabbccddeeff001122334455667788990011223344556677889900112233",
        "timestamp": 1774412892,
        "l1origin": { "hash": "0xaabbccdd00112233445566778899aabbccddeeff00112233445566778899aabb", "number": 24732192 },
        "sequenceNumber": 0
      },
      "safe_l2": {
        "hash": "0x8899aabbccddeeff00112233445566778899001122334455667788990011aabb",
        "number": 11615881,
        "parentHash": "0x9900aabbccddeeff001122334455667788990011223344556677889900112233",
        "timestamp": 1774412892,
        "l1origin": { "hash": "0xaabbccdd00112233445566778899aabbccddeeff00112233445566778899aabb", "number": 24732192 },
        "sequenceNumber": 0
      },
      "finalized_l2": {
        "hash": "0x7788990011223344556677889900aabbccddeeff00112233445566778899aabb",
        "number": 11615800,
        "parentHash": "0x8899001122334455667788990011223344556677aabbccddeeff001122334455",
        "timestamp": 1774412082,
        "l1origin": { "hash": "0x2233445566778899aabbccddeeff001122334455667788990011223344556677", "number": 24732100 },
        "sequenceNumber": 0
      }
    },
    "withdrawalStorageRoot": "0x8ed4baae3a927be3dea54996b4d5899f8c01e7594bf50b17dc1e741388ce3d12",
    "stateRoot": "0xf5e1d1c08df99fabc86c73c2f88f137f63a880e9776315964f0c8ac77ae86305"
  }
}
```

