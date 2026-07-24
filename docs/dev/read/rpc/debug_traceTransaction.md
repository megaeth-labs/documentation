---
description: "Replays a MegaETH transaction and returns its execution trace."
---

# debug_traceTransaction

## Summary

Replays a transaction in its original block context and returns an execution trace.
The public MegaETH endpoint supports this standard debug method.

## Parameters

| Position | Name              | Type             | Required                  | Description                                                                   |
| -------- | ----------------- | ---------------- | ------------------------- | ----------------------------------------------------------------------------- |
| `0`      | `transactionHash` | `DATA`, 32 bytes | Yes                       | Hash of a mined transaction.                                                  |
| `1`      | `traceConfig`     | object           | Yes on the public gateway | Tracer selection and tracer-specific options. Use `{}` for the opcode tracer. |

## Result

The result shape depends on the tracer.
With no named tracer, the result contains opcode-level `structLogs`; with `callTracer`, it is a nested call frame.

## MegaETH Behavior

### Ethereum Standard

The method reconstructs the transaction's pre-execution state, replays the transaction, and returns the selected trace format.

### MegaETH Node Behavior

MegaETH provides geth-compatible opcode and named tracers.
Tracing a system transaction may expose MegaETH system-contract calls.

### MegaETH Public Gateway

The public gateway streams this method's response and requires both positional parameters.
Support and a successful `callTracer` response were observed on July 24, 2026.

## Errors

The `| Scope |` column distinguishes method failures from gateway policy errors.

| Code     | Scope            | Message           | When it happens                                                                         |
| -------- | ---------------- | ----------------- | --------------------------------------------------------------------------------------- |
| `-32602` | Method           | Invalid params    | The hash or trace configuration is missing or malformed.                                |
| `-32000` | Method           | Server error      | The transaction or required history is unavailable, a timeout occurs, or tracing fails. |
| `-32099` | Transport/policy | Payload too large | The request exceeds the public endpoint body limit.                                     |

## Examples

Endpoint: `https://mainnet.megaeth.com/rpc`

Capture date: July 24, 2026

Outcome: success

```json
{
  "jsonrpc": "2.0",
  "id": 1,
  "method": "debug_traceTransaction",
  "params": [
    "0xecc262f36652019b75f4cb7315ff19f430fc92efd5a8048948400407d55fd904",
    { "tracer": "callTracer" }
  ]
}
```

The nested call frame is abbreviated below.

```json
{
  "jsonrpc": "2.0",
  "id": 1,
  "result": {
    "from": "0xdeaddeaddeaddeaddeaddeaddeaddeaddead0001",
    "to": "0x4200000000000000000000000000000000000015",
    "gas": "0x5f5e100",
    "gasUsed": "0xb9d56c",
    "type": "CALL"
  }
}
```

## Sources

- Spec: [Ethereum Execution APIs, `src/debug/trace.yaml`](https://github.com/ethereum/execution-apis/blob/50d1e5e0b6f5a5046e45421e5c84497ab6e55e6c/src/debug/trace.yaml)
- Node: [mega-reth debug RPC API](https://github.com/megaeth-labs/mega-reth/blob/0264d0821a8fe14ac6c7f710e9452edef7407b3f/crates/rpc/rpc-api/src/debug.rs)
- Gateway: [mega-rpc method registry](https://github.com/megaeth-labs/mega-rpc/blob/06aa35aa95d569c227cc25d2aa12834eb0458aa0/workers/src/spec/methods.ts)
- Probe: MegaETH Mainnet public endpoint, July 24, 2026
