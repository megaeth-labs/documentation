---
description: How to get ETH, stablecoins, and other assets on MegaETH Mainnet.
---

# Get Funds on Mainnet

There are several ways to get tokens on MegaETH Mainnet — bridge from Ethereum or other chains, swap cross-chain, or buy directly with a card.

{% hint style="info" %}
This page is for **mainnet only**.
For testnet tokens, use the [faucet](faucet.md) instead.
{% endhint %}

## Bridge via Rabbithole

The easiest way to move assets to MegaETH is through **Rabbithole**, the official MegaETH portal.

{% stepper %}
{% step %}
### Go to the bridge

Visit [**rabbithole.megaeth.com/bridge**](https://rabbithole.megaeth.com/bridge).
{% endstep %}

{% step %}
### Connect your wallet

Click **Connect Wallet** and approve the connection in your wallet (MetaMask, Rabby, etc.).
{% endstep %}

{% step %}
### Choose a bridge and token

Rabbithole offers two built-in options:

- **USDm Bridge** — convert USDC to USDm at a 1:1 rate.
- **LI.FI** — swap and bridge tokens from Ethereum and other chains to MegaETH.

Select the token and amount you want to bridge, then confirm the transaction in your wallet.
{% endstep %}

{% step %}
### Wait for confirmation

Your tokens will appear on MegaETH once the transaction is processed.
The estimated time is shown before you confirm.
{% endstep %}
{% endstepper %}

## Other Bridges

Several third-party bridges also support MegaETH.
You can find them listed at the bottom of the [Rabbithole bridge page](https://rabbithole.megaeth.com/bridge), including:

- [**Bungee**](https://www.bungee.exchange/) — crosschain swap aggregator
- [**Stargate**](https://stargate.finance/) — bridge USDT0 and USDm to MegaETH, powered by LayerZero
- [**deBridge**](https://debridge.com/) — instant bridging from Solana and 25+ chains
- [**Across**](https://across.to/) — fast and cheap cross-chain transfers
- [**Portal (Wormhole)**](https://portalbridge.com/) — bridge USDC, ETH, SOL, and 100+ tokens across 30+ chains
- [**Jumper**](https://jumper.xyz/) — multi-asset bridge and swap aggregator, powered by LI.FI
- [**Relay**](https://relay.link/) — pay for any onchain action with any asset, across any chain

{% hint style="info" %}
For a full list of supported bridges, see [**fluffle.tools/bridge**](https://www.fluffle.tools/bridge).
{% endhint %}

## Buy with a Card

If you do not already hold crypto, you can buy ETH or stablecoins directly on MegaETH using a debit card, credit card, or bank transfer.

Go to the **Fund** tab at [**rabbithole.megaeth.com/fund**](https://rabbithole.megaeth.com/fund), connect your wallet, and follow the prompts from the fiat onramp provider.

## Advanced: Direct Contract Bridge

{% hint style="warning" %}
This method is for advanced users only.
Most users should use the [Rabbithole bridge](https://rabbithole.megaeth.com/bridge) above.
{% endhint %}

MegaETH uses an OP Stack [Standard Bridge](https://docs.optimism.io/app-developers/guides/bridging/standard-bridge).
You can send ETH directly to the bridge contract on Ethereum Mainnet:

`0x0CA3A2FBC3D770b578223FBB6b062fa875a2eE75`

The same amount of ETH (minus Ethereum gas fees) will appear at your address on MegaETH after the Ethereum transaction is finalized.
For developer details on the bridge contract, see the [Developer Docs](../dev/getting-started.md).
