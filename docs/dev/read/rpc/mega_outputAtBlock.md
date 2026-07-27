---
description: "mega_outputAtBlock JSON-RPC reference for MegaETH."
---

# mega_outputAtBlock

## Summary

Returns the output root at a given block.

The public MegaETH endpoint supports this method. The standard, node, and gateway layers below identify behavior that differs from a generic Ethereum endpoint.

## Parameters

**`blockNumber`** Quantity **REQUIRED**

Concrete hex block number; block tags such as `latest` are not accepted.

## Result

- **`version`** Hash32, optional

  Output version. Fresh upstream responses can include it, while the gateway's cached projection currently omits it.

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

## MegaETH Behavior

### Ethereum Standard

`mega_outputAtBlock` is not part of the core Ethereum execution JSON-RPC API. It is a MegaETH extension.

### MegaETH Node Behavior

The current MegaETH execution node's related native method is `mega_optimismOutputAtBlock`, which forwards a concrete block number to the OP node's `optimism_outputAtBlock` endpoint. The public `mega_outputAtBlock` spelling is a gateway-facing compatibility name.

### MegaETH Public Gateway

The gateway rewrites this method to `optimism_outputAtBlock` and routes it to the OP-node pool. It caches stable output data for 30 minutes but refreshes the embedded synchronization status on a 1-second cadence.
Its cached projection omits the upstream `version` field, so callers must tolerate `version` being present on a fresh response and absent on a cache hit.

This public behavior was confirmed from gateway source and the example was observed on July 27, 2026. Gateway policy and operational values may change.

## Errors

The `| Scope |` column distinguishes method failures from gateway policy errors.

| Code     | Scope            | Message             | When it happens                                                                       |
| -------- | ---------------- | ------------------- | ------------------------------------------------------------------------------------- |
| `-32602` | Request          | Invalid params      | Missing block number, wrong parameter count, or block tag instead of hex block number |
| `-32603` | Method           | Internal error      | Backend cannot produce output data for the requested block                            |
| `-32005` | Transport/policy | Rate limit exceeded | The caller exceeds the public gateway's simple read budget.                           |
| `-32099` | Transport/policy | Payload too large   | The request body exceeds the 128 KiB public endpoint limit.                           |

See also [Error Codes](./error-codes.md).

## Examples

Endpoint: `https://mainnet.megaeth.com/rpc`

Capture date: July 27, 2026

Outcome: success

```json
{
  "jsonrpc": "2.0",
  "id": 1,
  "method": "mega_outputAtBlock",
  "params": ["0x154de48"]
}
```

The captured response below is abridged; `syncStatus` contains additional L1 and L2 progress fields.

```json
{
  "jsonrpc": "2.0",
  "id": 1,
  "result": {
    "outputRoot": "0xf90851c88ec4adfe04b03f33beab99bbabbd73fc474ab7b3a8fa109a3913f047",
    "blockRef": {
      "hash": "0xce5344be15fecbe70574c97e57626f79a0816e8ebfc37a53ad535e82dd2def56",
      "number": 22339144,
      "parentHash": "0x85f2e75f7be8967a319af7de35275ad257150f80ae243b97f07b45332d3476a1",
      "timestamp": 1785136155,
      "l1origin": {
        "hash": "0xf79fbbd55e49baaff2f61e027b424b1b5b1ef7cd58bd7d664eb39947352b2f73",
        "number": 25622475
      },
      "sequenceNumber": 137
    },
    "syncStatus": {
      "head_l1": {
        "number": 25622556
      }
    },
    "withdrawalStorageRoot": "0x891f4462376be7ecac17a67a0ee5be7bc0c35979c182e5f7f19ebb2b1e320cc3",
    "stateRoot": "0x686f5150a2aec8f1b5ae15108288530860fa4157a9f39c71e55b0fa24783d506"
  }
}
```

## Sources

- Spec: EIP-1474 for JSON-RPC framing and error conventions; this method is an extension or legacy compatibility method.
- Code: `git@github.com:megaeth-labs/mega-reth.git @ ab60376631228edab3a6df180f295280bad26e93: crates/megaeth/rpc/src/mega.rs`
- Code: `git@github.com:megaeth-labs/mega-rpc.git @ 06aa35aa95d569c227cc25d2aa12834eb0458aa0: workers/src/processors/op-output-processor.ts`
- Probe: MegaETH Mainnet public endpoint, July 27, 2026; response abridged to stable top-level fields
