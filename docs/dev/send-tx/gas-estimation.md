---
description: How to estimate gas on MegaETH — code examples, toolchain configuration, and common pitfalls.
---

# Gas Estimation

MegaETH's [dual gas model](../execution/gas-model.md) charges both compute gas and storage gas.
Standard Ethereum toolchains are unaware of storage gas and will underestimate the gas a transaction needs.
This page explains how to estimate gas correctly and avoid common errors.

## Why Standard Tooling Underestimates Gas

Ethereum toolchains like Foundry and Hardhat often run a local EVM to simulate transactions and estimate gas.
These local EVMs do not implement MegaETH's storage gas, so they only account for compute gas.
The result is an estimate that is too low — sometimes by a large margin.

For example, a simple Ether transfer costs 21,000 gas on Ethereum but **60,000 gas** on MegaETH (21,000 compute + 39,000 storage).
A toolchain that estimates 21,000 will produce a transaction that fails with "intrinsic gas too low."

The fix is straightforward: **always use a MegaETH RPC endpoint for gas estimation** instead of relying on local simulation.

## Using `eth_estimateGas`

Calling `eth_estimateGas` on a MegaETH RPC endpoint is the recommended approach.
The endpoint runs the transaction through MegaEVM and returns an accurate estimate that accounts for compute gas, storage gas, the bucket multiplier, and all resource dimensions.

{% tabs %}
{% tab title="curl" %}
```bash
curl -s https://mainnet.megaeth.com/rpc \
  -X POST \
  -H "Content-Type: application/json" \
  -d '{
    "jsonrpc": "2.0",
    "method": "eth_estimateGas",
    "params": [{
      "from": "0xYourAddress",
      "to": "0xContractAddress",
      "data": "0xCalldata"
    }],
    "id": 1
  }'
```
{% endtab %}

{% tab title="cast" %}
```bash
cast estimate 0xContractAddress \
  'myFunction(uint256)' 42 \
  --rpc-url https://mainnet.megaeth.com/rpc \
  --from 0xYourAddress
```
{% endtab %}
{% endtabs %}

Any Ethereum SDK (ethers.js, viem, alloy, web3.py, etc.) works the same way — just point it at a MegaETH RPC endpoint and call `estimateGas` as usual.

### The RPC Compute Gas Cap

`eth_estimateGas` (and `eth_call`) enforce a compute gas limit of **60,000,000** on the public RPC endpoint.
This is separate from the protocol per-transaction gas limit of 10,000,000,000.

If your transaction requires more than 60M compute gas to simulate, the RPC call will fail.
There are two workarounds:

1. **Set a manual gas limit.**
   Use the `--gas-limit` flag (see [Toolchain Configuration](#toolchain-configuration) below) to skip estimation entirely and submit the transaction with a known gas value.
   You can determine the right value by simulating the transaction locally with [`mega-evme`](debugging.md#using-mega-evme), which has no gas cap and fully implements MegaETH's gas model.
2. **Use a managed RPC provider with a higher cap.**
   Managed RPC providers typically allow much more gas for `eth_call` and `eth_estimateGas` than the public endpoint.
   For reference, standard Ethereum node software (geth, reth) defaults to 50M, and providers like Alchemy support up to 550M.
   See the [RPC Providers](../tooling.md#rpc-providers) table for providers that support MegaETH.

## Toolchain Configuration

### Foundry

Foundry's `forge script` uses its own built-in EVM for local simulation, which does not account for MegaETH's storage gas.
Pass `--skip-simulation` to bypass the local EVM — `forge script` will then call `eth_estimateGas` on the remote RPC before broadcasting each transaction:

```bash
forge script MyScript \
  --skip-simulation \
  --rpc-url https://mainnet.megaeth.com/rpc
```

For `cast send`, gas estimation goes through the remote RPC by default, so no special flags are needed.
If you want to set a manual gas limit instead, pass `--gas-limit` to skip estimation entirely:

```bash
cast send 0xContractAddress \
  'myFunction(uint256)' 42 \
  --gas-limit 30000000 \
  --rpc-url https://mainnet.megaeth.com/rpc \
  --private-key $PRIVATE_KEY
```

## Common Errors

### "intrinsic gas too low"

The transaction's `gasLimit` is below the minimum intrinsic gas cost.
On MegaETH, the minimum is **60,000** (21,000 compute + 39,000 storage), not 21,000 as on Ethereum.

**Fix:** Use `eth_estimateGas` on a MegaETH endpoint, or set `gasLimit` to at least 60,000.

### Out of gas from storage gas

The transaction ran out of gas because storage-heavy operations (contract creation, `SSTORE`, `LOG`) consumed more gas than expected.
This typically happens when gas was estimated by a non-MegaETH-aware tool.

**Fix:** Use `eth_estimateGas` on a MegaETH endpoint.
For contract deployments, note that code deposit costs **10,000 storage gas per byte** — a 24 KB contract costs roughly 240,000,000 storage gas alone.

### Out of gas from volatile data access

Accessing volatile data — `block.timestamp`, `block.number`, oracle storage — caps the transaction's compute gas to **20,000,000**.
If the transaction performs heavy computation after reading volatile data, it may hit this cap and revert.

**Fix:** Split the work across multiple transactions so that only lightweight transactions (under 20M compute gas) access volatile data.
See [Volatile Data Access](../execution/volatile-data.md) for the full list of triggers and best practices.

### Resource limit exceeded

MegaETH enforces per-transaction limits beyond gas: Data Size (12.5 MB), KV Updates (500,000), and State Growth (1,000).
A transaction that stays within its gas budget can still fail if it exceeds one of these limits.

**Fix:** Reduce the number of state operations per transaction.
See [Resource Limits](../execution/resource-limits.md) for the full table.

## Interpreting Gas in Receipts

The `gasUsed` field in a transaction receipt reports the **total gas consumed** — compute gas plus storage gas combined.
MegaETH does not expose a per-dimension breakdown in the receipt.

This means `gasUsed` will be higher than what a standard Ethereum tool would predict for the same operations.
If you need to debug which dimension caused a failure, see [Debugging Transactions](debugging.md) for how to replay a transaction with full tracing.

## Related Pages

- [Gas Model](../execution/gas-model.md) — how compute gas, storage gas, and the bucket multiplier work
- [EVM Differences](../execution/overview.md) — volatile data caps, SSTORE refund changes, 98/100 forwarding
- [RPC Reference](../read/overview.md) — method availability and restrictions
- [Developer FAQ](../faq.md) — `eth_estimateGas` gas cap, block gas limit
- [Dual Gas Model (spec)](https://app.gitbook.com/o/iBzILuNyLtuxU3vUEuPe/s/apRp1sxFYuGhHAo7Y2Pz/evm/dual-gas-model) — formal specification of compute gas and storage gas
- [Resource Limits (spec)](https://app.gitbook.com/o/iBzILuNyLtuxU3vUEuPe/s/apRp1sxFYuGhHAo7Y2Pz/evm/resource-limits) — per-transaction and per-block limit enforcement
