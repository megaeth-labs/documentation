# eth_estimateGas

Estimates the gas required to execute a transaction.

## Parameters

| Position | Name | Type | Required | Notes |
|---|---|---|---|---|
| `0` | `transaction` | `object` | Yes | Transaction to simulate |
| `1` | `block` | [`BlockNumberOrTag`](../types.md#blocknumberortag) | No | Default: `"latest"` |

### `transaction`

| Field | Type | Required | Notes |
|---|---|---|---|
| `from` | `Address` | No | Caller |
| `to` | `Address \| null` | No | Target; `null` for create simulation |
| `value` | `Quantity` | No | Native value sent |
| `input` | `Data` | No | Calldata; prefer over `data` |
| `gas` | `Quantity` | No | Gas cap |
| `gasPrice` | `Quantity` | No | Legacy fee; do not mix with EIP-1559 fields |
| `maxFeePerGas` | `Quantity` | No | EIP-1559 max fee |
| `maxPriorityFeePerGas` | `Quantity` | No | EIP-1559 tip cap |
| ... | | | See [`TransactionCall`](../types.md#transactioncall) for the complete field list |

### `block`

Execution context. Accepts a hex block number or one of: `"earliest"`, `"latest"`, `"pending"`, `"safe"`, `"finalized"`. Default: `"latest"`.

## Returns

| Field | Type | Notes |
|---|---|---|
| `result` | [`Quantity`](../types.md#quantity) | Estimated execution gas |

## Errors

| Code | Cause | Fix |
|---|---|---|
| `-32602` | Malformed transaction fields, fee model, or block selector | Fix the request |
| `-32000` | Estimation failed, hit a provider-side execution limit, or used a rejected explicit gas cap | Inspect `error.message` and adjust gas or call shape |
| `3` | Simulated execution reverted | Decode `error.data` and fix the call conditions |

See also [Error reference](../errors.md).

## Example

```bash
curl -sS https://mainnet.megaeth.com/rpc \
  -H 'content-type: application/json' \
  --data '{"jsonrpc":"2.0","id":57,"method":"eth_estimateGas","params":[{"to":"0x0000000000000000000000000000000000000000","value":"0x0"},"latest"]}'
```

```jsonc
{"jsonrpc":"2.0","id":57,"result":"0xea60"}  // 60,000 gas
```
