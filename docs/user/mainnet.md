---
description: Connect your wallet and start using MegaETH Mainnet.
---

# Mainnet

MegaETH Mainnet is live.
This page covers how to connect, explore, and bridge assets.

## Chain Parameters

| Parameter | Value |
| --------- | ----- |
| **Network Name** | MegaETH |
| **Chain ID** | 4326 (0x10e6) |
| **Currency** | Ether (ETH) |
| **Block Time** | ~1 second |
| **RPC URL** | `https://mainnet.megaeth.com/rpc` |

## Connect Your Wallet

{% stepper %}
{% step %}
### Open your wallet settings

In MetaMask, Rabby, or any Ethereum-compatible wallet, go to **Settings → Networks → Add Network**.
{% endstep %}

{% step %}
### Enter MegaETH network details

| Field | Value |
| ----- | ----- |
| Network Name | MegaETH |
| RPC URL | `https://mainnet.megaeth.com/rpc` |
| Chain ID | 4326 |
| Currency Symbol | ETH |
| Block Explorer | `https://megaeth.blockscout.com` |
{% endstep %}

{% step %}
### Save and switch

Save the network and switch to MegaETH.
Your wallet is now connected to MegaETH Mainnet.
{% endstep %}
{% endstepper %}

## Block Explorers

Two block explorers are available for MegaETH Mainnet:

- [Blockscout](https://megaeth.blockscout.com/)
- [Etherscan](https://mega.etherscan.io)

## Bridge ETH to MegaETH

MegaETH uses a canonical bridge to move ETH from Ethereum to MegaETH.

The simplest way to bridge is to send ETH directly to the bridge contract address on Ethereum Mainnet:

`0x0CA3A2FBC3D770b578223FBB6b062fa875a2eE75`

The same amount of ETH (minus Ethereum gas fees) will appear at your address on MegaETH after the Ethereum transaction is finalized.

{% hint style="info" %}
The bridge runs on OP Stack's [Standard Bridge](https://docs.optimism.io/app-developers/guides/bridging/standard-bridge).
For advanced usage (specifying gas limits or extra data), see the [Developer Docs](../dev/getting-started.md).
{% endhint %}

## Key Tokens

| Token | Address |
| ----- | ------- |
| MEGA | `0x28B7E77f82B25B95953825F1E3eA0E36c1c29861` |
| WETH9 | `0x4200000000000000000000000000000000000006` |
| USDM | `0xFAfDdbb3FC7688494971a79cc65DCa3EF82079E7` |

For a comprehensive list of tokens, see the [mega-tokenlist](https://github.com/megaeth-labs/mega-tokenlist).
