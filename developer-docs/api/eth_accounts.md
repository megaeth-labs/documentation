# eth_accounts

## Summary
Returns the list of addresses managed by the client/node.

This method is part of the standard Ethereum JSON-RPC API and takes no parameters.

On MegaETH, `eth_accounts` returns an empty array `[]`.

## Parameters
- None

  Standard usage:
  - Send `params: []`.

  MegaETH behavior:
  - Omitted `params` are accepted.
  - Extra positional parameters are ignored for this method.

  Portability recommendation:
  - Always send `params: []`, because omitted or extra parameters are not portable Ethereum JSON-RPC behavior.

## Returns
- `result` (array)

  An array of `0x`-prefixed 20-byte Ethereum addresses managed by the client/node.

  Notes:
  - Each item, when present, is a hex-encoded Ethereum address.
  - An empty array is a valid result when no accounts are exposed.
  - On MegaETH, the result is `[]`.

## Examples

### curl: standard request (`params: []`)
```bash
curl -sS https://mainnet.megaeth.com/rpc \
  -H 'content-type: application/json' \
  --data '{"jsonrpc":"2.0","id":41,"method":"eth_accounts","params":[]}'
```

### JSON-RPC request: standard
```json
{"jsonrpc":"2.0","id":41,"method":"eth_accounts","params":[]}
```

### Response: standard
```json
{"jsonrpc":"2.0","id":41,"result":[]}
```

### JSON-RPC request: omitted `params` (MegaETH behavior)
```json
{"jsonrpc":"2.0","id":42,"method":"eth_accounts"}
```

### Response: omitted `params`
```json
{"jsonrpc":"2.0","id":42,"result":[]}
```

### JSON-RPC request: extra parameter (MegaETH behavior)
```json
{"jsonrpc":"2.0","id":43,"method":"eth_accounts","params":["0x1"]}
```

### Response: extra parameter
```json
{"jsonrpc":"2.0","id":43,"result":[]}
```

### JSON-RPC request: invalid envelope (`id: null`)
```json
{"jsonrpc":"2.0","id":null,"method":"eth_accounts","params":[]}
```

### Error response: invalid envelope
```json
{"jsonrpc":"2.0","id":null,"error":{"code":-32600,"message":"Invalid Request: id is required"}}
```

### Error response: rate limited (HTTP `429`)
```json
{"jsonrpc":"2.0","id":null,"error":{"code":-32005,"message":"Rate limit exceeded"}}
```

## MegaETH Behavior
- On MegaETH, `eth_accounts` returns `[]`.
- MegaETH accepts requests that omit `params` and ignores extra positional parameters for this method.
- This differs from full Ethereum nodes that may return locally managed signer addresses.
- `eth_accounts` is not available over MegaETH WebSocket RPC; use HTTP for this method.
- On public RPC endpoints, `eth_accounts` is in the `instant` rate-limit tier. Typical public usage is limited to `2,000` requests per `10` seconds; exceedance can return HTTP `429` with JSON-RPC error code `-32005`.

## Errors
- `-32005` Rate limit exceeded

  When it happens: The request exceeds the public endpoint rate limit for the `instant` tier.

  Typical transport: HTTP `429` with JSON-RPC error code `-32005`.

  Typical public limit: `2,000` requests per `10` seconds.

  Client handling: Retry with backoff and reduce burst rate.

- `-32600` Invalid request

  When it happens: The JSON-RPC envelope is malformed. On the MegaETH public HTTP path, single requests with a missing `id`, `id: null`, or an unsupported `id` type can be rejected.

  Client handling: Send a valid JSON-RPC 2.0 request object and use an `id` that is a string or number.

- `-32601` Method not allowed over WebSocket

  When it happens: `eth_accounts` is sent over MegaETH WebSocket RPC instead of HTTP.

  Example:
  ```json
  {"jsonrpc":"2.0","id":1,"error":{"code":-32601,"message":"Method not allowed over WebSocket: eth_accounts. Use HTTP RPC instead."}}
  ```

  Client handling: Send the method over HTTP instead.

## Best Practices
- Always send `params: []` for cross-provider compatibility.
- Do not use `eth_accounts` to discover end-user wallet addresses on MegaETH; expect `[]` and source addresses from your wallet or application flow.
- In user-wallet flows, use wallet/provider APIs such as EIP-1193 `eth_requestAccounts`.
- Use HTTP for this method.
- Treat an empty-array result as a normal successful response, not as an error.
- Back off on HTTP `429` / JSON-RPC `-32005`.

## Compatibility
- The method itself is standard Ethereum JSON-RPC.
- MegaETH's public endpoint behavior of always returning `[]` and tolerating omitted or extra `params` is implementation-specific and may differ from other providers.
- Other nodes may return locally managed signer addresses instead of `[]`.
