---
description: Volatile data access on MegaETH — what triggers the 20M compute gas cap, best practices for reading block data and oracle state, and common pitfalls.
---

# Volatile Data Access

MegaETH provides APIs for transactions to access _volatile data_ — data that changes frequently and expires quickly after being accessed.
This includes the current block metadata (block number, timestamp, coinbase), the beneficiary account state, and data from the [native oracle interface](system-contracts.md#native-oracle).

When a transaction reads volatile data, a dependency forms between it and other transactions that modify the same data.
This harms parallel execution performance — for example, reading `block.number` prevents the sequencer from producing the next block until the reading transaction finishes.

To mitigate this, MegaEVM imposes an **absolute cap of 20,000,000 compute gas** on the entire transaction once it accesses any volatile data source.
This is not 20M of _additional_ gas — it is a hard ceiling on total compute gas for the transaction.
If the transaction has already consumed more than 20M compute gas before the access, execution halts immediately.

## What Triggers the Cap

### Block Environment Opcodes

Accessing any of these opcodes caps the transaction's total compute gas to **20,000,000**.

| Opcode | Description |
| ------ | ----------- |
| `NUMBER` | Current block number |
| `TIMESTAMP` | Current block timestamp |
| `COINBASE` | Block beneficiary address |
| `DIFFICULTY` | Block difficulty |
| `GASLIMIT` | Block gas limit |
| `BASEFEE` | Base fee per gas |
| `PREVRANDAO` | Previous block randomness |
| `BLOCKHASH` | Historical block hash |
| `BLOBBASEFEE` | Blob base fee |
| `BLOBHASH` | Blob hash lookup |

### Beneficiary Account Access

Accessing the block beneficiary (coinbase) account in any way also triggers the cap:

| Trigger | Description |
| ------- | ----------- |
| `BALANCE`, `SELFBALANCE` | Reading beneficiary's balance |
| `EXTCODECOPY`, `EXTCODESIZE`, `EXTCODEHASH` | Accessing beneficiary's code |
| Transaction sender is beneficiary | When `msg.sender == block.coinbase` |
| Transaction recipient is beneficiary | When call target is `block.coinbase` |
| `DELEGATECALL` to beneficiary | Delegated context accessing beneficiary |

### Native Oracle Service

Reading oracle data via `SLOAD` from the oracle contract storage triggers the cap.

- Oracle contract address: `0x6342000000000000000000000000000000000001`
- Triggered by: `SLOAD` from oracle contract storage
- `DELEGATECALL` to the oracle contract does **not** trigger this limit

### Shared Cap

All volatile data sources share the same 20,000,000 compute gas cap.
Accessing multiple sources (e.g., both `block.timestamp` and oracle storage) does not increase the cap to 40M — the same 20M ceiling applies.

## Best Practices

### Keep transactions under 20M compute gas

Under the current absolute cap, the order of operations does not matter — reading volatile data early or late makes no difference because the 20M ceiling applies to total compute gas regardless.
Design transactions that access volatile data to stay well within 20M compute gas total.

{% hint style="danger" %}
The following pattern will fail if the loop consumes more than 20M compute gas:

```solidity
function processWithTimestamp(uint256[] calldata items) external {
    uint256 currentTime = block.timestamp; // Triggers 20M cap
    // This loop might run out of gas!
    for (uint i = 0; i < items.length; i++) {
        heavyComputation(items[i], currentTime);
    }
}
```
{% endhint %}

<details>
<summary>Rex4 (unstable): Relative detention — read order matters</summary>

Rex4 changes the cap from absolute to relative: accessing volatile data allows **20M more** compute gas from the point of access, regardless of how much was consumed before.

Under relative detention, reading volatile data **as late as possible** becomes a valid optimization.
A transaction that uses 15M compute gas before reading `block.timestamp` would still have 20M remaining (effective limit = 15M + 20M = 35M).
Under the current absolute model, the same transaction has only 5M remaining.

```solidity
// Good under Rex4: heavy computation first, volatile read last
function processAndCheckTime(uint256[] calldata items) external {
    for (uint i = 0; i < items.length; i++) {
        processItem(items[i]);
    }
    require(block.timestamp <= deadline, "Expired");
}
```

For the formal definition, see [Gas Detention](../spec/evm/gas-detention.md).

</details>

### Split heavy transactions

If your contract needs both volatile data and heavy computation, split the work across two transactions:

1. A lightweight transaction that reads volatile data and stores the result.
2. A separate transaction that reads the stored result and performs heavy computation — no cap applies.

### Use DELEGATECALL for oracle reads

`DELEGATECALL` to the oracle contract does **not** trigger the compute gas cap.
If your contract calls a helper that reads oracle data via DELEGATECALL, the cap is not applied.
Use this pattern when you need oracle data in a sub-call without constraining the parent transaction.

### Keep gas-sensitive logic separate

If a function has both a gas-sensitive path (large loops, recursive calls) and a volatile data read, refactor them into separate functions.
Callers can then invoke the gas-heavy function first and the lightweight volatile-data function second.

## Related Pages

- [EVM Differences](evm-differences.md) — full list of MegaEVM behavioral differences
- [Gas Estimation](gas-estimation.md) — estimate gas correctly on MegaETH
- [Debugging Transactions](debugging.md) — trace gas consumption with mega-evme
- [Gas Detention (spec)](../spec/evm/gas-detention.md) — formal specification of the gas detention mechanism
