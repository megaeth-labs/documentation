---
description: "debug_getHistoryTransactionCount JSON-RPC reference for MegaETH."
---

# debug_getHistoryTransactionCount

## Summary

Returns the chain-wide cumulative transaction count up to and including a given block.

The public MegaETH endpoint supports this method. The standard, node, and gateway layers below identify behavior that differs from a generic Ethereum endpoint.

## Parameters

**`block`** string **REQUIRED**

Hex block number or tag (`earliest`, `latest`, `safe`, `finalized`).
`pending` is not supported.

## Result

**`result`** Quantity

Cumulative transaction count across all blocks up to the selected block.
Consecutive blocks with no transactions return the same value.

## Comparison with Ethereum Standard JSON-RPC

### Ethereum Standard

`debug_getHistoryTransactionCount` is not part of the core Ethereum execution JSON-RPC API. It is a MegaETH debug extension.

### MegaETH Node Behavior

MegaETH adds this diagnostic method. It resolves the selected block and returns the cumulative transaction count through that block; `pending` is not a supported selector.

### MegaETH Public Gateway

The public gateway exposes the method in the simple read tier and caches resolved results as immutable data for 30 minutes.

## Errors

The `| Scope |` column distinguishes method failures from gateway policy errors.

| Code     | Scope            | Message             | When it happens                                                                 |
| -------- | ---------------- | ------------------- | ------------------------------------------------------------------------------- |
| `-32001` | Method           | Resource not found  | Block selector cannot be resolved or unsupported tag such as `pending` was used |
| `-32602` | Request          | Invalid params      | Invalid parameter shape                                                         |
| `-32005` | Transport/policy | Rate limit exceeded | The caller exceeds the public gateway's simple read budget.                     |
| `-32099` | Transport/policy | Payload too large   | The request body exceeds the 128 KiB public endpoint limit.                     |

See also [Error Codes](../error-codes.md).

## Examples

Endpoint: `https://mainnet.megaeth.com/rpc`

Capture date: July 24, 2026

Outcome: success

```json
{
  "jsonrpc": "2.0",
  "id": 1,
  "method": "debug_getHistoryTransactionCount",
  "params": ["0x12a05f"]
}
```

```json
{
  "jsonrpc": "2.0",
  "id": 1,
  "result": "0x12cbab"
}
```

## Sources

- Spec: EIP-1474 for JSON-RPC framing and error conventions; this method is an extension or legacy compatibility method.
- Code: `git@github.com:megaeth-labs/mega-reth.git @ ab60376631228edab3a6df180f295280bad26e93: crates/megaeth/rpc/src/debug.rs`
- Code: `git@github.com:megaeth-labs/mega-rpc.git @ 06aa35aa95d569c227cc25d2aa12834eb0458aa0: workers/src/spec/methods.ts`
- Probe: MegaETH Mainnet public endpoint, July 24, 2026
