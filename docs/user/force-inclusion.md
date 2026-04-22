---
description: How to force-include a transaction on MegaETH by submitting it directly to Ethereum via Etherscan, bypassing the sequencer.
---

# Force-include a transaction

Force inclusion submits a transaction directly to the L1 OptimismPortal, bypassing the sequencer.
Once submitted on Ethereum, MegaETH is required to include it on L2 within 12 hours.
Under normal conditions it lands in about 5–20 minutes.

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

## Steps

You need a browser wallet (MetaMask, Rabby, etc.) funded with ETH on Ethereum Mainnet or Sepolia.

{% stepper %}
{% step %}

### Open OptimismPortal on Etherscan

Go to the OptimismPortal contract for your network and open the **Write as Proxy** tab:

- **Mainnet:** [OptimismPortal on Etherscan](https://etherscan.io/address/0x7f82f57F0Dd546519324392e408b01fcC7D709e8#writeProxyContract) (`0x7f82f57F0Dd546519324392e408b01fcC7D709e8`)
- **Testnet (Sepolia):** [OptimismPortal on Sepolia Etherscan](https://sepolia.etherscan.io/address/0xF68D900e1Cdec64a8f5Dc0Ee873A9E2879256b10#writeProxyContract) (`0xF68D900e1Cdec64a8f5Dc0Ee873A9E2879256b10`)

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

| Field                 | What to enter                                                                                                                                                       |
| --------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `payableAmount (ETH)` | ETH to send to MegaETH (e.g. `0.001`). Enter `0` for contract calls with no ETH attached.                                                                           |
| `_to (address)`       | The destination address on MegaETH — your wallet address for a plain ETH transfer, or a contract address for a call.                                                |
| `_value (uint256)`    | Same as `payableAmount` in wei. For 0.001 ETH enter `1000000000000000`. Enter `0` if sending no ETH.                                                                |
| `_gasLimit (uint64)`  | Gas budget for L2 execution. Use `100000` for a plain ETH transfer; for contract call estimates see [Force Inclusion — Foundry](../dev/send-tx/force-inclusion.md). |
| `_isCreation (bool)`  | `false` unless you are deploying a new contract on MegaETH.                                                                                                         |
| `_data (bytes)`       | `0x` for a plain ETH transfer. For a contract call, paste the encoded function call data here.                                                                      |

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

After 5–20 minutes, check your balance or transaction on the block explorer:

- **Mainnet:** [megaeth.blockscout.com](https://megaeth.blockscout.com)
- **Testnet:** [megaeth-testnet-v2.blockscout.com](https://megaeth-testnet-v2.blockscout.com)

{% endstep %}
{% endstepper %}

For scripted or automated force inclusion using Foundry, see [Force Inclusion — Foundry](../dev/send-tx/force-inclusion.md).
