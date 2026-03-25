# eth_sendRawTransactionSync

## Summary
Submits a signed raw transaction and waits until the transaction is included in a canonical block, then returns its receipt.

This method is defined by [EIP-7966](https://eips.ethereum.org/EIPS/eip-7966). MegaETH supports it, with some current differences from the draft EIP described in Compatibility. It does not wait for finality.

## Parameters
- `rawTx` (required): `string`

  Accepted values:
  - a `0x`-prefixed hex string containing a fully signed raw transaction

  Notes:
  - Send the signed transaction as `params[0]`.
  - The transaction must already be signed for the target chain before submission.
  - Invalid hex, undecodable transaction bytes, or an invalid transaction shape return an error.
  - For portable behavior, send exactly one or two positional parameters.

- `timeoutMs` (optional): `number`

  Accepted values:
  - a positive timeout in milliseconds

  Notes:
  - Send the timeout as `params[1]`.
  - This limits how long the call waits for inclusion before returning a timeout error.
  - If omitted, the endpoint default wait window applies.
  - On MegaETH, invalid timeout values are rejected with `-32602`.

## Returns
- `result` (`object`)

  When resolved, returns a transaction receipt object.

  Common fields:
  - `transactionHash`
  - `blockHash`
  - `blockNumber`
  - `from`
  - `to`
  - `status`
  - `gasUsed`
  - `cumulativeGasUsed`
  - `effectiveGasPrice`
  - `logs`

  Notes:
  - The returned object follows the general shape of `eth_getTransactionReceipt`.
  - Unlike `eth_sendRawTransaction`, this method returns the receipt directly instead of only the transaction hash.
  - A reverted transaction can still return a receipt with `status` equal to `0x0`.
  - The receipt reflects canonical inclusion, not finality.
  - Additional network-specific receipt fields may appear.

## Examples

### curl: send a signed transaction and wait for receipt
```bash
curl -sS https://mainnet.megaeth.com/rpc \
  -H 'content-type: application/json' \
  --data '{"jsonrpc":"2.0","id":91,"method":"eth_sendRawTransactionSync","params":["0xf86480830f424082ea6094000000000000000000000000000000000000000080808231b1a050e782f95780eaaf16dfaa0c1294c6705ada7a97b525f119c924f35dd14e0165a05c57cf60cd5c818445d3b5c4f25488540a8af6b3214cf82758794933df5aa108"]}'
```

### JSON-RPC request: send a signed transaction and wait for receipt
```json
{"jsonrpc":"2.0","id":91,"method":"eth_sendRawTransactionSync","params":["0xf86480830f424082ea6094000000000000000000000000000000000000000080808231b1a050e782f95780eaaf16dfaa0c1294c6705ada7a97b525f119c924f35dd14e0165a05c57cf60cd5c818445d3b5c4f25488540a8af6b3214cf82758794933df5aa108"]}
```

### Response: successful inclusion
```json
{"jsonrpc":"2.0","id":91,"result":{"transactionHash":"0xb7cb129026cdb9dc9f590386e5cb5ae469872acb188939d641491f123031f442","from":"0xbe862ad9abfe6f22bcb087716c7d89a26051f74c","to":"0x0000000000000000000000000000000000000000","type":"0x0","status":"0x1","blockNumber":"0x100","logs":[]}}
```

### JSON-RPC request: send with a 3000 ms timeout
```json
{"jsonrpc":"2.0","id":92,"method":"eth_sendRawTransactionSync","params":["0xf86480830f424082ea6094000000000000000000000000000000000000000080808231b1a050e782f95780eaaf16dfaa0c1294c6705ada7a97b525f119c924f35dd14e0165a05c57cf60cd5c818445d3b5c4f25488540a8af6b3214cf82758794933df5aa108",3000]}
```

### Error response: timeout waiting for receipt
```json
{"jsonrpc":"2.0","id":92,"error":{"code":-32000,"message":"timeout waiting for receipt"}}
```

### JSON-RPC request: invalid raw transaction hex
```json
{"jsonrpc":"2.0","id":93,"method":"eth_sendRawTransactionSync","params":["deadbeef"]}
```

### Error response: invalid raw transaction hex
```json
{"jsonrpc":"2.0","id":93,"error":{"code":-32602,"message":"Invalid params: raw transaction must be a valid hex string starting with 0x"}}
```

### JSON-RPC request: invalid timeout
```json
{"jsonrpc":"2.0","id":94,"method":"eth_sendRawTransactionSync","params":["0xf86480830f424082ea6094000000000000000000000000000000000000000080808231b1a050e782f95780eaaf16dfaa0c1294c6705ada7a97b525f119c924f35dd14e0165a05c57cf60cd5c818445d3b5c4f25488540a8af6b3214cf82758794933df5aa108",0]}
```

### Error response: invalid timeout
```json
{"jsonrpc":"2.0","id":94,"error":{"code":-32602,"message":"Invalid params: timeout must be a positive number"}}
```

## MegaETH Behavior
- Returns once the transaction has a receipt in a canonical block.
- Does not wait for finality; later reorgs remain possible.
- On timeout, the method returns an error instead of falling back to a transaction hash.
- Batch requests containing this method are supported, and each item is handled independently.
- Public endpoints may enforce rate limits.

## Errors
- `-32602` Invalid params

  When it happens: `params[0]` is missing or not a `0x`-prefixed hex string, the raw transaction cannot be decoded, or `params[1]` is present but not a positive number.

  Example:
  ```json
  {"jsonrpc":"2.0","id":93,"error":{"code":-32602,"message":"Invalid params: raw transaction must be a valid hex string starting with 0x"}}
  ```

  Client handling: send `params` as `[rawTx]` or `[rawTx, timeoutMs]`, validate the raw transaction client-side, and only pass positive timeout values.

- `-32000` Timeout waiting for receipt

  When it happens: the transaction was not included within the allowed wait window.

  Example:
  ```json
  {"jsonrpc":"2.0","id":92,"error":{"code":-32000,"message":"timeout waiting for receipt"}}
  ```

  Client handling: treat the timeout as inconclusive, keep the precomputed transaction hash, and follow up with `eth_getTransactionReceipt`.

- `-32000` Transaction rejected

  When it happens: the node or mempool rejects the signed transaction, for example because the nonce is too low, the fee settings are invalid, the chain ID is wrong, or the transaction is already known.

  Example:
  ```json
  {"jsonrpc":"2.0","id":95,"error":{"code":-32000,"message":"already known"}}
  ```

  Client handling: inspect the error message, fix or replace the signed transaction, and retry only when appropriate.

## Best Practices
- Precompute and store the transaction hash from the signed raw transaction before submission.
- Use `eth_sendRawTransaction` instead if you only need the transaction hash immediately.
- Keep your client or HTTP timeout slightly above the RPC wait window.
- Treat timeout errors as inconclusive and reconcile by transaction hash.
- Treat a returned receipt with `status: 0x0` as an on-chain execution failure, not a transport error.
- Wait for additional confirmations if your application needs stronger finality guarantees.
- Parse receipt objects permissively so future network-specific fields do not break the client.

## Compatibility
- `eth_sendRawTransactionSync` is defined by `EIP-7966`, which is still a draft standard.
- Support is optional across providers. Endpoints that do not implement the method may return `-32601 Method not found`.
- On success, MegaETH returns a transaction receipt with the general shape of `eth_getTransactionReceipt`.
- `EIP-7966` says invalid timeout values should fall back to the node-configured timeout. MegaETH currently rejects invalid timeout values with `-32602`.
- `EIP-7966` defines timeout error code `4` and includes the transaction hash in `error.data`. MegaETH currently returns `-32000` with message `timeout waiting for receipt`.
- `EIP-7966` defines dedicated readiness and nonce-gap error codes `5` and `6`. MegaETH currently surfaces these cases as generic JSON-RPC errors rather than EIP-specific codes with structured `error.data`.
