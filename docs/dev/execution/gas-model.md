---
description: MegaETH dual gas model — compute gas, storage gas, bucket multiplier, resource limits, and developer tips.
---

# Gas Model

MegaETH uses a _multidimensional gas model_ that separates gas costs into two categories:

- **Compute Gas**: Standard execution costs as defined in Ethereum's EVM
- **Storage Gas**: Additional costs for operations that create persistent data

The total gas of a transaction is the sum of its compute gas and storage gas.

## How Gas Limit, Compute Gas, and Storage Gas Relate

The `gas_limit` field in a transaction works the same as on Ethereum — it sets the maximum total gas the transaction may consume.
Both compute gas and storage gas are deducted from this single budget.
In addition, MegaEVM enforces a separate compute gas ceiling of 200,000,000 that caps only the compute portion.
A transaction can be halted by either ceiling: the total `gas_limit` or the compute gas cap.

{% hint style="info" %}
**In practice:**

- **`gas_limit`:** Set this to cover your expected total gas (compute + storage). `eth_estimateGas` on a MegaETH endpoint accounts for both.
- **`gas_used` in receipts:** Reports total gas consumed (compute + storage combined).
- **Compute gas limit:** An invisible additional ceiling of 200,000,000. Most transactions stay well under it.
{% endhint %}

### Transaction Intrinsic Costs

Every transaction pays a base cost before any execution begins:

| Component | Cost |
| --------- | ---- |
| Compute gas | 21,000 |
| Storage gas | 39,000 |
| **Total** | **60,000** |

The RPC returns "intrinsic gas too low" when the transaction gas limit is below 60,000.

## Compute Gas Costs

For any operation, its compute gas cost in MegaEVM equals its gas cost in standard EVM.
For example, updating a cold storage slot from zero to nonzero costs 22,100 gas in standard EVM, so the compute gas cost of that operation in MegaEVM is also 22,100.
Every transaction incurs an intrinsic compute gas cost of 21,000, just as in Ethereum.

As a rule of thumb, the amount of compute gas a transaction burns equals the amount of gas it would burn in Ethereum's EVM.

## Storage Gas Costs

The storage gas cost of most operations is zero.
The following table lists all operations where storage gas applies.
Some storage gas calculations involve a parameter called _bucket multiplier_ (denoted as m).
The next section explains this concept.

| Operation | Storage Gas Cost | Remarks |
| --------- | ---------------- | ------- |
| Intrinsic | 39,000 | Incurred by every transaction. Combined with the intrinsic compute gas cost of 21,000, the total intrinsic gas cost of a transaction is 60,000. |
| Zero-to-nonzero `SSTORE` | 20,000 × (m−1) | Only applies to zero-to-nonzero writes. |
| Account creation | 25,000 × (m−1) | Value transfer to empty account. |
| Contract creation | 32,000 × (m−1) | `CREATE`/`CREATE2` operations. |
| Code deposit | 10,000/byte | Per byte of deployed bytecode. |
| `LOG` topic | 3,750/topic | Per topic in event. |
| `LOG` data | 80/byte | Per byte of event data. |
| Calldata (zero) | 40/byte | Per zero byte in transaction input. |
| Calldata (nonzero) | 160/byte | Per nonzero byte in transaction input. |
| EIP-7623 floor (zero) | 100/byte | [EIP-7623](https://eips.ethereum.org/EIPS/eip-7623) floor cost per zero byte in transaction input. |
| EIP-7623 floor (nonzero) | 400/byte | [EIP-7623](https://eips.ethereum.org/EIPS/eip-7623) floor cost per nonzero byte in transaction input. |

All other operations not mentioned in the table incur no storage gas cost.

**Calldata floor cost:** [EIP-7623](https://eips.ethereum.org/EIPS/eip-7623) introduced a minimum ("floor") charge for calldata.
After execution, if total gas consumed is less than the calldata floor cost, the transaction is charged the floor cost instead.
MegaETH applies the same 10× storage gas multiplier to the floor cost (hence the 100/byte and 400/byte entries in the table above).

**Revert behavior for `LOG`:** `LOG` storage gas follows standard EVM gas semantics — gas spent in a reverted call frame is consumed and not refunded.
However, the data size tracked for the `LOG` is rolled back on revert, since the log itself is discarded.

**Prefer transient storage or memory over persistent storage.**
Allocating new storage slots costs storage gas and counts towards [resource limits](resource-limits.md).
Use transient storage ([EIP-1153](https://eips.ethereum.org/EIPS/eip-1153) `TSTORE`/`TLOAD`) for data that only needs to persist within a transaction, or memory for data within a single call.

**Reuse storage slots.**
Storage gas applies when changing a slot from zero to nonzero but not when overwriting a nonzero slot.
If a slot will be freed and reallocated soon, consider keeping it nonzero to avoid the storage gas charge on the next write.

## Bucket Multiplier

Accounts and their storage slots are stored in segments of MegaETH's SALT state trie called "buckets."
Buckets grow in size and capacity as they hold more data.
The cost of writing new data to a bucket (creating new accounts or changing storage slots from zero to nonzero) varies based on its capacity, and such variation is reflected in storage gas costs in the form of the _bucket multiplier_ (denoted as m).

The bucket multiplier of a bucket is defined as the ratio of its capacity to the minimum capacity of buckets:

```
Bucket Multiplier = Bucket Capacity / MIN_BUCKET_CAP
```

SALT's design ensures that the bucket multiplier is always an integer.

A few rules of thumb for developers:

- Unless a bucket has expanded to handle heavy storage needs, the bucket multiplier is typically 1.
- When the bucket multiplier is 1, `SSTORE`, account creation, and contract creation incur zero storage gas cost.
- Buckets expand as they fill up; the multiplier increases and storage gas costs rise.
- Developers typically do not need to consider the bucket multiplier when designing contracts.

Below are examples of storage gas costs at different bucket multiplier values.

| Operation | m=1 | m=2 | m=4 |
| --------- | --- | --- | --- |
| Zero-to-nonzero `SSTORE` | 0 | 20,000 | 60,000 |
| Account creation | 0 | 25,000 | 75,000 |
| Contract creation | 0 | 32,000 | 96,000 |

{% hint style="success" %}
**Gas estimation:** Use `eth_estimateGas` on a MegaETH RPC endpoint for accurate gas estimates.
The endpoint accounts for SALT multipliers, storage gas, and all resource dimensions.
Do not attempt to compute gas costs manually — the dynamic multiplier depends on on-chain SALT bucket state.
See [Gas Estimation](../send-tx/gas-estimation.md) for code examples, toolchain configuration, and common pitfalls.
{% endhint %}

## Multidimensional Resource Limits

In addition to the gas limit, MegaEVM enforces four per-transaction and per-block resource limits: compute gas, data size, KV updates, and state growth.
A transaction that stays within its gas budget can still fail if it exceeds one of these limits.
See [Resource Limits](resource-limits.md) for the full limits table, enforcement behavior, and resource type definitions.

## Related Pages

- [Resource Limits](resource-limits.md) — per-transaction and per-block resource ceilings
- [EVM Differences](evm-differences.md) — full list of behavioral differences from Ethereum
- [Dual Gas Model (spec)](https://app.gitbook.com/o/iBzILuNyLtuxU3vUEuPe/s/apRp1sxFYuGhHAo7Y2Pz/evm/dual-gas-model) — formal specification of compute gas and storage gas
- [Resource Accounting (spec)](https://app.gitbook.com/o/iBzILuNyLtuxU3vUEuPe/s/apRp1sxFYuGhHAo7Y2Pz/evm/resource-accounting) — how counters are tracked per opcode
