# eth_createAccessList

## Summary
Simulates a transaction against a selected block state and returns the addresses and storage keys the EVM would access, along with the gas used by the simulation.

This method is part of the standard Ethereum JSON-RPC API. The result can be attached to a transaction as an EIP-2930 `accessList`. On MegaETH, the public endpoint currently accepts both `input` and `data` as calldata field names, and currently also accepts an omitted block parameter.

## Parameters
- `transaction` (required): `object`

  Accepted fields:
  - `type`: `0x`-prefixed transaction type `QUANTITY`
  - `from`: `0x`-prefixed 20-byte sender address
  - `to`: `0x`-prefixed 20-byte recipient address; omit or use `null` for contract creation
  - `gas`: `0x`-prefixed gas limit `QUANTITY`
  - `gasPrice`: legacy fee-per-gas `QUANTITY`
  - `maxFeePerGas`: EIP-1559 max fee per gas `QUANTITY`
  - `maxPriorityFeePerGas`: EIP-1559 priority fee per gas `QUANTITY`
  - `value`: wei amount as a `QUANTITY`
  - `input`: calldata or init code as `0x`-prefixed hex data
  - `data`: calldata alias accepted by MegaETH and many clients
  - `nonce`: transaction nonce as a `QUANTITY`
  - `accessList`: EIP-2930 access list
  - `chainId`: chain id as a `QUANTITY`
  - chain/client-dependent extended fields such as `maxFeePerBlobGas`, `blobVersionedHashes`, `blobs`, and `authorizationList`

  Notes:
  - For portable behavior, prefer `input` and avoid sending both `input` and `data` in the same request.
  - For contract creation, omit `to` and put the init code in `input` or `data`.
  - Use either `gasPrice` or EIP-1559 fee fields. Do not mix them in the same request.
  - If you provide an `accessList`, MegaETH uses it as a seed and augments it with any additional addresses and slots discovered during simulation.
  - Pre-execution checks still apply. A too-low gas cap or an unfunded sender can fail before simulation completes.

- `block` (optional): `string`

  Accepted values:
  - hex block number as a `0x`-prefixed `QUANTITY`
  - one of: `earliest`, `finalized`, `safe`, `latest`, `pending`

  Notes:
  - Use an explicit block selector for portable and reproducible behavior.
  - Block hash / EIP-1898 block-object selectors are not part of this method's standard parameter shape.
  - MegaETH currently accepts an omitted block parameter, but that should be treated as a convenience rather than a portable guarantee.

## Returns
- `result` (`object`)

  Fields:
  - `accessList`: array of accessed accounts and storage slots
  - `gasUsed`: `0x`-prefixed hex `QUANTITY`
  - `error` (optional): string describing an execution failure reported inside the result

  Access list entry shape:
  - `address`: `0x`-prefixed 20-byte address
  - `storageKeys`: array of `0x`-prefixed 32-byte storage slot keys

  Notes:
  - `accessList` can be empty.
  - `gasUsed` is the gas consumed by the simulation.
  - Some execution failures are reported in `result.error` while still returning `accessList` and `gasUsed`.
  - Pre-execution validation failures can still surface as top-level JSON-RPC errors instead of `result.error`.

## Examples

### curl: explicit `latest` using `input`
```bash
curl -sS https://mainnet.megaeth.com/rpc \
  -H 'content-type: application/json' \
  --data '{"jsonrpc":"2.0","id":7,"method":"eth_createAccessList","params":[{"to":"0x1111111111111111111111111111111111111111","input":"0x"},"latest"]}'
```

### JSON-RPC request: explicit `latest` using `input`
```json
{"jsonrpc":"2.0","id":7,"method":"eth_createAccessList","params":[{"to":"0x1111111111111111111111111111111111111111","input":"0x"},"latest"]}
```

### Response: explicit `latest` using `input`
```json
{"jsonrpc":"2.0","id":7,"result":{"accessList":[],"gasUsed":"0xea60"}}
```

