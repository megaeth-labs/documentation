# eth_call

Simulates a transaction against a given block's state and returns the result without creating an on-chain transaction.

## Parameters

Pass `params` as `[transaction, block, stateOverride, blockOverrides]`. Only `transaction` is required.

### `transaction`

Describes the simulated transaction.

| Field | Type | Required | Notes |
|---|---|---|---|
| `to` | `Data` (20 bytes) | Yes | Target contract address |
| `from` | `Data` (20 bytes) | No | Sender address. Set explicitly when `msg.sender` matters |
| `input` | `Data` | No | Calldata. MegaETH also accepts `data`, but prefer `input` for portability |
| `value` | `Quantity` | No | Wei to send with the call |
| `gas` | `Quantity` | No | Gas limit for the simulation |
| `gasPrice` | `Quantity` | No | Legacy gas price. Cannot be combined with EIP-1559 fee fields |
| `maxFeePerGas` | `Quantity` | No | EIP-1559 max fee. Cannot be combined with `gasPrice` |
| `maxPriorityFeePerGas` | `Quantity` | No | EIP-1559 priority fee. Cannot be combined with `gasPrice` |

See the [types reference](../types.md#transactioncall) for the complete field list.

### `block`

Block state to simulate against. Accepts a hex block number or one of: `"earliest"`, `"latest"`, `"pending"`, `"safe"`, `"finalized"`. Default: `"latest"`.

### `stateOverride`

Temporary account-level overrides applied only for this simulation. Keyed by address.

| Field | Type | Notes |
|---|---|---|
| `balance` | `Quantity` | Override the account balance |
| `nonce` | `Quantity` | Override the account nonce |
| `code` | `Data` | Override the account bytecode |
| `state` | `Object` | Replace the entire storage (slot → value mapping). Cannot be combined with `stateDiff` |
| `stateDiff` | `Object` | Patch individual storage slots without replacing the full state. Cannot be combined with `state` |

### `blockOverrides`

Temporary block-environment overrides applied only for this simulation.

| Field | Type | Notes |
|---|---|---|
| `number` | `Quantity` | Override `block.number` |
| `time` | `Quantity` | Override `block.timestamp` |
| `gasLimit` | `Quantity` | Override `block.gasLimit` |
| `feeRecipient` | `Data` (20 bytes) | Override `block.coinbase` |
| `baseFeePerGas` | `Quantity` | Override `block.baseFee` |

## Returns

| Field | Type | Notes |
|---|---|---|
| `result` | [`Data`](../types.md#data) | Raw return bytes from the call. `0x` is a valid result (e.g., calls to non-contract addresses). Reverts surface as JSON-RPC errors, not as a normal `result` |

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
