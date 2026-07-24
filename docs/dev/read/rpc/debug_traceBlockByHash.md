---
description: "Replays every transaction in a MegaETH block selected by hash and returns execution traces."
---

# debug_traceBlockByHash

## Summary

Replays a block selected by hash and returns one execution trace per transaction.
The public MegaETH endpoint supports this standard debug method.

## Parameters

| Position | Name          | Type             | Required                  | Description                                                                   |
| -------- | ------------- | ---------------- | ------------------------- | ----------------------------------------------------------------------------- |
| `0`      | `blockHash`   | `DATA`, 32 bytes | Yes                       | Hash of the block to replay.                                                  |
| `1`      | `traceConfig` | object           | Yes on the public gateway | Tracer selection and tracer-specific options. Use `{}` for the opcode tracer. |

Common `traceConfig` fields include `tracer`, `tracerConfig`, and `timeout`.
For example, set `tracer` to `"callTracer"` for a nested call frame instead of opcode-level `structLogs`.

## Result

The result is an array ordered by transaction index.
Each entry contains `txHash` and either `result` or `error`; the shape of `result` depends on the selected tracer.

## MegaETH Behavior

### Ethereum Standard

The method replays all transactions in the selected block against its parent state.
The genesis block cannot be replayed because it has no parent state.

### MegaETH Node Behavior

MegaETH uses the standard geth-compatible tracer options and returns a trace paired with each transaction hash.
System transactions may therefore appear in block traces.

### MegaETH Public Gateway

The public gateway streams trace responses because they can be large.
It requires two positional parameters and was observed to support `callTracer` on July 24, 2026.

## Errors

The `| Scope |` column distinguishes method failures from gateway policy errors.

| Code     | Scope            | Message           | When it happens                                                          |
| -------- | ---------------- | ----------------- | ------------------------------------------------------------------------ |
| `-32602` | Method           | Invalid params    | Either positional parameter is missing or malformed.                     |
| `-32000` | Method           | Server error      | The block is unknown, its parent state is unavailable, or tracing fails. |
| `-32099` | Transport/policy | Payload too large | The request exceeds the public endpoint body limit.                      |

## Examples

Endpoint: `https://mainnet.megaeth.com/rpc`

Capture date: July 24, 2026

Outcome: success

```json
{
  "jsonrpc": "2.0",
  "id": 1,
  "method": "debug_traceBlockByHash",
  "params": [
    "0x57804c21b747137075b29ce153b4f559345a3624273660c87e81bd57e7cbbc3d",
    { "tracer": "callTracer" }
  ]
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
