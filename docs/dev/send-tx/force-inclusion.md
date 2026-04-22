---
description: Force-include a transaction on MegaETH using Foundry (cast or forge) — step-by-step guide for scripted and automated submissions.
---

# Force Inclusion — Foundry

Force inclusion submits a transaction directly to the L1 OptimismPortal, bypassing the sequencer.
This page covers the scripted path using [Foundry](https://getfoundry.sh/).
For the Etherscan UI path, see [Force-include a transaction](../../user/force-inclusion.md).

## Contract addresses

{% tabs %}
{% tab title="Mainnet" %}

| Contract       | Chain              | Address                                      |
| -------------- | ------------------ | -------------------------------------------- |
| OptimismPortal | Ethereum (chain 1) | `0x7f82f57F0Dd546519324392e408b01fcC7D709e8` |

{% endtab %}
{% tab title="Testnet (Sepolia)" %}

| Contract       | Chain                             | Address                                      |
| -------------- | --------------------------------- | -------------------------------------------- |
| OptimismPortal | Ethereum Sepolia (chain 11155111) | `0xF68D900e1Cdec64a8f5Dc0Ee873A9E2879256b10` |

{% endtab %}
{% endtabs %}

## Step-by-step

Your L1 wallet address is preserved as the sender on MegaETH — so the same private key that holds tokens on MegaETH signs the L1 transaction.

{% stepper %}
{% step %}

### Set environment variables

```bash
export PRIVATE_KEY=0x...
export TOKEN=...        # ERC-20 contract address on MegaETH
export RECIPIENT=...    # address to receive the tokens
export AMOUNT=...       # amount in wei

# Testnet
export PORTAL=0xF68D900e1Cdec64a8f5Dc0Ee873A9E2879256b10
export L1_RPC=https://ethereum-sepolia-rpc.publicnode.com
export L2_RPC=https://carrot.megaeth.com/rpc  # see Connect page for all RPC options

# Mainnet
# export PORTAL=0x7f82f57F0Dd546519324392e408b01fcC7D709e8
# export L1_RPC=<your Ethereum mainnet RPC>
# export L2_RPC=https://mainnet.megaeth.com/rpc
```

{% endstep %}
{% step %}

### Check your L2 token balance

```bash
SENDER=$(cast wallet address --private-key $PRIVATE_KEY)
cast call $TOKEN "balanceOf(address)(uint256)" $SENDER --rpc-url $L2_RPC
```

{% endstep %}
{% step %}

### Estimate L2 gas

Always query the MegaETH L2 RPC — MegaETH's dual gas model (compute + storage) means standard Ethereum tooling underestimates.
Add 20% headroom to account for storage gas variance.

```bash
SENDER=$(cast wallet address --private-key $PRIVATE_KEY)

GAS_EST=$(cast estimate $TOKEN \
  "transfer(address,uint256)" $RECIPIENT $AMOUNT \
  --from $SENDER \
  --rpc-url $L2_RPC)

export GAS_LIMIT=$(( GAS_EST * 120 / 100 ))
echo "estimate: $GAS_EST   limit: $GAS_LIMIT"
```

For a standard ERC-20 `transfer()` on MegaETH the estimate is approximately 54,000 gas; a limit of 65,000 is sufficient.

{% hint style="warning" %}
The portal enforces a minimum `_gasLimit` based on calldata length (~26,500 for a `transfer()` call).
Values below the minimum revert with `SmallGasLimit`.
{% endhint %}

{% endstep %}
{% step %}

### Encode the calldata

The `_data` field passed to `depositTransaction` is the function call you want to execute on L2, serialized into bytes (ABI-encoded).
Use `cast calldata` to produce it:

```bash
CALLDATA=$(cast calldata "transfer(address,uint256)" $RECIPIENT $AMOUNT)
echo $CALLDATA
```

Example output:

```
0xa9059cbb000000000000000000000000<recipient>0000000000000000000000000000000000000000000000000de0b6b3a7640000
```

The first 4 bytes (`0xa9059cbb`) are the `transfer` function selector.
The remaining 64 bytes are the ABI-encoded `recipient` address and `amount`.

For a plain ETH transfer with no contract call, set `_data` to `0x` and skip this step.

{% endstep %}
{% step %}

### Submit depositTransaction on L1

{% tabs %}
{% tab title="cast" %}

```bash
cast send $PORTAL \
  "depositTransaction(address,uint256,uint64,bool,bytes)" \
  $TOKEN \
  0 \
  $GAS_LIMIT \
  false \
  $CALLDATA \
  --value 0 \
  --rpc-url $L1_RPC \
  --private-key $PRIVATE_KEY
```

{% endtab %}
{% tab title="forge script" %}

Create `script/ForceInclude.s.sol`:

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.25;

import {Script} from "forge-std/Script.sol";

interface IOptimismPortal {
    function depositTransaction(
        address _to, uint256 _value, uint64 _gasLimit,
        bool _isCreation, bytes calldata _data
    ) external payable;
}

contract ForceInclude is Script {
    function run() external {
        address portal    = vm.envAddress("PORTAL");
        address token     = vm.envAddress("TOKEN");
        address recipient = vm.envAddress("RECIPIENT");
        uint256 amount    = vm.envUint("AMOUNT");
        uint64  gasLimit  = uint64(vm.envUint("GAS_LIMIT"));

        bytes memory data = abi.encodeWithSignature(
            "transfer(address,uint256)", recipient, amount
        );

        vm.startBroadcast();
        IOptimismPortal(portal).depositTransaction(
            token, 0, gasLimit, false, data
        );
        vm.stopBroadcast();
    }
}
```

```bash
forge script script/ForceInclude.s.sol \
  --rpc-url $L1_RPC \
  --broadcast \
  --private-key $PRIVATE_KEY
```

{% endtab %}
{% endtabs %}

The call emits a `TransactionDeposited` event on L1.
Save the transaction hash to track the deposit.

{% endstep %}
{% step %}

### Verify on L2

After 5–20 minutes, confirm the recipient's balance increased.

```bash
cast call $TOKEN "balanceOf(address)(uint256)" $RECIPIENT --rpc-url $L2_RPC
```

{% endstep %}
{% endstepper %}

## How it works

1. `depositTransaction` emits `TransactionDeposited(address indexed from, address indexed to, uint256 indexed version, bytes opaqueData)` on L1.
2. MegaETH watches for these events and converts each one into a deposited transaction (type `0x7E`) to execute on L2.
3. The deposited transaction runs on L2 with your L1 wallet address as the sender (no address transformation is applied for regular wallets).
4. `_gasLimit` caps L2 execution gas. If unused, it is not refunded, but no ETH is charged on L1 for it — only the standard Ethereum gas fee for calling `depositTransaction` applies.
5. Setting `_value` forwards ETH to `_to`; it must equal `msg.value`.

For the formal deposit specification, see [Deposits](https://specs.optimism.io/protocol/deposits.html) in the OP Stack spec.
