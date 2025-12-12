---
title: Frontier
rank: 1
---

# A Very Important Message

__Access to Frontier is permissioned.__

__Please refrain from sharing your private RPC
endpoints or your whitelisted wallets!__

---

# Chain Parameters

| Item | Value |
| ----- | ------------- |
| __Chain ID__ | 4326 (0x10e6) |
| __Native & Gas Token__ | Ether (ETH), 18 decimals |
| __Block Time__ | Mini blocks: 10ms<br/>EVM blocks: 1s |
| __Block Gas Limit__ | 10 billion ($$10^10$$) gas per EVM block |
| __Base Fee Per Gas__ | 0.001 gwei ($$10^6$$ wei) |
| __EIP-1559 Parameters__ | Base fee adjustment is effectively disabled |

# Connecting to Frontier

## RPC

Contact the team for a private endpoint. Alchemy and Quicknode sell managed endpoints.

See [Realtime API](/realtime-api.html) for a list of additional features on top
of the standard Ethereum JSON-RPC. These features are available on RPC
endpoints provided by MegaETH; availability varies on third-party endpoints.

## Block Explorer

[Blockscout](https://user:Mpp0gRdftB1ynLMbmLUg@megaeth-testnet-v3.blockscout.com/)
is available. For the time being, its frontend and URL are dubbed "testnet-v3"
instead of "mainnet" for confidentiality, but it is indeed for Frontier.

Etherscan is integrating.

# Developing Smart Contracts

MegaETH is fully compatible with Ethereum smart contracts but there are a few
differences between MegaETH and Ethereum especially around the gas model. See
[MegaEVM](/megaevm.html) for a complete list of differences.

Because of the said differences, existing toolchains might incorrectly estimate
the amount of gas a transaction needs if they use their own EVM implementations
to locally simulate the transaction. Sometimes, this issue causes the RPC to
throw "intrinsic gas too low" errors or the transaction to run out of gas and
revert. The solution is to either tell the toolchain to skip local gas
estimation and use a hardcoded gas limit (for `forge script`, as an example,
`--gas-limit` with a sufficiently large number plus `--skip-simulation`), or
use MegaETH's RPC servers to estimate gas. See [MegaEVM](/megaevm.html) for
more details.

# Using the Canonical Bridge

MegaETH's canonical bridge is the preferred method to bridge Ether (ETH) and
ERC20 tokens from Ethereum to MegaETH. The Ethereum side of the bridge is at
`0x0CA3A2FBC3D770b578223FBB6b062fa875a2eE75` on Ethereum mainnet. Currently, it
runs OP Stack's [Standard
Bridge](https://docs.optimism.io/app-developers/guides/bridging/standard-bridge)
in its [op-contracts/v3.0.0
release](https://github.com/ethereum-optimism/optimism/blob/backports/op-contracts/v3.0.0/packages/contracts-bedrock/src/universal/StandardBridge.sol)
with a small patch adjusting a few parameters.

The easiest way to bridge Ether to MegaETH is sending Ether to the
aforementioned address on Ethereum mainnet in a plain native transfer. The same
amount of Ether sans gas fees will appear in sender's address on MegaETH after
the transfer is finalized on Ethereum mainnet.

# Running a Node

Please reach out to the team.

# Contracts of Potential Interest

## On MegaETH Mainnet (Frontier)

| Item | Address | Remarks |
| --------- | ------------- | ---------------------------- |
| MEGA Token | `0x28B7E77f82B25B95953825F1E3eA0E36c1c29861` | ERC20; 18 decimals. |
| WETH9 | `0x4200000000000000000000000000000000000006` | |
| Multicall3 | `0xcA11bde05977b3631167028862bE2a173976CA11` | | 
<!--
| **High Resolution Timestamp** | `0x6342000000000000000000000000000000000002` | The function signature is `function timestamp() external view returns (uint256)` where the return value is timestamp in microseconds. |
-->

See OP Stack docs for a complete list of
[predeployed](https://docs.optimism.io/op-stack/protocol/smart-contracts#layer-2-contracts-predeploys) and
[preinstalled](https://docs.optimism.io/op-stack/features/preinstalls#contracts-and-deployed-addresses)
contracts.

## On Ethereum Mainnet

| Item | Address | Remarks |
| --------- | ------------- | ---------------------------- |
| L1CrossDomainMessengerProxy         | `0x6C7198250087B29A8040eC63903Bc130f4831Cc9` | |
| L1ERC721BridgeProxy                 | `0x3D8ee269F87A7f3F0590c5C0d825FFF06212A242` | |
| L1StandardBridgeProxy               | `0x0CA3A2FBC3D770b578223FBB6b062fa875a2eE75` | |
| OptimismPortalProxy                 | `0x7f82f57F0Dd546519324392e408b01fcC7D709e8` | |
| OptimismMintableERC20FactoryProxy   | `0xF875030B9464001fC0f964E47546b0AFEEbD7C61` | |
| SystemConfigProxy                   | `0x1ED92E1bc9A2735216540EDdD0191144681cb77E` | |

MegaETH's smart contracts are from OP Stack's [op-contracts/v3.0.0
release](https://github.com/ethereum-optimism/optimism/tree/backports/op-contracts/v3.0.0/packages/contracts-bedrock).
See OP Stack docs for [descriptions of these
contracts](https://docs.optimism.io/op-stack/protocol/smart-contracts#l1-contract-details).
