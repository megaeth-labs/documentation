---
description: MegaETH RPC endpoints, chain IDs, contract addresses, and connection details.
---

# Connect to the Network

## Network Parameters

{% tabs %}
{% tab title="Mainnet" %}
| Parameter | Value |
| --------- | ----- |
| **Network Name** | MegaETH |
| **Chain ID** | 4326 (0x10e6) |
| **Native & Gas Token** | Ether (ETH), 18 decimals |
| **RPC URL** | `https://mainnet.megaeth.com/rpc` |
| **Block Explorer** | [megaeth.blockscout.com](https://megaeth.blockscout.com/) / [mega.etherscan.io](https://mega.etherscan.io) |
| **Block Time** | Mini-blocks: 10ms / EVM blocks: 1s |
| **Block Gas Limit** | 10 billion (10¹⁰) gas per EVM block |
| **Base Fee Per Gas** | 0.001 gwei (10⁶ wei) |
| **EIP-1559** | Base fee adjustment is effectively disabled |
{% endtab %}

{% tab title="Testnet" %}
| Parameter | Value |
| --------- | ----- |
| **Network Name** | MegaETH Testnet |
| **Chain ID** | 6343 (0x18c7) |
| **Native & Gas Token** | Ether (ETH), 18 decimals |
| **RPC URL** | `https://carrot.megaeth.com/rpc` |
| **WebSocket URL** | `wss://carrot.megaeth.com/wss` |
| **Block Explorer** | [megaeth-testnet-v2.blockscout.com](https://megaeth-testnet-v2.blockscout.com/) |
| **Block Time** | Mini-blocks: 10ms / EVM blocks: 1s |
| **Block Gas Limit** | 10 billion (10¹⁰) gas per EVM block |
| **Base Fee Per Gas** | 0.001 gwei (10⁶ wei) |
| **EIP-1559** | Base fee adjustment is effectively disabled |
{% endtab %}
{% endtabs %}

{% hint style="info" %}
MegaETH supports enhanced real-time RPC features on its own endpoints.
See the [Realtime API](../dev/realtime-api.md) for details.
These features are available on RPC endpoints provided by MegaETH; availability varies on third-party endpoints.
{% endhint %}

## Contract Addresses

### On MegaETH Mainnet

| Contract | Address | Notes |
| -------- | ------- | ----- |
| MEGA Token | `0x28B7E77f82B25B95953825F1E3eA0E36c1c29861` | ERC20; 18 decimals |
| WETH9 | `0x4200000000000000000000000000000000000006` | |
| Multicall3 | `0xcA11bde05977b3631167028862bE2a173976CA11` | |
| USDM | `0xFAfDdbb3FC7688494971a79cc65DCa3EF82079E7` | |

See OP Stack docs for a complete list of [predeployed](https://docs.optimism.io/op-stack/protocol/smart-contracts#layer-2-contracts-predeploys) and [preinstalled](https://docs.optimism.io/op-stack/features/preinstalls#contracts-and-deployed-addresses) contracts.

See the [mega-tokenlist](https://github.com/megaeth-labs/mega-tokenlist) for a comprehensive list of tokens in the ecosystem.

### On Ethereum Mainnet

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
| USDM | `0xEc2AF1C8B110a61fD9C3Fa6a554a031Ca9943926` |

MegaETH's smart contracts are from OP Stack's [op-contracts/v3.0.0 release](https://github.com/ethereum-optimism/optimism/tree/backports/op-contracts/v3.0.0/packages/contracts-bedrock).
See OP Stack docs for [descriptions of these contracts](https://docs.optimism.io/op-stack/protocol/smart-contracts#l1-contract-details).
