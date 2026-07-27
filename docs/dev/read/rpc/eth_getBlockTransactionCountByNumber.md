---
description: "eth_getBlockTransactionCountByNumber JSON-RPC reference for MegaETH."
---

# eth_getBlockTransactionCountByNumber

## Summary

Returns the number of transactions in a block identified by block number or tag.

The public MegaETH endpoint supports this method. The standard, node, and gateway layers below identify behavior that differs from a generic Ethereum endpoint.

## Parameters

**`block`** string **REQUIRED**

Hex block number or tag: `latest`, `safe`, `finalized`, `earliest`, `pending`.

## Result

**`result`** Quantity | null

Transaction count; `null` when the block is not found.

## MegaETH Behavior

### Ethereum Standard

The canonical Ethereum method uses the parameter and result contract documented above, including the stated `null`, `false`, or zero-value semantics where applicable.

### MegaETH Node Behavior

The node resolves the number or tag and returns the block's transaction count. An unknown block produces `null`.

### MegaETH Public Gateway

The gateway caches successful fixed-block lookups for 30 minutes in the simple read tier.

This public behavior was confirmed from gateway source and the example was observed on July 24, 2026. Gateway policy and operational values may change.

## Errors

The `| Scope |` column distinguishes method failures from gateway policy errors.

| Code     | Scope            | Message             | When it happens                                             |
| -------- | ---------------- | ------------------- | ----------------------------------------------------------- |
| `-32602` | Request          | Invalid params      | Block selector is malformed                                 |
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
  "id": 4,
  "method": "eth_getBlockTransactionCountByNumber",
  "params": ["0xb11362"]
}
```

```json
{
  "jsonrpc": "2.0",
  "id": 4,
  "result": "0x17"
}
```

## Sources

- Spec: `git@github.com:ethereum/execution-apis.git @ d24f58b56dcd16ab0f0c70ec609bcc1c42750b51: src/eth/block.yaml`
- Code: `git@github.com:megaeth-labs/mega-reth.git @ ab60376631228edab3a6df180f295280bad26e93: crates/rpc/rpc-eth-api/src/core.rs`
- Code: `git@github.com:megaeth-labs/mega-rpc.git @ 06aa35aa95d569c227cc25d2aa12834eb0458aa0: workers/src/spec/methods.ts`
- Probe: MegaETH Mainnet public endpoint, July 24, 2026
