---
title: MegaEVM 
rank: 5
---

_MegaEVM_ is MegaETH's execution environment. It is fully compatible with Ethereum smart contracts while introducing optimizations for the unique characteristics of MegaETH's architecture.

# Overview

MegaEVM builds on established standards. Its latest hardfork, _Rex_, is based on [Optimism Isthmus](https://specs.optimism.io/protocol/isthmus/overview.html), which in turn is adapted from [Ethereum Prague](https://ethereum.org/roadmap/pectra/). This means:

- All standard Solidity contracts work on MegaETH.
- Standard development tools (Hardhat, Foundry, Remix, etc.) are compatible.
- Existing Ethereum libraries and patterns apply.

Meanwhile, MegaEVM introduces a few changes to accommodate MegaETH's low fees
and high capacity. The most important change is the _multidimensional gas model
and resource limits_. In MegaEVM, transactions consume two types of gas:
_compute gas_, which models computation at large and is identically defined as
Ethereum's gas; and _storage gas_, a new concept that models the storage
subsystem in particular. Similarly, MegaEVM caps resource usage of transactions
using rules that each targets an individual type of resource.
Developers should consider these changes in contrast to Ethereum's EVM, where
gas is the singular metric for metering and limiting the amount of resources
consumed by transactions.

## Key Differences at a Glance

| Feature             | Ethereum     | MegaETH                          | Remarks |
| -------------- | ------------ | ------------ | -------------------- |
| Max contract size   | 24 KB        | **512 KB**                             | |
| Max initcode size   | 48 KB        | **536 KB**                             | |
| Gas forwarding rule | 63/64        | **98/100**                             | As defined in [EIP-150](https://eips.ethereum.org/EIPS/eip-150). |
| `SELFDESTRUCT`      | Deprecated      | **Disabled**                           | Deprecated in [EIP-6049](https://eips.ethereum.org/EIPS/eip-6049). |
| Gas model           | Unidimensional | **Multidimensional**           | Compute gas and storage gas. Compute gas is identical to Ethereum's gas. |
| Resource limits     | Unidimensional | **Multidimensional**                       | 4 limits in addition to total gas limit specified by sender. |
| Base intrinsic gas  | 21,000       | **60,000** | 21,000 compute gas plus 39,000 storage gas.|

#  Multidimensional Gas Model

MegaETH uses a _multidimensional gas model_ that separates gas costs into two categories:

- **Compute Gas**: Standard execution costs as defined in Ethereum's EVM
- **Storage Gas**: Additional costs for operations that create persistent data

The total gas of a transaction is the sum of its compute gas and storage gas.

## Compute Gas Costs

For any operation, its compute gas cost in MegaEVM is equal to its gas cost in
standard EVM. For example, updating a cold storage slot from zero to nonzero
costs 22,100 gas in standard EVM, so the compute gas cost of the said operation
in MegaEVM is also 22,100. As another example, every transaction incurs an
intrinsic gas cost of 21,000 in standard EVM, so every transaction also incurs
an intrinsic compute gas cost of 21,000 in MegaEVM.

As a rule of thumb, the amount of compute gas a transaction burns is equal to
the amount of gas it would burn in Ethereum's EVM.

## Storage Gas Costs

The storage gas cost of most operations is zero. The following table lists all
operations where storage gas does apply. Some storage gas calculations involve a parameter called _bucket multiplier_ (denoted as m). The next section explains this concept.

| Operation                 | Storage Gas Cost | Remarks |
| ------------------------- | ---------------- | ------------------------------------- |
| Intrinsic             | 39,000    | Incurred by every transaction. Combined with the intrinsic compute gas cost of 21,000, the total intrinsic gas cost of a transaction is 60,000.            |
| Zero-to-nonzero `SSTORE`   | 20,000 × (m-1)   | Only applies to zero-to-nonzero writes.      |
| Account creation      | 25,000 × (m-1)   | Value transfer to empty account.       |
| Contract creation     | 32,000 × (m-1)   | `CREATE`/`CREATE2` operations.             |
| Code deposit          | 10,000/byte      | Per byte of deployed bytecode.         |
| `LOG` topic             | 3,750/topic      | Per topic in event.                    |
| `LOG` data              | 80/byte          | Per byte of event data.                |
| Calldata (zero)  | 40/byte          | Per zero byte in transaction input.             |
| Calldata (nonzero)   | 160/byte         | Per nonzero byte in transaction input.         |
| EIP-7623 floor (zero)     | 100/byte         | [EIP-7623](https://eips.ethereum.org/EIPS/eip-7623) floor cost per zero byte in transaction input.     |
| EIP-7623 floor (nonzero)      | 400/byte         | [EIP-7623](https://eips.ethereum.org/EIPS/eip-7623) floor cost per nonzero byte in transaction input. |

All other operations not mentioned in the previous table incurs no storage gas
cost.

## Bucket Multiplier

Accounts and their storage slots are stored in segments of MegaETH's SALT state
trie called "buckets". Buckets grow in size and capacity as they hold more
data. The cost of writing new data to a bucket (creating new accounts or
changing storage slots from zero to nonzero) varies based on its capacity, and
such variation is reflected in storage gas costs of these operations in the
form of the _bucket multiplier_ (denoted as m).

The bucket multiplier of a bucket is simply defined as the ratio of its
capacity and the minimum capacity of buckets. The latter is a system parameter. In other words,

```
Bucket Multiplier = Bucket Capacity / MIN_BUCKET_CAP.
```

SALT's design ensures that bucket multiplier is always an integer.

Without diving into details of SALT, here are a few rules of thumb for developers.

- Unless a bucket has expanded to handle heavy storage needs, bucket multiplier is typically 1.
- When bucket multiplier is 1, `SSTORE`, account creation, and contract creation incurs zero storage gas cost.
- Bucket expand as they fill up; the multiplier increases and storage gas costs rise.
- Developers typically do not need to consider bucket multiplier when designing contracts.

Below are a few examples of storage gas costs at different bucket multiplier
values.

| Operation           | m=1 | m=2    | m=4    |
| ------------------- | ------ | ------ | ------ |
| Zero-to-nonzero `SSTORE` | 0   | 20,000 | 60,000 |
| Account creation    | 0   | 25,000 | 75,000 |
| Contract creation   | 0   | 32,000 | 96,000 |

## Tips for Developers

- **Use MegaETH's native gas estimation APIs.** Tools not explicitly modified for MegaEVM does not account for storage gas and will report overly small numbers.
    - For example, when running `forge script`, use `--skip-simulation` to avoid its built-in EVM and use `--gas-limit` to manually specify a sufficiently high gas limit.
- **Account for storage gas.** A Ether transfer costs 60,000 gas (21,000 compute gas plus 39,000 storage gas). This is the minimum gas cost (intrinsic gas) for any transaction.
    - The RPC returns "intrinsic gas too low" when transaction gas limit is smaller than 60,000.
- **Prefer transient storage or memory over persistent storage.** Allocating new storage slots costs storage gas and counts towards various resource limits (explained in the next section). Use transient storage ([EIP-1153](https://eips.ethereum.org/EIPS/eip-1153) `TSTORE`/`TLOAD`) for data that only needs to persist within a transaction, or memory for data within a single call. This avoids storage gas costs entirely and ensures calling transactions stay within resource limits.
- **Reuse storage slots.** Storage gas applies when changing a slot from zero to nonzero and does not apply when overwriting a slot that is already nonzero. When a slot can be freed (i.e., changed to zero) but is expected to be allocated again (i.e., changed to nonzero) very soon, consider keeping the slot at nonzero so that no storage gas is charged the next time it is used.
    - As a rule of thumb, avoid design patterns that allocate a lot of slots only to free them soon after.

# Multidimensional Resource Limits

In addition to the sender-specified limit on total gas, MegaEVM enforces four
additional limits on how much resources each transaction may consume. The
following table is an overview. The next few sections explain what counts
towards each type of resource and the respective limit.

| Resource Type | Per-Transaction Limit  |
| ---------------- | ------------------ |
| Total Gas | Specified by sender |
| Compute Gas  | 200,000,000 |
| Data Size    | 12.5 MB            |
| KV Updates   | 500,000            |
| State Growth | 1,000              |

When a transaction hits _any_ of the aforementioned limits, the following happens:

1. Execution halts immediately.
2. Any remaining gas is preserved and refunded to sender.
3. Transaction is included in the block with status set to failed (status=0).
4. No state changes from the transaction are applied.

## Definitions of Resource Types

### Compute Gas

Compute gas cost of a transaction as defined in previous sections.

### Data Size

Data size measures the amount of data that needs to be transmitted and stored
for each transaction. Both the transaction itself and its execution results are
considered. It is the total size of the following items:

- Transaction calldata
- Event logs (topics and data)
- Storage writes (40 bytes per write)
- Account updates (40 bytes each)
- Deployed contract code

### KV Updates

KV updates measure the total number of state entries (accounts and storage
slots) updated by a transaction. Each update to a storage slot or an account
counts as one update towards the limit. Repeated updates to the same storage
slot or account counts as only one update.

### State Growth

State growth measures the number of new state entries (accounts and storage
slots) created by a transaction. Each new storage slot (created by a
zero-to-nonzero `SSTORE`), account, or contract counts as one unit towards the
limit. If a newly created storage slot or account is cleared before the
transaction ends, thus occupying no storage space permanently, it does not
count towards the limit.

<!-- next time

# Volatile Data Access

## The Problem

MegaETH achieves high throughput through parallel transaction execution. Transactions that access frequently-changing data (like block timestamps or high-frequency updated oracles) create conflicts that limit parallelism. Such frequently-changing data is called `volatile data`.

To support efficient execution, MegaETH implements **compute gas restriction** - when you access volatile data, your remaining compute gas is capped.

## Block Environment Opcodes

Accessing these opcodes caps remaining compute gas to **20,000,000**:

| Opcode        | Description               |
| ------------- | ------------------------- |
| `NUMBER`      | Current block number      |
| `TIMESTAMP`   | Current block timestamp   |
| `COINBASE`    | Block beneficiary address |
| `DIFFICULTY`  | Block difficulty          |
| `GASLIMIT`    | Block gas limit           |
| `BASEFEE`     | Base fee per gas          |
| `PREVRANDAO`  | Previous block randomness |
| `BLOCKHASH`   | Historical block hash     |
| `BLOBBASEFEE` | Blob base fee             |
| `BLOBHASH`    | Blob hash lookup          |

## Beneficiary Account Access

Accessing the block beneficiary (coinbase) account also caps remaining compute gas to **20,000,000**:

| Trigger                                     | Description                             |
| ------------------------------------------- | --------------------------------------- |
| `BALANCE`, `SELFBALANCE`                    | Reading beneficiary's balance           |
| `EXTCODECOPY`, `EXTCODESIZE`, `EXTCODEHASH` | Accessing beneficiary's code            |
| Transaction sender is beneficiary           | When `msg.sender == block.coinbase`     |
| Transaction recipient is beneficiary        | When call target is `block.coinbase`    |
| `DELEGATECALL` to beneficiary               | Delegated context accessing beneficiary |

## Oracle Access

Accessing the oracle contract caps remaining compute gas to **1,000,000**:

- Oracle contract address: `0x6342000000000000000000000000000000000001`
- Applies to CALL, STATICCALL, DELEGATECALL, CALLCODE

## Most Restrictive Limit Applies

When multiple volatile data types are accessed in the same transaction, the **most restrictive limit applies**:

- Block env access (20M) + Oracle access (1M) = **1M cap**
- The order of access doesn't matter - the lowest cap is enforced globally

## Patterns to Avoid

```solidity
// Bad: Heavy computation after reading timestamp
function processWithTimestamp() external {
    uint256 currentTime = block.timestamp; // Triggers 20M gas cap
    // This loop might run out of gas!
    for (uint i = 0; i < 10000; i++) {
        heavyComputation(i, currentTime);
    }
}
```

# System Contracts & Oracle Service

## High-Precision Timestamp Oracle

**Address:** `0x6342000000000000000000000000000000000002`

**Interface:**

```solidity
interface HighPrecisionTimestampOracle {
    function timestamp() external view returns (uint256);
}
```

Use case: microsecond timestamp precision when `block.timestamp` isn't granular enough.

Note that the oracle data are served by the sequencer on demand, only when a transaction tries to read the oracle data, will the sequencer submits system transactions to update the oracle contract.

**Volatile Data**: The High-Precision Timestamp Oracle internally reads oracle data from the core oracle contract `0x6342000000000000000000000000000000000001`. Hence, obtaining high-precision timestamp is essentially a volatile data access and is subject to the "compute gas restriction" in Section 5.1.

**Trust Assumption**: The oracle service requires trusting the sequencer to publish accurate data. Consider this when building applications.

# Precompiles

MegaETH inherits all precompiles from Optimism Isthmus, which includes Ethereum Prague precompiles, EIP-2537 BLS12-381 precompiles, and RIP-7212 P256VERIFY.

## MegaETH-Specific Modifications

**KZG Point Evaluation (0x0A):**

- MegaETH: **100,000 gas**
- Ethereum: 50,000 gas
- Reason: 2x increase to reflect computational cost

**ModExp (0x05):**

- Uses EIP-7883 pricing
-->

# Miscellaneous

## Increased Contract Size Limit 

MegaETH supports contracts up to 512 KB in size. This is increased from 24 KB
in Ethereum. 

## `SELFDESTRUCT` is Disabled

The `SELFDESTRUCT` opcode is completely disabled and is treated as an `INVALID`
opcode. It will cause any transaction using this opcode to fail. In Ethereum,
`SELFDESTRUCT` is deprecated but still available.

## "98/100" Rule for Gas Forwarding

MegaETH allows a caller to forward at most 98/100 of remaining gas to callee.
The parameter is 63/64 in Ethereum.

