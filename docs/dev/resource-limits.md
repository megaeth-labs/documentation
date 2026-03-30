---
description: MegaETH per-transaction and per-block resource limits — compute gas, data size, KV updates, and state growth ceilings.
---

# Resource Limits

In addition to the gas limit specified by the sender, MegaEVM enforces four additional resource limits on each transaction and block.
These limits cap compute gas, data size, KV updates, and state growth independently, ensuring no single transaction or block monopolizes a particular resource.

## Limits

| Resource Type | Per-Transaction Limit | Per-Block Limit |
| ------------- | --------------------- | --------------- |
| Compute Gas | 200,000,000 | N/A |
| Data Size | 12.5 MB | 12.5 MB |
| KV Updates | 500,000 | 500,000 |
| State Growth | 1,000 | 1,000 |

## Per-Transaction Limit Behavior

When a transaction hits any of the per-transaction limits, the following happens:

1. Execution halts immediately.
2. Any remaining gas is preserved and refunded to the sender.
3. The transaction is included in the block with status set to failed (status=0).
4. No state changes from the transaction are applied.

## Per-Block Limit Enforcement

The per-block limits for data size, KV updates, and state growth can only be fully evaluated after a transaction has been executed.
When building a block, these limits are enforced as follows:

1. Before executing a transaction, the block builder checks whether any previous transaction has already caused the block to exceed a per-block limit. If so, the new transaction is rejected before execution and the block is sealed.
2. Otherwise, the transaction is executed. If its execution causes the block to exceed a per-block limit, the transaction is still included — it is not reverted or discarded. Per-transaction limits still apply.
3. No further transactions will be added to the block after it exceeds any per-block limit.

In other words, the last transaction in a block is allowed to push the block's resource usage beyond the per-block limit.
This maximizes block utilization by avoiding the waste of a valid transaction whose resource consumption can only be known after execution.

## Resource Type Definitions

For all resource types, the usage incurred by a block is the sum of the usage incurred by each transaction in the block.
For example, if a block contains two transactions — one using 300 KV updates and the other using 400 KV updates — then the block uses 700 KV updates.

### Compute Gas

The compute gas cost of a transaction, as defined in the [Gas Model](gas-model.md).

### Data Size

Data size measures the amount of data that needs to be transmitted and stored for each transaction.
Both the transaction itself and its execution results are considered.
It is the total size of the following items:

- Transaction calldata
- Event logs (topics and data)
- Storage writes (40 bytes per write)
- Account updates (40 bytes each)
- Deployed contract code

### KV Updates

KV updates measure the total number of state entries (accounts and storage slots) updated by a transaction.
Each update to a storage slot or an account counts as one update towards the limit.
Repeated updates to the same storage slot or account count as only one update.

### State Growth

State growth measures the number of new state entries (accounts and storage slots) created by a transaction.
Each new storage slot (created by a zero-to-nonzero `SSTORE`), account, or contract counts as one unit towards the limit.
If a newly created storage slot or account is cleared before the transaction ends, thus occupying no storage space permanently, it does not count towards the limit.

## Related Pages

- [Gas Model](gas-model.md) — compute gas, storage gas, and the bucket multiplier
- [Gas Estimation](gas-estimation.md) — estimate gas correctly and avoid common errors
- [EVM Differences](evm-differences.md) — full list of behavioral differences from Ethereum
- [Resource Limits (spec)](../spec/evm/resource-limits.md) — formal specification of limit enforcement
- [Resource Accounting (spec)](../spec/evm/resource-accounting.md) — how counters are tracked per opcode
