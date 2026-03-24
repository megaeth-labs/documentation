# eth_getBalance

## Summary
Returns the balance of an account, in wei, at a specified block.

This method is part of the Ethereum JSON-RPC API. On MegaETH, the public endpoint currently accepts an omitted block parameter and defaults it to `latest`, but that behavior is not standard and should not be relied on for portable integrations.

## Parameters
- `address` (required): `string`

  Accepted values:
  - a `0x`-prefixed 20-byte Ethereum address
  - 40 hex characters after the `0x` prefix

  Notes:
  - Address matching is case-insensitive.
  - EIP-55 checksum formatting is not required.

- `block` (required by the Ethereum JSON-RPC specification): `string`

  Accepted values:
  - hex block number as a `0x`-prefixed `QUANTITY`
  - one of: `earliest`, `finalized`, `safe`, `latest`, `pending`
  - a `0x`-prefixed 32-byte block hash

  Notes:
  - Use an explicit block selector for portable client behavior.
  - On MegaETH, omitting this parameter is currently accepted and treated as `latest`, but this is a non-standard convenience.
  - Fixed block numbers and block hashes are stable and deterministic.
  - Tag-based selectors such as `latest` and `pending` may change over time.

## Returns
- `result` (string)

  A `0x`-prefixed hex `QUANTITY` representing the account balance in wei at the selected block.

  Notes:
  - The value has no leading zeros, except `0x0`.
  - Convert the value to decimal units in client code as needed.
  - If the account does not exist at the selected block, the method returns `0x0`.

## Examples

### curl: by block number
```bash
curl -sS https://mainnet.megaeth.com/rpc \
  -H 'content-type: application/json' \
  --data '{"jsonrpc":"2.0","id":1,"method":"eth_getBalance","params":["0x0000000000000000000000000000000000000000","0xada7a9"]}'
```

### JSON-RPC request: by block number
```json
{"jsonrpc":"2.0","id":1,"method":"eth_getBalance","params":["0x0000000000000000000000000000000000000000","0xada7a9"]}
```

### Response: by block number
```json
{"jsonrpc":"2.0","id":1,"result":"0xe7bc7211178"}
```

### JSON-RPC request: by tag
```json
{"jsonrpc":"2.0","id":1,"method":"eth_getBalance","params":["0xc1cadaffffffffffffffffffffffffffffffffff","safe"]}
```

### Response: by tag
```json
{"jsonrpc":"2.0","id":1,"result":"0x0"}
```

### JSON-RPC request: by block hash
```json
{"jsonrpc":"2.0","id":1,"method":"eth_getBalance","params":["0x0000000000000000000000000000000000000000","0xfeddc41d49c9572185d57488acf4a53ef319cc439ca834bf4b32d5f8b4b2abf5"]}
```

### Response: by block hash
```json
{"jsonrpc":"2.0","id":1,"result":"0xe7bc7211178"}
```

### JSON-RPC request: MegaETH-only convenience example
```json
{"jsonrpc":"2.0","id":1,"method":"eth_getBalance","params":["0xc1cadaffffffffffffffffffffffffffffffffff"]}
```

### Response: MegaETH-only convenience example
```json
{"jsonrpc":"2.0","id":1,"result":"0x0"}
```

Note: MegaETH currently treats an omitted block parameter as `latest`. This is not standard Ethereum JSON-RPC behavior.

## MegaETH Behavior
- On the MegaETH public endpoint, omitting the `block` parameter is currently accepted and defaults to `latest`.
- On the MegaETH public endpoint, `pending` behaves the same as `latest` for this method.
- Near head, repeated calls with `latest` or `pending` may return different balances as chain state advances.
- Historical state may be unavailable on pruned configurations beyond the retained window.
- Public endpoints may enforce rate limits.

## Errors
- `-32602` Invalid params

  When it happens: The request is missing the required `address`, uses an invalid parameter shape, or includes malformed values.

  Example:
  ```json
  {"jsonrpc":"2.0","id":1,"error":{"code":-32602,"message":"invalid params"}}
  ```

  Client handling: Fix the request shape or parameter values before retrying.

- `-32001` Block not found

  When it happens: The specified block cannot be resolved, for example because the hash is unknown or the referenced block is unavailable.

  Example:
  ```json
  {"jsonrpc":"2.0","id":1,"error":{"code":-32001,"message":"block not found: hash 0x0000000000000000000000000000000000000000000000000000000000000000"}}
  ```

  Client handling: Treat this as an unresolved block selector. Retry only if you expect the block to become available.

- `4444` Pruned history unavailable

  When it happens: The node cannot answer the request because the required historical state has been pruned.

  Example:
  ```json
  {"jsonrpc":"2.0","id":1,"error":{"code":4444,"message":"pruned history unavailable"}}
  ```

  Client handling: Retry against a node with the required historical state.

- `-32005` Rate limited

  When it happens: The request exceeds the applicable rate limit.

  Example:
  ```json
  {"jsonrpc":"2.0","id":1,"error":{"code":-32005,"message":"rate limited"}}
  ```

  Client handling: Retry with backoff. MegaETH may also return HTTP `429`.

## Best Practices
- Always send both `address` and an explicit `block` selector.
- Use a fixed block number or block hash for reproducible results.
- Use `safe` or `finalized` when you need stronger consistency near head.
- Use `latest` only when you want the freshest available balance and accept that it may change between calls.
- Treat `0x0` as a valid balance response, including for unknown accounts.
- Handle rate limits, unresolved block selectors, and pruned-history failures explicitly.

## Compatibility
- The method itself is standard Ethereum JSON-RPC.
- MegaETH public endpoint handling for this method is not fully standard:
  - omitted `block` parameter -> accepted and treated as `latest`
  - `pending` -> behaves the same as `latest`
- Do not assume other providers behave the same way.
