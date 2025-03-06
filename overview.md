---
title: Overview
---

# MegaETH Testnet Overview

##  Testnet Notice

MegaETH is currently in **Testnet**, which means:

- **Onboarding Developers and Infrastructure Providers** → The initial phase of the Testnet focuses on onboarding developers and infrastructure providers. They are deploying on the Testnet and checking their integration. In the meantime, the public faucet is disabled. 
- **RPC Endpoints Are Rate Limited And May Change** → Always check this page for the latest URLs and status.
- **Network Maintenance May Occur** → RPCs may go offline during upgrades. Contracts and states may be rolled back in rare cases.
- **Testnet Is Not Incentivized** → Testnet tokens and transactions have no real monetary value. *Everything happening on the chain is solely for experimental purposes.*

## Fact Sheet
| Parameter | Value | 
| --------         | --------    | 
| **Network Name**     | MegaETH Testnet     | 
| **Chain ID**       | 6342        |
| **Network ID** | 6342 |
| **Native Token (Symbol)** | MegaETH Testnet Ether (ETH)|
| **Native Token Decimals** | 18 |
| **RPC HTTP URL**     | [https://carrot.megaeth.com/rpc](https://carrot.megaeth.com/rpc) |
| **RPC WebSocket URL** | wss://carrot.megaeth.com/ws |
| **Block Explorer** | Performance Dashboard: [https://uptime.megaeth.com](https://uptime.megaeth.com) <br/> Community Explorer: [https://megaexplorer.xyz](https://megaexplorer.xyz) <!-- <br/> OKX Explorer: https://www.okx.com/web3/explorer/megaeth-testnet --> |
| **Experimental EIPs Supported** | EIP-7702 |
| **EIP-1559 Base Fee Price** | 0.0025 Gwei |
| **EIP-1559 Max Block Size** | 2 Giga gas |
| **EIP-1559 Target Block Size** | 50% (1 Giga gas) |
| **Block Time** | 10ms for mini blocks<br/>1s for EVM blocks |

## Next Steps

- **[Architecture](/architecture.html)** → Get an overview of MegaETH’s architecture.
- **[Realtime API](/realtime-api.html)** → MegaETH is compatible with Ethereum JSON-RPC API. To fully exploit the 10ms block time and build realtime experiences, it is necessary to use MegaETH’s Realtime API.
- **[Mini Blocks and EVM Blocks](/mini-and-evm-blocks.html)** → Learn about the similarities and differences between the two types of blocks in MegaETH: mini blocks and EVM blocks.
