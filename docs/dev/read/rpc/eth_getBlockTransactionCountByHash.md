---
description: "eth_getBlockTransactionCountByHash JSON-RPC reference for MegaETH."
---

# eth_getBlockTransactionCountByHash

## Summary

Returns the number of transactions in the block matching the given hash.

The public MegaETH endpoint supports this method. The standard, node, and gateway layers below identify behavior that differs from a generic Ethereum endpoint.

## Parameters

**`blockHash`** Hash32 **REQUIRED**

Target block hash.

## Result

**`result`** Quantity | null

Transaction count; `null` when the block is not found.

## MegaETH Behavior

### Ethereum Standard

The canonical Ethereum method uses the parameter and result contract documented above, including the stated `null`, `false`, or zero-value semantics where applicable.

### MegaETH Node Behavior

The node looks up the block and returns its transaction count. An unknown block produces `null`.

### MegaETH Public Gateway

The gateway caches successful hash-based lookups for 30 minutes in the simple read tier.

This public behavior was confirmed from gateway source and the example was observed on July 24, 2026. Gateway policy and operational values may change.

## Errors

The `| Scope |` column distinguishes method failures from gateway policy errors.

| Code     | Scope            | Message             | When it happens                                             |
| -------- | ---------------- | ------------------- | ----------------------------------------------------------- |
| `-32602` | Request          | Invalid params      | Block hash missing or malformed                             |
| `-32005` | Transport/policy | Rate limit exceeded | The caller exceeds the public gateway's simple read budget. |
| `-32099` | Transport/policy | Payload too large   | The request body exceeds the 128 KiB public endpoint limit. |

See also [Error Codes](./error-codes.md).

## Examples

Endpoint: `https://mainnet.megaeth.com/rpc`

Capture date: July 24, 2026

Outcome: success

```json
{
  "jsonrpc": "2.0",
  "id": 3,
  "method": "eth_getBlockTransactionCountByHash",
  "params": [
    "0xa97b8563203de36f0c8430709734438fbf7f2444b6de9f307853fc46b230de3e"
  ]
}
```

```json
{
  "jsonrpc": "2.0",
  "id": 3,
  "result": "0x18"
}
```

## Sources

- Spec: `git@github.com:ethereum/execution-apis.git @ d24f58b56dcd16ab0f0c70ec609bcc1c42750b51: src/eth/block.yaml`
- Code: `git@github.com:megaeth-labs/mega-reth.git @ ab60376631228edab3a6df180f295280bad26e93: crates/rpc/rpc-eth-api/src/core.rs`
- Code: `git@github.com:megaeth-labs/mega-rpc.git @ 06aa35aa95d569c227cc25d2aa12834eb0458aa0: workers/src/spec/methods.ts`
- Probe: MegaETH Mainnet public endpoint, July 24, 2026
