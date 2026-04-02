---
description: Volatile data access on MegaETH — what triggers the 20M compute gas cap, best practices for reading block data and oracle state, and common pitfalls.
---

# Volatile Data Access

MegaETH provides APIs for transactions to access _volatile data_ — data that changes frequently and expires quickly after being accessed.
This includes the current block metadata (block number, timestamp, coinbase), the beneficiary account state, and data from the [native oracle interface](system-contracts.md).

When a transaction reads volatile data, a dependency forms between it and other transactions that modify the same data.
This harms parallel execution performance — for example, reading `block.number` prevents the sequencer from producing the next block until the reading transaction finishes.

To mitigate this, MegaEVM imposes a **detention cap of 20,000,000 compute gas** on the transaction once it accesses any volatile data source.
The cap is relative: accessing volatile data allows **20M more** compute gas from the point of access, regardless of how much was consumed before.
For example, a transaction that uses 15M compute gas before reading `block.timestamp` still has 20M of compute gas remaining (effective limit = 15M + 20M = 35M).

## What Triggers the Cap

### Block Environment Opcodes

Accessing any of these opcodes triggers a **20,000,000 compute gas** detention cap from the point of access.

| Opcode        | Description               |
| ------------- | ------------------------- |
| `NUMBER`      | Current block number      |
| `TIMESTAMP`   | Current block timestamp   |
| `COINBASE`    | Block beneficiary address |
| `PREVRANDAO`  | Previous block randomness |
| `GASLIMIT`    | Block gas limit           |
| `BASEFEE`     | Base fee per gas          |
| `BLOCKHASH`   | Historical block hash     |
| `BLOBBASEFEE` | Blob base fee             |
| `BLOBHASH`    | Blob hash lookup          |

### Beneficiary Account Access

Accessing the block beneficiary (coinbase) account in any way also triggers the cap:

| Trigger                                     | Description                             |
| ------------------------------------------- | --------------------------------------- |
| `BALANCE`, `SELFBALANCE`                    | Reading beneficiary's balance           |
| `EXTCODECOPY`, `EXTCODESIZE`, `EXTCODEHASH` | Accessing beneficiary's code            |
| Transaction sender is beneficiary           | When `msg.sender == block.coinbase`     |
| Transaction recipient is beneficiary        | When call target is `block.coinbase`    |
| `DELEGATECALL` to beneficiary               | Delegated context accessing beneficiary |

### Native Oracle Service

Reading oracle data via `SLOAD` from the oracle contract storage triggers the cap.

- Oracle contract address: `0x6342000000000000000000000000000000000001`
- Triggered by: `SLOAD` from oracle contract storage
- `DELEGATECALL` to the oracle contract does **not** trigger this limit

### Shared Cap

All volatile data sources share the same 20,000,000 compute gas detention cap.
The first volatile read triggers the cap; subsequent reads of other volatile sources do not extend it.

## Best Practices

### Read volatile data as late as possible

Because the detention cap is measured from the point of access, deferring the volatile data read to the end of the transaction maximizes the computation you can perform.

```solidity
// Good: heavy computation first, volatile read last
function processAndCheckTime(uint256[] calldata items) external {
    for (uint i = 0; i < items.length; i++) {
        processItem(items[i]);
    }
    // Cap starts here — but the heavy work is already done
    require(block.timestamp <= deadline, "Expired");
}
```

```solidity
// Bad: reading volatile data first wastes the budget
function processWithTimestamp(uint256[] calldata items) external {
    uint256 currentTime = block.timestamp; // Cap starts immediately
    for (uint i = 0; i < items.length; i++) {
        processItem(items[i]);  // Competing with the 20M budget
    }
}
```

For the formal definition, see [Gas Detention](https://docs.megaeth.com/spec/megaevm/gas-detention).

### Split volatile reads and heavy computation into separate transactions

If your contract needs both volatile data and more than 20M compute gas of heavy computation after the volatile read, split the work across two transactions:

1. A lightweight transaction that reads volatile data and stores the result on-chain.
2. A separate transaction that reads the stored result and performs heavy computation — no cap applies because it never accesses volatile data.

## Related Pages

- [EVM Differences](overview.md) — full list of MegaEVM behavioral differences
- [Gas Estimation](../send-tx/gas-estimation.md) — estimate gas correctly on MegaETH
- [Debugging Transactions](../send-tx/debugging.md) — trace gas consumption with mega-evme
- [Gas Detention (spec)](https://docs.megaeth.com/spec/megaevm/gas-detention) — formal specification of the gas detention mechanism
