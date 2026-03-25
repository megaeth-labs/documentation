# eth_getHeaderByNumber

## Summary
Returns the block header identified by a block number or block tag.

This method is a MegaETH-specific extension and is not part of the standard Ethereum JSON-RPC API. It returns a header-only object and does not include transactions or a `size` field.

## Parameters
- `block` (required): `string`

  Accepted values:
  - a `0x`-prefixed hex block number encoded as a `QUANTITY`
  - one of: `earliest`, `finalized`, `safe`, `latest`, `pending`

  Notes:
  - Send exactly one block selector for portable behavior.
  - Numeric values must be hex `QUANTITY` strings such as `0x0` or `0xb11048`; decimal strings such as `12345` are rejected.
  - EIP-1898-style block identifier objects are rejected with `-32602`.

## Returns
- `result` (`object | null`)

  When resolved, returns a header-only object.

  Common fields:
  - `hash`
  - `parentHash`
  - `stateRoot`
  - `transactionsRoot`
  - `receiptsRoot`
  - `logsBloom`
  - `number`
  - `gasLimit`
  - `gasUsed`
  - `timestamp`
  - fork-dependent fields such as `baseFeePerGas`, `withdrawalsRoot`, `blobGasUsed`, `excessBlobGas`, and `parentBeaconBlockRoot`

  Notes:
  - Numeric fields are returned as `0x`-prefixed hex `QUANTITY` values.
  - The response is header-only: no `transactions`, no `uncles`, and no `size` field.
  - `null` means the requested block could not be resolved or is not available.

## Examples

### curl: by block number
```bash
curl -sS https://mainnet.megaeth.com/rpc \
  -H 'content-type: application/json' \
  --data '{"jsonrpc":"2.0","id":27,"method":"eth_getHeaderByNumber","params":["0xb11048"]}'
```

### JSON-RPC request: by block number
```json
{"jsonrpc":"2.0","id":27,"method":"eth_getHeaderByNumber","params":["0xb11048"]}
```

### Response: by block number
```json
{"jsonrpc":"2.0","id":27,"result":{"hash":"0x235d80b5e91125a1a1d6da6776c6a9ee087d1818c494f71736b09bed61b1411e","parentHash":"0x6fc0412abfba89bbfab17b2d8bd36cb1c214c1d53ed213fa8958439d0c4f9c18","sha3Uncles":"0x1dcc4de8dec75d7aab85b567b6ccd41ad312451b948a7413f0a142fd40d49347","miner":"0x4200000000000000000000000000000000000011","stateRoot":"0x301d7b77a74893451bd76e5d1672aaaa493cd78c06d59e885218d48917a35c03","transactionsRoot":"0xd42ca50387074e932e3f6613d3baa1d9c255aff7260a83015a2ca6d3fa70977e","receiptsRoot":"0x815562d20a655dc3c16cb5ffc0c426a08273de103d275385c84ad19c54ff9612","logsBloom":"0x000008040020000000000008000000800000000000000000000000080000002004000000020000000000000000000200000000001208800000000000020020000000000000000000000000000200000000000008000100200008000000000000200000020200000000004000a0020800000000000000010004020000001000200080000400000000000000000000020000004000000000000000000100400000800000000018000000000000002004000000002020900020000000020000410040000020011000001000000002800000000000400008000000000000000020000000010000000001000100000000000400008000002400000200480001080000","difficulty":"0x0","number":"0xb11048","gasLimit":"0x2540be400","gasUsed":"0x6be7e8","timestamp":"0x69c3361b","extraData":"0x00000000fa00000001","mixHash":"0x95e0093e48c766f4b96021e0f62625a9d057b07045545c7f7390b74322a89735","nonce":"0x0000000000000000","baseFeePerGas":"0xf4240","withdrawalsRoot":"0x5d35e62744505d3ba8a9b955b70685a30041f513c12fd3a40e109cf294aa899f","blobGasUsed":"0x0","excessBlobGas":"0x0","parentBeaconBlockRoot":"0x17297d124e49908856c634086be1152ea978132da1cbbb72607512d6b4e5566d","requestsHash":"0xe3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855"}}}
```

### JSON-RPC request: `pending`
```json
{"jsonrpc":"2.0","id":3,"method":"eth_getHeaderByNumber","params":["pending"]}
```

### Response: `pending`
```json
{"jsonrpc":"2.0","id":3,"result":null}
```

### JSON-RPC request: invalid decimal string
```json
{"jsonrpc":"2.0","id":4,"method":"eth_getHeaderByNumber","params":["12345"]}
```

### Error response: invalid decimal string
```json
{"jsonrpc":"2.0","id":4,"error":{"code":-32602,"message":"Invalid params","data":"hex string without 0x prefix"}}
```

## MegaETH Behavior
- This method is a MegaETH-specific extension.
- If you need wider compatibility, use `eth_getBlockByNumber` and read header fields from the block object.
- Public endpoints may enforce rate limits.

## Errors
- `-32602` Invalid params

  When it happens: The request is missing the required selector, uses a non-string selector, sends an unsupported object form, or sends a malformed numeric selector such as a decimal string.

  Example:
  ```json
  {"jsonrpc":"2.0","id":4,"error":{"code":-32602,"message":"Invalid params","data":"hex string without 0x prefix"}}
  ```

  Client handling: Send exactly one string selector and use a hex `QUANTITY` for block numbers.

- `-32005` Rate limited

  When it happens: The request exceeds the applicable public-endpoint rate limit.

  Client handling: Retry with backoff. MegaETH may also return HTTP `429`.

## Best Practices
- Send exactly one selector and keep it to a lowercase tag or hex `QUANTITY`.
- Treat `pending` and `null` as expected outcomes, not transport failures.
- Use a fixed block number when you need deterministic results.
- Treat fork-dependent fields such as `baseFeePerGas` and `withdrawalsRoot` as optional in client code.

## Compatibility
- This method is not part of the standard Ethereum JSON-RPC API.
- Non-MegaETH providers may not implement it and may return `-32601 Method not found`.
