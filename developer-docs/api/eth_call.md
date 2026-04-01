# eth_call

Simulates a transaction against a given block's state and returns the result without creating an on-chain transaction.

## Parameters

| Position | Name | Type | Required | Notes |
|---|---|---|---|---|
| `0` | `transaction` | `object` | Yes | Call parameters |
| `1` | `block` | [`BlockNumberOrTag`](../types.md#blocknumberortag) | No | Default: `"latest"` |
| `2` | `stateOverride` | `object` | No | Per-account overrides |
| `3` | `blockOverrides` | `object` | No | Block-environment overrides |

### `transaction`

| Field | Type | Required | Notes |
|---|---|---|---|
| `from` | `Address` | No | Caller; set explicitly when `msg.sender` matters |
| `to` | `Address \| null` | No | Target; `null` for create simulation |
| `value` | `Quantity` | No | Native value sent |
| `input` | `Data` | No | Calldata; `data` is also accepted but `input` is preferred. If both are present they must be identical |
| `gas` | `Quantity` | No | Gas cap |
| `gasPrice` | `Quantity` | No | Legacy fee; do not mix with EIP-1559 fields |
| `maxFeePerGas` | `Quantity` | No | EIP-1559 max fee |
| `maxPriorityFeePerGas` | `Quantity` | No | EIP-1559 tip cap |
| ... | | | See [`TransactionCall`](../types.md#transactioncall) for the complete field list |

### `block`

Block state to simulate against. Accepts a hex block number or one of: `"earliest"`, `"latest"`, `"pending"`, `"safe"`, `"finalized"`. Default: `"latest"`.

### `stateOverride`

Temporary account-level overrides applied only for this simulation. Object keyed by address; each value contains:

| Field | Type | Notes |
|---|---|---|
| `balance` | `Quantity` | Override the account balance |
| `nonce` | `Quantity` | Override the account nonce |
| `code` | `Data` | Override the account bytecode |
| `state` | `Object` | Replace the account's full storage (slot → value mapping); mutually exclusive with `stateDiff` |
| `stateDiff` | `Object` | Patch individual storage slots; mutually exclusive with `state` |
| `movePrecompileToAddress` | `Address` | Move a precompile to the specified address before `code` is applied |

### `blockOverrides`

Temporary block-environment overrides applied only for this simulation.

| Field | Type | Notes |
|---|---|---|
| `number` | `Quantity` | Override `block.number` |
| `time` | `Quantity` | Override `block.timestamp` |
| `gasLimit` | `Quantity` | Override `block.gasLimit` |
| `feeRecipient` | `Address` | Override `block.coinbase` |
| `prevRandao` | `Quantity` | Override randomness |
| `baseFeePerGas` | `Quantity` | Override `block.baseFee` |
| `withdrawals` | `Withdrawal[]` | Override withdrawals |
| `blobBaseFee` | `Quantity` | Override blob base fee |

## Returns

| Field | Type | Notes |
|---|---|---|
| `result` | `Data` | Raw return bytes from the call. `0x` is valid for successful calls to non-contract addresses. Reverts surface as JSON-RPC errors, not as a normal result |

## Errors

| Code | Cause | Fix |
|---|---|---|
| `-32602` | Malformed call object, block selector, or override object, or `input` and `data` disagree | Fix the request |
| `3` | Simulated execution reverted | Decode `error.data` and fix the call conditions |
| `-32000` | Simulation failed or hit an execution limit | Inspect `error.message` and adjust gas or call shape |

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
