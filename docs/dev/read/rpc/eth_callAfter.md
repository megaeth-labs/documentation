---
description: eth_callAfter — execute eth_call after waiting for an account's nonce to reach a target value.
---

# eth_callAfter

Executes `eth_call` after waiting for an account's nonce to reach a target value.
Useful for simulating a transaction that depends on prior transactions completing — for example, checking the result of a swap after a preceding approval has been confirmed.

## Parameters

Pass `params` as `[request, condition, stateOverride, blockOverrides]`. Only `request` and `condition` are required.

### `request`

Describes the simulated transaction.

| Field                  | Type              | Required | Notes                                                                     |
| ---------------------- | ----------------- | -------- | ------------------------------------------------------------------------- |
| `to`                   | `Data` (20 bytes) | Yes      | Target contract address                                                   |
| `from`                 | `Data` (20 bytes) | No       | Sender address. Set explicitly when `msg.sender` matters                  |
| `input`                | `Data`            | No       | Calldata. MegaETH also accepts `data`, but prefer `input` for portability |
| `value`                | `Quantity`        | No       | Wei to send with the call                                                 |
| `gas`                  | `Quantity`        | No       | Gas limit for the simulation                                              |
| `gasPrice`             | `Quantity`        | No       | Legacy gas price. Cannot be combined with EIP-1559 fee fields             |
| `maxFeePerGas`         | `Quantity`        | No       | EIP-1559 max fee. Cannot be combined with `gasPrice`                      |
| `maxPriorityFeePerGas` | `Quantity`        | No       | EIP-1559 priority fee. Cannot be combined with `gasPrice`                 |

### `condition`

| Field     | Type              | Required | Notes                                                        |
| --------- | ----------------- | -------- | ------------------------------------------------------------ |
| `account` | `Data` (20 bytes) | Yes      | Account address whose nonce to monitor                       |
| `nonce`   | `Quantity`        | Yes      | Target nonce value to wait for                               |
| `timeout` | `Number`          | No       | Max wait time in milliseconds. Default: `3000`. Max: `60000` |

### `stateOverride`

Optional. Temporary account-level overrides applied only for this simulation. Keyed by address.

| Field       | Type       | Notes                                                                          |
| ----------- | ---------- | ------------------------------------------------------------------------------ |
| `balance`   | `Quantity` | Override the account balance                                                   |
| `nonce`     | `Quantity` | Override the account nonce                                                     |
| `code`      | `Data`     | Override the account bytecode                                                  |
| `state`     | `Object`   | Replace the entire storage (slot → value). Cannot be combined with `stateDiff` |
| `stateDiff` | `Object`   | Patch individual storage slots. Cannot be combined with `state`                |

### `blockOverrides`

Optional. Temporary block-environment overrides applied only for this simulation.

| Field           | Type              | Notes                      |
| --------------- | ----------------- | -------------------------- |
| `number`        | `Quantity`        | Override `block.number`    |
| `time`          | `Quantity`        | Override `block.timestamp` |
| `gasLimit`      | `Quantity`        | Override `block.gasLimit`  |
| `feeRecipient`  | `Data` (20 bytes) | Override `block.coinbase`  |
| `baseFeePerGas` | `Quantity`        | Override `block.baseFee`   |

## Returns

| Field    | Type   | Notes                                                   |
| -------- | ------ | ------------------------------------------------------- |
| `result` | `Data` | Return data from the executed call — same as `eth_call` |

## Errors

| Code     | Cause                                                                                              | Fix                                                               |
| -------- | -------------------------------------------------------------------------------------------------- | ----------------------------------------------------------------- |
| `-32000` | `Timeout: timeout waiting for nonce condition` — nonce did not reach the target within the timeout | Increase `timeout`, or verify the prior transaction was submitted |
| `-32000` | `InternalError` — internal processing error                                                        | Retry the request                                                 |

See also [Error reference](error-codes.md).

## Example

Execute `eth_call` after waiting for account nonce to reach 5:

```bash
curl -sS https://mainnet.megaeth.com/rpc \
  -X POST -H "Content-Type: application/json" \
  -d '{
    "jsonrpc": "2.0",
    "id": 1,
    "method": "eth_callAfter",
    "params": [
      {
        "from": "0xf39fd6e51aad88f6f4ce6ab8827279cfffb92266",
        "to": "0x1234567890abcdef1234567890abcdef12345678",
        "data": "0x70a08231000000000000000000000000f39fd6e51aad88f6f4ce6ab8827279cfffb92266"
      },
      {
        "account": "0xf39fd6e51aad88f6f4ce6ab8827279cfffb92266",
        "nonce": "0x5",
        "timeout": 30000
      }
    ]
  }'
```

Successful response:

```json
{
  "jsonrpc": "2.0",
  "id": 1,
  "result": "0x0000000000000000000000000000000000000000000000000de0b6b3a7640000"
}
```

Timeout response:

```json
{
  "jsonrpc": "2.0",
  "id": 1,
  "error": {
    "code": -32000,
    "message": "Timeout: timeout waiting for nonce condition"
  }
}
```
