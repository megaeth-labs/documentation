---
description: Oracle system contract semantics, interface, write restrictions, and interception behavior.
spec: Rex3
---

# Oracle

This page specifies the Oracle system contract and the stable high-precision timestamp wrapper contract.
It defines the addresses, interfaces, restricted write behavior, and EVM-level interception semantics.

## Motivation

MegaETH needs a canonical protocol-level storage backend for externally sourced data such as timestamps and other oracle-fed values.
That storage must be readable by contracts, writable by protocol-controlled maintenance transactions, and stable across specs.

MegaETH also needs a stable wrapper contract for the protocol-defined timestamp service so that its address, interface, and storage mapping are part of the specification.

## Specification

### Address

The Oracle system contract MUST exist at `ORACLE_CONTRACT_ADDRESS`.
The high-precision timestamp wrapper contract MUST exist at `HIGH_PRECISION_TIMESTAMP_ADDRESS`.

### Public Read Interface

The Oracle contract MUST expose the following externally callable read methods:

```solidity
interface IOracle {
    function getSlot(uint256 slot) external view returns (bytes32 value);
    function getSlots(uint256[] calldata slots) external view returns (bytes32[] memory values);
}
```

`getSlot` MUST return the storage value at the specified slot.
`getSlots` MUST return the storage values at the specified slots in the same order as the input array.

### Restricted Write Interface

The Oracle contract MUST expose the following write and log-emission methods:

```solidity
interface IOracle {
    function setSlot(uint256 slot, bytes32 value) external;
    function setSlots(uint256[] calldata slots, bytes32[] calldata values) external;
    function emitLog(bytes32 topic, bytes calldata data) external;
    function emitLogs(bytes32 topic, bytes[] calldata dataVector) external;
}
```

The methods above MUST be callable only by `MEGA_SYSTEM_ADDRESS`.
Calls from any other sender MUST revert with `NotSystemAddress()`.

For `setSlots`, if the `slots` and `values` array lengths differ, the call MUST revert with `InvalidLength(uint256 slotsLength, uint256 valuesLength)`.

### Auxiliary Interface

The Oracle contract MUST expose the following auxiliary methods:

```solidity
interface IOracle {
    function multiCall(bytes[] calldata data) external returns (bytes[] memory results);
    function sendHint(bytes32 topic, bytes calldata data) external view;
}
```

`multiCall` MUST execute each payload by `DELEGATECALL` into the Oracle contract and MUST return the results in order.
If any delegated call fails, `multiCall` MUST revert and MUST bubble up the revert data if present.

`sendHint` MUST be externally callable and MUST be a no-op at the Solidity bytecode level.

### Storage Access Semantics

`getSlot` and `getSlots` MUST read Oracle storage directly via `SLOAD`.
`setSlot` and `setSlots` MUST write Oracle storage directly via `SSTORE`.

### EVM-Level Interception

A call to `sendHint(bytes32,bytes)` targeting `ORACLE_CONTRACT_ADDRESS` MUST be intercepted by the EVM and forwarded to the external oracle backend before ordinary contract execution proceeds.

The Oracle contract's `sendHint` Solidity function body MUST remain a no-op.
The observable protocol behavior is the combination of:

- EVM-level hint forwarding, and
- normal contract execution of the no-op function body.

### Gas and Detention Semantics

The following gas and detention rules MUST apply:

- `SLOAD` against Oracle storage MUST use the cold access gas cost.
- Oracle storage reads MUST participate in [gas detention](../evm/gas-detention.md).
- `CALL` or `STATICCALL` to the Oracle contract address alone MUST NOT trigger oracle detention unless Oracle storage is actually read.
- `DELEGATECALL` to the Oracle contract MUST NOT trigger oracle detention solely by targeting the Oracle address.

### Versioning

Pre-[Rex2](../upgrades/rex2.md), the deployed Oracle bytecode does not include `sendHint`.
From [Rex2](../upgrades/rex2.md) onward, the stable Oracle bytecode includes `sendHint`.

### High-Precision Timestamp Wrapper

The high-precision timestamp wrapper contract at `HIGH_PRECISION_TIMESTAMP_ADDRESS` MUST expose the following interface:

```solidity
interface IHighPrecisionTimestamp {
    function timestamp() external view returns (uint256);
    function update(uint256 index) external;
    function oracle() external view returns (address);
    function baseSlot() external view returns (uint256);
    function maxSlots() external view returns (uint32);
}
```

`oracle()` MUST return `ORACLE_CONTRACT_ADDRESS`.
`baseSlot()` MUST return `TIMESTAMP_BASE_SLOT`.
`maxSlots()` MUST return `TIMESTAMP_MAX_SLOTS`.

The `timestamp()` method MUST return the value stored at Oracle slot `TIMESTAMP_BASE_SLOT`, interpreted as a `uint256` number of microseconds since Unix epoch.

### Timestamp Storage Layout

The timestamp service allocation within Oracle storage MUST be:

| Slot Range | Meaning |
| ---------- | ------- |
| `0` | Current high-precision timestamp in microseconds |
| `1`–`7` | Reserved for future use |

### Timestamp Service Semantics

For each user transaction that accesses timestamp-backed Oracle data, the sequencer MUST provide a per-transaction snapshot of the timestamp service.
That snapshot value MUST be written to Oracle storage via a [Mega System Transaction](system-tx.md) before the corresponding user transaction in the final block ordering.

If a transaction does not access timestamp-backed Oracle data, the protocol MUST NOT require a timestamp-service write for that transaction.

The timestamp service MUST satisfy the following guarantees:

- the value is expressed in microseconds,
- the value is capped above by `block.timestamp × 1,000,000`,
- successive transactions within a block observe non-decreasing timestamp values,
- and each transaction observes a stable per-transaction snapshot.

## Constants

| Constant | Value | Description |
| -------- | ----- | ----------- |
| `ORACLE_CONTRACT_ADDRESS` | `0x6342000000000000000000000000000000000001` | Stable Oracle system-contract address |
| `HIGH_PRECISION_TIMESTAMP_ADDRESS` | `0x6342000000000000000000000000000000000002` | Stable high-precision timestamp wrapper address |
| `TIMESTAMP_BASE_SLOT` | `0` | Oracle storage base slot for the timestamp service |
| `TIMESTAMP_MAX_SLOTS` | `8` | Number of Oracle slots reserved for the timestamp service |

## Rationale

**Why centralize oracle-backed data in one contract?**
Oracle-backed protocol data needs a single canonical storage location so all contracts and all nodes observe the same values under the same addressing scheme.

**Why make the timestamp wrapper part of the system-contract spec?**
The wrapper's address, interface, and storage mapping are part of MegaETH's verifiable behavior.
Nodes and contracts must agree on how the timestamp service is exposed, not only on the existence of underlying Oracle storage.

**Why restrict writes to `MEGA_SYSTEM_ADDRESS`?**
Externally sourced oracle values are part of protocol-maintained state.
Allowing arbitrary writes would destroy the meaning of oracle-backed data and make the values untrustworthy as protocol inputs.

**Why intercept `sendHint` at the EVM level?**
Hint forwarding depends on external backend behavior that cannot be represented by ordinary bytecode alone.
The no-op Solidity body provides a stable interface, while interception supplies the protocol-level side effect.

## Spec History

- [MiniRex](../upgrades/minirex.md) introduced the Oracle contract and the high-precision timestamp wrapper.
- [Rex2](../upgrades/rex2.md) added the `sendHint` entry point to the deployed Oracle bytecode.
- [Rex3](../upgrades/rex3.md) changed oracle detention to SLOAD-based triggering and raised the oracle detention cap to 20M.
