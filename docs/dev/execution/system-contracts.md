---
description: MegaETH system contracts — addresses, interfaces, preconditions, and usage examples.
---

# System Contracts

MegaETH provides system contracts that give transactions access to functionality beyond the standard EVM.

| Contract                                              | Address                                                                                                                           | Purpose                                              |
| ----------------------------------------------------- | --------------------------------------------------------------------------------------------------------------------------------- | ---------------------------------------------------- |
| [High-Precision Timestamp](#high-precision-timestamp) | [`0x6342000000000000000000000000000000000002`](https://megaeth.blockscout.com/address/0x6342000000000000000000000000000000000002) | Microsecond-resolution timestamps                    |
| [KeylessDeploy](#keyless-deployment)                  | [`0x6342000000000000000000000000000000000003`](https://megaeth.blockscout.com/address/0x6342000000000000000000000000000000000003) | Deterministic cross-chain deployment (Nick's Method) |
| [MegaAccessControl](#mega-access-control)             | [`0x6342000000000000000000000000000000000004`](https://megaeth.blockscout.com/address/0x6342000000000000000000000000000000000004) | Opt out of volatile data access detection            |
| [MegaLimitControl](#mega-limit-control)               | [`0x6342000000000000000000000000000000000005`](https://megaeth.blockscout.com/address/0x6342000000000000000000000000000000000005) | Query remaining compute gas budget                   |
| [SequencerRegistry](#sequencer-registry)              | [`0x6342000000000000000000000000000000000006`](https://megaeth.blockscout.com/address/0x6342000000000000000000000000000000000006) | System address and sequencer role registry           |

## Sequencer Registry

Tracks the current system address (Oracle and system-transaction authority) and the current sequencer (mini-block signing key).
Rex5 introduces this contract.
Most dapp code does not call it directly, but contracts and tools can read it when they need the canonical onchain source for either role.

**Address:** `0x6342000000000000000000000000000000000006`

For the formal specification, see [SequencerRegistry (spec)](https://docs.megaeth.com/spec/system-contracts/sequencer-registry).

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
- Reading the timestamp accesses [volatile data](volatile-data.md) and **triggers the 20M compute gas detention cap**.
  Avoid reading it in transactions that perform heavy computation.

**Properties:**

| Property     | Value                                                                     |
| ------------ | ------------------------------------------------------------------------- |
| Precision    | 1 μs (1/1,000,000 second)                                                 |
| Range        | `(previous_block.timestamp × 1,000,000, block.timestamp × 1,000,000]`     |
| Monotonicity | Non-decreasing within a block                                             |
| Snapshot     | Stable within a single transaction — repeated reads return the same value |

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

- `keylessDeploymentTransaction` must be a valid RLP-encoded Nick's Method deployment transaction: pre-EIP-155, contract creation (`to` = null), nonce = 0, with no trailing bytes after the signed payload.
- `gasLimitOverride` must be ≥ the original transaction's gas limit.
- The deployment address must not already contain code.
- The call must carry zero ETH value.
- The signer's balance must cover the inner transaction's `value` (zero for typical deployments) — the sandbox runs fee-free, so the signer needs no balance for gas.

**Outcome:**

- On success: returns `gasUsed`, `deployedAddress` (the deterministic address), and empty `errorData`.
- On deployment failure (e.g., out of gas): the call **does not revert**. It returns `gasUsed`, `deployedAddress = 0x0`, and `errorData` describing the failure. State changes from the attempted deployment are still applied, and the gas it consumed is charged to the outer call.

### Gas billing

The outer transaction pays for everything the sandboxed deployment does:

| Charge                 | Amount                                       | When                                                                        |
| ---------------------- | -------------------------------------------- | --------------------------------------------------------------------------- |
| Dispatch overhead      | 100,000 compute gas                          | Always — retained even if the deployment is rejected                        |
| Sandbox gas            | Exact gas used by the re-executed deployment | On every completed deployment attempt, success or failure                   |
| Signer materialization | New-account storage gas for the inner signer | Only if the signer account does not exist yet (one-time per signer address) |

Size the outer transaction's gas limit for `100,000 + sandbox gas used + signer materialization`, not just the inner deployment's own cost.
`gasLimitOverride` is capped to the outer call's remaining gas, so the sandbox can never spend more than the outer transaction provides.
The sandbox's resource usage (compute gas, data size, KV updates, and state growth) also counts toward the outer transaction's [resource limits](resource-limits.md).

The inner signer pays no gas: the sandbox runs fee-free, so the signer address needs no ETH beyond the inner transaction's `value` (zero for typical Nick's Method deployments).
A consequence is that the `GASPRICE` opcode reads `0` inside the deployed contract's constructor.

{% hint style="danger" %}
**Migration note (Rex5):** before Rex5, the outer call was charged only the 100,000 gas dispatch overhead.
Rex5 charges the full sandbox gas to the outer transaction — for storage-heavy deployments this raises the relayer-side gas budget by 10–100×.
{% endhint %}

{% hint style="warning" %}
Code deposit costs 10,000 storage gas per byte on MegaETH.
A 24 KB contract costs roughly 240M storage gas.
If `gasLimitOverride` is too low for this cost, the inner deployment will fail (out of gas) but the outer call still succeeds — check `errorData` and `deployedAddress`, and note the outer call is still charged the gas the failed attempt consumed.
Simulate the transaction with [`mega-evme`](../send-tx/debugging.md#simulating-a-new-transaction) to find the required gas — it has no gas cap and fully implements MegaETH's gas model.
Alternatively, use `eth_estimateGas` on a MegaETH endpoint (subject to the [RPC compute gas cap](../send-tx/gas-estimation.md#the-rpc-compute-gas-cap)).
{% endhint %}

{% hint style="info" %}
Deploying common keyless contracts (e.g., CREATE2 Factory, EIP-1820 Registry) can be expensive due to storage gas.
If you need a widely-used contract deployed, reach out to the MegaETH team — it may already be deployed or the team can assist.
{% endhint %}

**Already-deployed contracts** (available on MegaETH via KeylessDeploy):

| Contract                                                                      | Deployed Address                                                                                                                  |
| ----------------------------------------------------------------------------- | --------------------------------------------------------------------------------------------------------------------------------- |
| [CREATE2 Factory](https://github.com/Arachnid/deterministic-deployment-proxy) | [`0x4e59b44847b379578588920ca78fbf26c0b4956c`](https://megaeth.blockscout.com/address/0x4e59b44847b379578588920ca78fbf26c0b4956c) |
| [EIP-1820 Registry](https://eips.ethereum.org/EIPS/eip-1820)                  | [`0x1820a4B7618BdE71Dce8cdc73aAB6C95905faD24`](https://megaeth.blockscout.com/address/0x1820a4B7618BdE71Dce8cdc73aAB6C95905faD24) |

## Mega Access Control

Provides a proactive mechanism to prevent untrusted subcalls from accessing [volatile data](volatile-data.md).
A contract can disable volatile data access for its entire call subtree before any untrusted code runs.
Attempts to access volatile data while disabled revert immediately, preventing both the access and the [detention](volatile-data.md) side effect.

**Address:** `0x6342000000000000000000000000000000000004`

**Interface:**

Functions are declared `view` so they can be called from `view` contexts.
The node intercepts these calls and tracks the restriction outside EVM storage, so no state modification occurs.

```solidity
interface IMegaAccessControl {
    function disableVolatileDataAccess() external view;
    function enableVolatileDataAccess() external view;
    function isVolatileDataAccessDisabled() external view returns (bool disabled);
}

IMegaAccessControl accessControl = IMegaAccessControl(
    0x6342000000000000000000000000000000000004
);
accessControl.disableVolatileDataAccess();
// All subcalls from this point cannot access volatile data.
// Attempts to read block.timestamp, oracle storage, etc. revert immediately.
```

**Outcome:**

- `disableVolatileDataAccess()` — disables volatile data access for the caller's call frame and all descendant call frames.
- `enableVolatileDataAccess()` — re-enables access, but only if the restriction was set at the caller's own depth. If a parent frame disabled access, the call reverts with `DisabledByParent()`.
- `isVolatileDataAccessDisabled()` — returns `true` if volatile data access is currently disabled.

The restriction automatically ends when the call frame that called `disableVolatileDataAccess` returns.
No explicit cleanup is needed.

{% hint style="success" %}
Use MegaAccessControl when calling untrusted contracts to prevent them from silently triggering gas detention and tightening your gas budget.
{% endhint %}

**Common use cases:** DeFi protocols calling untrusted hooks, proxy contracts with user-supplied logic, batch execution of arbitrary calls.

## Mega Limit Control

Provides a runtime query for the effective remaining compute gas, accounting for both [gas detention](volatile-data.md) and per-call-frame resource budgets.
The standard `GAS` opcode does not reflect these MegaETH-specific constraints.

**Address:** `0x6342000000000000000000000000000000000005`

**Interface:**

```solidity
interface IMegaLimitControl {
    function remainingComputeGas() external view returns (uint64 remaining);
}

IMegaLimitControl limitControl = IMegaLimitControl(
    0x6342000000000000000000000000000000000005
);
uint64 remaining = limitControl.remainingComputeGas();
// Use 'remaining' to decide whether to attempt a costly sub-call
```

**Outcome:**

- Returns the effective remaining compute gas for the caller's call frame at the time of the call.
- The returned value accounts for both the detention cap (if triggered) and the per-call-frame compute gas budget — it is the minimum of the two.
- The value is a point-in-time snapshot that decreases as execution proceeds.

**Common use cases:** Gas-aware batching (loop until budget exhausted), deciding whether to attempt expensive sub-calls, on-chain gas budgeting.

## Related Pages

- [Volatile Data Access](volatile-data.md) — compute gas cap, best practices for reading volatile data
- [System Contracts (spec)](https://docs.megaeth.com/spec/system-contracts/overview) — formal specification of the system contract registry
- [Oracle (spec)](https://docs.megaeth.com/spec/system-contracts/oracle) — underlying oracle contract that powers the High-Precision Timestamp and other services
- [KeylessDeploy (spec)](https://docs.megaeth.com/spec/system-contracts/keyless-deploy) — keyless deployment sandbox and validation rules
- [MegaAccessControl (spec)](https://docs.megaeth.com/spec/system-contracts/mega-access-control) — volatile data access restriction mechanism
- [MegaLimitControl (spec)](https://docs.megaeth.com/spec/system-contracts/mega-limit-control) — remaining compute gas query
- [SequencerRegistry (spec)](https://docs.megaeth.com/spec/system-contracts/sequencer-registry) — system address and sequencer role registry
- [Rex5 Upgrade (spec)](https://docs.megaeth.com/spec/upgrades/rex5) — full list of Rex5 behavior changes
