# eth_estimateGas

Estimates the execution gas required for a transaction simulation without sending the transaction.

## Ethereum Standard

`eth_estimateGas(transaction, block?) -> Quantity`

## MegaETH Differences

- On MegaETH, simple transfer-shaped requests can return `0xea60` (`60000`) rather than Ethereum mainnet's common `0x5208` (`21000`).
- The public MegaETH endpoint currently accepts an omitted `block` parameter.

## Request

Portable clients should send `params` as `[transaction, block]`.

| Position | Type | Required | Notes |
|---|---|---|---|
| `0` | [`TransactionCall`](../types.md#transactioncall) | Yes | Simulation transaction object |
| `1` | [`BlockReferenceString`](../types.md#blockreferencestring) | No | Execution context |

Reader notes:

- Estimate the exact transaction shape you plan to send, including calldata and value.
- Use either `gasPrice` or EIP-1559 fee fields, not both.
- Omit `gas` unless you are intentionally constraining the search.
- Use an explicit block selector when you need more repeatable results.
- Do not hardcode `21000` for MegaETH transfers.

## Response

| Field | Type | Notes |
|---|---|---|
| `result` | [`Quantity`](../types.md#quantity) | Estimated execution gas |

- Add a safety margin in your transaction builder if your application needs one.
- For blob transactions, blob gas is separate and is not included in this value.

## Common Errors

| Code | When it usually happens | What to do |
|---|---|---|
| `-32602` | The transaction fields, fee model, or block selector are malformed | Fix the request before retrying |
| `-32000` | The estimation failed, hit a provider-side execution limit, or used a rejected explicit gas cap | Inspect `error.message`, remove or adjust the gas cap, and retry only after fixing the cause |
| `3` | The simulated execution reverted | Decode `error.data` when present and fix the call conditions |
| `-32005` | The public endpoint rate-limited the request | Back off and retry later |

See also [Error reference](../errors.md).

## Example

```bash
curl -sS https://mainnet.megaeth.com/rpc \
  -H 'content-type: application/json' \
  --data '{"jsonrpc":"2.0","id":57,"method":"eth_estimateGas","params":[{"to":"0x0000000000000000000000000000000000000000","value":"0x0"},"latest"]}'
```

```json
{"jsonrpc":"2.0","id":57,"result":"0xea60"}
```
