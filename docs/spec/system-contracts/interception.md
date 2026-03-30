---
description: Generic call-interception mechanism for MegaETH system contracts — frame-init hook, selector matching, short-circuit vs. fall-through semantics, gas treatment, and call-scheme exclusions.
spec: Rex3
---

# Call Interception

This page specifies the generic mechanism by which MegaETH intercepts calls to system-contract addresses at the EVM level.
It defines when interception fires, how selectors are matched, what happens on match or mismatch, and the gas and call-scheme rules that apply to all intercepted calls.

Individual system-contract pages define which functions are intercepted and what each interception does.

## Motivation

Some system-contract functions require protocol-level side effects that cannot be expressed by ordinary EVM bytecode alone.
Examples include forwarding hint data to an external oracle backend, executing a deployment inside a sandboxed EVM instance, or querying EVM-internal accounting state that is not accessible to contract bytecode.

Rather than introducing new opcodes or precompiles for each such function, MegaETH intercepts ordinary `CALL` and `STATICCALL` operations targeting known system-contract addresses and matching known function selectors.
This allows contracts to invoke protocol-level behavior through standard Solidity call syntax while keeping the system-contract ABI stable.

## Specification

### Interception Point

Interception fires during call-frame initialization, after the `CALL` or `STATICCALL` opcode has been executed but before a child call frame is created.
At this point the opcode-level gas accounting (including [gas forwarding](../evm/gas-forwarding.md) cap and new-account storage-gas charges) has already been applied.

A node MUST evaluate interception for every `CALL` and `STATICCALL` frame input.
A node MUST NOT evaluate interception for `CREATE` or `CREATE2` frame inputs.

### Dispatch Order

When a call frame is being initialized, the node MUST evaluate interceptors in the order specified below.
Each interceptor is active only when the current spec is at or above its activation spec.
Interceptors whose activation spec is not yet reached MUST be skipped entirely.

