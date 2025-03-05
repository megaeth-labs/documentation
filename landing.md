# MegaETH Technical Documentation 
# Testnet Notice

MegaETH is currently in **testnet**, which means:

- Transactions have no real monetary value.
- Testnet tokens are only for testing and experimentation purposes.
- There may be downtime, bugs, network resets, or changes to contract addresses.
- Specific implications are detailed on relevant pages.

For a deeper understanding of testnets and their role, see [Devnet vs Testnet vs Mainnet](https://www.notion.so/Devnet-vs-Testnet-vs-Mainnet-198ad4014d5380bb9c89c83de22a7c49?pvs=21) 

# Get Started

[**Use:**](https://hackmd.io/Tf3HIuIuTqGeRWAIdWN8_w) Learn how to interact with MegaETH, from setting up a wallet to making transactions and using dApps. 

**Develop:** Build on MegaETH with smart contracts, developer tools, frontend integration and more.

**Learn:** Explore the architecture, security and unique features that power MegaETH. 

**Research:** Dive into advanced topics like finality, sequencing, cryptographic security and the evolution of MegaETH

**Contribute:** Help improve MegaETH by reporting issues, contributing to docs or joining audits and security initiatives. 

[**Real-Timeness:**](https://www.megaeth.com/about) Unlock the full potential of MegaETH by understanding the key optimizations that enable ultra-low latency.

# At a glance

### Testnet Status: 🟢 Operational (Last updated: February 11, 2025, 14:00 UTC)

### Faucet Status:  ⚠️ **Depleted** (Next Refill: 00:00 UTC)

### Announcements:

**February 11, 2025: Improved `eth_subscribe` Granularity for State Updates**

**Key Details:**

- `eth_subscribe` now provides more **granular state updates**, reducing unnecessary data retrieval.
- Developers can expect **lower bandwidth usage** and improved **query efficiency** for real-time dApp interactions.
- No changes are required for existing integrations, but updating to leverage the new granularity is recommended.

**No developer action required**, but if you experience unexpected issues, please report them via our Bug Report Form.

### Next Reset:

- **Date:** February 20, 2025, 12:00 UTC (Scheduled network upgrade)
- **Estimated downtime:** ~ 3 hours
- **Key Changes:**
    - Implementation of enhanced gas estimation logic
    - Refinements to the bridge contract for better L1↔L2 messaging
- **Notices:**
    - Transactions submitted close to the reset may not be processed
    - Some RPC endpoints may be intermittently unavailable
    - Faucet will be unavailable during this window
- **Developer Action Required:**
    - Ensure any critical testnet operations are completed before maintenance begins.
    - Verify contract deployments and update dependencies post-reset

### Reset history:

- January 15, 2025 - Network reset due to protocol upgrade (Downtime: 104 minutes)
- December 10, 2024 - Testnet reset following security breach (Downtime: 54 minutes)
- [View Full Reset Log](https://www.notion.so/Reset-Log-198ad4014d5380f79980e118406b78ad?pvs=21)
