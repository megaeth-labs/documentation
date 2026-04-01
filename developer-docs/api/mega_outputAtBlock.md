# mega_outputAtBlock

Returns the L2 output commitment for a given block, including the output root, state root, and current sync status.

## Parameters

| Position | Name | Type | Required | Notes |
|---|---|---|---|---|
| `0` | `blockNumber` | [`Quantity`](../types.md#quantity) | Yes | Concrete hex block number; block tags such as `latest` are not accepted |

## Returns

| Field | Type | Notes |
|---|---|---|
| `version` | `Data (32 bytes)` | Output version; may be omitted on cache-hit paths |
| `outputRoot` | `Data (32 bytes)` | Output commitment |
| `blockRef` | `object` | Block reference; see fields below |
| `withdrawalStorageRoot` | `Data (32 bytes)` | Withdrawal storage root |
| `stateRoot` | `Data (32 bytes)` | State root |
| `syncStatus` | `object` | Backend sync-status snapshot |

**`blockRef` fields:**

| Field | Type | Notes |
|---|---|---|
| `hash` | `Data (32 bytes)` | Block hash |
| `number` | `number` | Block number (JSON number) |
| `parentHash` | `Data (32 bytes)` | Parent block hash |
| `timestamp` | `number` | Block timestamp (JSON number) |
| `l1origin` | `object` | L1 origin with `hash` and `number` |
| `sequenceNumber` | `number` | Sequence number |

## Errors

| Code | Cause | Fix |
|---|---|---|
| `-32602` | Missing block number, wrong parameter count, or block tag instead of hex block number | Fix the request parameters |
| `-32603` | Backend cannot produce output data for the requested block | Retry transient failures; inspect the error message for details |

See also [Error reference](../errors.md).

## Example

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
