---
description: MegaETH system contracts — addresses, interfaces, preconditions, and usage examples.
---

# System Contracts

MegaETH provides system contracts that give transactions access to functionality beyond the standard EVM.

| Contract | Address | Purpose |
| -------- | ------- | ------- |
| [High-Precision Timestamp](#high-precision-timestamp) | [`0x6342000000000000000000000000000000000002`](https://megaeth.blockscout.com/address/0x6342000000000000000000000000000000000002) | Microsecond-resolution timestamps |
| [KeylessDeploy](#keyless-deployment) | [`0x6342000000000000000000000000000000000003`](https://megaeth.blockscout.com/address/0x6342000000000000000000000000000000000003) | Deterministic cross-chain deployment (Nick's Method) |

## High-Precision Timestamp

Provides timestamps at microsecond resolution.
The timestamp is the moment when the transaction _started_ execution on the sequencer.
Useful when `block.timestamp` (one-second resolution) is not granular enough.

{% hint style="info" %}
This timestamp is published by the sequencer based on its local clock.
Using it requires trusting the sequencer to provide accurate time data.
{% endhint %}

**Address:** `0x6342000000000000000000000000000000000002`

**Interface:**

```solidity
interface IHighPrecisionTimestamp {
    /// @notice Returns the current timestamp in microseconds since Unix epoch.
    /// @return Microsecond-precision timestamp, non-decreasing within a block,
    ///         capped at block.timestamp × 1,000,000.
    function timestamp() external view returns (uint256);
}

IHighPrecisionTimestamp hpt = IHighPrecisionTimestamp(
    0x6342000000000000000000000000000000000002
);
uint256 timestampUs = hpt.timestamp(); // microsecond timestamp
uint256 timestampSec = timestampUs / 1_000_000; // convert to second timestamp
```

**Outcome:**

- Returns the current timestamp in microseconds since Unix epoch.
- Reading the timestamp accesses [volatile data](volatile-data.md) and **caps the transaction's Compute Gas to 20M**.
  Avoid reading it in transactions that perform heavy computation.

**Properties:**

| Property | Value |
| -------- | ----- |
| Precision | 1 μs (1/1,000,000 second) |
| Range | `(previous_block.timestamp × 1,000,000, block.timestamp × 1,000,000]` |
| Monotonicity | Non-decreasing within a block |
| Snapshot | Stable within a single transaction — repeated reads return the same value |

**Common use cases:** HFT strategies, rate limiting, latency measurements, sub-second auctions, TWAP calculations.

## Keyless Deployment

Deploys a contract to a deterministic address using Nick's Method — a technique for deploying to the same address on every EVM chain without holding the deployer's private key.

On MegaETH, the original keyless deployment transaction would run out of gas because code deposit storage gas (10,000 gas/byte) makes deploying even a small contract far more expensive than on Ethereum.
This system contract re-executes the original transaction with a caller-supplied gas limit override.

**Address:** `0x6342000000000000000000000000000000000003`

**Interface:**

```solidity
interface IKeylessDeploy {
    /// @notice Re-executes a pre-signed keyless deployment transaction with a custom gas limit,
    ///         deploying the contract to the same deterministic address as on any other EVM chain.
    /// @param keylessDeploymentTransaction RLP-encoded signed deployment transaction by Nick's Method.
    /// @param gasLimitOverride Gas limit to use instead of the original transaction's gas limit.
    /// @return gasUsed Actual gas consumed by the deployment.
    /// @return deployedAddress Address where the contract was deployed.
    /// @return errorData Empty on success; revert data on failure.
    function keylessDeploy(
        bytes calldata keylessDeploymentTransaction,
        uint256 gasLimitOverride
    ) external returns (uint64 gasUsed, address deployedAddress, bytes memory errorData);
}

IKeylessDeploy deployer = IKeylessDeploy(0x6342000000000000000000000000000000000003);
bytes memory originalTx = hex"f8a58085174876e800830186a08080b853604580600e...";
(uint64 gasUsed, address deployed,) = deployer.keylessDeploy(originalTx, 500_000);
```

**Preconditions:**

- `keylessDeploymentTransaction` must be a valid RLP-encoded Nick's Method deployment transaction: pre-EIP-155, contract creation (`to` = null), nonce = 0.
- `gasLimitOverride` must be ≥ the original transaction's gas limit.
- The deployment address must not already contain code.
- The call must carry zero ETH value.

**Outcome:**

- On success: returns `gasUsed`, `deployedAddress` (the deterministic address), and empty `errorData`.
- On deployment failure (e.g., out of gas): the call **does not revert**. It returns `gasUsed`, `deployedAddress = 0x0`, and `errorData` describing the failure. State changes from the attempted deployment (including gas charges) are still applied.

{% hint style="warning" %}
Code deposit costs 10,000 storage gas per byte on MegaETH.
A 24 KB contract costs roughly 240M storage gas.
If `gasLimitOverride` is too low for this cost, the inner deployment will fail (out of gas) but the outer call still succeeds — check `errorData` and `deployedAddress`.
Simulate the transaction with [`mega-evme`](debugging.md#simulating-a-new-transaction) to find the required gas — it has no gas cap and fully implements MegaETH's gas model.
Alternatively, use `eth_estimateGas` on a MegaETH endpoint (subject to the [10M RPC gas cap](gas-estimation.md#the-10m-rpc-gas-cap)).
{% endhint %}

{% hint style="info" %}
Deploying common keyless contracts (e.g., CREATE2 Factory, EIP-1820 Registry) can be expensive due to storage gas.
If you need a widely-used contract deployed, reach out to the MegaETH team — it may already be deployed or the team can assist.
{% endhint %}

**Already-deployed contracts** (available on MegaETH via KeylessDeploy):

| Contract | Deployed Address |
| -------- | ---------------- |
| [CREATE2 Factory](https://github.com/Arachnid/deterministic-deployment-proxy) | [`0x4e59b44847b379578588920ca78fbf26c0b4956c`](https://megaeth.blockscout.com/address/0x4e59b44847b379578588920ca78fbf26c0b4956c) |
| [EIP-1820 Registry](https://eips.ethereum.org/EIPS/eip-1820) | [`0x1820a4B7618BdE71Dce8cdc73aAB6C95905faD24`](https://megaeth.blockscout.com/address/0x1820a4B7618BdE71Dce8cdc73aAB6C95905faD24) |

<details>
<summary>Rex4 preview — upcoming system contracts</summary>

The following system contracts are planned for the Rex4 hardfork.
Addresses and interfaces are subject to change before release.

| Contract | Address | Purpose |
| -------- | ------- | ------- |
| MegaAccessControl | `0x6342000000000000000000000000000000000004` | Opt out of volatile data access detection via `disableVolatileDataAccess()` |
| MegaLimitControl | `0x6342000000000000000000000000000000000005` | Query remaining compute gas budget via `remainingComputeGas()` |

</details>

## Related Pages

- [Volatile Data Access](volatile-data.md) — compute gas cap, best practices for reading volatile data
- [System Contracts (spec)](../spec/system-contracts/overview.md) — formal specification of the system contract registry
- [Oracle (spec)](../spec/system-contracts/oracle.md) — underlying oracle contract that powers the High-Precision Timestamp and other services
- [KeylessDeploy (spec)](../spec/system-contracts/keyless-deploy.md) — keyless deployment sandbox and validation rules
