---
description: Bridge ETH from Ethereum to MegaETH using the canonical bridge.
---

# Bridge

MegaETH uses a canonical bridge to move ETH from Ethereum to MegaETH.

{% hint style="info" %}
The bridge runs on OP Stack's [Standard Bridge](https://docs.optimism.io/app-developers/guides/bridging/standard-bridge).
For advanced usage (specifying gas limits or extra data), see the [Developer Docs](../dev/getting-started.md).
{% endhint %}

## How to Bridge ETH

The simplest way to bridge is to send ETH directly to the bridge contract address on Ethereum Mainnet:

`0x0CA3A2FBC3D770b578223FBB6b062fa875a2eE75`

The same amount of ETH (minus Ethereum gas fees) will appear at your address on MegaETH after the Ethereum transaction is finalized.

{% hint style="warning" %}
Bridging moves ETH from **Ethereum Mainnet** to **MegaETH Mainnet**.
For testnet tokens, use the [faucet](faucet.md) instead.
{% endhint %}
