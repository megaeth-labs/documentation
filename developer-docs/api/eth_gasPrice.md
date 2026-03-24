# eth_gasPrice

## Summary
Returns the current gas price in wei as a `0x`-prefixed hex `QUANTITY`.

This method is part of the Ethereum JSON-RPC API and takes no parameters. On the MegaETH public gateway, standalone request behavior differs from typical provider behavior: a single request returns a fixed value, while a batch request returns a network-derived value.

## Parameters
- None

  Send `params: []` for maximum interoperability. Do not send extra parameters.

## Returns
- `result` (string)

  A `0x`-prefixed hex `QUANTITY` representing the gas price in wei.

  Notes:
  - The value has no leading zeros, except `0x0`.
  - Parse it as an integer in wei.
  - Convert units in client code as needed.

## Examples

### curl: standalone request
```bash
curl -sS https://mainnet.megaeth.com/rpc \
  -H 'content-type: application/json' \
  --data '{"jsonrpc":"2.0","id":1,"method":"eth_gasPrice","params":[]}'
```

### JSON-RPC request: standalone
```json
{"jsonrpc":"2.0","id":1,"method":"eth_gasPrice","params":[]}
```

### Response: standalone
```json
{"jsonrpc":"2.0","id":1,"result":"0xf4240"}
```

### curl: single-element batch request
```bash
curl -sS https://mainnet.megaeth.com/rpc \
  -H 'content-type: application/json' \
  --data '[{"jsonrpc":"2.0","id":1,"method":"eth_gasPrice","params":[]}]'
```

### JSON-RPC request: batch
```json
[{"jsonrpc":"2.0","id":1,"method":"eth_gasPrice","params":[]}]
```

### Response: batch
```json
[{"jsonrpc":"2.0","id":1,"result":"<HEX_QUANTITY>"}]
```

Notes:
- In batch mode, the response is an array.
- Match results by `id`, not by array position.
- The batch value is network-derived and may vary over time.
- Under low activity, the batch-derived value may also be `0xf4240`.

## MegaETH Behavior
- On the MegaETH public gateway, a standalone `eth_gasPrice` request returns a fixed value: `0xf4240`.
- On the MegaETH public gateway, any batch request, including a single-element batch, returns a network-derived gas price.
- This standalone-vs-batch behavior is MegaETH public gateway specific and is not part of the Ethereum JSON-RPC specification.
- The batch-derived value may be briefly stale. Do not rely on an exact refresh interval.
- Public endpoints may enforce rate limits.

## Errors
- `-32005` Rate limited

  When it happens: The request exceeds the applicable rate limit.

  Example:
  ```json
  {"jsonrpc":"2.0","id":1,"error":{"code":-32005,"message":"rate limited"}}
  ```

  Client handling: Retry with backoff. MegaETH may also return HTTP `429`.

- `-32600` Invalid request

  When it happens: The JSON-RPC envelope is malformed, for example a missing or invalid `id`.

  Client handling: Fix the JSON-RPC request envelope before retrying.

- `-32601` Method not found

  When it happens: The server does not support `eth_gasPrice`.

  Client handling: Confirm that the endpoint supports this method and that the request was sent to the expected route.

- `-32602` Invalid params

  When it happens: The request includes unexpected parameters or an invalid `params` shape.

  Example:
  ```json
  {"jsonrpc":"2.0","id":1,"error":{"code":-32602,"message":"invalid params"}}
  ```

  Client handling: Send `params: []` and remove unexpected arguments before retrying.

## Best Practices
- Always send `params: []`.
- On MegaETH, use batch mode if you need a network-derived gas price.
- Do not use the standalone MegaETH response for fee estimation.
- Prefer EIP-1559-aware fee logic in transaction construction.
- When processing batch responses, match by `id` rather than array order.

## Compatibility
- The method itself is standard Ethereum JSON-RPC.
- MegaETH public gateway handling for this method is not standard:
  - standalone request -> fixed value
  - batch request -> network-derived value
- Do not assume other providers behave the same way.
