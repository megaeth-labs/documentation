---
description: "Replays every transaction in a MegaETH block selected by number and returns execution traces."
---

# debug_traceBlockByNumber

## Summary

Replays a block selected by number or tag and returns one execution trace per transaction.
The public MegaETH endpoint supports this standard debug method.

## Parameters

| Position | Name          | Type                    | Required                  | Description                                                                   |
| -------- | ------------- | ----------------------- | ------------------------- | ----------------------------------------------------------------------------- |
| `0`      | `block`       | `QUANTITY` or block tag | Yes                       | Block number or `latest`, `safe`, `finalized`, `earliest`, or `pending`.      |
| `1`      | `traceConfig` | object                  | Yes on the public gateway | Tracer selection and tracer-specific options. Use `{}` for the opcode tracer. |

Common `traceConfig` fields include `tracer`, `tracerConfig`, and `timeout`.

## Result

The result is an array ordered by transaction index.
Each entry contains `txHash` and either `result` or `error`; the shape of `result` depends on the selected tracer.

## MegaETH Behavior

### Ethereum Standard

The method replays all transactions in the selected block against its parent state.
The genesis block cannot be replayed because it has no parent state.

### MegaETH Node Behavior

MegaETH uses geth-compatible tracer options and includes system transactions in the block trace when present.

### MegaETH Public Gateway

The public gateway streams trace responses and requires two positional parameters.

## Errors

The `| Scope |` column distinguishes method failures from gateway policy errors.

| Code     | Scope            | Message           | When it happens                                                               |
| -------- | ---------------- | ----------------- | ----------------------------------------------------------------------------- |
| `-32602` | Method           | Invalid params    | Either positional parameter is missing or malformed.                          |
| `-32000` | Method           | Server error      | The block or parent state is unavailable, a timeout occurs, or tracing fails. |
| `-32099` | Transport/policy | Payload too large | The request exceeds the public endpoint body limit.                           |

## Examples

Endpoint: `https://mainnet.megaeth.com/rpc`

Capture date: July 24, 2026

Outcome: success

```json
{
  "jsonrpc": "2.0",
  "id": 1,
  "method": "debug_traceBlockByNumber",
  "params": ["0x1", { "tracer": "callTracer" }]
}
```

The nested call frame is abbreviated below.

```json
{
  "jsonrpc": "2.0",
  "id": 1,
  "result": [
    {
      "txHash": "0xecc262f36652019b75f4cb7315ff19f430fc92efd5a8048948400407d55fd904",
      "result": {
        "from": "0xdeaddeaddeaddeaddeaddeaddeaddeaddead0001",
        "to": "0x4200000000000000000000000000000000000015",
        "gasUsed": "0xb9d56c",
        "type": "CALL"
      }
    }
  ]
}
```

## Sources

- Spec: [Ethereum Execution APIs, `src/debug/trace.yaml`](https://github.com/ethereum/execution-apis/blob/50d1e5e0b6f5a5046e45421e5c84497ab6e55e6c/src/debug/trace.yaml)
- Probe: MegaETH Mainnet public endpoint, July 24, 2026
