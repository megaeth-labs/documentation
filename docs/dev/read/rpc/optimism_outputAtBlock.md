---
description: "Returns the OP Stack output-root data for a MegaETH block."
---

# optimism_outputAtBlock

## Summary

Returns the same output-root data as [`mega_outputAtBlock`](./mega_outputAtBlock.md).
The two names are aliases on MegaETH.

The public MegaETH endpoint supports this method. The standard, node, and gateway layers below identify behavior that differs from a generic Ethereum endpoint.

## Parameters

| Position | Name          | Type       | Required | Description                                                     |
| -------- | ------------- | ---------- | -------- | --------------------------------------------------------------- |
| `0`      | `blockNumber` | `QUANTITY` | Yes      | Concrete hexadecimal block number; block tags are not accepted. |

## Result

An output object containing `outputRoot`, `blockRef`, `withdrawalStorageRoot`, `stateRoot`, and `syncStatus`.
The upstream `version` field can be present on a fresh response but is omitted by the gateway's cached projection.
See [`mega_outputAtBlock`](./mega_outputAtBlock.md#result) for every field.

## MegaETH Behavior

### Ethereum Standard

`optimism_outputAtBlock` is not part of the core Ethereum execution JSON-RPC API. It is an OP Stack extension.

### MegaETH Node Behavior

This is the OP node's native output-root method. The related MegaETH execution-node method is `mega_optimismOutputAtBlock`, which forwards to it.

### MegaETH Public Gateway

The gateway accepts this name and `mega_outputAtBlock`, routes both to the OP-node pool as `optimism_outputAtBlock`, and applies the same split cache policy for output data and synchronization status.
Because the cached projection omits `version`, callers must not require that field even though it can appear on a fresh response.

## Errors

The `| Scope |` column distinguishes method failures from gateway policy errors.

No method-specific errors were observed.

| Code     | Scope            | Message             | When it happens                                             |
| -------- | ---------------- | ------------------- | ----------------------------------------------------------- |
| `-32005` | Transport/policy | Rate limit exceeded | The caller exceeds the public gateway's simple read budget. |
| `-32099` | Transport/policy | Payload too large   | The request body exceeds the 128 KiB public endpoint limit. |

See also [Error Codes](./error-codes.md).

## Examples

Endpoint: `https://mainnet.megaeth.com/rpc`

Capture date: July 27, 2026

Outcome: success

```json
{
  "jsonrpc": "2.0",
  "id": 1,
  "method": "optimism_outputAtBlock",
  "params": ["0x154de48"]
}
```

The captured response below is abridged; `syncStatus` contains additional L1 and L2 progress fields.

```json
{
  "jsonrpc": "2.0",
  "id": 1,
  "result": {
    "version": "0x0000000000000000000000000000000000000000000000000000000000000000",
    "outputRoot": "0xf90851c88ec4adfe04b03f33beab99bbabbd73fc474ab7b3a8fa109a3913f047",
    "blockRef": {
      "hash": "0xce5344be15fecbe70574c97e57626f79a0816e8ebfc37a53ad535e82dd2def56",
      "number": 22339144
    },
    "withdrawalStorageRoot": "0x891f4462376be7ecac17a67a0ee5be7bc0c35979c182e5f7f19ebb2b1e320cc3",
    "stateRoot": "0x686f5150a2aec8f1b5ae15108288530860fa4157a9f39c71e55b0fa24783d506",
    "syncStatus": {
      "head_l1": {
        "number": 25622556
      }
    }
  }
}
```

## Sources

- Spec: EIP-1474 for JSON-RPC framing and error conventions; this method is an extension or legacy compatibility method.
- Code: `git@github.com:megaeth-labs/mega-reth.git @ ab60376631228edab3a6df180f295280bad26e93: crates/megaeth/rpc/src/mega.rs`
- Code: `git@github.com:megaeth-labs/mega-rpc.git @ 06aa35aa95d569c227cc25d2aa12834eb0458aa0: workers/src/processors/op-output-processor.ts`
- Probe: MegaETH Mainnet public endpoint, July 27, 2026; response abridged to stable top-level fields
