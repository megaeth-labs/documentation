---
title: Overview
---

# MegaETH Testnet Documentation

## Testnet Notice

MegaETH is currently in **Testnet**, which means:

- **Onboarding Developers and Infrastructure Providers** → The initial phase of the Testnet focuses on onboarding developers and infrastructure providers. They are deploying on the Testnet and checking their integration. In the meantime, the public faucet is disabled.
- **RPC Endpoints Are Rate Limited And May Change** → Always check this page for the latest URLs and status.
- **Network Maintenance May Occur** → RPCs may go offline during upgrades. Contracts and states may be rolled back in rare cases.
- **Testnet Is Not Incentivized** → Testnet tokens and transactions have no real monetary value. _Everything happening on the chain is solely for experimental purposes._

## Fact Sheet

| Parameter | Value |
| --------- | ----- |
| **Network Name** | MegaETH Testnet |
| **Chain ID** | 6342 |
| **Network ID** | 6342 |
| **Native Token (Symbol)** | MegaETH Testnet Ether (ETH) |
| **Native Token Decimals** | 18 |
| **RPC HTTP URL** | https://carrot.megaeth.com/rpc |
| **Block Explorer** | Performance dashboard: [https://uptime.megaeth.com](https://uptime.megaeth.com) <br/> Community explorer: [https://megaexplorer.xyz](https://megaexplorer.xyz) |
| **EIP-1559 Parameters** | Base fee price target: 0.0025 Gwei<br/>Base fee price floor: 0.001 Gwei<br/>Max block size: 2 Giga gas<br/>Target block size: 50% (1 Giga gas) |
| **Block Time** | 10ms for mini blocks<br/>1s for EVM blocks |

## Next Steps

- **[Architecture](/architecture)** → Get an overview of MegaETH’s architecture.
- **[Realtime API](/realtime-api)** → MegaETH is compatible with Ethereum JSON-RPC API. To fully exploit the 10ms block time and build realtime experiences, it is necessary to use MegaETH’s Realtime API.
- **[Mini Blocks and EVM Blocks](/mini-blocks)** → Learn about the similarities and differences between the two types of blocks in MegaETH: mini blocks and EVM blocks.
- **[FAQ](/faq)** → Check out a list of frequently asked questions.

