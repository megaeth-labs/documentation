# eth_estimateGas

## Summary
Estimates the gas required to execute a transaction against the selected block state without sending the transaction.

This method is part of the standard Ethereum JSON-RPC API. The node simulates the transaction call object you provide and returns a `0x`-prefixed hex `QUANTITY` gas estimate.

On MegaETH, simple transfer-shaped requests can return `0xea60` (`60000`) rather than Ethereum mainnet's common `0x5208` (`21000`), so always estimate the exact transaction shape you plan to send.

## Parameters
- `transaction` (required): `object`

  Accepted fields:
  - `from`: `0x`-prefixed 20-byte sender address
  - `to`: `0x`-prefixed 20-byte recipient address; omit for contract creation
  - `gas`: `0x`-prefixed gas limit `QUANTITY`
  - `gasPrice`: legacy fee-per-gas `QUANTITY`
  - `maxFeePerGas`: EIP-1559 max fee per gas `QUANTITY`
  - `maxPriorityFeePerGas`: EIP-1559 priority fee per gas `QUANTITY`
  - `value`: wei amount as a `QUANTITY`
  - `data`: calldata or contract init code as `0x`-prefixed hex data
  - `nonce`: transaction nonce as a `QUANTITY`
  - `accessList`: EIP-2930 access list
  - chain/client-dependent extended fields such as `maxFeePerBlobGas`, `blobVersionedHashes`, and `authorizationList`

  Notes:
  - Use either `gasPrice` or EIP-1559 fee fields. Do not mix them in the same request.
  - For contract creation, omit `to` and put the init code in `data`.
  - On MegaETH public RPC endpoints, requests with `gas` above `10,000,000` may be rejected.
  - For portable client behavior, use only the standard `[transaction, block?]` parameter shape.

- `block` (optional): `string`

  Accepted values:
  - hex block number as a `0x`-prefixed `QUANTITY`
  - one of: `earliest`, `finalized`, `safe`, `latest`, `pending`

  Notes:
  - Use an explicit block selector when you need repeatable behavior.
  - On MegaETH, omitting this parameter is accepted.

## Returns
- `result` (string)

  A `0x`-prefixed hex `QUANTITY` representing the estimated gas required for the simulated execution to succeed.

  Notes:
  - The value is an estimate, not a guarantee for final on-chain inclusion.
  - The returned value has no leading zeros, except `0x0`.
  - The estimate depends on transaction shape, selected block state, and current chain conditions.
  - For blob transactions, blob gas is separate and is not included in this value.

## Examples

### curl: explicit `latest`
```bash
curl -sS https://mainnet.megaeth.com/rpc \
  -H 'content-type: application/json' \
  --data '{"jsonrpc":"2.0","id":57,"method":"eth_estimateGas","params":[{"to":"0x0000000000000000000000000000000000000000","value":"0x0"},"latest"]}'
```

### JSON-RPC request: explicit `latest`
```json
{"jsonrpc":"2.0","id":57,"method":"eth_estimateGas","params":[{"to":"0x0000000000000000000000000000000000000000","value":"0x0"},"latest"]}
```

### Response: explicit `latest`
```json
{"jsonrpc":"2.0","id":57,"result":"0xea60"}
```

### JSON-RPC request: omitted block
```json
{"jsonrpc":"2.0","id":51,"method":"eth_estimateGas","params":[{"to":"0x0000000000000000000000000000000000000000","value":"0x0"}]}
```

### Response: omitted block
```json
{"jsonrpc":"2.0","id":51,"result":"0xea60"}
```

### JSON-RPC request: conflicting fee fields
```json
{"jsonrpc":"2.0","id":56,"method":"eth_estimateGas","params":[{"to":"0x0000000000000000000000000000000000000000","gasPrice":"0x1","maxFeePerGas":"0x2"}]}
```

