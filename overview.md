# Network Overview

##  Testnet Notice

MegaETH is currently in **testnet**, which means the following for Network usage:
- **RPC Endpoints Are Rate Limited And May Change** → Always check this page for the latest URLs.
- **Network Maintenance May Occur** → RPCs may go offline during upgrades. Contracts and states may be reset. Refer to [At a Glance](https://hackmd.io/KPnLpDE6RViLDhFG411HEw#At-a-glance) for annoucements and updates. 
<!-- -  **Mainnet Will Have Different RPCs** → The testnet and mainnet are separate, with **mainnet launching with a clean state**.
- **Testnet & Mainnet Will Coexist** → The testnet will continue running after mainnet launch.-->


**To learn more about the implications of being on testnet and our rollout roadmap, see [Network Phases](https://hackmd.io/zTV7ghoXRqWLLT8W5UN9BQ#Network-Phases).**


## Network Specifications & RPC Endpoints 
| Parameter | Value | 
| --------         | --------    | 
| **Network Name**     | MegaETH Testnet     | 
| **Chain ID**       | 6342        |
| **Network ID** | 6342 |
| **Native Currency (Symbol)** | MegaETH Testnet Ether (ETH)|
| **RPC HTTP URL**     |https://carrot.megaeth.com/rpc |
| **RPC WebSocket URL** | wss://carrot.megaeth.com/ws |
| **Block Explorer** | Performance Dashboard: https://uptime.megaeth.com <br/> Community Explorer: https://megaexplorer.xyz |
<!--| **Block-Explorer** | https://www.okx.com/web3/explorer/megaeth-testnet |-->

Refer to the [Verify RPC Connection](https://hackmd.io/QixSQRWsRv6PlpkQ3WMKDA#Verify-RPC-Connection) to make sure everything is up and running correctly!

## EIP-1559 Parameters 
| **Parameter**   | **Value** |
|---------------|----------|
| **Base Fee Price** | 0.0025 Gwei |
| **Max Block Size** | 2 Giga gas |
| **Target Block Size** | 50% (1 Giga gas) |
<!--
| **Sequencing Model** | FIFO |

**FIFO Sequencing on Day 1**
- Transactions are **processed strictly in order of arrival**.
- There is **no priority fee** or bidding mechanism.
- No **MEV-based transaction reordering**.-->


## Essential References 

For additional details on MegaETH network functionality, refer to:
- **[JSON RPC API](../fees)** → To get low latency (10ms block time), you will need to use the low-latency WebSocket RPCs that we added.
- **[Mini Blocks And EVM Blocks]()** → Learn difference between the two types of blocks MegaETH uses.
- **[Faucet](../fees)** → Get Testnet ETH now. 
<!-- - **[Bridging Assets](../bridging)** → Move assets between MegaETH and other networks.-->
<!-- - **[Block Explorers](../explorers)** → Track transactions, smart contracts, and block data.-->
<!-- - **[Account Abstraction](../account-abstraction)** → Use smart contract wallets & ERC-4337/7702.-->
<!-- - **[Gas & Fee Structure](../fees)** → Learn how gas fees are calculated and optimized.-->
<!-- - **[Indexers](../indexers)** → Query blockchain data efficiently.-->
<!-- - **[Oracles](../oracles)** → Integrate off-chain data into your smart contracts.-->

Click the links above for **detailed guides** on each topic.


<div style="display: flex; justify-content: flex-end; margin-top: 40px;">
  <a href="https://hackmd.io/Tf3HIuIuTqGeRWAIdWN8_w#Set-Up-and-Connect-a-Wallet" 
     style="padding: 20px 40px; font-size: 16px; font-weight: bold; border: 1px solid #ddd; text-decoration: none; border-radius: 10px; display: inline-block; text-align: right; width: 350px; color: black;">
    <span style="font-size: 14px; color: #6c757d;">Next</span><br>
    <span style="font-size: 18px; color: #5c3cff;">Setup and Connect a Wallet »</span>
  </a>
</div>

