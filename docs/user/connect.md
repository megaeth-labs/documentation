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
| **Chain ID** | <code class="expression">space.vars.mainnet_chain_id</code> (<code class="expression">space.vars.mainnet_chain_id_hex</code>) |
| **Native & Gas Token** | Ether (ETH), 18 decimals |
| **RPC URL** | <code class="expression">space.vars.mainnet_rpc</code> |
| **Block Time** | Mini-blocks: <code class="expression">space.vars.miniblock_time</code> / EVM blocks: <code class="expression">space.vars.evm_block_time</code> |
| **Block Gas Limit** | <code class="expression">space.vars.block_gas_limit</code> gas per EVM block |
| **Base Fee Per Gas** | <code class="expression">space.vars.base_fee_per_gas</code> |
| **EIP-1559** | Base fee adjustment is effectively disabled |
{% endtab %}

{% tab title="Testnet" %}
| Parameter | Value |
| --------- | ----- |
| **Network Name** | MegaETH Testnet |
| **Chain ID** | <code class="expression">space.vars.testnet_chain_id</code> (<code class="expression">space.vars.testnet_chain_id_hex</code>) |
| **Native & Gas Token** | Ether (ETH), 18 decimals |
| **RPC URL** | <code class="expression">space.vars.testnet_rpc</code> |
| **Managed RPC** | [Alchemy](https://www.alchemy.com/) sells managed endpoints for higher rate limits |
| **Block Time** | Mini-blocks: <code class="expression">space.vars.miniblock_time</code> / EVM blocks: <code class="expression">space.vars.evm_block_time</code> |
| **Block Gas Limit** | <code class="expression">space.vars.block_gas_limit</code> gas per EVM block |
| **Base Fee Per Gas** | <code class="expression">space.vars.base_fee_per_gas</code> |
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
| RPC URL | <code class="expression">space.vars.mainnet_rpc</code> |
| Chain ID | <code class="expression">space.vars.mainnet_chain_id</code> |
| Currency Symbol | ETH |
| Block Explorer | <code class="expression">space.vars.mainnet_etherscan</code> |
{% endtab %}

{% tab title="Testnet" %}
| Field | Value |
| ----- | ----- |
| Network Name | MegaETH Testnet |
| RPC URL | <code class="expression">space.vars.testnet_rpc</code> |
| Chain ID | <code class="expression">space.vars.testnet_chain_id</code> |
| Currency Symbol | ETH |
| Block Explorer | <code class="expression">space.vars.testnet_blockscout</code> |
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
