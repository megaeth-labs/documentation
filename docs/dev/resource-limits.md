---
description: MegaETH resource limits — 7 per-transaction and per-block ceilings on gas, compute, data, KV updates, state growth, transaction size, and DA size.
---

# Resource Limits

MegaETH enforces seven resource limits on transactions and blocks.
Four are **protocol constants** defined in the EVM specification; three are **sequencer-configured** values that may change without a hardfork.

## Resource Types

- **Gas** — the total gas (compute + storage) a transaction may consume, as defined in the [Gas Model](gas-model.md).
- **[Compute Gas](gas-model.md#compute-gas-costs)** — the computational component of gas, identical to Ethereum's gas definition.
- **Data Size** — the total bytes that need to be transmitted and stored for a transaction, including calldata, event logs (topics and data), storage writes (40 bytes per write), account updates (40 bytes each), and deployed contract code.
- **KV Updates** — the number of distinct state entries (accounts and storage slots) modified by a transaction. Repeated updates to the same entry count as one.
- **State Growth** — the number of new state entries (accounts, storage slots, contracts) created by a transaction. Entries cleared before the transaction ends do not count.
- **Transaction Encoded Size** — the byte size of the RLP-encoded transaction.
- **DA Size** — the compressed size of the transaction's data for L1 data availability submission.

For data size, KV updates, and state growth, block-level usage is the sum of usage across all transactions in the block.

## Limits

### Pre-Execution Limits (Sequencer-Configured)

These limits are checked before a transaction is executed.
Transactions that exceed them are rejected by the transaction pool.
The values below reflect the current mainnet sequencer configuration and may change without a hardfork.

| Resource | Per-Transaction Limit | Per-Block Limit |
| -------- | --------------------- | --------------- |
| Gas | 2,000,000,000 (2B) | 2,000,000,000 (2B) |
| Transaction Encoded Size | 1,048,576 (1 MiB) | — |
| DA Size | Dynamic (set via RPC) | Dynamic (set via RPC) |

### Runtime Limits (Protocol Constants)

These limits are enforced during execution.
They are protocol constants that can only change through a hardfork.

| Resource | Per-Transaction Limit | Per-Block Limit |
| -------- | --------------------- | --------------- |
| Compute Gas | 200,000,000 | Unlimited (subject to block gas limit) |
| Data Size | 12.5 MB | 12.5 MB |
| KV Updates | 500,000 | 500,000 |
| State Growth | 1,000 | 1,000 |

## Per-Transaction Limit Behavior

When a transaction hits any of the runtime per-transaction limits, the following happens:

1. Execution halts immediately.
2. Any remaining gas is preserved and refunded to the sender.
3. The transaction is included in the block with status set to failed (status=0).
4. No state changes from the transaction are applied.

Pre-execution limit violations cause the transaction to be permanently rejected from the transaction pool — it is never included in a block.

## Per-Block Limit Enforcement

The per-block limits for data size, KV updates, and state growth can only be fully evaluated after a transaction has been executed.
When building a block, these limits are enforced as follows:

1. Before executing a transaction, the block builder checks whether any previous transaction has already caused the block to exceed a per-block limit. If so, the new transaction is rejected before execution and the block is sealed.
2. Otherwise, the transaction is executed. If its execution causes the block to exceed a per-block limit, the transaction is still included — it is not reverted or discarded. Per-transaction limits still apply.
3. No further transactions will be added to the block after it exceeds any per-block limit.

In other words, the last transaction in a block is allowed to push the block's resource usage beyond the per-block limit.
This maximizes block utilization by avoiding the waste of a valid transaction whose resource consumption can only be known after execution.

## Related Pages

- [Gas Model](gas-model.md) — compute gas, storage gas, and the bucket multiplier
- [Gas Estimation](gas-estimation.md) — estimate gas correctly and avoid common errors
- [EVM Differences](evm-differences.md) — full list of behavioral differences from Ethereum
- [Resource Limits (spec)](../spec/evm/resource-limits.md) — formal specification of limit enforcement
- [Resource Accounting (spec)](../spec/evm/resource-accounting.md) — how counters are tracked per opcode
