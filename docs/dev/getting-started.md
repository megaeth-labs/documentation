---
description: Start building smart contracts and dapps on MegaETH.
---

# Getting Started

MegaETH is fully compatible with Ethereum smart contracts.
Standard Solidity toolchains (Foundry, Hardhat, Remix) work out of the box.

## Connect to MegaETH

| Parameter | Mainnet | Testnet |
| --------- | ------- | ------- |
| **Chain ID** | 4326 (0x10e6) | 6343 (0x18c7) |
| **RPC URL** | `https://mainnet.megaeth.com/rpc` | `https://carrot.megaeth.com/rpc` |
| **Currency** | ETH | ETH |
| **Block Explorer** | [megaeth.blockscout.com](https://megaeth.blockscout.com/) | [megaeth-testnet-v2.blockscout.com](https://megaeth-testnet-v2.blockscout.com/) |

A second block explorer is also available for mainnet: [Etherscan](https://mega.etherscan.io).

## EVM Compatibility

MegaETH's execution environment is called **MegaEVM**.
It is fully compatible with Ethereum smart contracts but introduces a few differences compared to Ethereum's EVM, especially around the gas model.
See [EVM Differences](evm-differences.md) for a complete list.

The MegaEVM implementation is open source and can be found on [GitHub](https://github.com/megaeth-labs/mega-evm).

## Gas Estimation

{% hint style="warning" %}
Toolchains not yet customized for MegaETH might incorrectly estimate the amount of gas a transaction needs if they use their own EVM implementations, as opposed to MegaEVM, to locally simulate the transaction.
Sometimes, this issue causes the RPC to throw "intrinsic gas too low" errors or the transaction to run out of gas and revert.
{% endhint %}

**Two solutions:**

{% tabs %}
{% tab title="Use MegaETH RPC for estimation" %}
Point your toolchain at a MegaETH RPC endpoint and let it call `eth_estimateGas` remotely.
This is the recommended approach — it uses MegaEVM and gives accurate results.
{% endtab %}

{% tab title="Skip local simulation (Foundry)" %}
For `forge script`, bypass local estimation with a hardcoded gas limit:

```bash
forge script MyScript --gas-limit 30000000 --skip-simulation --rpc-url https://mainnet.megaeth.com/rpc
```

Use `--gas-limit` with a sufficiently large number plus `--skip-simulation`.
{% endtab %}
{% endtabs %}

## Debugging Transactions

The best tool for debugging MegaETH transactions is **`mega-evme`**.
It uses the open-source MegaEVM implementation and can thus perfectly simulate any transaction's behavior on MegaETH.

Instructions on building and using `mega-evme` are available in the [mega-evme README](https://github.com/megaeth-labs/mega-evm/blob/main/bin/mega-evme/README.md).

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

MegaETH's smart contracts are from OP Stack's [op-contracts/v3.0.0 release](https://github.com/ethereum-optimism/optimism/tree/backports/op-contracts/v3.0.0/packages/contracts-bedrock).
See OP Stack docs for [descriptions of these contracts](https://docs.optimism.io/op-stack/protocol/smart-contracts#l1-contract-details).

| Contract | Address |
| -------- | ------- |
| DisputeGameFactoryProxy | `0x8546840adf796875cd9aacc5b3b048f6b2c9d563` |
| L1CrossDomainMessengerProxy | `0x6C7198250087B29A8040eC63903Bc130f4831Cc9` |
| L1ERC721BridgeProxy | `0x3D8ee269F87A7f3F0590c5C0d825FFF06212A242` |
| L1StandardBridgeProxy | `0x0CA3A2FBC3D770b578223FBB6b062fa875a2eE75` |
| OptimismMintableERC20FactoryProxy | `0xF875030B9464001fC0f964E47546b0AFEEbD7C61` |
| OptimismPortalProxy | `0x7f82f57F0Dd546519324392e408b01fcC7D709e8` |
| ProtocolVersionsProxy | `0x150355311f965af4937fcca526f9df0573fd5b85` |
| SuperchainConfigProxy | `0x5d0ff601bc8580d8682c0462df55343cb0b99285` |
| SystemConfigProxy | `0x1ED92E1bc9A2735216540EDdD0191144681cb77E` |

## Next Steps

- [EVM Differences](evm-differences.md) — what's different from Ethereum
- [Gas Model](gas-model.md) — how MegaETH's dual gas model works
- [System Contracts](system-contracts.md) — oracle, timestamp, and other system contracts
- [RPC Reference](rpc/README.md) — JSON-RPC methods and error codes
- [Realtime API](realtime-api.md) — WebSocket and real-time RPC extensions