### JSON-RPC request: omitted block using `data`
```json
{"jsonrpc":"2.0","id":6,"method":"eth_createAccessList","params":[{"to":"0x1111111111111111111111111111111111111111","data":"0x"}]}
```

### Response: omitted block using `data`
```json
{"jsonrpc":"2.0","id":6,"result":{"accessList":[],"gasUsed":"0xea60"}}
```

### JSON-RPC request: gas too low
```json
{"jsonrpc":"2.0","id":3,"method":"eth_createAccessList","params":[{"to":"0x2222222222222222222222222222222222222222","gas":"0x5208"},"latest"]}
```

### Error response: gas too low
```json
{"jsonrpc":"2.0","id":3,"error":{"code":-32000,"message":"intrinsic gas too low"}}
```

## MegaETH Behavior
- both `input` and `data` were accepted as calldata field names for this method.
- omitting the `block` parameter was accepted for the simple requests shown above and returned the same result as explicit `latest`.
- The simple empty-calldata calls shown above returned an empty `accessList` and `gasUsed` of `0xea60` (`60000`).
- If execution actually reverts or halts after it begins, MegaETH's implementation can return a normal `result` object with `accessList`, `gasUsed`, and `result.error`.
- Pre-execution failures such as intrinsic-gas checks and insufficient-funds checks can still be returned as top-level JSON-RPC errors.
- Requests may be rate-limited by the public RPC provider.

## Errors
- `-32602` Invalid params

  When it happens: The request has the wrong parameter shape, malformed hex, an invalid address, or an unsupported field/value combination.

  Example:
  ```json
  {"jsonrpc":"2.0","id":1,"error":{"code":-32602,"message":"Invalid params"}}
  ```

  Client handling: Fix the request shape or field values before retrying.

- `-32000` Server-side precheck failed

  When it happens: The node rejects the request before normal execution simulation begins. A common case is `intrinsic gas too low`.

  Example:
  ```json
  {"jsonrpc":"2.0","id":3,"error":{"code":-32000,"message":"intrinsic gas too low"}}
  ```

  Client handling: Raise or remove the `gas` cap and make sure the request satisfies intrinsic gas requirements.

- `-32003` Insufficient funds

  When it happens: The supplied sender, fees, and value cannot be covered by the sender balance in the selected state.

  Example message:
  ```json
  {"jsonrpc":"2.0","id":5,"error":{"code":-32003,"message":"insufficient funds for gas * price + value: have 0 want 10"}}
  ```

  Client handling: Fund the sender or lower the value / fee requirements before retrying.

- `-32005` Rate limited

  When it happens: The request exceeds the public endpoint's rate limit.

  Client handling: Retry with backoff and reduce burst rate.

- Execution revert / halt reported in `result.error`

  When it happens: Execution starts but fails during simulation. In that case the response may still be a normal `result` object containing `accessList`, `gasUsed`, and `error`.

  Client handling: Inspect both top-level JSON-RPC errors and `result.error`; do not assume all failures use the same channel.

## Best Practices
- Use an explicit block selector when you need portable or reproducible behavior.
- Prefer `input` for calldata in client code, even though MegaETH currently also accepts `data`.
- Do not set `gas` unless you intentionally want to cap the simulation. If you do set it, make sure it is comfortably above intrinsic gas.
- Treat an empty `accessList` as a valid result.
- If you already have a partial `accessList`, you can provide it and let MegaETH augment it.
- Check both `result.error` and top-level JSON-RPC errors in client integrations.
- Use a fixed block number rather than `latest` or `pending` when deterministic replay matters.

## Compatibility
- `eth_createAccessList` is standard Ethereum JSON-RPC.
- The standard parameter shape is `[transaction, block?]`.
- MegaETH currently accepts omitted `block` and both `input` / `data`, but other providers may not.
- Do not assume block-hash selectors or provider-specific extension parameters are portable for this method.
