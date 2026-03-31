---
description: How to submit transactions on MegaETH — deploy contracts, estimate gas, and debug failures.
---

# Send Transaction

MegaETH is fully EVM-compatible.
Point your toolchain at a MegaETH RPC endpoint and everything works — Foundry, Hardhat, Remix, ethers.js, viem, web3.py.
For network parameters (chain ID, RPC URLs), see [Connect to MegaETH](../../user/connect.md).
To bridge ETH or tokens from Ethereum, see [Bridge](../../user/bridge.md).

## Estimate gas correctly

MegaETH's [dual gas model](../execution/gas-model.md) charges both compute gas and storage gas.
Local EVM simulations (Foundry, Hardhat) only know about compute gas and will underestimate — sometimes by a large margin.

A simple ETH transfer costs 21,000 gas on Ethereum but **60,000 gas** on MegaETH (21,000 compute + 39,000 storage).
A toolchain that estimates 21,000 will produce a transaction that reverts with "intrinsic gas too low."

**The fix:** always estimate gas against a MegaETH RPC endpoint or use [`mega-evme`](debugging.md#simulating-a-new-transaction) tool to simulate, instead of a local standard EVM.

{% tabs %}
{% tab title="Foundry" %}
```bash
# Estimate with MegaETH RPC (correct)
cast estimate 0xContract 'myFunction(uint256)' 42 \
  --rpc-url https://mainnet.megaeth.com/rpc
```
{% endtab %}
{% tab title="curl" %}
```bash
curl -s https://mainnet.megaeth.com/rpc \
  -X POST -H "Content-Type: application/json" \
  -d '{
    "jsonrpc": "2.0",
    "method": "eth_estimateGas",
    "params": [{"from":"0xYou","to":"0xContract","data":"0xCalldata"}],
    "id": 1
  }'
```
{% endtab %}
{% endtabs %}

{% hint style="warning" %}
The public RPC caps `eth_estimateGas` at **10M gas**.
If your transaction needs more (e.g., deploying a large contract), either set a manual gas limit or use a [managed RPC provider](../tooling.md#rpc-providers) with a higher cap.
You can determine the exact gas needed by simulating locally with [`mega-evme`](debugging.md#simulating-a-new-transaction).
{% endhint %}

For the full list of pitfalls (volatile data caps, resource limits, receipt interpretation), see [Gas Estimation](gas-estimation.md).

## Submit transaction

{% tabs %}
{% tab title="Foundry (forge create)" %}
```bash
# forge create calls eth_estimateGas on the RPC — no local simulation
forge create src/MyContract.sol:MyContract \
  --rpc-url https://mainnet.megaeth.com/rpc \
  --private-key $PRIVATE_KEY
```
{% endtab %}
{% tab title="Foundry (forge script)" %}
```bash
# forge script runs local EVM simulation by default, which underestimates gas.
# Use --skip-simulation to bypass local estimation and let the RPC handle it.
forge script script/Deploy.s.sol \
  --rpc-url https://mainnet.megaeth.com/rpc \
  --private-key $PRIVATE_KEY \
  --skip-simulation \
  --broadcast
```
{% endtab %}
{% endtab %}
{% tab title="cast" %}
```bash
# Send a simple ETH transfer
cast send 0xRecipient --value 0.1ether \
  --rpc-url https://mainnet.megaeth.com/rpc \
  --private-key $PRIVATE_KEY
```
{% endtab %}
{% tab title="eth_sendRawTransaction" %}
```bash
# 1. Sign the transaction offline (e.g., with cast)
SIGNED_TX=$(cast mktx 0xRecipient --value 0.1ether \
  --rpc-url https://mainnet.megaeth.com/rpc \
  --private-key $PRIVATE_KEY)

# 2. Submit via eth_sendRawTransaction
curl -s https://mainnet.megaeth.com/rpc \
  -X POST -H "Content-Type: application/json" \
  -d "{\"jsonrpc\":\"2.0\",\"id\":1,\"method\":\"eth_sendRawTransaction\",\"params\":[\"$SIGNED_TX\"]}"
```

{% endtab %}
{% tab title="realtime_sendRawTransaction" %}
```bash
# Sign the transaction offline
SIGNED_TX=$(cast mktx 0xRecipient --value 0.1ether \
  --rpc-url https://mainnet.megaeth.com/rpc \
  --private-key $PRIVATE_KEY)

# Submit and get the receipt back in one call — no polling needed
curl -s https://mainnet.megaeth.com/rpc \
  -X POST -H "Content-Type: application/json" \
  -d "{\"jsonrpc\":\"2.0\",\"id\":1,\"method\":\"realtime_sendRawTransaction\",\"params\":[\"$SIGNED_TX\"]}"
```

Returns the full transaction receipt directly.
Times out after 10 seconds if the transaction has not been executed.
See [`realtime_sendRawTransaction`](../read/rpc/realtime_sendRawTransaction.md) for the full reference.
{% endtab %}
{% endtabs %}

For key contract addresses (bridge, CREATE2 factory), token lists (stablecoins, LSTs, BTC), and how to bridge tokens onto MegaETH, see [Contracts & Tokens](contracts.md).
To bridge assets from Ethereum, see [Bridge](../../user/bridge.md).

## Debug a failed transaction

When a transaction reverts, MegaETH provides two debugging tools:

1. **`debug_traceTransaction`** — standard Ethereum debug RPC, available through [managed providers](../tooling.md#rpc-providers) like Alchemy.
2. **[`mega-evme`](debugging.md#simulating-a-new-transaction)** — MegaETH's local transaction simulation tool. No RPC provider needed.

{% tabs %}
{% tab title="mega-evme (replay)" %}
```bash
# Replay a failed transaction with call-level tracing
mega-evme replay 0xYourTxHash \
  --rpc https://mainnet.megaeth.com/rpc \
  --trace --tracer call
```
{% endtab %}
{% tab title="mega-evme (what-if)" %}
```bash
# Would the transaction succeed with more gas?
mega-evme replay 0xYourTxHash \
  --rpc https://mainnet.megaeth.com/rpc \
  --override.gas-limit 30000000
```
{% endtab %}
{% tab title="cast (debug RPC)" %}
```bash
# Requires a provider that supports debug_traceTransaction
cast rpc debug_traceTransaction 0xYourTxHash \
  --rpc-url https://your-alchemy-endpoint.com
```
{% endtab %}
{% endtabs %}

Common failure causes:

| Symptom | Likely cause | Fix |
| ------- | ------------ | --- |
| `intrinsic gas too low` | Gas estimated by local EVM, missing storage gas | Estimate against MegaETH RPC |
| `out of gas` with low compute usage | Storage gas exceeded the limit | Increase gas limit or reduce state writes |
| `out of gas` after reading `block.timestamp` | Volatile data access caps compute gas to 20M | Split work across multiple transactions |
| `resource limit exceeded` | Hit data size, KV updates, or state growth cap | Reduce state operations per transaction |

For the full debugging guide, see [Debugging Transactions](debugging.md).

## Understand execution semantics

MegaETH is EVM-compatible, but the execution model has differences that affect gas costs and transaction behavior.
The key concepts:

- **Dual gas model** — every transaction pays compute gas + storage gas. See [Gas Model](../execution/gas-model.md).
- **Resource limits** — per-transaction caps on data size, KV updates, and state growth beyond gas. See [Resource Limits](../execution/resource-limits.md).
- **Volatile data access** — reading `block.timestamp`, `block.number`, or oracle data caps compute gas to 20M. See [Volatile Data Access](../execution/volatile-data.md).
- **System contracts** — oracle, high-precision timestamp, and keyless deployment at fixed addresses. See [System Contracts](../execution/system-contracts.md).

For the complete list of behavioral differences, see [EVM Differences](../execution/evm-differences.md).
