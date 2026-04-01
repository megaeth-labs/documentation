---
description: MegaETH resource limits — 7 per-transaction and per-block ceilings on gas, compute, data, KV updates, state growth, transaction size, and DA size.
---

# Resource Limits

MegaETH enforces seven resource limits on transactions and blocks.

| Resource                     | Per-Transaction | Per-Block      | How it changes       |
| ---------------------------- | --------------- | -------------- | -------------------- |
| **Gas**                      | 10,000,000,000  | 10,000,000,000 | Sequencer-configured |
| **Compute Gas**              | 200,000,000     | Unlimited      | Protocol constant    |
| **Data Size**                | 12.5 MB         | 12.5 MB        | Protocol constant    |
| **KV Updates**               | 500,000         | 500,000        | Protocol constant    |
| **State Growth**             | 1,000           | 1,000          | Protocol constant    |
| **Transaction Encoded Size** | 1 MB            | Unlimited      | Sequencer-configured |
| **DA Size**                  | Adaptive        | Adaptive       | Adaptive             |

Note: "Unlimited" means no dedicated per-block limit exists for that resource, but it is still implicitly bounded by other per-block limits such as block gas limit and DA size.

- **Protocol constants** can only change through a hardfork.
- **Sequencer-configured** values reflect the current mainnet configuration and may change without a hardfork.
- **Adaptive** values are adjusted by the sequencer at runtime, following the same mechanism as OP Stack's [DA Footprint Block Limit](https://specs.optimism.io/protocol/jovian/exec-engine.html#da-footprint-block-limit).

## Resource Definitions

- **Gas** — the total gas (compute + storage) a transaction may consume. Uses the same semantics as the block gas limit and transaction gas limit of standard Ethereum. See [Gas Model](gas-model.md).
- **[Compute Gas](gas-model.md#compute-gas-costs)** — the computational component of gas, identical to Ethereum's gas definition.
- **Data Size** — the total bytes that need to be transmitted and stored for a transaction, including calldata, event logs (topics and data), storage writes (40 bytes per write), account updates (40 bytes each), and deployed contract code.
- **KV Updates** — the number of distinct state entries (accounts and storage slots) modified by a transaction. Repeated updates to the same entry count as one.
- **State Growth** — the number of new state entries (accounts, storage slots, contracts) created by a transaction. Entries cleared before the transaction ends do not count.
- **Transaction Encoded Size** — the byte size of the RLP-encoded transaction.
- **DA Size** — the compressed size of the transaction's data for L1 data availability submission.

For Data Size, KV Updates, and State Growth, block-level usage is the sum of usage across all transactions in the block.

For formal definitions of resource limits and accounting, see [Resource Limits (spec)](https://app.gitbook.com/o/iBzILuNyLtuxU3vUEuPe/s/apRp1sxFYuGhHAo7Y2Pz/evm/resource-limits) and [Resource Accounting (spec)](https://app.gitbook.com/o/iBzILuNyLtuxU3vUEuPe/s/apRp1sxFYuGhHAo7Y2Pz/evm/resource-accounting).

## Enforcement

The seven limits are enforced at two different stages, which determines what happens when a transaction exceeds one.

### Before execution

**Gas**, **Transaction Encoded Size**, and **DA Size** are checked before a transaction enters a block.
A transaction that exceeds any of these per-transaction limits is **rejected by the transaction pool** and never included in a block.

**Gas** and **DA Size** also have per-block limits.
The block builder stops adding transactions once the block's cumulative gas or DA size reaches the limit.

### During execution

**Compute Gas**, **Data Size**, **KV Updates**, and **State Growth** are enforced while the transaction runs (see [formal spec](https://app.gitbook.com/o/iBzILuNyLtuxU3vUEuPe/s/apRp1sxFYuGhHAo7Y2Pz/evm/resource-limits)).

**Per-transaction**: when a transaction exceeds any of these four limits:

1. Execution halts immediately.
2. Any remaining gas is preserved and refunded to the sender.
3. The transaction is included in the block with status set to failed (status=0).
4. No state changes from the transaction are applied.

**Data Size**, **KV Updates**, and **State Growth** also have per-block limits, enforced during block building:

1. Before executing a transaction, the block builder checks whether any previous transaction has already caused the block to exceed a per-block limit. If so, the block is sealed and no more transactions are added.
2. Otherwise, the transaction is executed. If its execution causes the block to exceed a per-block limit, the transaction is still included — it is not reverted or discarded. Per-transaction limits still apply.
3. No further transactions will be added to the block after it exceeds any per-block limit.

The last transaction in a block is allowed to push the block's resource usage beyond the per-block limit.
This maximizes block utilization by avoiding the waste of a valid transaction whose resource consumption can only be known after execution.

**Compute Gas** has no separate per-block limit.
Since Compute Gas is a component of total gas, and each transaction's total gas counts towards the block gas limit, the cumulative Compute Gas in a block is implicitly bounded by the block gas limit.

## Related Pages

- [Gas Model](gas-model.md) — compute gas, storage gas, and the bucket multiplier
- [Gas Estimation](../send-tx/gas-estimation.md) — estimate gas correctly and avoid common errors
- [EVM Differences](overview.md) — full list of behavioral differences from Ethereum
- [Resource Limits (spec)](https://app.gitbook.com/o/iBzILuNyLtuxU3vUEuPe/s/apRp1sxFYuGhHAo7Y2Pz/evm/resource-limits) — formal specification of limit enforcement
- [Resource Accounting (spec)](https://app.gitbook.com/o/iBzILuNyLtuxU3vUEuPe/s/apRp1sxFYuGhHAo7Y2Pz/evm/resource-accounting) — how counters are tracked per opcode
