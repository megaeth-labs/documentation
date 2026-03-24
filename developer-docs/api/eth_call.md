# eth_call

## Summary
Executes a read-only EVM message call against the state of a specified block. No transaction is created and no state is modified.

This method is part of the standard Ethereum JSON-RPC API. It is commonly used to read contract state or to simulate transaction execution without broadcasting a transaction.

On MegaETH, the public endpoint currently also accepts optional non-standard 3rd and 4th parameters (`stateOverrides`, `blockOverrides`) for targeted simulations.

## Parameters
- `transaction` (required): `object`

  Accepted fields:
  - `to`: `0x`-prefixed 20-byte recipient / contract address; omit or use `null` for contract creation
  - `from`: `0x`-prefixed 20-byte sender address
  - `gas`: `0x`-prefixed gas limit `QUANTITY`
  - `gasPrice`: legacy fee-per-gas `QUANTITY`
  - `maxFeePerGas`: EIP-1559 max fee per gas `QUANTITY`
  - `maxPriorityFeePerGas`: EIP-1559 priority fee per gas `QUANTITY`
  - `value`: wei amount as a `QUANTITY`
  - `input`: calldata or init code as `0x`-prefixed hex data
  - `data`: calldata alias currently accepted by MegaETH and many clients
  - `nonce`: transaction nonce as a `QUANTITY`
  - `accessList`: EIP-2930 access list
  - chain/client-dependent extended fields such as `maxFeePerBlobGas`, `blobVersionedHashes`, `blobs`, and `authorizationList`

  Notes:
  - Prefer `input` for portable client behavior.
  - If both `input` and `data` are present, they must be identical or the request is rejected.
  - For contract creation, omit `to` and put init code in `input` or `data`.
  - Use either `gasPrice` or EIP-1559 fee fields. Do not mix them in the same request.
  - If `from` is omitted, `msg.sender` is implementation-defined. Set it explicitly when it matters.
  - Servers may apply a call gas cap; very large `gas` values can be rejected.

- `block` (optional): `string`

  Accepted values:
  - hex block number as a `0x`-prefixed `QUANTITY`
  - one of: `earliest`, `finalized`, `safe`, `latest`, `pending`
  - a `0x`-prefixed 32-byte block hash

  Notes:
  - Use an explicit block selector for portable and reproducible behavior.
  - MegaETH currently accepts an omitted block parameter, but that should be treated as a convenience rather than a portable guarantee.
  - EIP-1898 block-object selectors are not part of the simple parameter shape documented here.

- `stateOverrides` (optional, MegaETH extension): `object`

  Accepted per-account fields:
  - `nonce`: `0x`-prefixed `QUANTITY`
  - `balance`: `0x`-prefixed `QUANTITY`
  - `code`: `0x`-prefixed bytecode
  - `state`: full storage map
  - `stateDiff`: partial storage map
  - `movePrecompileToAddress`: address

  Notes:
  - Object keys are `0x`-prefixed account addresses.
  - For one account, `state` and `stateDiff` are mutually exclusive.
  - Overrides apply only to the simulation; they do not persist state.

- `blockOverrides` (optional, MegaETH extension): `object`

  Accepted fields include:
  - `number`
  - `time`
  - `gasLimit`
  - `feeRecipient`
  - `baseFeePerGas`
  - `prevRandao`
  - `withdrawals`
  - `blobBaseFee`

  Notes:
  - These fields override the simulated block environment only for this call.
  - This is non-standard behavior and should not be assumed on other providers.

## Returns
- `result` (string)

  A `0x`-prefixed hex data string containing the returned bytes from the call.

  Notes:
  - `0x` means the call returned no data.
  - Calls to non-contract addresses can return `0x`.
  - Decode the returned bytes according to the target contract ABI.
  - Reverts are typically surfaced as top-level JSON-RPC errors rather than as a normal `result`.

## Examples

### curl: explicit `latest` using `input`
```bash
curl -sS https://mainnet.megaeth.com/rpc \
  -H 'content-type: application/json' \
  --data '{"jsonrpc":"2.0","id":46,"method":"eth_call","params":[{"to":"0x0000000000000000000000000000000000000004","input":"0x11223344"},"latest"]}'
```

### JSON-RPC request: explicit `latest` using `input`
```json
{"jsonrpc":"2.0","id":46,"method":"eth_call","params":[{"to":"0x0000000000000000000000000000000000000004","input":"0x11223344"},"latest"]}
```

### Response: explicit `latest` using `input`
```json
{"jsonrpc":"2.0","id":46,"result":"0x11223344"}
```

