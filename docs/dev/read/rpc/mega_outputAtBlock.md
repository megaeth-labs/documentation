---
description: "mega_outputAtBlock JSON-RPC reference for MegaETH."
---

# mega_outputAtBlock

Returns the output root at a given block.

## Parameters

**`blockNumber`** Quantity **REQUIRED**

Concrete hex block number; block tags such as `latest` are not accepted.

## Returns

- **`version`** Hash32

  Output version.

- **`outputRoot`** Hash32

  Output commitment.

- **`blockRef`** object

  Block reference; see fields below.

  - **`hash`** Hash32

    Block hash.

  - **`number`** number

    Block number (JSON number).

  - **`parentHash`** Hash32

    Parent block hash.

  - **`timestamp`** number

    Block timestamp (JSON number).

  - **`l1origin`** object

    L1 origin with `hash` and `number`.

  - **`sequenceNumber`** number

    Sequence number.

- **`withdrawalStorageRoot`** Hash32

  Withdrawal storage root.

- **`stateRoot`** Hash32

  State root.

- **`syncStatus`** object

  Backend sync-status snapshot.

## Errors

| Code     | Cause                                                                                 | Fix                                                             |
| -------- | ------------------------------------------------------------------------------------- | --------------------------------------------------------------- |
| `-32602` | Missing block number, wrong parameter count, or block tag instead of hex block number | Fix the request parameters                                      |
| `-32603` | Backend cannot produce output data for the requested block                            | Retry transient failures; inspect the error message for details |

See also [Error reference](error-codes.md).

## Example

```bash
curl -sS https://mainnet.megaeth.com/rpc \
  -H 'content-type: application/json' \
  --data '{"jsonrpc":"2.0","id":301,"method":"mega_outputAtBlock","params":["0x100"]}'
```

The response below is illustrative; hashes and sync-status values are synthetic.

```json
{
  "jsonrpc": "2.0",
  "id": 301,
  "result": {
    "version": "0x0000000000000000000000000000000000000000000000000000000000000000",
    "outputRoot": "0x0000000000000000000000000000000000000000000000000000000000000001",
    "blockRef": {
      "hash": "0x0000000000000000000000000000000000000000000000000000000000000002",
      "number": 256,
      "parentHash": "0x0000000000000000000000000000000000000000000000000000000000000003",
      "timestamp": 1762797267,
      "l1origin": {
        "hash": "0x0000000000000000000000000000000000000000000000000000000000000004",
        "number": 21000000
      },
      "sequenceNumber": 0
    },
    "syncStatus": {
      "current_l1": {
        "hash": "0x0000000000000000000000000000000000000000000000000000000000000011",
        "number": 24732192
      },
      "unsafe_l2": {
        "hash": "0x0000000000000000000000000000000000000000000000000000000000000012",
        "number": 11615881
      },
      "safe_l2": {
        "hash": "0x0000000000000000000000000000000000000000000000000000000000000013",
        "number": 11615881
      },
      "finalized_l2": {
        "hash": "0x0000000000000000000000000000000000000000000000000000000000000014",
        "number": 11615800
      }
    },
    "withdrawalStorageRoot": "0x0000000000000000000000000000000000000000000000000000000000000005",
    "stateRoot": "0x0000000000000000000000000000000000000000000000000000000000000006"
  }
}
```
