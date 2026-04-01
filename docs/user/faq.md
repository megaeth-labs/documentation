---
description: Frequently asked questions for MegaETH users — wallet issues, testnet ETH, and faucet.
---

# User FAQ

## Wallet & Transactions

### My wallet transfers keep getting stuck and don't go through. What should I do?

This is usually caused by a pending transaction with a nonce conflict or underpriced gas.
Try replacing the stuck transaction with a higher gas price.

### Why am I getting a 405 error when I click on the RPC endpoint link?

RPC endpoints are not meant to be opened directly in a browser.
They only accept POST requests with properly formatted data, and will return a "405 Method Not Allowed" error if you try to open them in a browser (which sends a GET request instead).
To use the RPC, connect through a wallet, dApp, or developer tool.

## Testnet ETH

### How can I get testnet ETH to interact with the chain?

Use the [official faucet](https://testnet.megaeth.com) to request testnet ETH.

If you are on the Fluffle whitelist, registered via Discord, active in Telegram, or have interacted with MegaETH on Twitter, you may already be prefunded and can start using the chain right away.

### Is the faucet capped?

Yes.
The faucet provides a maximum of 0.005 testnet ETH per user every 24 hours.

### Can I use different wallets to get more ETH from the faucet?

No.
Requests are tracked by IP address, so switching wallets will not bypass the request limit.

### The testnet ETH from the faucet is not enough for me to deploy and test my protocol. How can I get more?

Please reach out to the team directly.

### Can I set up my own faucet in my dApp?

No.
Please direct users to the official MegaETH faucet instead.

### Why is testnet ETH distribution controlled?

The limits exist purely as a last line of defense against abuse and to maintain network stability.
They are not there to create artificial scarcity or out of concern about inflation.

### Will the faucet stay open after mainnet?

Yes, it will remain operational after mainnet launch but will continue to distribute tokens only for the testnet.
It will not be possible to bridge testnet ETH onto mainnet.
