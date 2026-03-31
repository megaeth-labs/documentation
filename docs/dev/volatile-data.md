---
description: Volatile data access on MegaETH — what triggers the 20M compute gas cap, best practices for reading block data and oracle state, and common pitfalls.
---

# Volatile Data Access

MegaETH provides APIs for transactions to access _volatile data_ — data that changes frequently and expires quickly after being accessed.
This includes the current block metadata (block number, timestamp, coinbase), the beneficiary account state, and data from the [native oracle interface](system-contracts.md#reading-oracle-data).

When a transaction reads volatile data, a dependency forms between it and other transactions that modify the same data.
This harms parallel execution performance — for example, reading `block.number` prevents the sequencer from producing the next block until the reading transaction finishes.

To mitigate this, MegaEVM imposes an **absolute cap of 20,000,000 compute gas** on the entire transaction once it accesses any volatile data source.
This is not 20M of _additional_ gas — it is a hard ceiling on total compute gas for the transaction.
If the transaction has already consumed more than 20M compute gas before the access, execution halts immediately.

<details>
<summary>Rex4 (unstable): Relative detention</summary>

Rex4 changes the cap from absolute to relative: accessing volatile data allows **20M more** compute gas from the point of access, regardless of how much was consumed before.

For example, a transaction that uses 15M compute gas before reading `block.timestamp` would still have 20M of compute gas remaining (effective limit = 15M + 20M = 35M).
Under the current absolute model, the same transaction would have only 5M remaining (absolute cap = 20M).

This change removes the penalty for accessing volatile data late in a transaction's execution.
Under relative detention, reading volatile data **as late as possible** becomes a valid optimization — see [Best Practices](#best-practices).
For the formal definition, see [Gas Detention](../spec/evm/gas-detention.md).

</details>

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

### Split volatile reads and heavy computation into separate transactions

If your contract needs both volatile data and heavy computation, split the work across two transactions:

1. A lightweight transaction that reads volatile data and stores the result on-chain.
2. A separate transaction that reads the stored result and performs heavy computation — no cap applies because it never accesses volatile data.


<details>
<summary>Rex4 (unstable): Read volatile data as late as possible</summary>

Rex4 changes the cap from absolute to relative: accessing volatile data allows **20M more** compute gas from the point of access, regardless of how much was consumed before.
This means deferring the volatile data read to the end of the transaction maximizes the computation you can perform.

```solidity
// Good under Rex4: heavy computation first, volatile read last
function processAndCheckTime(uint256[] calldata items) external {
    for (uint i = 0; i < items.length; i++) {
        processItem(items[i]);
    }
    // Cap starts here — but the heavy work is already done
    require(block.timestamp <= deadline, "Expired");
}
```

```solidity
// Bad under Rex4: reading volatile data first wastes the budget
function processWithTimestamp(uint256[] calldata items) external {
    uint256 currentTime = block.timestamp; // Cap starts immediately
    for (uint i = 0; i < items.length; i++) {
        processItem(items[i]);  // Competing with the 20M budget
    }
}
```

Under the current absolute cap, read order makes no difference — the 20M ceiling applies to total compute gas regardless.
For the formal definition, see [Gas Detention](../spec/evm/gas-detention.md).

</details>


## Related Pages

- [EVM Differences](evm-differences.md) — full list of MegaEVM behavioral differences
- [Gas Estimation](gas-estimation.md) — estimate gas correctly on MegaETH
- [Debugging Transactions](debugging.md) — trace gas consumption with mega-evme
- [Gas Detention (spec)](../spec/evm/gas-detention.md) — formal specification of the gas detention mechanism
