---
description: "eth_getHeaderByNumber JSON-RPC reference for MegaETH."
---

# eth_getHeaderByNumber

## Summary

Returns a header-only view of a block by number or block tag.

The public MegaETH endpoint supports this method. The standard, node, and gateway layers below identify behavior that differs from a generic Ethereum endpoint.

## Parameters

**`block`** string **REQUIRED**

Hex block number or tag: `latest`, `safe`, `finalized`, `earliest`, `pending`.

## Result

`Header | null` — `null` when the block is not found.

- **`number`** Quantity

  Block number.

- **`hash`** Hash32

  Block hash.

- **`parentHash`** Hash32

  Parent block hash.

- **`timestamp`** Quantity

  Block timestamp.

- **`miner`** Address

  Fee recipient / coinbase.

- **`gasLimit`** Quantity

  Block gas limit.

- **`gasUsed`** Quantity

  Gas consumed.

Additional standard header fields (`stateRoot`, `logsBloom`, `transactionsRoot`, `receiptsRoot`, `baseFeePerGas`, …) are also included.

## MegaETH Behavior

### Ethereum Standard

`eth_getHeaderByNumber` is not part of the core Ethereum execution JSON-RPC API. It is an implementation-specific extension.

### MegaETH Node Behavior

MegaETH exposes a header-only lookup by number or tag. It returns `null` when the block cannot be resolved.

### MegaETH Public Gateway

The gateway returns `null` immediately for `pending`; other header responses are streamed and cached, with fixed blocks treated as immutable.

This public behavior was confirmed from gateway source and the example was observed on July 24, 2026. Gateway policy and operational values may change.

## Errors

The `| Scope |` column distinguishes method failures from gateway policy errors.

| Code     | Scope            | Message             | When it happens                                                |
| -------- | ---------------- | ------------------- | -------------------------------------------------------------- |
| `-32602` | Request          | Invalid params      | Malformed selector, decimal string, or unsupported object form |
| `-32005` | Transport/policy | Rate limit exceeded | The caller exceeds the public gateway's simple read budget.    |
| `-32099` | Transport/policy | Payload too large   | The request body exceeds the 128 KiB public endpoint limit.    |

See also [Error Codes](./error-codes.md).

## Examples

Endpoint: `https://mainnet.megaeth.com/rpc`

Capture date: July 24, 2026

Outcome: success

```json
{
  "jsonrpc": "2.0",
  "id": 27,
  "method": "eth_getHeaderByNumber",
  "params": ["0xb11048"]
}
```

```json
{
  "jsonrpc": "2.0",
  "id": 27,
  "result": {
    "hash": "0x235d80b5e91125a1a1d6da6776c6a9ee087d1818c494f71736b09bed61b1411e",
    "parentHash": "0x6fc0412abfba89bbfab17b2d8bd36cb1c214c1d53ed213fa8958439d0c4f9c18",
    "stateRoot": "0x301d7b77a74893451bd76e5d1672aaaa493cd78c06d59e885218d48917a35c03",
    "number": "0xb11048",
    "timestamp": "0x69c3361b",
    "baseFeePerGas": "0xf4240"
  }
}
```

## Sources

- Spec: EIP-1474 for JSON-RPC framing and error conventions; this method is an extension or legacy compatibility method.
- Code: `git@github.com:megaeth-labs/mega-reth.git @ ab60376631228edab3a6df180f295280bad26e93: crates/megaeth/rpc/src/eth/ext.rs`
- Code: `git@github.com:megaeth-labs/mega-rpc.git @ 06aa35aa95d569c227cc25d2aa12834eb0458aa0: workers/src/processors/simple-cache-processor.ts`
- Probe: MegaETH Mainnet public endpoint, July 24, 2026
