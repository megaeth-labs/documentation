# eth_getHeaderByHash

## Summary
Returns the block header identified by a block hash.

This method is a MegaETH-specific extension and is not part of the standard Ethereum JSON-RPC API. It returns a header-only object and does not include transactions or a `size` field.

## Parameters
- `blockHash` (required): `string`

  Accepted values:
  - a `0x`-prefixed 32-byte block hash
  - exactly 64 hex characters after the `0x` prefix

  Notes:
  - Send exactly one block hash parameter for portable behavior.
  - Malformed hash strings are rejected with `-32602`.

## Returns
- `result` (`object | null`)

  When resolved, returns a header-only object with fields such as `hash`, `parentHash`, `stateRoot`, `transactionsRoot`, `receiptsRoot`, `logsBloom`, `number`, `gasLimit`, `gasUsed`, `timestamp`, and fork-dependent fields such as `baseFeePerGas`.

  Notes:
  - The response is header-only: no `transactions`, no `uncles`, and no `size` field.
  - `null` means the specified block hash could not be resolved.

## Examples

### curl: by block hash
```bash
curl -sS https://mainnet.megaeth.com/rpc \
  -H 'content-type: application/json' \
  --data '{"jsonrpc":"2.0","id":26,"method":"eth_getHeaderByHash","params":["0x6f3fcff78eefe9591d2ad590b8a78738b8ad80d9646eccd302618cd9198b73e0"]}'
```

### JSON-RPC request: by block hash
```json
{"jsonrpc":"2.0","id":26,"method":"eth_getHeaderByHash","params":["0x6f3fcff78eefe9591d2ad590b8a78738b8ad80d9646eccd302618cd9198b73e0"]}
```

### Response: by block hash
```json
{"jsonrpc":"2.0","id":26,"result":{"hash":"0x6f3fcff78eefe9591d2ad590b8a78738b8ad80d9646eccd302618cd9198b73e0","parentHash":"0x6b6b52368c21dcdba7348fa37edae3e945013627a83a96b64d55217696899d30","sha3Uncles":"0x1dcc4de8dec75d7aab85b567b6ccd41ad312451b948a7413f0a142fd40d49347","miner":"0x4200000000000000000000000000000000000011","stateRoot":"0xf328fa2752aea1c211a73067d17c25d09a416b4b6a7785441f39bcc930028717","transactionsRoot":"0xeb022b6dbe9f4c52a4f2099eba8e693f72c171be2eb64be0e75cb90a98dc9b48","receiptsRoot":"0x0424bde5ec87be8a069011f8f73ad60ecf6b1b5c328e4e762f9dec3a7cba0fab","logsBloom":"0x20000004002004400000000000000080000000000001400000000008000000200400000002000000000100000010020800000000000800000000000000000800000000000000000000000008000000000000000800010020004000000000000008000002020a000000004000a0020800000002000400010004020012001000200010000400000000000000000000020000000000000000000000000002400080800020000008000000000000000000020000002020100220002000030000010000000022001000000000000000000000000000c08200000000000000000020000000010000000001000110000000000400200010002400000200000000010000","difficulty":"0x0","number":"0xb10f64","gasLimit":"0x2540be400","gasUsed":"0x721dd7","timestamp":"0x69c33537","extraData":"0x00000000fa00000001","mixHash":"0x8bfe2d726b8e0668a43c61c347aad9a183f4341adafb14a0412433d0ecd49bdb","nonce":"0x0000000000000000","baseFeePerGas":"0xf4240","withdrawalsRoot":"0x5d35e62744505d3ba8a9b955b70685a30041f513c12fd3a40e109cf294aa899f","blobGasUsed":"0x0","excessBlobGas":"0x0","parentBeaconBlockRoot":"0x925f2e7ead0cc2dd30253ed7c9b2c14a5fa58cb22501044a9e123a54174d0cc6","requestsHash":"0xe3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855"}}}
```

### JSON-RPC request: unknown block hash
```json
{"jsonrpc":"2.0","id":1,"method":"eth_getHeaderByHash","params":["0x0000000000000000000000000000000000000000000000000000000000000000"]}
```

### Response: unknown block hash
```json
{"jsonrpc":"2.0","id":1,"result":null}
```

### JSON-RPC request: missing block hash
```json
{"jsonrpc":"2.0","id":1,"method":"eth_getHeaderByHash","params":[]}
```

### Error response: missing block hash
```json
{"jsonrpc":"2.0","id":1,"error":{"code":-32602,"message":"Missing block hash"}}
```

### JSON-RPC request: malformed block hash
```json
{"jsonrpc":"2.0","id":1,"method":"eth_getHeaderByHash","params":["0x1234"]}
```

### Error response: malformed block hash
```json
{"jsonrpc":"2.0","id":1,"error":{"code":-32602,"message":"Invalid params","data":"invalid string length at line 1 column 8"}}
```

## MegaETH Behavior
- This method is a MegaETH-specific extension.
- If you need transactions or block size, use `eth_getBlockByHash` instead.
- Public endpoints may enforce rate limits.

## Errors
- `-32602` Invalid params

  When it happens: The request is missing the required hash parameter or uses a malformed hash value.

  Example:
  ```json
  {"jsonrpc":"2.0","id":1,"error":{"code":-32602,"message":"Missing block hash"}}
  ```

  Client handling: Send exactly one `0x`-prefixed 32-byte block hash.

- `-32005` Rate limited

  When it happens: The request exceeds the applicable public-endpoint rate limit.

  Client handling: Retry with backoff. MegaETH may also return HTTP `429`.

## Best Practices
- Validate the block hash format client-side before sending the request.
- Treat `null` as a normal outcome and handle it explicitly.
- Use `eth_getBlockByHash` if you need transactions or block size.
- In batch mode, match responses by `id`.

## Compatibility
- This method is not part of the standard Ethereum JSON-RPC API.
- Do not assume other providers implement it.
