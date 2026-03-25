# eth_unsubscribe

## Summary
Cancels an active subscription created by `eth_subscribe`.

Use this method over WebSocket. The subscription ID is scoped to the WebSocket connection that created it.

## Parameters
- `subscriptionId` (required): `string`

  Accepted values:
  - the exact subscription ID previously returned by `eth_subscribe`

  Notes:
  - Send the subscription ID as `params[0]`.
  - Send exactly one positional parameter.
  - Use the same WebSocket connection that created the subscription.

## Returns
- `result` (`boolean`)

  Returns `true` if the subscription was removed.

  Returns `false` if no matching subscription is currently known for that request.

  Notes:
  - This method returns only an acknowledgement boolean.
  - A successful unsubscribe stops future notifications for that subscription on the current connection.

## Examples

### wscat: connect over WebSocket
```bash
wscat -n -c wss://mainnet.megaeth.com/rpc
```

### JSON-RPC request: subscribe to newHeads
```json
{"jsonrpc":"2.0","id":1,"method":"eth_subscribe","params":["newHeads"]}
```

### Response: subscribe success
```json
{"jsonrpc":"2.0","result":"0x3fd9d5f731bc9d92235eb378da083e53","id":1}
```

### JSON-RPC request: unsubscribe
```json
{"jsonrpc":"2.0","id":2,"method":"eth_unsubscribe","params":["0x3fd9d5f731bc9d92235eb378da083e53"]}
```

### Response: unsubscribe success
```json
{"jsonrpc":"2.0","result":true,"id":2}
```

### JSON-RPC request: unknown subscription ID
```json
{"jsonrpc":"2.0","id":11,"method":"eth_unsubscribe","params":["0xdeadbeef"]}
```

### Response: unknown subscription ID
```json
{"jsonrpc":"2.0","result":false,"id":11}
```

### JSON-RPC request: missing subscription ID
```json
{"jsonrpc":"2.0","id":12,"method":"eth_unsubscribe","params":[]}
```

### Error response: missing subscription ID
```json
{"jsonrpc":"2.0","error":{"code":-32602,"message":"Invalid params: subscription ID required"},"id":12}
```

### curl: HTTP request on the public endpoint
```bash
curl -sS https://mainnet.megaeth.com/rpc \
  -H 'content-type: application/json' \
  --data '{"jsonrpc":"2.0","id":201,"method":"eth_unsubscribe","params":["0x1"]}'
```

### Error response: HTTP request
```json
{"jsonrpc":"2.0","id":null,"error":{"code":-32601,"message":"Method eth_unsubscribe not found"}}
```

## MegaETH Behavior
- On the MegaETH public endpoint, use `wss://mainnet.megaeth.com/rpc` for `eth_unsubscribe`.
- The public HTTP endpoint `https://mainnet.megaeth.com/rpc` currently does not expose this method.
- A missing subscription ID returns `-32602`.
- A subscription ID that is not valid for the current client may return `false` or an error, depending on how the server classifies it.
- Public endpoints may enforce rate limits.

## Errors
- `-32602` Invalid params

  When it happens: The request omits `params[0]`.

  Example:
  ```json
  {"jsonrpc":"2.0","error":{"code":-32602,"message":"Invalid params: subscription ID required"},"id":12}
  ```

  Client handling: Always send exactly one subscription ID in `params[0]`.

- `-32600` Subscription not owned by this client

  When it happens: The subscription ID does not belong to the current WebSocket client, for example after it has already been removed from that client.

  Example:
  ```json
  {"jsonrpc":"2.0","error":{"code":-32600,"message":"Cannot unsubscribe: subscription not owned by this client"},"id":3}
  ```

  Client handling: Track subscription IDs per WebSocket connection and only unsubscribe on the connection that created them.

- `-32601` Method not found

  When it happens: The request is sent to the public HTTP endpoint instead of the WebSocket endpoint.

  Example:
  ```json
  {"jsonrpc":"2.0","id":null,"error":{"code":-32601,"message":"Method eth_unsubscribe not found"}}
  ```

  Client handling: Use `wss://mainnet.megaeth.com/rpc` for subscription methods.

## Best Practices
- Store subscription IDs exactly as returned by `eth_subscribe`.
- Unsubscribe on the same WebSocket connection that created the subscription.
- Treat `result: false` as a no-op.
- Handle both `false` and ownership-related errors for stale subscription IDs.
- Use WebSocket transport for `eth_subscribe` and `eth_unsubscribe`.

## Compatibility
- `eth_unsubscribe` is a WebSocket subscription method, not a general-purpose HTTP RPC method.
- Subscription IDs are connection-scoped and are not portable across connections or providers.
- MegaETH public endpoint behavior differs by transport: WebSocket supports this method, while HTTP currently returns `-32601`.