### JSON-RPC request: omitted block using `data`
```json
{"jsonrpc":"2.0","id":47,"method":"eth_call","params":[{"to":"0x0000000000000000000000000000000000000004","data":"0x11223344"}]}
```

### Response: omitted block using `data`
```json
{"jsonrpc":"2.0","id":47,"result":"0x11223344"}
```

### JSON-RPC request: with `stateOverrides` and `blockOverrides`
```json
{"jsonrpc":"2.0","id":48,"method":"eth_call","params":[{"to":"0x0000000000000000000000000000000000000004","input":"0x11223344"},"latest",{"0x0000000000000000000000000000000000000000":{"balance":"0x1"}},{"time":"0x1"}]}
```

### Response: with `stateOverrides` and `blockOverrides`
```json
{"jsonrpc":"2.0","id":48,"result":"0x11223344"}
```

### JSON-RPC request: mismatched `input` and `data`
```json
{"jsonrpc":"2.0","id":44,"method":"eth_call","params":[{"to":"0x0000000000000000000000000000000000000000","input":"0x01","data":"0x02"},"latest"]}
```

### Error response: mismatched `input` and `data`
```json
{"jsonrpc":"2.0","error":{"code":-32602,"message":"both \"data\" and \"input\" are set and not equal. Please use \"input\" to pass transaction call data"},"id":44}
```

## MegaETH Behavior
- On the MegaETH public endpoint, both `input` and `data` were accepted as calldata field names for the examples above.
- On the MegaETH public endpoint, omitting the `block` parameter was accepted for the example above and returned the same result as explicit `latest`.
- On the MegaETH public endpoint, the optional `stateOverrides` and `blockOverrides` parameters were accepted for the example above.
- For the identity precompile call shown above (`to = 0x0000000000000000000000000000000000000004`, calldata `0x11223344`), MegaETH returned `0x11223344`.
- When both `input` and `data` were present with different values, MegaETH returned JSON-RPC error `-32602`.
- Public endpoints may enforce rate limits.

## Errors
- `3` Execution reverted

  When it happens: The simulated EVM execution reverts.

  Example:
  ```json
  {"jsonrpc":"2.0","id":1,"error":{"code":3,"message":"execution reverted","data":"0x08c379a0..."}}
  ```

  Client handling: Inspect and decode `error.data` when present to recover the revert payload.

- `-32602` Invalid params

  When it happens: The request shape is invalid, hex values are malformed, mutually exclusive fields are combined, or `input` / `data` are both present but different.

  Example:
  ```json
  {"jsonrpc":"2.0","error":{"code":-32602,"message":"both \"data\" and \"input\" are set and not equal. Please use \"input\" to pass transaction call data"},"id":44}
  ```

  Client handling: Fix the request shape or field values before retrying.

- `-32005` Rate limited

  When it happens: The request exceeds the public endpoint's rate limit.

  Client handling: Retry with backoff and reduce burst rate.

- Provider-specific execution failure

  When it happens: The request exceeds a provider-side call gas cap, runs out of gas, hits an invalid opcode, or otherwise fails during server-side execution.

  Client handling: Inspect `error.message` and `error.data` when present, then adjust gas, calldata, or simulation context.

- Block resolution failure

  When it happens: The specified block number, hash, or tag cannot be resolved.

  Notes:
  - Depending on the client and context, this can surface as a provider-specific `block not found` error.
  - Some Ethereum clients also use `-39001` (`Unknown block`) for unresolved block contexts.

  Client handling: Retry only if you expect the referenced block to become available.

## Best Practices
- Prefer `input` over `data` in client code.
- If you send both `input` and `data`, make them identical.
- Set `from` explicitly when `msg.sender` matters to the simulation.
- Use a fixed block number, `safe`, or `finalized` when deterministic reads matter.
- Omit `gas` unless you intentionally want to cap the simulation.
- Do not mix `gasPrice` with EIP-1559 fee fields.
- Treat `stateOverrides` and `blockOverrides` as debugging or simulation tools, not portable production behavior.
- Decode the returned bytes with the target contract ABI, and inspect `error.data` for reverts.

## Compatibility
- `eth_call` is standard Ethereum JSON-RPC.
- The portable parameter shape is `[transaction, block?]`.
- MegaETH currently also accepts an omitted `block` parameter, both `input` and `data` as calldata field names, and optional `stateOverrides` / `blockOverrides`.
- Do not assume those MegaETH-specific conveniences and extensions will work on other providers.