### Error response: conflicting fee fields
```json
{"jsonrpc":"2.0","id":56,"error":{"code":-32602,"message":"both gasPrice and (maxFeePerGas or maxPriorityFeePerGas) specified"}}
```

### Error response: execution reverted (common Ethereum client shape)
```json
{"jsonrpc":"2.0","id":58,"error":{"code":3,"message":"execution reverted","data":"0x08c379a0..."}}
```

### Error response: rate limited (HTTP `429`)
```json
{"jsonrpc":"2.0","id":null,"error":{"code":-32005,"message":"Rate limit exceeded"}}
```

## MegaETH Behavior
- For the simple zero-value transfer-shaped requests shown above, MegaETH returns `0xea60` (`60000`), not Ethereum mainnet's common `0x5208` (`21000`).
- Do not hardcode Ethereum mainnet's common `21000` baseline for MegaETH; estimate each transaction shape directly.
- MegaETH accepts an omitted `block` parameter for this method.
- MegaETH applies provider-side execution limits to gas estimation requests. Long-running estimations may fail with server-side execution errors.
- On public RPC endpoints, `eth_estimateGas` is in the `compute` rate-limit tier. Typical public usage is limited to `200` requests per `10` seconds; exceedance can return HTTP `429` with JSON-RPC error code `-32005`.
- On MegaETH public RPC endpoints, requests with `gas` above `10,000,000` may be rejected with a limit error.
- Estimates can change as state changes.

## Errors
- `-32602` Invalid params

  When it happens: The request contains malformed fields such as an invalid address, bad hex encoding, conflicting fee fields, or an invalid block selector.

  Example:
  ```json
  {"jsonrpc":"2.0","id":55,"error":{"code":-32602,"message":"Invalid params"}}
  ```

  Client handling: Fix the request shape or field values before retrying.

- `-32005` Rate limit exceeded

  When it happens: The request exceeds the public endpoint rate limit for the `compute` tier.

  Typical transport: HTTP `429` with JSON-RPC error code `-32005`.

  Typical public limit: `200` requests per `10` seconds.

  Client handling: Retry with backoff and reduce burst rate.

- `-32000` Gas estimation failed / exceeds limit

  When it happens: The request is rejected by provider-side execution limits. Common cases include a provided `gas` value that is too low, a request `gas` value above the MegaETH public RPC limit, or other execution-side failures surfaced by the provider.

  Typical messages include `gas required exceeds allowance` and `exceeds limit`.

  Client handling: Remove or raise the `gas` cap, keep `gas` at or below `10,000,000` on MegaETH public RPC endpoints, and inspect `error.message` and `error.data` when present.

- `3` Execution reverted (common Ethereum client behavior)

  When it happens: The simulated execution reverts.

  Notes:
  - Standard Ethereum clients commonly return code `3` and include raw revert bytes in `error.data`.
  - Providers can surface execution-side failures under different non-standard error codes.
  - Decode `error.data` in client code to recover the revert reason when available.

  Client handling: Inspect and decode the revert payload, then fix the underlying call conditions.

## Best Practices
- Estimate gas for the exact transaction shape you plan to send.
- Do not hardcode `21000` for MegaETH transfers.
- Provide `from`, `to`, `value`, and `data` explicitly when relevant.
- Omit `gas` unless you intentionally want to cap the search. If you do provide it, keep it at or below `10,000,000` on MegaETH public RPC endpoints.
- Use either `gasPrice` or EIP-1559 fee fields, never both.
- Use an explicit block selector if you need more repeatable results.
- Handle provider-specific execution errors by inspecting both `error.message` and `error.data` when present.
- Treat the returned value as an estimate and keep a safety margin when building the final transaction.
- For blob transactions, budget blob gas separately; `eth_estimateGas` returns execution gas only.

## Compatibility
- `eth_estimateGas` is standard Ethereum JSON-RPC.
- Provider-specific extensions beyond `[transaction, block?]` are not portable.
- Returned estimates can differ across chains, endpoints, and block states.
