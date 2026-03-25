# eth_getTransactionCount

## Summary
Returns the nonce of an account at a specified block.

This method is part of the standard Ethereum JSON-RPC API. On MegaETH, omitting the `block` parameter is accepted and treated as `latest`, but that behavior is not standard and should not be relied on for portable integrations.

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
  - For portable behavior, send an explicit block selector.
  - On MegaETH, omitting this parameter is accepted and treated as `latest`.
  - Fixed block numbers and block hashes are stable and deterministic.
  - Tag-based selectors such as `latest` and `pending` may change over time.
  - Unknown block numbers or hashes return `-32001`.

## Returns
- `result` (string)

  A `0x`-prefixed hex `QUANTITY` representing the account nonce at the selected block.

  Notes:
  - The value has no leading zeros, except `0x0`.
  - `0x0` is returned for non-existent accounts and for accounts whose nonce is zero.
  - This is the account nonce stored in state, which may differ from the number of transactions sent for some account types.

## Examples

### curl: by block number
```bash
curl -sS https://mainnet.megaeth.com/rpc \
  -H 'content-type: application/json' \
  --data '{"jsonrpc":"2.0","id":91,"method":"eth_getTransactionCount","params":["0xa344fb2d117501ee379d2ea9c0c016959ad94f1e","0xb120c6"]}'
```

### JSON-RPC request: by block number
```json
{"jsonrpc":"2.0","id":91,"method":"eth_getTransactionCount","params":["0xa344fb2d117501ee379d2ea9c0c016959ad94f1e","0xb120c6"]}
```

### Response: by block number
```json
{"jsonrpc":"2.0","id":91,"result":"0xfa8c"}
```

### JSON-RPC request: by block hash
```json
{"jsonrpc":"2.0","id":92,"method":"eth_getTransactionCount","params":["0xa344fb2d117501ee379d2ea9c0c016959ad94f1e","0xf773491fd24617452b30c3ed626bf440b5846b9c818ec7d8d7f71c9a02993c8b"]}
```

### Response: by block hash
```json
{"jsonrpc":"2.0","id":92,"result":"0xfa8c"}
```

### JSON-RPC request: unknown account
```json
{"jsonrpc":"2.0","id":93,"method":"eth_getTransactionCount","params":["0xc1cadaffffffffffffffffffffffffffffffffff","latest"]}
```

### Response: unknown account
```json
{"jsonrpc":"2.0","id":93,"result":"0x0"}
```

### JSON-RPC request: MegaETH-only convenience with omitted `block`
```json
{"jsonrpc":"2.0","id":94,"method":"eth_getTransactionCount","params":["0xc1cadaffffffffffffffffffffffffffffffffff"]}
```

### Response: MegaETH-only convenience
```json
{"jsonrpc":"2.0","id":94,"result":"0x0"}
```

### JSON-RPC request: missing address
```json
{"jsonrpc":"2.0","id":95,"method":"eth_getTransactionCount","params":[]}
```

### Error response: missing address
```json
{"jsonrpc":"2.0","id":95,"error":{"code":-32602,"message":"Missing address parameter"}}
```

### JSON-RPC request: unknown block hash
```json
{"jsonrpc":"2.0","id":96,"method":"eth_getTransactionCount","params":["0xa344fb2d117501ee379d2ea9c0c016959ad94f1e","0x0000000000000000000000000000000000000000000000000000000000000000"]}
```

### Error response: unknown block hash
```json
{"jsonrpc":"2.0","id":96,"error":{"code":-32001,"message":"block not found: hash 0x0000000000000000000000000000000000000000000000000000000000000000"}}
```

## MegaETH Behavior
- If `block` is omitted, MegaETH treats it as `latest`.
- On MegaETH, `pending` currently behaves the same as `latest` for this method.
- Public endpoints may enforce rate limits.

## Errors
- `-32602` Invalid params

  When it happens: The request is missing required parameters, uses a malformed address, or uses an invalid block selector.

  Example:
  ```json
  {"jsonrpc":"2.0","id":95,"error":{"code":-32602,"message":"Missing address parameter"}}
  ```

  Client handling: Validate the address and block selector before sending the request.

- `-32001` Block not found

  When it happens: The specified block number or block hash cannot be resolved.

  Example:
  ```json
  {"jsonrpc":"2.0","id":96,"error":{"code":-32001,"message":"block not found: hash 0x0000000000000000000000000000000000000000000000000000000000000000"}}
  ```

  Client handling: Treat this as an unresolved block selector. Retry only if you expect the block to become available.

- `-32005` Rate limited

  When it happens: The request exceeds the applicable public-endpoint rate limit.

  Client handling: Retry with backoff. MegaETH may also return HTTP `429`.

## Best Practices
- Send both `address` and an explicit `block` selector.
- Use a fixed block number or block hash for reproducible results.
- Treat `0x0` as a valid response for unknown accounts and zero-nonce accounts.
- Do not assume this value always matches the number of transactions sent from the account.
- Do not depend on an omitted `block` parameter if you need cross-provider compatibility.

## Compatibility
- The method is standard Ethereum JSON-RPC.
- For portable clients, always send an explicit `block` selector.
- MegaETH currently treats `pending` the same as `latest` for this method.
