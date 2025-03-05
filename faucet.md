# Aquire Tokens
## Testnet Notice

MegaETH is currently in **testnet**, which means the following for the tokens:

- **Testnet tokens have no real-world value** and **cannot** be bridged to mainnet.
- **Daily request** and **global token** limits are in place to prevent abuse.
- **The faucet will remain operational after mainnet launch** but will continue to distribute tokens **only for the testnet.**
- Testnet is **unincentivized** and users can claim testnet tokens for free from faucets.

**To learn more about the implications of being on testnet and our rollout roadmap, see [Network Phases](https://hackmd.io/zTV7ghoXRqWLLT8W5UN9BQ#Network-Phases).**


## Overiew
### What is a Token?
### Use Cases 
### Token Standards
### What is MegaETH Testnet's Native Token?
### What if I want Users to Spend Real Money?

## Faucets 
Generally speaking, a **crypto faucet** is a service that distributes small amounts of tokens to users, often in return for basics tasks.

However, a **testnet faucet** works a little bit differently in that it distributes **free testnet tokens** to developers and users so they can interact and experiment on the testnet. A key distinction is that **no work is required to receive testnet tokens** from a faucet, but there are certain access limits to ensure fair distribution and prevent abuse. (See Access Limits & Best Practices below).


## How to Use a Faucet

MegaETH has a few ways to request testnet tokens:

> Before you can request tokens, ensure that your wallet is properly configured to the MegaETH network. Refer to the previous page on [Wallets](https://www.notion.so/Set-up-and-Connect-a-Wallet-198ad4014d5380aabfeffd2e4adbf60e?pvs=21).
> 

### **Option 1: Web Faucet**

Enter you wallet address below and request tokens:

> **Best for:** Users who would like a simple, one-time request to interact with a dApp.
> 

### **Option 2: Telegram Bot Faucet**

1. Open a chat with the telegram bot user `@megaburrow_bot` and send the following commands:

```jsx
/start 

/feed <your MegaETH wallet address>
```

1. If successful, the bot will respond with a confirmation message:

**`Sucess:** Transferred <TBD> testnet Ether to <your wallet address>. Transaction hash <transaction hash>`

> **Best for:** Developers who need an automated or programable way to acquire tokens regularly and/or at a regular cadence
> 

## Access limits & Best Practices

To ensure fair distribution and prevent abuse, the MegaETH faucet enforces the following limits: 

- **Daily Request Limit** - Each user can request one (1) token per 24 hour period.
- **IP-Base Restrictions** - Requests are tracked by IP address, meaning that switching wallets will not bypass the request limit.
- **Global Daily Token Cap** — The faucet has a finite supply cap per day. Once the faucet is depleted, further requested will be paused until the next cycle.

> Note: We haven’t put these limits in place to create artificial scarcity or out of concern of inflation— Testnet tokens have no real-world value. Their sole purpose is as a last line of defense against abuse and to maintain network security.



<div style="display: flex; justify-content: space-between; margin-top: 40px;">
  <a href="https://hackmd.io/Tf3HIuIuTqGeRWAIdWN8_w#Set-Up-and-Connect-a-Wallet" 
     style="padding: 20px 40px; font-size: 16px; font-weight: bold; border: 1px solid #ddd; text-decoration: none; border-radius: 10px; display: inline-block; text-align: left; width: 350px; color: black;">
    <span style="font-size: 14px; color: #6c757d;">Previous</span><br>
    <span style="font-size: 18px; color: #5c3cff;">« Setup and Connect a Wallet</span>
  </a>
  <a href="https://hackmd.io/ZMe52In5SfqIwfoNHpsl5g#Aquire-Tokens" 
     style="padding: 20px 40px; font-size: 16px; font-weight: bold; border: 1px solid #ddd; text-decoration: none; border-radius: 10px; display: inline-block; text-align: right; width: 350px; color: black;">
    <span style="font-size: 14px; color: #6c757d;">Next</span><br>
    <span style="font-size: 18px; color: #5c3cff;">Setup The Development Enviornment »</span>
  </a>
</div>
