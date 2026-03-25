# eth_getBlockTransactionCountByHash

## Summary
Returns the number of transactions contained in the block identified by a block hash.

This method is part of the standard Ethereum JSON-RPC API.

## Parameters
- `blockHash` (required): `string`

  Accepted values:
  - a `0x`-prefixed 32-byte block hash
  - exactly 64 hex characters after the `0x` prefix

  Notes:
  - Send exactly one positional parameter for portable behavior.
  - Malformed hash strings and non-string values are rejected with `-32602`.
  - Use lowercase hashes for consistency across providers.

## Returns
- `result` (`string | null`)

  A `0x`-prefixed hex `QUANTITY` representing the number of transactions in the specified block.

  Notes:
  - The value has no leading zeros, except `0x0`.
  - Parse the value as an unsigned integer in client code.
  - `0x0` means the block exists and contains zero transactions.
  - `null` means the specified block hash could not be resolved.

## Examples

### curl: by block hash
```bash
curl -sS https://mainnet.megaeth.com/rpc \
  -H 'content-type: application/json' \
  --data '{"jsonrpc":"2.0","id":3,"method":"eth_getBlockTransactionCountByHash","params":["0xa97b8563203de36f0c8430709734438fbf7f2444b6de9f307853fc46b230de3e"]}'
```

### JSON-RPC request: by block hash
```json
{"jsonrpc":"2.0","id":3,"method":"eth_getBlockTransactionCountByHash","params":["0xa97b8563203de36f0c8430709734438fbf7f2444b6de9f307853fc46b230de3e"]}
```

### Response: by block hash
```json
{"jsonrpc":"2.0","id":3,"result":"0x18"}
```

### JSON-RPC request: unknown block hash
```json
{"jsonrpc":"2.0","id":4,"method":"eth_getBlockTransactionCountByHash","params":["0x0000000000000000000000000000000000000000000000000000000000000000"]}
```

### Response: unknown block hash
```json
{"jsonrpc":"2.0","id":4,"result":null}
```

### JSON-RPC request: missing block hash
```json
{"jsonrpc":"2.0","id":5,"method":"eth_getBlockTransactionCountByHash","params":[]}
```

### Error response: missing block hash
```json
{"jsonrpc":"2.0","id":5,"error":{"code":-32602,"message":"Invalid params"}}
```

### JSON-RPC request: malformed block hash
```json
{"jsonrpc":"2.0","id":6,"method":"eth_getBlockTransactionCountByHash","params":["0x1234"]}
```

### Error response: malformed block hash
```json
{"jsonrpc":"2.0","id":6,"error":{"code":-32602,"message":"Invalid params"}}
```

## MegaETH Behavior
- Unknown block hashes return `null`.
- Public endpoints may enforce rate limits.

## Errors
- `-32602` Invalid params

  When it happens: The request is missing the required `blockHash`, uses a non-string parameter, or includes a malformed hash value.

  Example:
  ```json
  {"jsonrpc":"2.0","id":6,"error":{"code":-32602,"message":"Invalid params"}}
  ```

  Client handling: Send exactly one `0x`-prefixed 32-byte block hash.

- `-32005` Rate limited

  When it happens: The request exceeds the applicable public-endpoint rate limit.

  Client handling: Retry with backoff. MegaETH may also return HTTP `429`.

## Best Practices
- Validate the hash format client-side before sending the request.
- Treat `null` differently from `0x0`.
- Use response `id` values to correlate results in batch requests.
- Send exactly one block hash parameter.

## Compatibility
- The method itself is standard Ethereum JSON-RPC.
- Use a single block hash parameter for cross-provider compatibility.
