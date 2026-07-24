---
description: "Returns the Ethereum protocol version reported by the MegaETH RPC node."
---

# eth_protocolVersion

## Summary

Returns the Ethereum protocol version reported by the connected node.
The public MegaETH endpoint supports this legacy compatibility method.

## Parameters

None.

## Result

The result is a hexadecimal `QUANTITY`.
Do not confuse this compatibility value with the MegaETH chain ID or network ID.

## MegaETH Behavior

### Ethereum Standard

The legacy method reports an Ethereum wire-protocol version and takes no parameters.

### MegaETH Node Behavior

MegaETH exposes the inherited compatibility method through the `eth` namespace.

### MegaETH Public Gateway

The gateway treats this response as immutable and may cache it.
The value shown in the example was observed on July 24, 2026, but callers should not use it for chain selection; use [`eth_chainId`](./eth_chainId.md) instead.

## Errors

The `| Scope |` column distinguishes request failures from gateway policy errors.

| Code     | Scope            | Message           | When it happens                                     |
| -------- | ---------------- | ----------------- | --------------------------------------------------- |
| `-32602` | Request          | Invalid params    | Unexpected parameters are supplied.                 |
| `-32099` | Transport/policy | Payload too large | The request exceeds the public endpoint body limit. |

No method-specific errors were observed.

## Examples

Endpoint: `https://mainnet.megaeth.com/rpc`

Capture date: July 24, 2026

Outcome: success

```json
{
  "jsonrpc": "2.0",
  "id": 1,
  "method": "eth_protocolVersion",
  "params": []
}
```

```json
{
  "jsonrpc": "2.0",
  "id": 1,
  "result": "0x5"
}
```

## Sources

- Code: `mega-reth@0264d0821a8fe14ac6c7f710e9452edef7407b3f`, `crates/rpc/rpc-eth-api/src/core.rs` (internal repository)
- Code: `mega-rpc@06aa35aa95d569c227cc25d2aa12834eb0458aa0`, `workers/src/spec/methods.ts` (internal repository)
- Probe: MegaETH Mainnet public endpoint, July 24, 2026
