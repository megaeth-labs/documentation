---
description: Overview of developing on MegaETH — EVM compatibility, gas estimation, debugging, and bridging.
---

# Overview

MegaETH is fully compatible with Ethereum smart contracts.
Standard Solidity toolchains (Foundry, Hardhat, Remix) work out of the box.

For network parameters (chain ID, RPC URLs, block explorers), see [Connect to MegaETH](../user/connect.md).

## EVM Compatibility

MegaETH's execution environment is called **MegaEVM**.
It is fully compatible with Ethereum smart contracts but introduces a few differences compared to Ethereum's EVM, especially around the [dual gas model](https://docs.megaeth.com/spec/megaevm/dual-gas-model).
See [EVM Differences](execution/overview.md) for a complete list.

The MegaEVM implementation is open source and can be found on [GitHub](https://github.com/megaeth-labs/mega-evm).

## Gas Estimation

MegaETH's dual gas model means standard Ethereum toolchains may underestimate gas.
Always use a MegaETH RPC endpoint for gas estimation, or bypass local simulation entirely.
See [Gas Estimation](send-tx/gas-estimation.md) for code examples, toolchain configuration, and common pitfalls.

## Debugging Transactions

MegaETH supports `debug_traceTransaction` and other debug RPC methods (via managed RPC providers), and provides [`mega-evme`](https://docs.megaeth.com/mega-evme) for local transaction replay and simulation.
See [Debugging Transactions](send-tx/debugging.md) for usage examples and common debugging scenarios.

## Using the Canonical Bridge

MegaETH's canonical bridge is the preferred method to bridge Ether (ETH) from Ethereum to MegaETH.
The Ethereum side of the bridge is at `0x0CA3A2FBC3D770b578223FBB6b062fa875a2eE75` on Ethereum Mainnet.
Currently, it runs OP Stack's [Standard Bridge](https://docs.optimism.io/app-developers/guides/bridging/standard-bridge) in its [op-contracts/v3.0.0 release](https://github.com/ethereum-optimism/optimism/blob/backports/op-contracts/v3.0.0/packages/contracts-bedrock/src/universal/StandardBridge.sol) with a small patch adjusting a few parameters.

### Simple bridge (native transfer)

The easiest way to bridge Ether to MegaETH is sending Ether to the bridge address on Ethereum Mainnet in a plain native transfer.
The same amount of Ether sans gas fees will appear in sender's address on MegaETH after the transfer is finalized on Ethereum Mainnet.

### Advanced bridge (depositETH)

For more control, use the `depositETH` method of the bridge contract.
It allows for specifying the (approximate) amount of gas that should be charged by and forwarded from Ethereum Mainnet to MegaETH for the deposit transaction to use, as well as adding extra data to the transaction.

As an example, the following `cast send` command calls `depositETH` to bridge 0.001 Ether with 61000 gas and extra data `bunny`:

```bash
cast send 0x0CA3A2FBC3D770b578223FBB6b062fa875a2eE75 \
  'depositETH(uint32, bytes)' 61000 "0x62756e6e79" \
  --value 0.001ether
```

## L1 Contracts (Ethereum Mainnet)

See [Contracts & Tokens](send-tx/contracts.md#l1-contracts-ethereum) for all L1 contract addresses (bridge, DisputeGameFactory, OptimismPortal, SystemConfig, etc.).

## Next Steps

- [EVM Differences](execution/overview.md) — what's different from Ethereum
- [Gas Model](execution/gas-model.md) — how MegaETH's dual gas model works
- [System Contracts](execution/system-contracts.md) — oracle, timestamp, and other system contracts
- [RPC Reference](read/overview.md) — JSON-RPC methods and error codes
- [Realtime API](read/realtime-api.md) — WebSocket and real-time RPC extensions
