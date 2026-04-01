---
description: Debug failing transactions on MegaETH — trace with debug_traceTransaction, replay with mega-evme, and diagnose gas errors.
---

# Debugging Transactions

MegaETH provides two ways to debug transactions:

1. **`debug_*` RPC methods** — trace transactions via JSON-RPC (requires a managed RPC endpoint)
2. **`mega-evme`** — replay or simulate transactions locally with full tracing

## Debug RPC Methods

Standard Ethereum debug methods — `debug_traceTransaction`, `debug_traceCall`, and `debug_traceBlockByNumber` — are available through managed RPC providers but **not on the public MegaETH RPC endpoint**.
Use a provider such as [Alchemy](https://www.alchemy.com/) to access them.

The following methods are available through managed providers:

- **`debug_traceTransaction`** — trace an already-mined transaction by hash
- **`debug_traceCall`** — simulate and trace a call without broadcasting
- **`debug_traceBlockByNumber`** / **`debug_traceBlockByHash`** — trace all transactions in a block

### Supported Tracers

| Tracer | `tracer` value | Description |
| ------ | -------------- | ----------- |
| Default (struct logger) | *(omit `tracer` field)* | Opcode-level trace with gas, stack, memory, and storage at each step |
| callTracer | `"callTracer"` | Nested call tree with inputs, outputs, and gas usage per call |
| prestateTracer | `"prestateTracer"` | Account state before execution; set `"diffMode": true` for before/after diff |
| flatCallTracer | `"flatCallTracer"` | Parity-style flat list of all calls |
| 4byteTracer | `"4byteTracer"` | Counts function selector usage |

{% hint style="info" %}
JavaScript tracers are not supported.
{% endhint %}

For method parameters, tracer configuration options, and response formats, see the [geth debug namespace documentation](https://geth.ethereum.org/docs/interacting-with-geth/rpc/ns-debug) and [built-in tracers reference](https://geth.ethereum.org/docs/developers/evm-tracing/built-in-tracers).

## Using mega-evme

`mega-evme` is a local CLI tool that uses the open-source [MegaEVM](https://github.com/megaeth-labs/mega-evm) implementation.
It can perfectly simulate any transaction's behavior on MegaETH, including storage gas, compute gas caps, and resource limits.

Use `mega-evme` when you want full local control over tracing, or when you don't have access to a managed RPC endpoint with debug methods.

### Installation

```bash
git clone https://github.com/megaeth-labs/mega-evm.git
cd mega-evm
cargo build --release -p mega-evme
# Binary: target/release/mega-evme
```

### Replaying an On-Chain Transaction

Replay a transaction by its hash to see exactly what happened during execution:

```bash
mega-evme replay 0xYourTxHash \
  --rpc https://mainnet.megaeth.com/rpc \
  --trace \
  --tracer opcode
```

Use the **call tracer** for a higher-level view of the call tree:

```bash
mega-evme replay 0xYourTxHash \
  --rpc https://mainnet.megaeth.com/rpc \
  --trace \
  --tracer call \
  --trace.call.with-log
```

Use the **pre-state diff** to see exactly which storage slots and balances changed:

```bash
mega-evme replay 0xYourTxHash \
  --rpc https://mainnet.megaeth.com/rpc \
  --trace \
  --tracer pre-state \
  --trace.prestate.diff-mode
```

Save the trace to a file for later analysis:

```bash
mega-evme replay 0xYourTxHash \
  --rpc https://mainnet.megaeth.com/rpc \
  --trace \
  --tracer opcode \
  --trace.output trace.json
```

#### "What-if" Replay

Override transaction fields to test alternative scenarios without rebroadcasting:

```bash
# Replay with a higher gas limit
mega-evme replay 0xYourTxHash \
  --rpc https://mainnet.megaeth.com/rpc \
  --override.gas-limit 50000000 \
  --trace

# Replay with different calldata
mega-evme replay 0xYourTxHash \
  --rpc https://mainnet.megaeth.com/rpc \
  --override.input 0xNewCalldata \
  --trace
```

### Simulating a New Transaction

Simulate a transaction against live chain state by forking from an RPC endpoint:

```bash
mega-evme tx \
  --fork \
  --fork.rpc https://mainnet.megaeth.com/rpc \
  --receiver 0xContractAddress \
  --input 0xCalldata \
  --sender 0xYourAddress \
  --trace \
  --tracer call
```

Fork from a specific block:

```bash
mega-evme tx \
  --fork \
  --fork.rpc https://mainnet.megaeth.com/rpc \
  --fork.block 12345678 \
  --receiver 0xContractAddress \
  --input 0xCalldata \
  --trace
```

### Tracers

`mega-evme` supports three tracers, each giving a different level of detail.
Pass `--tracer <type>` along with `--trace` to select one.

#### Opcode Tracer (`--tracer opcode`)

The default tracer.
Produces a step-by-step log of every EVM opcode executed, including the program counter, opcode name, gas remaining, stack contents, memory, and storage changes at each step.

Use this when you need to pinpoint the exact instruction where a transaction fails — for example, identifying which `SSTORE` consumed unexpected storage gas, or confirming that a specific opcode triggered the volatile data compute gas cap.
The output is verbose; use the flags below to reduce noise:

| Flag | Effect |
| ---- | ------ |
| `--trace.opcode.disable-memory` | Omit memory snapshots (significantly reduces output size) |
| `--trace.opcode.disable-stack` | Omit stack contents |
| `--trace.opcode.disable-storage` | Omit storage changes |
| `--trace.opcode.enable-return-data` | Include return data from calls |

#### Call Tracer (`--tracer call`)

Produces a nested call tree showing every `CALL`, `DELEGATECALL`, `STATICCALL`, and `CREATE` during execution, with gas usage, input/output data, and error messages for each frame.

Use this when you need to understand the high-level flow of a transaction — which contracts were called, in what order, and where a revert originated.
Add `--trace.call.with-log` to include emitted event logs in the output, or `--trace.call.only-top-call` to show only the top-level call.

#### Pre-state Tracer (`--tracer pre-state`)

Captures a snapshot of all account state (balances, nonces, code, storage slots) that the transaction touched before execution began.

Use this when you need to understand the initial conditions that led to a specific outcome — for example, verifying what a storage slot contained before an `SSTORE` overwrote it.
Add `--trace.prestate.diff-mode` to get a before/after diff showing exactly which balances, nonces, and storage slots changed.

## Common Debugging Scenarios

### Transaction Reverts with No Reason

Use the **callTracer** to find which internal call reverted and inspect its return data:

```bash
mega-evme replay 0xYourTxHash \
  --rpc https://mainnet.megaeth.com/rpc \
  --trace \
  --tracer call
```

Look for the deepest call with `"error": "Reverted"` in the output — its `output` field contains the ABI-encoded revert reason.

### Out of Gas from Storage Gas

If a transaction runs out of gas but the compute gas usage seems low, storage gas is likely the cause.
Use the **opcode tracer** and look for `SSTORE`, `CREATE`, `LOG`, or calldata-heavy operations consuming unexpectedly large amounts of gas.

See [Gas Estimation](gas-estimation.md) for how to avoid this with proper estimation.

### Out of Gas from Volatile Data Access

Accessing `block.timestamp`, `block.number`, or oracle storage caps the transaction's compute gas to 20,000,000.
If the trace shows execution halting after one of these reads, the transaction exceeded the 20M total compute gas cap imposed by volatile data access.
Split the work across multiple transactions so that only lightweight transactions access volatile data.

See [Volatile Data Access](../execution/volatile-data.md) for the full list of triggers and best practices.

## Related Pages

- [Gas Estimation](gas-estimation.md) — estimate gas correctly and avoid common errors
- [EVM Differences](../execution/overview.md) — volatile data caps, SSTORE refund changes, 98/100 forwarding
- [Gas Model](../execution/gas-model.md) — how compute gas and storage gas work
- [RPC Reference](../read/overview.md) — method availability and restrictions
- [Dual Gas Model (spec)](https://app.gitbook.com/o/iBzILuNyLtuxU3vUEuPe/s/apRp1sxFYuGhHAo7Y2Pz/evm/dual-gas-model) — formal specification of compute gas and storage gas
- [Gas Detention (spec)](https://app.gitbook.com/o/iBzILuNyLtuxU3vUEuPe/s/apRp1sxFYuGhHAo7Y2Pz/evm/gas-detention) — compute gas cap triggered by volatile data access
