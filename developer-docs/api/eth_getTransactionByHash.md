# eth_getTransactionByHash

## Summary
Returns information about a transaction identified by its hash.

This method is part of the standard Ethereum JSON-RPC API.

## Parameters
- `hash` (required): `string`

  Accepted values:
  - a `0x`-prefixed 32-byte transaction hash
  - exactly 64 hex characters after the `0x` prefix

  Notes:
  - Send exactly one transaction hash parameter.
  - Use lowercase hashes for consistency across providers.
  - Validate the hash format client-side before sending the request.

## Returns
- `result` (`object | null`)

  When resolved, returns a transaction object.

  Common fields:
  - `hash`
  - `from`
  - `to`
  - `nonce`
  - `gas`
  - `value`
  - `input`
  - `type`

  Notes:
  - `null` means the transaction could not be found.
  - `to` is `null` for contract-creation transactions.
  - For pending transactions, `blockHash`, `blockNumber`, and `transactionIndex` may be `null`.
  - Additional fee, access-list, blob, or signature fields may appear depending on the transaction type.

## Examples

### curl: by transaction hash
```bash
curl -sS https://mainnet.megaeth.com/rpc \
  -H 'content-type: application/json' \
  --data '{"jsonrpc":"2.0","id":79,"method":"eth_getTransactionByHash","params":["0x89f0ccba20d5bbbe1cb6b44fb8d1f9a9e14b620a0b947a3de81cff684462f60c"]}'
```

### JSON-RPC request: by transaction hash
```json
{"jsonrpc":"2.0","id":79,"method":"eth_getTransactionByHash","params":["0x89f0ccba20d5bbbe1cb6b44fb8d1f9a9e14b620a0b947a3de81cff684462f60c"]}
```

### Response: by transaction hash
```json
{"jsonrpc":"2.0","id":79,"result":{"type":"0x0","chainId":"0x10e6","nonce":"0x597ac57","gasPrice":"0x0","gas":"0x3d5720","to":"0x6342000000000000000000000000000000000001","value":"0x0","input":"0x01caec130000000000000000000000000000000000000000000000000000000000000040000000000000000000000000000000000000000000000000000000000000008000000000000000000000000000000000000000000000000000000000000000010000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000100000000000000000000000000000000000000000000000000064dcfebed6da1","r":"0x78619b554241e8a123b979b890e64be18fc2f41d1691b5a6f80a33e91cc96fc8","s":"0x37d74b6ba1b71fc4236266aea35135a2eac3c6fa1ddf35dd46490e189eb2806a","v":"0x21ef","hash":"0x89f0ccba20d5bbbe1cb6b44fb8d1f9a9e14b620a0b947a3de81cff684462f60c","blockHash":"0xf773491fd24617452b30c3ed626bf440b5846b9c818ec7d8d7f71c9a02993c8b","blockNumber":"0xb120c6","transactionIndex":"0x1","from":"0xa887dcb9d5f39ef79272801d05abdf707cfbbd1d"}}
```

### JSON-RPC request: unknown transaction hash
```json
{"jsonrpc":"2.0","id":73,"method":"eth_getTransactionByHash","params":["0x00000000000000000000000000000000000000000000000000000000deadbeef"]}
```

### Response: unknown transaction hash
```json
{"jsonrpc":"2.0","id":73,"result":null}
```

### JSON-RPC request: missing transaction hash
```json
{"jsonrpc":"2.0","id":74,"method":"eth_getTransactionByHash","params":[]}
```

### Error response: missing transaction hash
```json
{"jsonrpc":"2.0","id":74,"error":{"code":-32602,"message":"Missing transaction hash"}}
```

### JSON-RPC request: short transaction hash
```json
{"jsonrpc":"2.0","id":75,"method":"eth_getTransactionByHash","params":["0x1234"]}
```

### Response: short transaction hash
```json
{"jsonrpc":"2.0","id":75,"result":null}
```

## MegaETH Behavior
- Unknown transaction hashes return `null`.
- Pending transactions, when returned, may have `blockHash`, `blockNumber`, and `transactionIndex` set to `null`.
- Non-canonical hash strings such as short hashes may also return `null`; validate input client-side.
- Public endpoints may enforce rate limits.

## Errors
- `-32602` Invalid params

  When it happens: The request is missing the required transaction hash or uses an invalid parameter shape.

  Example:
  ```json
  {"jsonrpc":"2.0","id":74,"error":{"code":-32602,"message":"Missing transaction hash"}}
  ```

  Client handling: Send exactly one transaction hash parameter.

- `-32005` Rate limited

  When it happens: The request exceeds the applicable public-endpoint rate limit.

  Client handling: Retry with backoff. MegaETH may also return HTTP `429`.

## Best Practices
- Validate the transaction hash format client-side before sending the request.
- Treat `null` as a normal outcome and handle it explicitly.
- Use `eth_getTransactionReceipt` to determine confirmation status, gas used, and execution outcome.
- Parse fee and signature fields according to the transaction `type`.
- Ignore unknown additional fields so clients remain compatible with newer transaction types.

## Compatibility
- The method itself is standard Ethereum JSON-RPC.
- Transaction objects can vary by transaction type and provider.
- Do not assume every provider returns identical auxiliary fields for every transaction type.
