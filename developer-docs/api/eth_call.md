# eth_call

Executes a read-only message call against the state of a selected block.

## Ethereum Standard

`eth_call(transaction, block?) -> Data`

## MegaETH Differences

- MegaETH currently accepts both `input` and `data` as calldata field names.
- The public MegaETH endpoint currently accepts an omitted `block` parameter.
- The public MegaETH endpoint also accepts optional [`StateOverride`](../types.md#stateoverride) and [`BlockOverrides`](../types.md#blockoverrides) parameters for simulation-only overrides.
- Those override parameters are MegaETH-specific and not portable Ethereum JSON-RPC behavior.

## Request

Portable clients should send `params` as `[transaction, block]`.

| Position | Type | Required | Notes |
|---|---|---|---|
| `0` | [`TransactionCall`](../types.md#transactioncall) | Yes | Call object with fields such as `to`, `from`, `value`, `input`, `gas`, and fee fields |
| `1` | [`BlockReferenceString`](../types.md#blockreferencestring) | Yes for portable clients | Execution context |
| `2` | [`StateOverride`](../types.md#stateoverride) | No, MegaETH only | Temporary per-account overrides for this simulation |
| `3` | [`BlockOverrides`](../types.md#blockoverrides) | No, MegaETH only | Temporary block-environment overrides for this simulation |

Reader notes:

- Prefer `input` for portable client behavior.
- If both `input` and `data` are present, they must be identical or the request is rejected.
- Use either `gasPrice` or EIP-1559 fee fields, not both.
- Set `from` explicitly when `msg.sender` matters to the simulation.
- Use a fixed block number, block hash, `safe`, or `finalized` when deterministic results matter.

## Response

| Field | Type | Notes |
|---|---|---|
| `result` | [`Data`](../types.md#data) | Raw return bytes from the call |

Reader notes:

- `0x` is a valid successful result; calls to non-contract addresses can return `0x`.
- Reverts surface as top-level JSON-RPC errors, not as a normal `result`.

## Common Errors

| Code | When it usually happens | What to do |
|---|---|---|
| `-32602` | The call object, block selector, or override object is malformed, or `input` and `data` disagree | Fix the request before retrying |
| `3` | The simulated execution reverted | Decode `error.data` when present and fix the call conditions |
| `-32000` | The simulation failed or hit a provider-side execution limit | Inspect `error.message`, adjust gas or call shape, and retry only after fixing the cause |
| `-32005` | The public endpoint rate-limited the request | Back off and retry later |

See also [Error reference](../errors.md).

## Example

```bash
curl -sS https://mainnet.megaeth.com/rpc \
  -H 'content-type: application/json' \
  --data '{"jsonrpc":"2.0","id":46,"method":"eth_call","params":[{"to":"0x0000000000000000000000000000000000000004","input":"0x11223344"},"latest"]}'
```

```json
{"jsonrpc":"2.0","id":46,"result":"0x11223344"}
```
