# eth_blockNumber

## Summary
Returns the current head block number as a `0x`-prefixed hex `QUANTITY`.

This method is part of the standard Ethereum JSON-RPC API and takes no parameters.

## Parameters
- None

  For portable client behavior, send either:
  - `params: []`
  - or omit `params` entirely

  Do not rely on omitted `params` or extra positional parameters being accepted by other providers.

## Returns
- `result` (string)

  A `0x`-prefixed hex `QUANTITY` representing the current head block number.

  Notes:
  - No leading zeros, except `0x0`.
  - Parse as an unsigned integer block height.
  - This is a moving head value and can change between calls.

## Examples

### curl: standard request (`params: []`)
```bash
curl -sS https://mainnet.megaeth.com/rpc \
  -H 'content-type: application/json' \
  --data '{"jsonrpc":"2.0","id":21,"method":"eth_blockNumber","params":[]}'
```

### JSON-RPC request: standard
```json
{"jsonrpc":"2.0","id":21,"method":"eth_blockNumber","params":[]}
```

### Response: standard
```json
{"jsonrpc":"2.0","id":21,"result":"0xaeb3d6"}
```

### JSON-RPC request: omitted `params`
```json
{"jsonrpc":"2.0","id":22,"method":"eth_blockNumber"}
```

### Response: omitted `params`
```json
{"jsonrpc":"2.0","id":22,"result":"0xaeb3d6"}
```

### JSON-RPC request: extra parameter (MegaETH observed behavior)
```json
{"jsonrpc":"2.0","id":23,"method":"eth_blockNumber","params":["0x2"]}
```

### Response: extra parameter
```json
{"jsonrpc":"2.0","id":23,"result":"0xaeb3d6"}
```

## MegaETH Behavior
- Public endpoint currently accepts requests that omit `params`; extra positional parameters are also accepted and ignored for this method.
- The lenient parameter behavior above is MegaETH implementation behavior and is not part of the Ethereum JSON-RPC specification.
- Public endpoints may enforce rate limits.

## Errors
- `-32005` Rate limit exceeded

  When it happens: The request exceeds the applicable rate limit.

  Typical transport: HTTP `429` with JSON-RPC error code `-32005`.

  Client handling: Retry with backoff.

- `-32603` Internal error

  When it happens: Upstream node/provider cannot serve current chain info.

  Client handling: Treat as transient infrastructure/provider failure and retry with backoff.

- `-32600` Invalid request

  When it happens: JSON-RPC envelope is malformed (for example, invalid `jsonrpc` field).

  Client handling: Fix request envelope before retrying.

## Best Practices
- Use `params: []` or omit `params`; avoid relying on extra-params tolerance.
- Parse `result` as a hex `QUANTITY` before converting to integer.
- Treat the value as a moving head, not a finality indicator.
- If you need stronger consistency semantics, use APIs that explicitly target `safe`/`finalized` blocks.
- Implement retry/backoff for HTTP `429` / JSON-RPC `-32005`.

## Compatibility
- The method itself is standard Ethereum JSON-RPC.
