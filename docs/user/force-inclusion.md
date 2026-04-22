---
description: How to force-include a transaction on MegaETH by submitting it directly to Ethereum, bypassing the sequencer — using Etherscan, cast, or forge.
---

# Force-include a transaction

Force inclusion submits a transaction directly to the L1 OptimismPortal, bypassing the sequencer.
Once submitted on Ethereum, MegaETH is required to include it on L2 within 12 hours.
Under normal conditions it lands in about 1–2 minutes.

{% hint style="warning" %}
This is an advanced operation.
For routine transactions, submit normally through your wallet or RPC.
{% endhint %}

## When to use

- The sequencer is offline and your transaction cannot get through.
- A transaction is being consistently ignored despite sufficient gas.
- You need a censorship-resistance guarantee for a high-stakes action.

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

## Using Etherscan

The easiest way to submit a force-inclusion transaction without any tooling.
You need a browser wallet (MetaMask, Rabby, etc.) funded with ETH on Ethereum Mainnet or Sepolia.

{% stepper %}
{% step %}

### Open OptimismPortal on Etherscan

Go to the OptimismPortal contract for your network and open the **Write as Proxy** tab:

- **Mainnet:** [0x7f82f57F0Dd546519324392e408b01fcC7D709e8](https://etherscan.io/address/0x7f82f57F0Dd546519324392e408b01fcC7D709e8#writeProxyContract) on Etherscan
- **Testnet (Sepolia):** [0xF68D900e1Cdec64a8f5Dc0Ee873A9E2879256b10](https://sepolia.etherscan.io/address/0xF68D900e1Cdec64a8f5Dc0Ee873A9E2879256b10#writeProxyContract) on Sepolia Etherscan

{% endstep %}
{% step %}

### Connect your wallet

Click **Connect to Web3** and approve the connection.
Make sure your wallet is set to the correct network — Ethereum Mainnet for production, Sepolia for testnet.

{% endstep %}
{% step %}

### Fill in the depositTransaction fields

Scroll to **depositTransaction** in the list and expand it.
Fill in the six fields:

| Field                 | What to enter                                                                                                               |
| --------------------- | --------------------------------------------------------------------------------------------------------------------------- |
| `payableAmount (ETH)` | ETH to send to MegaETH (e.g. `0.001`). Enter `0` for contract calls with no ETH attached.                                   |
| `_to (address)`       | The destination address on MegaETH — your wallet address for a plain ETH transfer, or a contract address for a call.        |
| `_value (uint256)`    | Same as `payableAmount` in wei. For 0.001 ETH enter `1000000000000000`. Enter `0` if sending no ETH.                        |
| `_gasLimit (uint64)`  | Gas budget for L2 execution. Use `100000` for a plain ETH transfer; see the cast section below for contract call estimates. |
| `_isCreation (bool)`  | `false` unless you are deploying a new contract on MegaETH.                                                                 |
| `_data (bytes)`       | `0x` for a plain ETH transfer. For a contract call, paste the encoded function call data here.                              |

{% hint style="info" %}
If `_gasLimit` is too low, the L2 transaction will revert on MegaETH — but your ETH is still delivered to `_to` even on failure.
The L1 gas fee for submitting the deposit is non-refundable regardless.
{% endhint %}

{% endstep %}
{% step %}

### Submit and save the transaction hash

Click **Write** and confirm in your wallet.
Save the Ethereum transaction hash to track the deposit.

{% endstep %}
{% step %}

### Verify on MegaETH

After 1–2 minutes, check your balance or transaction on the block explorer:

- **Mainnet:** [megaeth.blockscout.com](https://megaeth.blockscout.com)
- **Testnet:** [megaeth-testnet-v2.blockscout.com](https://megaeth-testnet-v2.blockscout.com)

{% endstep %}
{% endstepper %}

## Using cast or forge

For scripted or programmatic force inclusion using [Foundry](https://getfoundry.sh/).
The L1 sender address equals `msg.sender` on L2 — no aliasing applies for EOA callers — so the same private key that holds tokens on MegaETH signs the L1 transaction.

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

GAS_LIMIT=$(( GAS_EST * 120 / 100 ))
echo "estimate: $GAS_EST   limit: $GAS_LIMIT"
```

For a standard ERC-20 `transfer()` on MegaETH the estimate is approximately 54 000 gas; a limit of 65 000 is sufficient.

{% hint style="warning" %}
The portal enforces a minimum `_gasLimit` based on calldata length (~26 500 for a `transfer()` call).
Values below the minimum revert with `SmallGasLimit`.
{% endhint %}

{% endstep %}
{% step %}

### Encode the calldata

The `_data` field passed to `depositTransaction` is the ABI-encoded function call to execute on L2.
Use `cast calldata` to encode it:

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
export GAS_LIMIT=$GAS_LIMIT

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

After 1–2 minutes, confirm the recipient's balance increased.

```bash
cast call $TOKEN "balanceOf(address)(uint256)" $RECIPIENT --rpc-url $L2_RPC
```

{% endstep %}
{% endstepper %}

## How it works

1. `depositTransaction` emits `TransactionDeposited(address indexed from, address indexed to, uint256 indexed version, bytes opaqueData)` on L1.
2. The MegaETH derivation pipeline converts the event into a type-`0x7E` deposited transaction.
3. The deposited transaction executes on L2 with `msg.sender` equal to the L1 sender (no aliasing for EOA).
4. `_gasLimit` is pre-paid on L1 and is not refunded even if unused.
5. Setting `_value` forwards ETH to `_to`; it must equal `msg.value`.

For the formal deposit specification, see [Deposits](https://specs.optimism.io/protocol/deposits.html) in the OP Stack spec.
