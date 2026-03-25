# eth_syncing

## Summary
Returns the node's synchronization status.

This method is part of the standard Ethereum JSON-RPC API and takes no parameters.

## Parameters
- None

  Send `params: []` for maximum interoperability.

  You may also omit the `params` field entirely for a zero-parameter JSON-RPC request.

## Returns
- `result` (`false | object`)

  Returns `false` when the node is not syncing.

  When the node is syncing, returns an object with:
  - `startingBlock`
  - `currentBlock`
  - `highestBlock`

  Notes:
  - These fields are `0x`-prefixed hex `QUANTITY` values.
  - `highestBlock` may be equal to `currentBlock`.
  - Some providers may include additional non-standard fields. Ignore unknown fields for compatibility.

## Examples

### curl: standard request
```bash
curl -sS https://mainnet.megaeth.com/rpc \
  -H 'content-type: application/json' \
  --data '{"jsonrpc":"2.0","id":1,"method":"eth_syncing","params":[]}'
```

### JSON-RPC request: standard
```json
{"jsonrpc":"2.0","id":1,"method":"eth_syncing","params":[]}
```

### Response: not syncing
```json
{"jsonrpc":"2.0","id":1,"result":false}
```

### JSON-RPC request: omitted params
```json
{"jsonrpc":"2.0","id":2,"method":"eth_syncing"}
```

### Response: omitted params
```json
{"jsonrpc":"2.0","id":2,"result":false}
```

## MegaETH Behavior
- A fully synced node returns `false`.
- If the node is catching up, the result is a syncing progress object.
- Public endpoints may enforce rate limits.

## Errors
- `-32005` Rate limit exceeded

  When it happens: The request exceeds the applicable public-endpoint rate limit.

  Typical transport: HTTP `429` with JSON-RPC error code `-32005`.

  Client handling: Retry with backoff.

- `-32600` Invalid request

  When it happens: The JSON-RPC envelope is malformed, for example a missing or invalid `jsonrpc` field.

  Client handling: Fix the JSON-RPC request envelope before retrying.

## Best Practices
- Send zero parameters for portable behavior.
- Treat the result as a union type: `false` or a syncing progress object.
- Parse `startingBlock`, `currentBlock`, and `highestBlock` as hex `QUANTITY` values.
- Do not assume `highestBlock` is greater than `currentBlock`.
- Ignore unknown fields in the syncing object.
- Poll judiciously and respect rate limits.

## Compatibility
- The method itself is standard Ethereum JSON-RPC.
- `params: []` is the most portable request form across providers.
- MegaETH also accepts this method when the `params` field is omitted.
- Some providers may include extra non-standard fields in the syncing object.
