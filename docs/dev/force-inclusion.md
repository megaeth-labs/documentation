---
description: How to force-include a transaction on MegaETH using cast or forge, by calling depositTransaction on the L1 OptimismPortal.
---

# Force-include a transaction

Force inclusion submits a transaction directly to the L1 OptimismPortal, bypassing the sequencer.
The MegaETH derivation pipeline converts the resulting `TransactionDeposited` event into a type-`0x7E` deposited transaction and executes it on L2 within the sequencing window — 12 hours maximum, 1–2 minutes under normal operation.

For a UI-based walkthrough using Etherscan, see [Force-Include a Transaction](../user/force-inclusion.md).

## How it works

1. You call `depositTransaction` on the L1 OptimismPortal with the target L2 address, ETH value, gas limit, and calldata.
2. The portal emits `TransactionDeposited(address indexed from, address indexed to, uint256 indexed version, bytes opaqueData)`.
3. The MegaETH derivation pipeline derives an L2 transaction from the event.
4. The L2 transaction executes with `msg.sender` equal to the L1 sender — no aliasing applies for EOA callers.
5. Gas is pre-paid via `_gasLimit`; unused gas is not refunded.

## Function signature

```solidity
function depositTransaction(
    address _to,         // L2 target address
    uint256 _value,      // ETH forwarded to _to on L2; must equal msg.value
    uint64  _gasLimit,   // L2 execution gas budget (pre-paid, non-refundable)
    bool    _isCreation, // true only for CREATE deployments
    bytes   calldata _data
) external payable
```

## Prerequisites

- [Foundry](https://getfoundry.sh/) (`cast` and `forge`)
- ETH on L1 (Ethereum Mainnet or Sepolia) to pay the `depositTransaction` gas fee (~94 000 gas)
- The ERC-20 tokens to transfer must be at your address on MegaETH L2 — the same private key controls both sides since EOA addresses are not aliased

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

## Steps

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
export L2_RPC=https://carrot.megaeth.com/rpc

# Mainnet
# export PORTAL=0x7f82f57F0Dd546519324392e408b01fcC7D709e8
# export L1_RPC=<your Ethereum mainnet RPC>
# export L2_RPC=https://mainnet.megaeth.com/rpc
```

{% endstep %}
{% step %}

### Check your L2 token balance

The L1 sender address is the `msg.sender` on L2, so the same key that signs the L1 transaction must hold the tokens.

```bash
SENDER=$(cast wallet address --private-key $PRIVATE_KEY)
cast call $TOKEN "balanceOf(address)(uint256)" $SENDER --rpc-url $L2_RPC
```

{% endstep %}
{% step %}

### Estimate L2 gas

Always query the MegaETH L2 RPC for gas estimation — MegaETH's dual gas model (compute + storage) means standard Ethereum tooling underestimates.
Add 20% headroom to the estimate to account for storage gas variance.

```bash
SENDER=$(cast wallet address --private-key $PRIVATE_KEY)

GAS_EST=$(cast estimate $TOKEN \
  "transfer(address,uint256)" $RECIPIENT $AMOUNT \
  --from $SENDER \
  --rpc-url $L2_RPC)

GAS_LIMIT=$(( GAS_EST * 120 / 100 ))
echo "estimate: $GAS_EST   limit: $GAS_LIMIT"
```

For a standard ERC-20 `transfer()` on MegaETH the estimate is approximately 54 000 gas; a limit of 65 000 is sufficient.

{% hint style="warning" %}
The portal enforces a minimum `_gasLimit` derived from the calldata length.
For a `transfer()` call the minimum is around 26 500.
Passing a value below the minimum reverts with `SmallGasLimit`.
{% endhint %}

See [Gas Estimation](send-tx/gas-estimation.md) for more on MegaETH's dual gas model.

{% endstep %}
{% step %}

### Submit depositTransaction on L1

{% tabs %}
{% tab title="cast" %}

```bash
CALLDATA=$(cast calldata "transfer(address,uint256)" $RECIPIENT $AMOUNT)

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

Run it:

```bash
export GAS_LIMIT=$GAS_LIMIT

forge script script/ForceInclude.s.sol \
  --rpc-url $L1_RPC \
  --broadcast \
  --private-key $PRIVATE_KEY
```

{% endtab %}
{% endtabs %}

The call emits a `TransactionDeposited` event on L1.
Save the transaction hash — you can use it to track the deposit on the block explorer.

{% endstep %}
{% step %}

### Verify on L2

After 1–2 minutes, confirm the recipient's balance increased on MegaETH.

```bash
cast call $TOKEN "balanceOf(address)(uint256)" $RECIPIENT --rpc-url $L2_RPC
```

You can also search by your L1 transaction hash on the block explorer:

- **Mainnet:** [megaeth.blockscout.com](https://megaeth.blockscout.com)
- **Testnet:** [megaeth-testnet-v2.blockscout.com](https://megaeth-testnet-v2.blockscout.com)

{% endstep %}
{% endstepper %}

## Key values

| Field              | Value / rule                                                                                               |
| ------------------ | ---------------------------------------------------------------------------------------------------------- |
| `_to`              | The L2 contract or address to call — the ERC-20 address, not the token recipient                           |
| `_value`           | ETH to forward to `_to`; set to `0` for token-only calls; must equal `msg.value`                           |
| `_gasLimit`        | L2 execution budget; pre-paid on L1, non-refundable; must exceed portal minimum (~26 500 for `transfer()`) |
| `_isCreation`      | `false` for calls; `true` only when deploying a contract via CREATE                                        |
| `_data`            | ABI-encoded calldata for the L2 call                                                                       |
| `msg.sender` on L2 | Same as L1 sender for EOA callers — no address aliasing                                                    |

For the full deposit specification, see [Deposits](https://specs.optimism.io/protocol/deposits.html) in the OP Stack spec.
