---
description: MegaETH system contract addresses, native oracle interface, and Solidity usage examples.
---

# System Contracts

MegaEVM provides a native oracle interface that gives transactions realtime access to data from off-chain sources.

## System Contract Addresses

| Contract | Address | Description |
| -------- | ------- | ----------- |
| Core Oracle | `0x6342000000000000000000000000000000000001` | Internal oracle contract. Reading from this contract's storage via `SLOAD` triggers the volatile data compute gas limit. |
| High-Precision Timestamp Oracle | `0x6342000000000000000000000000000000000002` | Returns the current timestamp at microsecond resolution. |

## High-Precision Timestamp Oracle

This oracle provides timestamps at microsecond resolution.
It is useful when `block.timestamp` (which has one-second resolution) is not granular enough for your use case.

**Address:** `0x6342000000000000000000000000000000000002`

**Interface:**

```solidity
interface HighPrecisionTimestampOracle {
    function timestamp() external view returns (uint256);
}
```

### Trust Assumption

Data for this oracle is supplied solely by the sequencer based on its local clock.
This implies that the sequencer must be trusted to publish accurate data.
Avoid using this oracle if such a trust assumption is too strong for your use case.

### Volatile Data and Compute Gas Limit

This oracle internally reads the core oracle contract at `0x6342000000000000000000000000000000000001`.
Therefore, obtaining high-precision timestamps accesses volatile data and is subject to the compute gas limits detailed in [EVM Differences](evm-differences.md#accessing-the-native-oracle-interface).

Specifically, calling this oracle caps the transaction's global compute gas to **20,000,000**.
Avoid calling this oracle in transactions that perform heavy computation.

{% hint style="warning" %}
`DELEGATECALL` to the oracle contract does **not** trigger the volatile data compute gas limit.
Only direct `SLOAD` from the oracle contract storage triggers the limit.
{% endhint %}

{% hint style="info" %}
For the formal specification of system contracts, see the [EVM Specification](https://docs.megaeth.com/evm-spec/system-contracts/overview).
{% endhint %}
