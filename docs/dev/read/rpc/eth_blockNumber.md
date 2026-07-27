---
description: "eth_blockNumber JSON-RPC reference for MegaETH."
---

# eth_blockNumber

## Summary

Returns the latest block number.

The public MegaETH endpoint supports this method. The standard, node, and gateway layers below identify behavior that differs from a generic Ethereum endpoint.

## Parameters

None.

## Result

**`result`** Quantity

Current head block number; advances with each new block.

## Comparison with Ethereum Standard JSON-RPC

### Ethereum Standard

The canonical Ethereum method uses the parameter and result contract documented above, including the stated `null`, `false`, or zero-value semantics where applicable.

### MegaETH Node Behavior

The node returns the current canonical EVM block height. Mini-blocks produced within the current EVM block do not each increment this number.

### MegaETH Public Gateway

The gateway uses the instant read tier and may cache the head number for 1 second. Applications that need mini-block cadence should use WebSocket subscriptions instead.

## Errors

The `| Scope |` column distinguishes method failures from gateway policy errors.

No method-specific errors were observed.

| Code     | Scope            | Message             | When it happens                                              |
| -------- | ---------------- | ------------------- | ------------------------------------------------------------ |
| `-32005` | Transport/policy | Rate limit exceeded | The caller exceeds the public gateway's instant read budget. |
| `-32099` | Transport/policy | Payload too large   | The request body exceeds the 128 KiB public endpoint limit.  |

See also [Error Codes](./error-codes.md).

## Examples

Endpoint: `https://mainnet.megaeth.com/rpc`

Capture date: July 24, 2026

Outcome: success

```json
{
  "jsonrpc": "2.0",
  "id": 21,
  "method": "eth_blockNumber",
  "params": []
}
```

```json
{
  "jsonrpc": "2.0",
  "id": 21,
  "result": "0xaeb3d6"
}
```

## Sources

- Spec: `git@github.com:ethereum/execution-apis.git @ d24f58b56dcd16ab0f0c70ec609bcc1c42750b51: src/eth/client.yaml`
- Code: `git@github.com:megaeth-labs/mega-reth.git @ ab60376631228edab3a6df180f295280bad26e93: crates/rpc/rpc-eth-api/src/core.rs`
- Code: `git@github.com:megaeth-labs/mega-rpc.git @ 06aa35aa95d569c227cc25d2aa12834eb0458aa0: workers/src/spec/methods.ts`
- Probe: MegaETH Mainnet public endpoint, July 24, 2026
