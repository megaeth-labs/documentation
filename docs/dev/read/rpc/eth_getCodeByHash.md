---
description: "eth_getCodeByHash JSON-RPC reference for MegaETH."
---

# eth_getCodeByHash

## Summary

Returns runtime bytecode for a given code hash.

The public MegaETH endpoint supports this method. The standard, node, and gateway layers below identify behavior that differs from a generic Ethereum endpoint.

## Parameters

**`codeHash`** Hash32 **REQUIRED**

Target runtime code hash.

## Result

**`result`** Data

Runtime bytecode; `0x` when no bytecode is stored for that hash.

## MegaETH Behavior

### Ethereum Standard

`eth_getCodeByHash` is not part of the core Ethereum execution JSON-RPC API. It is an implementation-specific extension.

### MegaETH Node Behavior

MegaETH adds a direct code-hash lookup that returns the stored runtime bytecode. An unknown code hash produces empty bytecode rather than an account lookup.

### MegaETH Public Gateway

The public gateway exposes this MegaETH extension and caches successful immutable lookups for 30 minutes.

This public behavior was confirmed from gateway source and the example was observed on July 24, 2026. Gateway policy and operational values may change.

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
  "id": 43,
  "method": "eth_getCodeByHash",
  "params": [
    "0xfa8c9db6c6cab7108dea276f4cd09d575674eb0852c0fa3187e59e98ef977998"
  ]
}
```

```json
{
  "jsonrpc": "2.0",
  "id": 43,
  "result": "0x6080604052\u2026"
}
```

## Sources

- Spec: EIP-1474 for JSON-RPC framing and error conventions; this method is an extension or legacy compatibility method.
- Code: `git@github.com:megaeth-labs/mega-reth.git @ ab60376631228edab3a6df180f295280bad26e93: crates/megaeth/rpc/src/eth/ext.rs`
- Code: `git@github.com:megaeth-labs/mega-rpc.git @ 06aa35aa95d569c227cc25d2aa12834eb0458aa0: workers/src/spec/methods.ts`
- Probe: MegaETH Mainnet public endpoint, July 24, 2026
