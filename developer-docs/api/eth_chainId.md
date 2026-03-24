# eth_chainId

## Summary
Returns the current network's chain ID as a `0x`-prefixed hex `QUANTITY`.

This method is part of the standard Ethereum JSON-RPC API and takes no parameters.

## Parameters
- None

  Send `params: []` for maximum interoperability.

  Do not rely on extra positional parameters being accepted by other providers.

## Returns
- `result` (string)

  A `0x`-prefixed hex `QUANTITY` representing the current network's chain ID.

  Notes:
  - No leading zeros, except `0x0`.
  - Parse as an unsigned integer chain identifier.
  - The value is stable for a given endpoint/network and can usually be cached client-side.

## Examples

### curl: standard request
```bash
curl -sS https://mainnet.megaeth.com/rpc \
  -H 'content-type: application/json' \
  --data '{"jsonrpc":"2.0","id":31,"method":"eth_chainId","params":[]}'
```

### JSON-RPC request: standard
```json
{"jsonrpc":"2.0","id":31,"method":"eth_chainId","params":[]}
```

### Response: standard
```json
{"jsonrpc":"2.0","id":31,"result":"0x10e6"}
```

### JSON-RPC request: extra parameter (MegaETH observed behavior)
```json
{"jsonrpc":"2.0","id":32,"method":"eth_chainId","params":["0x2"]}
```

### Response: extra parameter
```json
{"jsonrpc":"2.0","id":32,"result":"0x10e6"}
```

## MegaETH Behavior
- On the MegaETH mainnet public endpoint, `eth_chainId` currently returns `0x10e6`.
- MegaETH currently ignores an extra positional parameter for this method, but this is a non-standard compatibility behavior and should not be relied on.
- Public endpoints may enforce rate limits.

## Errors
- `-32005` Rate limit exceeded

  When it happens: The request exceeds the applicable rate limit.

  Typical transport: HTTP `429` with JSON-RPC error code `-32005`.

  Client handling: Retry with backoff.

- `-32600` Invalid request

  When it happens: The JSON-RPC envelope is malformed, for example a missing or invalid `jsonrpc` field.

  Client handling: Fix the JSON-RPC request envelope before retrying.

## Best Practices
- Always send `params: []`.
- Cache the chain ID per endpoint and avoid calling this method repeatedly.
- Treat the result as a hex `QUANTITY`, not a decimal string.
- Do not depend on extra-parameter tolerance.
- Re-check the chain ID when switching endpoints or networks.

## Compatibility
- The method itself is standard Ethereum JSON-RPC.
