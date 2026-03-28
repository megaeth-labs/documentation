---
description: Connect your wallet to MegaETH — chain parameters, RPC endpoints, and block explorers for Mainnet and Testnet.
---

# Connect to MegaETH

## Chain Parameters

{% tabs %}
{% tab title="Mainnet" %}
| Parameter | Value |
| --------- | ----- |
| **Network Name** | MegaETH |
| **Chain ID** | 4326 (0x10e6) |
| **Native & Gas Token** | Ether (ETH), 18 decimals |
| **RPC URL** | `https://mainnet.megaeth.com/rpc` |
| **Block Time** | Mini-blocks: 10ms / EVM blocks: 1s |
| **Block Gas Limit** | 10 billion (10¹⁰) gas per EVM block |
| **Base Fee Per Gas** | 0.001 gwei (10⁶ wei) |
| **EIP-1559** | Base fee adjustment is effectively disabled |
{% endtab %}

{% tab title="Testnet" %}
| Parameter | Value |
| --------- | ----- |
| **Network Name** | MegaETH Testnet |
| **Chain ID** | 6343 (0x18c7) |
| **Native & Gas Token** | Ether (ETH), 18 decimals |
| **RPC URL** | `https://carrot.megaeth.com/rpc` |
| **Managed RPC** | [Alchemy](https://www.alchemy.com/) sells managed endpoints for higher rate limits |
| **Block Time** | Mini-blocks: 10ms / EVM blocks: 1s |
| **Block Gas Limit** | 10 billion (10¹⁰) gas per EVM block |
| **Base Fee Per Gas** | 0.001 gwei (10⁶ wei) |
| **EIP-1559** | Base fee adjustment is effectively disabled |

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
{% endtab %}
{% endtabs %}

## Connect Your Wallet

{% stepper %}
{% step %}
### Open your wallet settings

In MetaMask, Rabby, or any Ethereum-compatible wallet, go to **Settings → Networks → Add Network**.
{% endstep %}

{% step %}
### Enter MegaETH network details

{% tabs %}
{% tab title="Mainnet" %}
| Field | Value |
| ----- | ----- |
| Network Name | MegaETH |
| RPC URL | `https://mainnet.megaeth.com/rpc` |
| Chain ID | 4326 |
| Currency Symbol | ETH |
| Block Explorer | `https://mega.etherscan.io` |
{% endtab %}

{% tab title="Testnet" %}
| Field | Value |
| ----- | ----- |
| Network Name | MegaETH Testnet |
| RPC URL | `https://carrot.megaeth.com/rpc` |
| Chain ID | 6343 |
| Currency Symbol | ETH |
| Block Explorer | `https://megaeth-testnet-v2.blockscout.com` |
{% endtab %}
{% endtabs %}
{% endstep %}

{% step %}
### Save and switch

Save the network and switch to MegaETH.
Your wallet is now connected.
{% endstep %}
{% endstepper %}

## Block Explorers

{% tabs %}
{% tab title="Mainnet" %}
- [Blockscout](https://megaeth.blockscout.com/)
- [Etherscan](https://mega.etherscan.io)
{% endtab %}

{% tab title="Testnet" %}
- [Blockscout](https://megaeth-testnet-v2.blockscout.com/)
{% endtab %}
{% endtabs %}

## Network Status

Check real-time network performance — block height, block time, and transactions per second — at [uptime.megaeth.com](https://uptime.megaeth.com).

## Getting Testnet ETH

Use the [faucet](faucet.md) to request free testnet tokens.
