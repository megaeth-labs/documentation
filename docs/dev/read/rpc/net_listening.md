---
description: "net_listening JSON-RPC reference for MegaETH."
---

# net_listening

## Summary

Returns whether the node is listening for connections.

The public MegaETH endpoint supports this method. The standard, node, and gateway layers below identify behavior that differs from a generic Ethereum endpoint.

## Parameters

None.

## Result

**`result`** boolean

Always `true`.

## Comparison with Ethereum Standard JSON-RPC

### Ethereum Standard

`net_listening` is a legacy Ethereum client/network compatibility method rather than a current execution-API method. Implementations commonly expose it with the result shape above.

### MegaETH Node Behavior

The inherited network method reports whether the node's peer-to-peer service is listening.

### MegaETH Public Gateway

The gateway forwards this dynamic value without response caching in the simple read tier.

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

Capture date: July 24, 2026

Outcome: success

```json
{
  "jsonrpc": "2.0",
  "id": 1,
  "method": "net_listening",
  "params": []
}
```

```json
{
  "jsonrpc": "2.0",
  "id": 1,
  "result": true
}
```

## Sources

- Spec: EIP-1474 for JSON-RPC framing and error conventions; this method is an extension or legacy compatibility method.
- Code: `git@github.com:megaeth-labs/mega-reth.git @ ab60376631228edab3a6df180f295280bad26e93: crates/rpc/rpc/src/net.rs`
- Code: `git@github.com:megaeth-labs/mega-rpc.git @ 06aa35aa95d569c227cc25d2aa12834eb0458aa0: workers/src/spec/methods.ts`
- Probe: MegaETH Mainnet public endpoint, July 24, 2026
