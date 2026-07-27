---
description: "Executes ordered bundles of read-only calls against a selected MegaETH state."
---

# eth_callMany

## Summary

Executes one or more ordered bundles of read-only calls and returns a result for every call.
The public MegaETH gateway adds validation, compute limits, and an optional timeout to the node method.

## Parameters

| Position | Name             | Type             | Required | Description                                                        |
| -------- | ---------------- | ---------------- | -------- | ------------------------------------------------------------------ |
| `0`      | `bundles`        | array            | Yes      | One to 100 bundle objects, with at most 100 transactions in total. |
| `1`      | `stateContext`   | object           | Yes      | State against which the bundles execute.                           |
| `2`      | `stateOverrides` | object or `null` | No       | Temporary account-state overrides.                                 |
| `3`      | `timeoutMs`      | integer          | No       | Gateway timeout from 1 to 25,000 milliseconds; defaults to 5,000.  |

Each bundle requires a non-empty `transactions` array and may include a `blockOverride` object.
Each transaction uses the standard `eth_call` transaction-call fields.
`stateContext.blockNumber` is required and accepts a block number, block tag, or EIP-1898-style block reference.
`stateContext.transactionIndex` may be `-1` or a non-negative integer.

## Result

The result is an array of bundle results.
Each bundle result is an array containing one object per transaction; a successful call object contains a `value` field with the returned `DATA`.

## Comparison with Ethereum Standard JSON-RPC

### Ethereum Standard

`eth_callMany` is not part of the core Ethereum JSON-RPC API, although compatible implementations use it for ordered multi-call simulation.

### MegaETH Node Behavior

The MegaETH node executes bundles in order against a shared evolving simulation state and returns a nested result array.

### MegaETH Public Gateway

The gateway accepts two to four positional parameters, limits requests to 100 bundles and 100 total transactions, and limits each call to 60,000,000 compute gas.
It applies a 5-second default timeout and accepts an explicit timeout up to 25 seconds.

## Errors

The `| Scope |` column distinguishes method failures from gateway policy errors.

| Code     | Scope            | Message           | When it happens                                                                                             |
| -------- | ---------------- | ----------------- | ----------------------------------------------------------------------------------------------------------- |
| `-32602` | Method           | Invalid params    | Required objects are missing, fields are malformed, or bundle, transaction, or timeout limits are exceeded. |
| `-32000` | Method           | Server error      | A simulation cannot execute or its timeout expires.                                                         |
| `-32099` | Transport/policy | Payload too large | The request exceeds the 1.5 MiB public endpoint body limit.                                                 |

## Examples

Endpoint: `https://mainnet.megaeth.com/rpc`

Capture date: July 24, 2026

Outcome: success

```json
{
  "jsonrpc": "2.0",
  "id": 1,
  "method": "eth_callMany",
  "params": [
    [
      {
        "transactions": [
          {
            "to": "0x0000000000000000000000000000000000000000",
            "data": "0x"
          }
        ]
      }
    ],
    { "blockNumber": "latest" }
  ]
}
```

```json
{
  "jsonrpc": "2.0",
  "id": 1,
  "result": [[{ "value": "0x" }]]
}
```

## Sources

- Probe: MegaETH Mainnet public endpoint, July 24, 2026
