# debug_getHistoryTransactionCount

## Summary
Returns the total number of transactions recorded on chain at the end of the specified block.

This is a MegaETH-specific method and is not part of the standard Ethereum Execution API. It returns a chain-wide cumulative transaction count, not an account nonce, and must not be used as a substitute for `eth_getTransactionCount`.

## Parameters
- `block` (required): `string`

  Accepted values:
  - hex block number as a `0x`-prefixed `QUANTITY`
  - one of: `latest`, `safe`, `finalized`, `earliest`

  Notes:
  - `pending` is not supported on the public MegaETH mainnet endpoint for this method.
  - Block hashes are not accepted for this method.
  - Numeric block numbers are stable and deterministic.
  - Tag-based values such as `latest`, `safe`, and `finalized` resolve relative to the node's current view of chain state and may change over time.

## Returns
- `result` (string)

  A `0x`-prefixed hex `QUANTITY` representing the total number of transactions recorded on chain at the end of the selected block.

  Meaning:
  - This is a global cumulative counter for the chain.
  - It is not a per-account transaction count.
  - It is not an account nonce.

  Notes:
  - If the selected block contains no transactions, the returned value is unchanged from the previous block.
  - If the selected block contains `N` transactions, the returned value increases by `N` relative to the previous block.
  - At `earliest`, the result reflects the cumulative count at the genesis boundary.

## Examples

### curl: by block number
```bash
curl -sS https://mainnet.megaeth.com/rpc \
  -H 'content-type: application/json' \
  --data '{"jsonrpc":"2.0","id":1,"method":"debug_getHistoryTransactionCount","params":["0x12a05f"]}'
```

### JSON-RPC request: by block number
```json
{"jsonrpc":"2.0","id":1,"method":"debug_getHistoryTransactionCount","params":["0x12a05f"]}
```

### Response: by block number
```json
{"jsonrpc":"2.0","id":1,"result":"0x12cbab"}
```

### JSON-RPC request: by tag
```json
{"jsonrpc":"2.0","id":1,"method":"debug_getHistoryTransactionCount","params":["latest"]}
```

### Response: by tag
```json
{"jsonrpc":"2.0","id":1,"result":"0x2ae78e320"}
```

### Interpretation example
- If block `N` ends with a cumulative count of `0x64`, the chain has recorded 100 total transactions up to and including block `N`.
- If block `N+1` is empty, the method still returns `0x64`.
- If block `N+2` contains 2 transactions, the method returns `0x66`.

### JSON-RPC request: unsupported tag
```json
{"jsonrpc":"2.0","id":1,"method":"debug_getHistoryTransactionCount","params":["pending"]}
```

### Error response: unsupported tag
```json
{"jsonrpc":"2.0","id":1,"error":{"code":-32001,"message":"block not found: pending"}}
```

## MegaETH Behavior
- This method is a MegaETH-specific extension and is not expected to exist on standard Ethereum providers.
- On the public MegaETH mainnet endpoint, supported selectors are:
  - hex block numbers
  - `latest`
  - `safe`
  - `finalized`
  - `earliest`
- On the public MegaETH mainnet endpoint, `pending` is not supported for this method and returns `-32001`.
- Block hashes are not accepted.
- Public endpoints may enforce rate limits.

## Errors
- `-32001` Resource not found

  When it happens: The specified block does not exist or the requested tag cannot be resolved.

  Example:
  ```json
  {"jsonrpc":"2.0","id":1,"error":{"code":-32001,"message":"block not found: pending"}}
  ```

  Client handling: Treat this as an unresolved block selector. Retry only if you expect the referenced block or tag to become available.

- `-32602` Invalid params

  When it happens: The request uses an unsupported parameter form, such as a block hash, missing params, or an invalid params shape.

  Example:
  ```json
  {"jsonrpc":"2.0","id":1,"error":{"code":-32602,"message":"invalid params"}}
  ```

  Client handling: Fix the request shape before retrying.

- `-32005` Rate limited

  When it happens: The request exceeds the applicable rate limit.

  Example:
  ```json
  {"jsonrpc":"2.0","id":1,"error":{"code":-32005,"message":"rate limited"}}
  ```

  Client handling: Retry with backoff. MegaETH may also return HTTP `429`.

## Best Practices
- Do not use this method as a substitute for `eth_getTransactionCount`.
- Use a specific block number when you need stable, repeatable results.
- Use `finalized` when you want stronger consistency near head.
- Use `latest` only if you accept head movement and reorg-related changes.
- Do not send `pending` or block hashes for this method.
- Treat the result as a chain-wide cumulative counter, not an account-level value.

## Compatibility
- This method is not part of the standard Ethereum Execution API.
- Do not assume other providers implement it.
- The accepted block selector set for this method is MegaETH-specific and narrower than some standard Ethereum methods.
