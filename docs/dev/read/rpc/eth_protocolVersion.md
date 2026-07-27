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

## Comparison with Ethereum Standard JSON-RPC

### Ethereum Standard

The legacy method reports an Ethereum wire-protocol version and takes no parameters.

### MegaETH Node Behavior

MegaETH exposes the inherited compatibility method through the `eth` namespace.

### MegaETH Public Gateway

The gateway treats this response as immutable and may cache it.
Callers should not use this value for chain selection; use [`eth_chainId`](./eth_chainId.md) instead.

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

- Probe: MegaETH Mainnet public endpoint, July 24, 2026
