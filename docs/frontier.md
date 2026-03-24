---
title: Mainnet 
rank: 1
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

# Connecting to MegaETH Mainnet

## RPC

MegaETH hosts a public RPC endpoint at https://mainnet.megaeth.com/rpc.

See [Realtime API](/realtime-api.html) for a list of additional features on top
of the standard Ethereum JSON-RPC. These features are available on RPC
endpoints provided by MegaETH; availability varies on third-party endpoints.

## Block Explorer

[Blockscout](https://megaeth.blockscout.com/) and
[Etherscan](https://mega.etherscan.io) are available. 

# Developing Smart Contracts

MegaETH's execution environment is called _MegaEVM_. It is fully compatible
with Ethereum smart contracts but introduces a few differences compared to
Ethereum's EVM especially around the gas model. See the [MegaEVM manual
page](/megaevm.html) for a list of differences. Implementation of MegaEVM is
opensource and can be found on
[GitHub](https://github.com/megaeth-labs/mega-evm).

Because of the said differences, toolchains not yet customized for MegaETH
might incorrectly estimate the amount of gas a transaction needs if they use
their own EVM implementations, as opposed to MegaEVM, to locally simulate the
transaction. Sometimes, this issue causes the RPC to throw "intrinsic gas too
low" errors or the transaction to run out of gas and revert. The solution is to
either tell the toolchain to skip local gas estimation and use a hardcoded gas
limit (for `forge script`, as an example, `--gas-limit` with a sufficiently
large number plus `--skip-simulation`), or use MegaETH's RPC servers to
estimate gas.

_The best tool for debugging MegaETH transactions is `mega-evme`._ It uses the
aforementioned opensource implementation of MegaEVM and can thus perfectly
simulate any transaction's behavior on MegaETH. Instructions on building and
using `mega-evme` are available
[here](https://github.com/megaeth-labs/mega-evm/blob/main/bin/mega-evme/README.md).

# Using the Canonical Bridge

MegaETH's canonical bridge is the preferred method to bridge Ether (ETH) from Ethereum to MegaETH. The Ethereum side of the bridge is at
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

For more control, use the `depositETH` method of the bridge contract. It allows
for specifying the (approximate) amount of gas that should be charged by and
forwarded from Ethereum mainnet to MegaETH for the deposit transaction to use,
as well as adding extra data to the transaction. As an example, the following
`cast send` command calls `depositETH` to bridge 0.001 Ether with 61000 gas and
extra data `bunny`.

```bash
cast send 0x0CA3A2FBC3D770b578223FBB6b062fa875a2eE75 'depositETH(uint32, bytes)' 61000 "0x62756e6e79" --value 0.001ether
```

# Contracts of Potential Interest

## On MegaETH Mainnet

| Item | Address | Remarks |
| --------- | ------------- | ---------------------------- |
| MEGA Token | `0x28B7E77f82B25B95953825F1E3eA0E36c1c29861` | ERC20; 18 decimals. |
| WETH9 | `0x4200000000000000000000000000000000000006` | |
| Multicall3 | `0xcA11bde05977b3631167028862bE2a173976CA11` | | 
| USDM | `0xFAfDdbb3FC7688494971a79cc65DCa3EF82079E7` | |
<!--
| **High Resolution Timestamp** | `0x6342000000000000000000000000000000000002` | The function signature is `function timestamp() external view returns (uint256)` where the return value is timestamp in microseconds. |
-->

See OP Stack docs for a complete list of
[predeployed](https://docs.optimism.io/op-stack/protocol/smart-contracts#layer-2-contracts-predeploys) and
[preinstalled](https://docs.optimism.io/op-stack/features/preinstalls#contracts-and-deployed-addresses)
contracts.

See the [mega-tokenlist](https://github.com/megaeth-labs/mega-tokenlist) for a more comprehensive list of tokens in the ecosystem. 

## On Ethereum Mainnet

| Item | Address | Remarks |
| --------- | ------------- | ---------------------------- |
| DisputeGameFactoryProxy             | `0x8546840adf796875cd9aacc5b3b048f6b2c9d563` | |
| L1CrossDomainMessengerProxy         | `0x6C7198250087B29A8040eC63903Bc130f4831Cc9` | |
| L1ERC721BridgeProxy                 | `0x3D8ee269F87A7f3F0590c5C0d825FFF06212A242` | |
| L1StandardBridgeProxy               | `0x0CA3A2FBC3D770b578223FBB6b062fa875a2eE75` | |
| OptimismMintableERC20FactoryProxy   | `0xF875030B9464001fC0f964E47546b0AFEEbD7C61` | |
| OptimismPortalProxy                 | `0x7f82f57F0Dd546519324392e408b01fcC7D709e8` | |
| ProtocolVersionsProxy               | `0x150355311f965af4937fcca526f9df0573fd5b85` | |
| SuperchainConfigProxy               | `0x5d0ff601bc8580d8682c0462df55343cb0b99285` | |
| SystemConfigProxy                   | `0x1ED92E1bc9A2735216540EDdD0191144681cb77E` | |
| USDM                                | `0xEc2AF1C8B110a61fD9C3Fa6a554a031Ca9943926` | |

MegaETH's smart contracts are from OP Stack's [op-contracts/v3.0.0
release](https://github.com/ethereum-optimism/optimism/tree/backports/op-contracts/v3.0.0/packages/contracts-bedrock).
See OP Stack docs for [descriptions of these
contracts](https://docs.optimism.io/op-stack/protocol/smart-contracts#l1-contract-details).
