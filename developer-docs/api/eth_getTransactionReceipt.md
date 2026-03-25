# eth_getTransactionReceipt

## Summary
Returns the receipt for a transaction after it has been included in a block.

This method is part of the standard Ethereum JSON-RPC API. If the transaction is unknown or not yet mined, the result is `null`.

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

  When resolved, returns a transaction receipt object.

  Common fields:
  - `transactionHash`
  - `transactionIndex`
  - `blockHash`
  - `blockNumber`
  - `from`
  - `to`
  - `cumulativeGasUsed`
  - `gasUsed`
  - `effectiveGasPrice`
  - `contractAddress`
  - `logs`
  - `logsBloom`
  - `status`

  Notes:
  - `null` means the receipt is not available.
  - `to` is `null` for contract-creation transactions.
  - `contractAddress` is non-`null` only for contract-creation transactions.
  - `logs` contains log objects in the same general shape used by `eth_getLogs`.
  - Receipt log objects may include `blockTimestamp`.
  - Additional fields may appear depending on the transaction type or network.

## Examples

### curl: by transaction hash
```bash
curl -sS https://mainnet.megaeth.com/rpc \
  -H 'content-type: application/json' \
  --data '{"jsonrpc":"2.0","id":120,"method":"eth_getTransactionReceipt","params":["0xf3473347041eb4ccc045ee58e6c79c80d98ee4aa783d49e49c69d0a0e50d8ed6"]}'
```

### JSON-RPC request: by transaction hash
```json
{"jsonrpc":"2.0","id":120,"method":"eth_getTransactionReceipt","params":["0xf3473347041eb4ccc045ee58e6c79c80d98ee4aa783d49e49c69d0a0e50d8ed6"]}
```

### Response: by transaction hash
```json
{"jsonrpc":"2.0","id":120,"result":{"type":"0x2","status":"0x1","cumulativeGasUsed":"0x2736ca","logs":[{"address":"0xf818c8da51f9a712cfbcddd44d0c445fa1a104e6","topics":["0x994d1f10d7d73f3765b557bce9826b2fafd1bad3862fa6192211b39a12183815","0x00000000000000000000000000000000000000000000000000000000000000d8"],"data":"0x0000000000000000000954150000002f000000000000d6d800000000006ec9a2","blockHash":"0xf773491fd24617452b30c3ed626bf440b5846b9c818ec7d8d7f71c9a02993c8b","blockNumber":"0xb120c6","blockTimestamp":"0x69c34699","transactionHash":"0xf3473347041eb4ccc045ee58e6c79c80d98ee4aa783d49e49c69d0a0e50d8ed6","transactionIndex":"0x9","logIndex":"0x24","removed":false}],"logsBloom":"0x00000800000000000000000000000000000000000001000000000000000000000000000000000000000000000000000000000000000000000000000002000000000000000000000000000000020000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000100000000000000000000000000000000000000000000000000000200000000000000000000000000000000000000000002000000000000800000000000000000000000000000000000000000000000000000000000008000000000000000000000000000","transactionHash":"0xf3473347041eb4ccc045ee58e6c79c80d98ee4aa783d49e49c69d0a0e50d8ed6","transactionIndex":"0x9","blockHash":"0xf773491fd24617452b30c3ed626bf440b5846b9c818ec7d8d7f71c9a02993c8b","blockNumber":"0xb120c6","gasUsed":"0x215ec","effectiveGasPrice":"0xf4241","from":"0xa344fb2d117501ee379d2ea9c0c016959ad94f1e","to":"0x5e3ae52eba0f9740364bd5dd39738e1336086a8b","contractAddress":null,"l1GasPrice":"0x2221ebf","l1GasUsed":"0x640","l1Fee":"0x4ab5901","l1BaseFeeScalar":"0x558","l1BlobBaseFee":"0x1d64ab8f44912","l1BlobBaseFeeScalar":"0x0"}}
```

### JSON-RPC request: unknown transaction hash
```json
{"jsonrpc":"2.0","id":121,"method":"eth_getTransactionReceipt","params":["0x00000000000000000000000000000000000000000000000000000000deadbeef"]}
```

### Response: unknown transaction hash
```json
{"jsonrpc":"2.0","id":121,"result":null}
```

### JSON-RPC request: missing transaction hash
```json
{"jsonrpc":"2.0","id":122,"method":"eth_getTransactionReceipt","params":[]}
```

### Error response: missing transaction hash
```json
{"jsonrpc":"2.0","id":122,"error":{"code":-32602,"message":"Invalid params: txHash is required"}}
```

### JSON-RPC request: short transaction hash
```json
{"jsonrpc":"2.0","id":123,"method":"eth_getTransactionReceipt","params":["0x1234"]}
```

### Response: short transaction hash
```json
{"jsonrpc":"2.0","id":123,"result":null}
```

## MegaETH Behavior
- Receipts may include additional fee-accounting fields such as `l1Fee` and related L1 fee fields.
- Unknown transaction hashes return `null`.
- Non-canonical hash strings such as short hashes may also return `null`; validate input client-side.
- Public endpoints may enforce rate limits.

## Errors
- `-32602` Invalid params

  When it happens: The request is missing the required transaction hash or uses an invalid parameter shape.

  Example:
  ```json
  {"jsonrpc":"2.0","id":122,"error":{"code":-32602,"message":"Invalid params: txHash is required"}}
  ```

  Client handling: Send exactly one transaction hash parameter.

- `-32005` Rate limited

  When it happens: The request exceeds the applicable public-endpoint rate limit.

  Client handling: Retry with backoff. MegaETH may also return HTTP `429`.

## Best Practices
- Treat `null` as a normal outcome for unknown or not-yet-mined transactions.
- Use `status` to distinguish successful and failed execution.
- Use `contractAddress` only for contract-creation transactions.
- Use `effectiveGasPrice` and `gasUsed` for fee calculations after inclusion.
- Handle additional receipt fields permissively so clients stay compatible with network-specific extensions.

## Compatibility
- The method itself is standard Ethereum JSON-RPC.
- Receipt objects can vary by transaction type, fork, and provider.
- MegaETH includes some additional receipt fields that other providers may omit.
