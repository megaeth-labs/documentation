---
description: MegaETH system contract addresses, native oracle interface, and Solidity usage examples.
---

# System Contracts

MegaEVM provides a native oracle interface that gives transactions realtime access to data from off-chain sources.

## System Contract Addresses

| Contract | Address | Since | Purpose |
| -------- | ------- | ----- | ------- |
| Oracle | `0x6342000000000000000000000000000000000001` | MiniRex | Off-chain data key-value storage. Reading via `SLOAD` triggers the volatile data compute gas limit. |
| High-Precision Timestamp | `0x6342000000000000000000000000000000000002` | MiniRex | Sub-second timestamps (oracle service). |
| KeylessDeploy | `0x6342000000000000000000000000000000000003` | Rex2 | Deterministic cross-chain deployment (Nick's Method). |

## Reading Oracle Data

The core oracle contract at `0x6342000000000000000000000000000000000001` stores off-chain data as a key-value map of `uint256` slots to `bytes32` values.
Read it directly using the `IOracle` interface:

```solidity
interface IOracle {
    function getSlot(uint256 slot) external view returns (bytes32 value);
    function getSlots(uint256[] calldata slots) external view returns (bytes32[] memory values);
}

IOracle oracle = IOracle(0x6342000000000000000000000000000000000001);
bytes32 value = oracle.getSlot(slot);
```

Some oracle services also provide a dedicated wrapper contract with a typed interface (such as the High-Precision Timestamp below).
Check the service's documentation for the wrapper address and ABI.

### How Oracle-Backed Services Work

Oracle-backed services are not separate storage systems.
They are sequencer-operated data feeds built on top of the Oracle contract.
Each service is allocated a range of Oracle storage slots.

For each user transaction, the sequencer opens an oracle window and takes a snapshot of the current service data.
If the transaction reads one of those slots, the sequencer records the accessed slots and generates a system transaction that writes the snapshot values into the Oracle contract before the user transaction in the final block order.

This means:

- each transaction sees a stable snapshot,
- successive transactions can observe updated values,
- and no on-chain Oracle write is required when a transaction does not access Oracle-backed data.

{% hint style="info" %}
Oracle-backed values are published by the sequencer.
Using them requires trusting the sequencer to provide accurate off-chain data.
{% endhint %}

## High-Precision Timestamp Oracle

This oracle provides timestamps at microsecond resolution.
It is useful when `block.timestamp` (which has one-second resolution) is not granular enough for your use case.

**Address:** `0x6342000000000000000000000000000000000002`

**Interface:**

```solidity
interface IHighPrecisionTimestamp {
    function timestamp() external view returns (uint256);
    function update(uint256 index) external;
    function oracle() external view returns (address);
    function baseSlot() external view returns (uint256);
    function maxSlots() external view returns (uint32);
}
```

**Usage example:**

```solidity
IHighPrecisionTimestamp hpt = IHighPrecisionTimestamp(
    0x6342000000000000000000000000000000000002
);
uint256 timestampUs = hpt.timestamp();
uint256 timestampSec = timestampUs / 1_000_000;
```

**Via direct oracle storage** (equivalent, lower-level):

```solidity
IOracle oracle = IOracle(0x6342000000000000000000000000000000000001);
uint256 timestampUs = uint256(oracle.getSlot(0));
```

**Storage layout:**

| Slot | Contents | Format |
| ---- | -------- | ------ |
| 0 | Timestamp | `uint256`, microseconds since Unix epoch |
| 1–7 | Reserved | Reserved for future use |

**Timestamp guarantees:**

- **Precision:** Microsecond (1/1,000,000 second)
- **Freshness:** Updated per transaction
- **Upper bound:** Capped at `block.timestamp × 1,000,000`
- **Monotonicity:** Non-decreasing within a block

**Common use cases:** HFT strategies, rate limiting, latency measurements, sub-second auctions, TWAP calculations.

### Timestamp Snapshot Semantics

The timestamp value is captured per transaction.
Within a single transaction, repeated reads observe the same snapshot value.
Across transactions in the same block, the value is non-decreasing and may increase.

The timestamp is capped above by `block.timestamp × 1_000_000`, so it never exceeds the block timestamp converted to microseconds.

{% hint style="warning" %}
Reading the high-precision timestamp accesses volatile data and caps the transaction's compute gas to 20M.
Avoid reading it in transactions that perform heavy computation.
See [Volatile Data Access](volatile-data.md) for details and best practices.
{% endhint %}

### Trust Assumption

Data for this oracle is supplied solely by the sequencer based on its local clock.
This implies that the sequencer must be trusted to publish accurate data.
Avoid using this oracle if such a trust assumption is too strong for your use case.

### Volatile Data and Compute Gas Limit

This oracle internally reads the core oracle contract at `0x6342000000000000000000000000000000000001`.
Therefore, obtaining high-precision timestamps accesses volatile data and is subject to the compute gas limits detailed in [EVM Differences](evm-differences.md#accessing-the-native-oracle-interface).

Specifically, calling this oracle caps the transaction's global compute gas to **20,000,000**.
Avoid calling this oracle in transactions that perform heavy computation.

{% hint style="info" %}
`DELEGATECALL` to the oracle contract does **not** trigger the volatile data compute gas limit.
Only direct `SLOAD` from the oracle contract storage triggers the limit.
{% endhint %}

## Keyless Deployment (Nick's Method)

**Address:** `0x6342000000000000000000000000000000000003`

Nick's Method is a technique for deploying a contract to the same address on every EVM chain without holding the deployer's private key.
The original approach broadcasts a pre-signed transaction from a one-time key.
On MegaETH, that original transaction runs out of gas because code deposit storage gas (10,000 gas/byte) makes deploying even a small contract far more expensive than on Ethereum.

The `KeylessDeploy` system contract solves this.
It re-executes the original keyless deployment transaction with a caller-supplied gas limit override, so the deployment succeeds and lands at the same deterministic address.

**Interface:**

```solidity
interface IKeylessDeploy {
    function keylessDeploy(
        bytes calldata keylessDeploymentTransaction,
        uint256 gasLimitOverride
    ) external returns (uint64 gasUsed, address deployedAddress, bytes memory errorData);
}
```

**Example (Foundry):**

```solidity
IKeylessDeploy deployer = IKeylessDeploy(0x6342000000000000000000000000000000000003);
bytes memory originalTx = hex"f8a58085174876e800830186a08080b853604580600e...";
(uint64 gasUsed, address deployed,) = deployer.keylessDeploy(originalTx, 500_000);
```

**Already-deployed contracts** (available on MegaETH via `KeylessDeploy`):

| Contract | Deployed Address |
| -------- | ---------------- |
| CREATE2 Factory | `0x4e59b44847b379578588920ca78fbf26c0b4956c` |
| EIP-1820 Registry | `0x1820a4B7618BdE71Dce8cdc73aAB6C95905faD24` |

{% hint style="warning" %}
**Code deposit storage gas is significant.**
Deploying bytecode costs 10,000 storage gas per byte.
A 24 KB contract costs roughly 240,000,000 storage gas.
Set `gasLimitOverride` accordingly and verify with `eth_estimateGas` before calling.
{% endhint %}

<details>
<summary>Rex4 preview — upcoming system contracts</summary>

The following system contracts are planned for the Rex4 hardfork.
Addresses and interfaces are subject to change before release.

| Contract | Address | Purpose |
| -------- | ------- | ------- |
| MegaAccessControl | `0x6342000000000000000000000000000000000004` | Opt out of volatile data access detection via `disableVolatileDataAccess()` |
| MegaLimitControl | `0x6342000000000000000000000000000000000005` | Query remaining compute gas budget via `remainingComputeGas()` |

</details>

{% hint style="info" %}
For the formal specification of system contracts, see the [EVM Specification](https://docs.megaeth.com/evm-spec/system-contracts/overview).
{% endhint %}
