# eth_getBlockTransactionCountByNumber

## Summary
Returns the number of transactions contained in the block identified by a block number or block tag.

This method is part of the standard Ethereum JSON-RPC API.

## Parameters
- `block` (required): `string`

  Accepted values:
  - a `0x`-prefixed hex block number encoded as a `QUANTITY`
  - one of: `earliest`, `finalized`, `safe`, `latest`, `pending`

  Notes:
  - Send exactly one positional parameter for portable behavior.
  - Numeric values must be hex `QUANTITY` strings such as `0x0` or `0xb11362`; decimal strings such as `12345` are rejected.
  - EIP-1898-style block identifier objects are not accepted for this method.

## Returns
- `result` (`string | null`)

  A `0x`-prefixed hex `QUANTITY` representing the number of transactions in the selected block.

  Notes:
  - The value has no leading zeros, except `0x0`.
  - Parse the value as an unsigned integer in client code.
  - `0x0` means the block exists and contains zero transactions.
  - `null` means the block could not be resolved or is not available.

## Examples

### curl: by block number
```bash
curl -sS https://mainnet.megaeth.com/rpc \
  -H 'content-type: application/json' \
  --data '{"jsonrpc":"2.0","id":4,"method":"eth_getBlockTransactionCountByNumber","params":["0xb11362"]}'
```

### JSON-RPC request: by block number
```json
{"jsonrpc":"2.0","id":4,"method":"eth_getBlockTransactionCountByNumber","params":["0xb11362"]}
```

### Response: by block number
```json
{"jsonrpc":"2.0","id":4,"result":"0x17"}
```

### JSON-RPC request: by tag
```json
{"jsonrpc":"2.0","id":7,"method":"eth_getBlockTransactionCountByNumber","params":["safe"]}
```

### Response: by tag
```json
{"jsonrpc":"2.0","id":7,"result":"0x18"}
```

### JSON-RPC request: `pending`
```json
{"jsonrpc":"2.0","id":5,"method":"eth_getBlockTransactionCountByNumber","params":["pending"]}
```

### Response: `pending`
```json
{"jsonrpc":"2.0","id":5,"result":null}
```

### JSON-RPC request: future block number
```json
{"jsonrpc":"2.0","id":9,"method":"eth_getBlockTransactionCountByNumber","params":["0xdeadbeef"]}
```

### Response: future block number
```json
{"jsonrpc":"2.0","id":9,"result":null}
```

### JSON-RPC request: invalid decimal string
```json
{"jsonrpc":"2.0","id":10,"method":"eth_getBlockTransactionCountByNumber","params":["12345"]}
```

### Error response: invalid decimal string
```json
{"jsonrpc":"2.0","id":10,"error":{"code":-32602,"message":"Invalid params"}}
```

## MegaETH Behavior
- `pending` may return `null`; handle it explicitly.
- Future block numbers return `null`.
- Public endpoints may enforce rate limits.

## Errors
- `-32602` Invalid params

  When it happens: The request is missing the required selector, uses a non-string selector, sends an unsupported object form, or sends a malformed numeric selector such as a decimal string.

  Example:
  ```json
  {"jsonrpc":"2.0","id":10,"error":{"code":-32602,"message":"Invalid params"}}
  ```

  Client handling: Send exactly one string selector and use a hex `QUANTITY` for block numbers.

- `-32005` Rate limited

  When it happens: The request exceeds the applicable public-endpoint rate limit.

  Client handling: Retry with backoff. MegaETH may also return HTTP `429`.

## Best Practices
- Send exactly one selector and keep it to a lowercase tag or hex `QUANTITY`.
- Treat `null` differently from `0x0`.
- Use a fixed block number when you need deterministic results.

## Compatibility
- The method itself is standard Ethereum JSON-RPC.
- Use a single block selector for cross-provider compatibility.