The [Oracle hint](oracle.md#evm-level-interception) interceptor is a side-effect-only interceptor: it MUST be evaluated first for its side effect, and dispatch MUST always continue to the next interceptor regardless of whether it matched.

The remaining interceptors are short-circuit interceptors.
They MUST be evaluated in order, and the first one that produces a short-circuit result MUST terminate dispatch — no further interceptors are evaluated.

| Order | Interceptor | Target Address | Type | Activation Spec |
| ----- | ----------- | -------------- | ---- | --------------- |
| 1 | [Oracle hint](oracle.md#evm-level-interception) | `ORACLE_CONTRACT_ADDRESS` | Side-effect only | [Rex2](../upgrades/rex2.md) |
| 2 | [KeylessDeploy](keyless-deploy.md#interception-scope) | `KEYLESS_DEPLOY_ADDRESS` | Short-circuit | [Rex2](../upgrades/rex2.md) |

<details>
<summary>Rex4 (unstable): Additional interceptors</summary>

For Rex4, two additional short-circuit interceptors MUST be evaluated after KeylessDeploy:

| Order | Interceptor | Target Address | Type | Activation Spec |
| ----- | ----------- | -------------- | ---- | --------------- |
| 3 | MegaAccessControl | `MEGA_ACCESS_CONTROL_ADDRESS` | Short-circuit | Rex4 |
| 4 | MegaLimitControl | `MEGA_LIMIT_CONTROL_ADDRESS` | Short-circuit | Rex4 |

</details>

### Selector Matching

Each interceptor MUST first compare the call's target address against its system-contract address.
If the address does not match, the interceptor MUST produce no result and the next interceptor in dispatch order MUST be evaluated.

If the address matches, the interceptor MUST attempt to decode the first four bytes of the call input as a function selector.
If the selector matches one of the interceptor's handled functions, the interceptor MUST handle the call as specified on the corresponding system-contract page.
If the selector does not match any handled function, the interceptor MUST produce no result.

### Interception Outcomes

An interceptor MUST produce one of two outcomes:

- **Short-circuit**: The interceptor returns a synthetic call result directly.
  No child EVM frame is created, no journal checkpoint is opened, and the caller's EVM frame receives the synthetic result as if a child frame had executed and returned immediately.
- **Fall-through**: The interceptor produces no result.
  The next interceptor in dispatch order is evaluated, or if no interceptors remain, normal child-frame creation proceeds and the system contract's on-chain bytecode executes.

An interceptor MAY also perform a side effect (such as forwarding data to an external backend) and then fall through.
In that case, the on-chain bytecode still executes after the side effect.

### Fall-Through to Bytecode

If no interceptor produces a short-circuit result for a call targeting a system-contract address, normal frame initialization MUST proceed and the system contract's deployed bytecode MUST execute.

System contracts SHOULD implement a Solidity `fallback()` that reverts with `NotIntercepted()` for any selector that is expected to be intercepted but was not (for example, because the call did not meet interception preconditions such as depth requirements).

### Call Scheme Exclusion

Interception MUST apply only to `CALL` and `STATICCALL`.

`DELEGATECALL` and `CALLCODE` MUST NOT trigger interception.
For these call schemes, the EVM sets the call's target address to the calling contract's own address rather than the code address being invoked.
Because the target address does not equal the system-contract address, the address check fails and no interceptor matches.

### Gas Semantics

When an interceptor produces a short-circuit result, the following gas rules MUST apply:

- The `CALL` or `STATICCALL` opcode's own gas costs (including the [gas forwarding](../evm/gas-forwarding.md) cap adjustment) MUST be charged before interception fires.
  These costs are not refunded.
- The intercepted call MUST consume zero gas from the forwarded gas limit, unless the specific interceptor's specification states otherwise.
  The full forwarded gas limit MUST be returned to the caller as remaining gas.
- The intercepted call MUST NOT receive a storage-call stipend.
  The stipend is granted during normal child-frame initialization, which is bypassed by short-circuit interception.

Individual system-contract pages MAY specify additional gas charges for specific intercepted functions (for example, [KeylessDeploy](keyless-deploy.md) charges a fixed overhead before sandbox execution).

### Value Transfer Rejection

Interceptors that handle `view` or state-query functions MUST reject calls that carry a non-zero ETH value.
When such a call is detected, the interceptor MUST short-circuit with a revert containing the `NonZeroTransfer()` error selector.

This rule does not apply to interceptors that handle state-modifying functions where value transfer is part of the function's semantics.

## Constants

This page introduces no new constants.
System-contract addresses and function selectors are defined on the individual system-contract pages.

## Rationale

**Why intercept at frame initialization rather than at the opcode level?**
Intercepting at frame initialization allows the standard CALL opcode gas accounting to complete first, ensuring that callers are charged consistently regardless of whether a call is intercepted.
It also avoids modifying the opcode table or introducing opcode-level branching, keeping the interception mechanism orthogonal to the core EVM instruction set.

**Why a fixed dispatch order rather than a registry lookup?**
The number of system contracts with intercepted functions is small and known at compile time.
A fixed dispatch order is deterministic, easy to reason about, and avoids the complexity of a dynamic registry.

**Why exclude DELEGATECALL and CALLCODE implicitly rather than with an explicit check?**
For `DELEGATECALL` and `CALLCODE`, the EVM's own semantics set the target address to the caller's address.
This means the address check naturally fails for these call schemes without any additional logic.
Relying on this property keeps the interception path simple and avoids redundant checks.

**Why return full gas as remaining for short-circuited calls?**
Intercepted calls do not execute bytecode, so there is no meaningful gas consumption to meter.
Returning the full forwarded gas limit prevents callers from being penalized for invoking protocol-level functionality through standard call syntax.

**Why reject value transfers on view-style interceptors?**
View-style interceptors do not create child frames, so value transfer would be silently dropped.
Reverting explicitly prevents callers from accidentally losing ETH.

## Spec History

- [Rex2](../upgrades/rex2.md) introduced call interception for `Oracle.sendHint` and `KeylessDeploy.keylessDeploy`.
- [Rex4](../upgrades/rex4.md) *(unstable)* adds MegaAccessControl and MegaLimitControl interceptors.
