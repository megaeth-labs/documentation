---
description: How to deploy and bridge an ERC-20 token from Ethereum to MegaETH using the OP Stack Standard Bridge.
---

# Bridge ERC-20 Tokens

MegaETH's canonical bridge supports ERC-20 token bridging via the OP Stack [Standard Bridge](https://docs.optimism.io/app-developers/guides/bridging/standard-bridge).
Bridging locks tokens in the `L1StandardBridge` on Ethereum and mints a paired `OptimismMintableERC20` on MegaETH.

## Prerequisites

- [Foundry](https://getfoundry.sh/) installed (`forge` and `cast`)
- A wallet funded with ETH on both L1 (for deployment and bridging gas) and L2 (for registration gas)
- An ERC-20 contract ready to deploy, or an existing L1 token address

## Contract Addresses

{% tabs %}
{% tab title="Mainnet" %}
| Contract | Chain | Address |
| -------- | ----- | ------- |
| L1StandardBridge | Ethereum (chain 1) | `0x0CA3A2FBC3D770b578223FBB6b062fa875a2eE75` |
| OptimismMintableERC20Factory | Ethereum (chain 1) | `0x0B3004b843dA84FE5D4C46AeB5E80F826e5CD69A` |
| L2StandardBridge | MegaETH Mainnet (chain 4326) | `0x4200000000000000000000000000000000000010` |
| OptimismMintableERC20Factory | MegaETH Mainnet (chain 4326) | `0x4200000000000000000000000000000000000012` |
{% endtab %}
{% tab title="Testnet (Sepolia)" %}
| Contract | Chain | Address |
| -------- | ----- | ------- |
| L1StandardBridge | Ethereum Sepolia (chain 11155111) | `0x8033d50c753b3f19748f239ac8cf915b2888cd32` |
| OptimismMintableERC20Factory | Ethereum Sepolia (chain 11155111) | `0x11f008caa3083aa8a3b6f9f06f923e98a28fa286` |
| L2StandardBridge | MegaETH Testnet (chain 6343) | `0x4200000000000000000000000000000000000010` |
| OptimismMintableERC20Factory | MegaETH Testnet (chain 6343) | `0x4200000000000000000000000000000000000012` |
{% endtab %}
{% endtabs %}

## Steps

{% stepper %}
{% step %}

### Deploy your ERC-20 on L1

Deploy your token contract on Ethereum (or Sepolia for testing).
The example below uses a Foundry script; adapt it for your own token.

```bash
forge script script/Deploy.s.sol \
  --rpc-url $L1_RPC \
  --broadcast \
  --private-key $PRIVATE_KEY
```

Save the deployed token address — you will need it in the next step.

{% endstep %}
{% step %}

### Register the L2 counterpart

Call `createOptimismMintableERC20` on the `OptimismMintableERC20Factory` **on MegaETH**.
This deploys a bridgeable ERC-20 on L2 that is linked to your L1 token.

```bash
cast send $L2_MINTABLE_FACTORY \
  "createOptimismMintableERC20(address,string,string)" \
  $L1_TOKEN "MyToken" "MTK" \       # use your token's name and symbol
  --rpc-url $L2_RPC \
  --private-key $PRIVATE_KEY
```

The factory emits an `OptimismMintableERC20Created(address indexed localToken, address indexed remoteToken, address deployer)` event.
Parse the `localToken` field from the receipt to get your L2 token address.

```bash
# Extract the L2 token address from the event logs
cast receipt $TX_HASH --rpc-url $L2_RPC --json \
  | jq '.logs[] | select(.topics[0] == "0x52fe89dd5930f343d25650b62fd367bae47ef185") | .topics[1]'
```

{% endstep %}
{% step %}

### Approve the L1 bridge

Approve `L1StandardBridge` to spend the tokens you want to bridge.

```bash
cast send $L1_TOKEN \
  "approve(address,uint256)" \
  $L1_BRIDGE $AMOUNT \              # amount in wei, e.g. 100ether = 100000000000000000000
  --rpc-url $L1_RPC \
  --private-key $PRIVATE_KEY
```

{% endstep %}
{% step %}

### Bridge tokens to MegaETH

Call `bridgeERC20` on `L1StandardBridge`.
Pass both the L1 and L2 token addresses, the amount in wei, and a gas limit for L2 execution.

```bash
cast send $L1_BRIDGE \
  "bridgeERC20(address,address,uint256,uint32,bytes)" \
  $L1_TOKEN \                       # your L1 token
  $L2_TOKEN \                       # your registered L2 token
  $AMOUNT \                         # amount in wei
  200000 \                          # minGasLimit — 200 000 is sufficient for most tokens
  0x \                              # extraData — empty
  --rpc-url $L1_RPC \
  --private-key $PRIVATE_KEY
```

The bridge transaction locks tokens on L1 and relays a message to MegaETH to mint the equivalent amount on L2.

{% endstep %}
{% step %}

### Verify the L2 balance

After the L1 transaction is finalized and relayed (~1–2 minutes), check the balance on MegaETH.

```bash
cast call $L2_TOKEN \
  "balanceOf(address)(uint256)" \
  $(cast wallet address --private-key $PRIVATE_KEY) \
  --rpc-url $L2_RPC
```

{% hint style="info" %}
The deposit takes approximately 1–2 minutes to appear on MegaETH — one L1 block for finality, plus sequencer relay time.
You can track the L1 transaction on [Etherscan](https://etherscan.io) (mainnet) or [Sepolia Etherscan](https://sepolia.etherscan.io) (testnet), and the L2 deposit on [MegaETH Blockscout](https://megaeth.blockscout.com) (mainnet) or the [testnet explorer](https://megaeth-testnet-v2.blockscout.com).
{% endhint %}

{% endstep %}
{% endstepper %}

## Withdrawals (L2 → L1)

Withdrawing tokens back to Ethereum requires initiating a withdrawal on L2 and then proving and finalizing it on L1 after the challenge period.
This follows the standard OP Stack withdrawal flow — see the [OP Stack withdrawal guide](https://docs.optimism.io/app-developers/guides/bridging/standard-bridge#withdrawing-erc-20-tokens) for details.
