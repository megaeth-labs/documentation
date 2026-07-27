---
description: "mega_getBlockWitness JSON-RPC reference for MegaETH."
---

# mega_getBlockWitness

## Summary

Returns the execution witness for a block.

The public MegaETH endpoint supports this method. The standard, node, and gateway layers below identify behavior that differs from a generic Ethereum endpoint.

## Parameters

**`keys`** object **REQUIRED**

Block lookup key.

- **`blockNumber`** Quantity **REQUIRED**

  Target block number.

- **`blockHash`** Hash32

  Block hash for the same block number.
  Always include it when available so the lookup is pinned to a specific fork.

- **`parentHash`** Hash32

  Parent block hash for an OP payload lookup.
  Must be supplied together with `attributesHash` and cannot be combined with `blockHash`.

- **`attributesHash`** Hash32

  Payload-attributes hash for an OP payload lookup.
  Must be supplied together with `parentHash` and cannot be combined with `blockHash`.

{% hint style="warning" %}
A `blockNumber`-only lookup returns the first stored witness at that height and is not reorg-safe.
Use `blockNumber` together with `blockHash`, or the paired `parentHash` and `attributesHash`, for production verification.
{% endhint %}

## Result

**`result`** string

`v0:` followed by a base64-encoded zstd-compressed witness blob.

## MegaETH Behavior

### Ethereum Standard

`mega_getBlockWitness` is not part of the core Ethereum execution JSON-RPC API. It is a MegaETH extension.

### MegaETH Node Behavior

MegaETH returns a `v0:`-prefixed, base64-encoded zstd witness. Requests can select by block hash, or by the paired parent and payload-attributes hashes.

### MegaETH Public Gateway

The gateway does not cache witness responses. In an outer batch, if any witness request uses a block number below 7,385,897, at most four `mega_getBlockWitness` requests are allowed.

This public behavior was confirmed from gateway source and the example was observed on July 24, 2026. Gateway policy and operational values may change.

## Errors

The `| Scope |` column distinguishes method failures from gateway policy errors.

| Code     | Scope            | Message             | When it happens                                                             |
| -------- | ---------------- | ------------------- | --------------------------------------------------------------------------- |
| `-32602` | Request          | Invalid params      | `blockNumber` missing, invalid hex value, or invalid hash field combination |
| `-32603` | Method           | Internal error      | No witness exists for the requested keys, or the witness service failed     |
| `-32005` | Transport/policy | Rate limit exceeded | The caller exceeds the public gateway's simple read budget.                 |
| `-32099` | Transport/policy | Payload too large   | The request body exceeds the 128 KiB public endpoint limit.                 |

See also [Error Codes](./error-codes.md).

## Examples

Endpoint: `https://mainnet.megaeth.com/rpc`

Capture date: July 24, 2026

Outcome: success

```json
{
  "jsonrpc": "2.0",
  "id": 1,
  "method": "mega_getBlockWitness",
  "params": [
    {
      "blockNumber": "0x7fd",
      "blockHash": "0x262206173864c1e597ab9fcf2f718f95f942907207f4fed97dda66d272c5d4a6"
    }
  ]
}
```

```json
{
  "jsonrpc": "2.0",
  "id": 1,
  "result": "v0:KLUv/QBgzVUAZJwh\u2026"
}
```

## Sources

- Spec: EIP-1474 for JSON-RPC framing and error conventions; this method is an extension or legacy compatibility method.
- Code: `git@github.com:megaeth-labs/mega-reth.git @ ab60376631228edab3a6df180f295280bad26e93: crates/megaeth/rpc/src/witness.rs`
- Code: `git@github.com:megaeth-labs/mega-rpc.git @ 06aa35aa95d569c227cc25d2aa12834eb0458aa0: workers/src/services/batch/batch-processor.ts`
- Probe: MegaETH Mainnet public endpoint, July 24, 2026
