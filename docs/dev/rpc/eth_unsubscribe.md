---
description: "eth_unsubscribe JSON-RPC reference for MegaETH."
---

# eth_unsubscribe

## Summary

Cancels an existing subscription so that no further events are sent.

The public MegaETH endpoint supports this method. The standard, node, and gateway layers below identify behavior that differs from a generic Ethereum endpoint.

## Parameters

**`subscriptionId`** Data **REQUIRED**

Subscription ID returned by `eth_subscribe`.

## Result

**`result`** boolean

`true` if the subscription was found and cancelled; `false` if the ID was not active.

## Comparison with Ethereum Standard JSON-RPC

### Ethereum Standard

`eth_unsubscribe` is part of the commonly implemented Ethereum WebSocket subscription API, but it is not specified by the core execution JSON-RPC API.

### MegaETH Node Behavior

The node cancels a subscription in the WebSocket session that created it. Subscription IDs are connection-scoped.

### MegaETH Public Gateway

The public method is WebSocket-only. The gateway keeps subscription ownership per connection and rejects attempts to cancel a subscription from another session.

## Errors

The `| Scope |` column distinguishes method failures from gateway policy errors.

| Code     | Scope   | Message         | When it happens                                    |
| -------- | ------- | --------------- | -------------------------------------------------- |
| `-32602` | Request | Invalid params  | Subscription ID parameter is missing               |
| `-32600` | Request | Invalid request | Subscription was created by a different connection |

See also [Error Codes](./error-codes.md).

## Examples

Endpoint: `wss://mainnet.megaeth.com/ws` (WebSocket)

Capture date: July 24, 2026

Outcome: success

```json
{
  "jsonrpc": "2.0",
  "id": 1,
  "method": "eth_unsubscribe",
  "params": ["0xaec58cfc2dc41f873fc37d6c871230c1"]
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
- Code: `git@github.com:megaeth-labs/mega-reth.git @ ab60376631228edab3a6df180f295280bad26e93: crates/megaeth/rpc/src/eth/api.rs`
- Code: `git@github.com:megaeth-labs/mega-rpc.git @ 06aa35aa95d569c227cc25d2aa12834eb0458aa0: workers/src/rpc-gateway/websocket-session.ts`
- Probe: MegaETH Mainnet public endpoint, July 24, 2026
