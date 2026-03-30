---
description: How MegaEVM differs from standard Ethereum — contract size limits, gas forwarding, SELFDESTRUCT semantics, and precompile overrides.
---

# EVM Differences

_MegaEVM_ is MegaETH's execution environment.
It is fully compatible with Ethereum smart contracts while introducing optimizations for MegaETH's unique architecture.

## Overview

MegaEVM builds on established standards.
Its latest hardfork, _Rex3_, is based on [Optimism Isthmus](https://specs.optimism.io/protocol/isthmus/overview.html), which in turn is adapted from [Ethereum Prague](https://ethereum.org/roadmap/pectra/).
This means:

- All standard Solidity contracts work on MegaETH.
- Standard development tools (Hardhat, Foundry, Remix, etc.) are compatible.
- Existing Ethereum libraries and patterns apply.

MegaEVM introduces a few changes to accommodate MegaETH's low fees and high capacity.
The most important change is the _multidimensional gas model and resource limits_.
In MegaEVM, transactions consume two types of gas: _compute gas_, which models computation at large and is identically defined as Ethereum's gas; and _storage gas_, a new concept that models the storage subsystem in particular.
Similarly, MegaEVM caps resource usage of transactions and blocks using rules that each target an individual type of resource.
Developers should consider these changes in contrast to Ethereum's EVM, where gas is the singular metric for metering and limiting resource consumption.

## Key Differences at a Glance

| Feature | Ethereum | MegaETH | Remarks |
| ------- | -------- | ------- | ------- |
| Max contract size | 24 KB | **512 KB** | |
| Max initcode size | 48 KB | **536 KB** | |
| Gas forwarding rule | 63/64 | **98/100** | As defined in [EIP-150](https://eips.ethereum.org/EIPS/eip-150). |
| `SELFDESTRUCT` | Deprecated | **EIP-6780 semantics** | Active only within the creating transaction, per [EIP-6780](https://eips.ethereum.org/EIPS/eip-6780). |
| Gas model | Unidimensional | **Multidimensional** | Compute gas and storage gas. Compute gas is identical to Ethereum's gas. |
| Resource limits | Unidimensional | **Multidimensional** | 4 limits in addition to total gas limit specified by sender. |
| Base intrinsic gas | 21,000 | **60,000** | 21,000 compute gas plus 39,000 storage gas. |

For the full gas model details, see [Gas Model](gas-model.md).

## Access to Volatile Data

Reading volatile data — `block.timestamp`, `block.number`, oracle storage, or the beneficiary account — caps the transaction's total compute gas to **20,000,000**.
This ensures transactions with external dependencies yield quickly and don't block parallel execution.

For the full list of triggers, best practices for structuring contracts around this cap, and Solidity examples, see [Volatile Data Access](volatile-data.md).
For the formal specification, see [Gas Detention](../spec/evm/gas-detention.md).

## Increased Contract Size Limit

MegaETH supports contracts up to **512 KB** in size, increased from 24 KB in Ethereum.
For the formal specification, see [Contract Limits](../spec/evm/contract-limits.md).

## `SELFDESTRUCT` with EIP-6780 Semantics

The `SELFDESTRUCT` opcode follows [EIP-6780](https://eips.ethereum.org/EIPS/eip-6780) semantics.
It only destroys a contract when called within the same transaction that created the contract.
In all other cases, `SELFDESTRUCT` behaves as a simple Ether transfer without destroying the contract or clearing its storage.
For the formal specification, see [SELFDESTRUCT](../spec/evm/selfdestruct.md).

## No Storage Gas Refund for SSTORE Resets

On Ethereum, resetting a storage slot to its original value within the same transaction refunds part of the gas.
On MegaETH, storage gas is **not refunded** when a slot is set back to its original value — the full storage gas cost is still charged.

{% hint style="success" %}
Use transient storage ([EIP-1153](https://eips.ethereum.org/EIPS/eip-1153) `TSTORE`/`TLOAD`) for scratch data that only needs to persist within a transaction.
This avoids storage gas costs entirely.
{% endhint %}

## "98/100" Rule for Gas Forwarding

MegaETH allows a caller to forward at most **98/100** of remaining gas to a callee.
The parameter is 63/64 in Ethereum.

{% hint style="danger" %}
**Migration note:** Contracts that compute gas forwarding amounts assuming the standard 63/64 rule ([EIP-150](https://eips.ethereum.org/EIPS/eip-150)) will see different behavior.
The parent call frame retains 2% instead of ~1.6%, so subcalls receive slightly less gas.
Review any patterns that rely on precise gas forwarding calculations.
{% endhint %}

For the formal specification, see [Gas Forwarding](../spec/evm/gas-forwarding.md).

## Precompile Gas Overrides

MegaETH inherits all precompiles from Optimism Isthmus, which includes Ethereum Prague precompiles, EIP-2537 BLS12-381 precompiles, and RIP-7212 P256VERIFY.
Two precompiles have adjusted gas costs:

| Precompile | Address | Cost Override |
| ---------- | ------- | ------------- |
| KZG Point Evaluation | `0x0A` | 100,000 gas (2× the standard Prague cost of 50,000) |
| ModExp | `0x05` | [EIP-7883](https://eips.ethereum.org/EIPS/eip-7883) gas schedule (raises the cost floor for large-exponent calls) |

For the formal specification, see [Precompiles](../spec/evm/precompiles.md).

## Related Pages

- [Gas Model](gas-model.md) — full dual gas model and resource limits
- [System Contracts](system-contracts.md) — native oracle interface and high-precision timestamp
- [Volatile Data Access](volatile-data.md) — compute gas cap on volatile data reads
- [EVM Specification](../spec/evm/overview.md) — formal normative specification
