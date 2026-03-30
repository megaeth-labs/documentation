---
description: MegaETH system contract registry — addresses, whitelisting rules, and protocol-level execution constraints.
spec: Rex3
---

# System Contracts

This page specifies the system-contract registry and the protocol-level rules that apply to system contracts in MegaETH.
It defines the system-contract set.

## Specifications

### Stable Registry

A node MUST recognize the following contracts as system contracts:

| Contract | Address | Since | Purpose |
| -------- | ------- | ----- | ------- |
| [Oracle](oracle.md) | `ORACLE_CONTRACT_ADDRESS` | [MiniRex](../upgrades/minirex.md) | Off-chain data key-value storage |
| [High-Precision Timestamp](../oracle-services/timestamp.md) | `HIGH_PRECISION_TIMESTAMP_ADDRESS` | [MiniRex](../upgrades/minirex.md) | Sub-second timestamp oracle service |
| [KeylessDeploy](keyless-deploy.md) | `KEYLESS_DEPLOY_ADDRESS` | [Rex2](../upgrades/rex2.md) | Deterministic cross-chain deployment |

### Deployment Semantics

System contracts MUST be available at their specified addresses when the corresponding spec is active.
Their availability is gated by [spec](../hardfork-spec.md) activation.

### Intercepted Methods

Some system-contract methods are handled at the EVM level rather than exclusively by contract bytecode.
The following interception rules apply:

- [`KeylessDeploy.keylessDeploy`](keyless-deploy.md) MUST be intercepted at transaction depth 0 only.
- Unknown selectors sent to `KeylessDeploy`, or calls that are not intercepted, MUST fall through to contract bytecode and revert with `NotIntercepted()`.
- [`Oracle.sendHint`](oracle.md) MUST be intercepted to forward hint data to the external oracle backend.
- Other Oracle methods MUST execute via ordinary contract bytecode unless explicitly specified otherwise.

`DELEGATECALL` and `CALLCODE` to system-contract addresses MUST NOT receive special interception semantics unless explicitly specified on the corresponding concept page.

### Backward Compatibility Rule

Any change to system-contract semantics, bytecode-visible interface behavior, or interception rules MUST be introduced by a new spec.
Stable behavior for an already-activated spec MUST remain unchanged.

<details>
<summary>Rex4 (unstable): Additional system contracts</summary>

For Rex4, a node MUST additionally recognize:

| Contract | Address | Purpose |
| -------- | ------- | ------- |
| MegaAccessControl | `MEGA_ACCESS_CONTROL_ADDRESS` | Volatile-data access control |
| MegaLimitControl | `MEGA_LIMIT_CONTROL_ADDRESS` | Query remaining compute-gas budget |

</details>

## Constants

| Constant | Value | Description |
| -------- | ----- | ----------- |
| `ORACLE_CONTRACT_ADDRESS` | `0x6342000000000000000000000000000000000001` | Stable Oracle system-contract address |
| `HIGH_PRECISION_TIMESTAMP_ADDRESS` | `0x6342000000000000000000000000000000000002` | Stable high-precision timestamp wrapper address |
| `KEYLESS_DEPLOY_ADDRESS` | `0x6342000000000000000000000000000000000003` | Stable KeylessDeploy system-contract address |
| `MEGA_ACCESS_CONTROL_ADDRESS` | `0x6342000000000000000000000000000000000004` | Unstable Rex4 MegaAccessControl address |
| `MEGA_LIMIT_CONTROL_ADDRESS` | `0x6342000000000000000000000000000000000005` | Unstable Rex4 MegaLimitControl address |

## Spec History

- [MiniRex](../upgrades/minirex.md) introduced the Oracle and High-Precision Timestamp contracts.
- [Rex2](../upgrades/rex2.md) introduced KeylessDeploy.
- [Rex4](../upgrades/rex4.md) adds unstable MegaAccessControl and MegaLimitControl contracts.
