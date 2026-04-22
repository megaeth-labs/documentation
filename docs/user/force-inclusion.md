---
description: How to force a transaction onto MegaETH by submitting it directly to Ethereum, bypassing the sequencer.
---

# Force-include a transaction

Force inclusion lets you submit a transaction directly to Ethereum so MegaETH is required to include it — even if the sequencer is unresponsive or ignoring your transaction.
Once submitted on Ethereum, MegaETH guarantees your transaction will appear on L2 within 12 hours.
Under normal conditions it lands in about 1–2 minutes.

{% hint style="warning" %}
This method is for advanced users only.
For routine transactions, submit normally through your wallet.
{% endhint %}

## When to use force inclusion

- The sequencer is offline and your transaction cannot get through.
- A transaction is being consistently ignored despite sufficient gas.
- You need a censorship-resistance guarantee for a high-stakes action.

## What you need

- A browser wallet (MetaMask, Rabby, etc.) connected to Ethereum Mainnet or Ethereum Sepolia (for testnet).
- Enough ETH on L1 to cover the Ethereum gas fee plus any ETH you want to send to MegaETH.
- The destination address on MegaETH you want the transaction sent to.

## Steps

{% stepper %}
{% step %}

### Open OptimismPortal on Etherscan

Go to the OptimismPortal contract for your network and open the **Write as Proxy** tab:

- **Mainnet:** [0x7f82f57F0Dd546519324392e408b01fcC7D709e8](https://etherscan.io/address/0x7f82f57F0Dd546519324392e408b01fcC7D709e8#writeProxyContract) on Etherscan
- **Testnet (Sepolia):** [0xF68D900e1Cdec64a8f5Dc0Ee873A9E2879256b10](https://sepolia.etherscan.io/address/0xF68D900e1Cdec64a8f5Dc0Ee873A9E2879256b10#writeProxyContract) on Sepolia Etherscan

Click the **Write as Proxy** tab near the top of the contract page.

{% endstep %}
{% step %}

### Connect your wallet

Click **Connect to Web3** on the Etherscan page and approve the connection in your wallet.
Make sure your wallet is set to the correct network — Ethereum Mainnet for production, or Sepolia for testnet.

{% endstep %}
{% step %}

### Fill in the depositTransaction fields

Scroll to **depositTransaction** in the list and expand it.
Fill in the six fields:

| Field                 | What to enter                                                                                                              |
| --------------------- | -------------------------------------------------------------------------------------------------------------------------- |
| `payableAmount (ETH)` | Amount of ETH to send to MegaETH (e.g. `0.001`). Enter `0` if you are only calling a contract with no ETH attached.        |
| `_to (address)`       | The destination address on MegaETH — your wallet address for a plain ETH transfer.                                         |
| `_value (uint256)`    | The same amount as `payableAmount`, converted to wei. For 0.001 ETH enter `1000000000000000`. Enter `0` if sending no ETH. |
| `_gasLimit (uint64)`  | Gas budget for L2 execution. Use `100000` for a plain ETH transfer.                                                        |
| `_isCreation (bool)`  | `false` — leave this as false unless you are deploying a new contract on MegaETH.                                          |
| `_data (bytes)`       | `0x` for a plain ETH transfer. For a contract call, paste the encoded function call data here.                             |

{% hint style="info" %}
If `_gasLimit` is too low, the L2 transaction will revert on MegaETH — but your ETH is still delivered to `_to` even on failure.
The L1 gas fee for submitting the deposit is non-refundable regardless.
100 000 is a safe amount for a plain ETH transfer.
{% endhint %}

{% endstep %}
{% step %}

### Submit the transaction

Click **Write** and confirm the transaction in your wallet.
Save the Ethereum transaction hash — you can use it to track the deposit.

{% endstep %}
{% step %}

### Verify on MegaETH

After about 1–2 minutes (up to 12 hours if the sequencer is under stress), your transaction will appear on MegaETH.
Check your balance or transaction history on the block explorer:

- **Mainnet:** [megaeth.blockscout.com](https://megaeth.blockscout.com)
- **Testnet:** [megaeth-testnet-v2.blockscout.com](https://megaeth-testnet-v2.blockscout.com)

Search by your wallet address or the Ethereum transaction hash.

{% endstep %}
{% endstepper %}

For programmatic force inclusion using `cast` or `forge`, see the [Developer Guide](../dev/force-inclusion.md).
