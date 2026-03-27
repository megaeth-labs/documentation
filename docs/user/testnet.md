---
description: Connect to MegaETH Testnet — chain parameters, RPC endpoint, and block explorer.
---

# Testnet

{% hint style="warning" %}
**RPC endpoints are rate limited and may change.**
Always check this page for the latest URLs and status.
{% endhint %}

{% hint style="warning" %}
**Network maintenance may occur.**
RPCs may go offline during upgrades.
Contracts and state may be rolled back in rare cases.
{% endhint %}

{% hint style="info" %}
**Testnet is not incentivized.**
Testnet tokens and transactions have no real monetary value.
Everything on the chain is solely for experimental purposes.
{% endhint %}

## Chain Parameters

| Parameter | Value |
| --------- | ----- |
| **Network Name** | MegaETH Testnet |
| **Chain ID** | 6343 |
| **Native & Gas Token** | Ether (ETH), 18 decimals |
| **Block Time** | Mini blocks: 10ms / EVM blocks: 1s |
| **Block Gas Limit** | 10 billion (10¹⁰) gas per EVM block |
| **Base Fee Per Gas** | 0.001 gwei (10⁶ wei) |
| **EIP-1559** | Base fee adjustment is effectively disabled |

## Connecting to the Testnet

### RPC Endpoint

MegaETH provides a public endpoint at `https://carrot.megaeth.com/rpc`.
Alchemy also sells managed endpoints for higher rate limits.

### Block Explorer

- [Blockscout](https://megaeth-testnet-v2.blockscout.com/) — browse transactions, contracts, and accounts
- [uptime.megaeth.com](https://uptime.megaeth.com) — real-time network performance dashboard

## Getting Testnet ETH

Use the [faucet](faucet.md) to request free testnet tokens.
