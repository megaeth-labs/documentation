---
title: FAQ
owners: sami, alex
rank: 900
---

# Chain Behavior & EVM Compatibility 

## Which EIPs are supported or enforced on MegaETH?

| EIP        | Title                                                      | Enforced / Supported | Notes |
|------------|-------------------------|----------------|-----------------------------------------------|
| **EIP-55**   | Mixed-case checksum address encoding                      |  Not enforced        | Addresses may appear in lowercase, especially in logs and WebSocket responses. |
| **EIP-170**  | Contract code size limit                                  |  Not enforced        | MegaETH raises the contract size limit to **512KB** to support larger deployments. |
| **EIP-1559** | Fee market change for ETH 1.0 chain                       |  Supported           | MegaETH uses a dynamically adjusting base fee model with a different set of parameters. |
| **EIP-7702** | Account abstraction via temporary smart contract accounts |  Supported           | EOAs can be delegated to smart contracts and behave like smart contract wallets. See compatible tools [here](https://docs.megaeth.com/infra). |

## What versions of Solidity does MegaETH support?

As long as the output bytecode targets the Prague EVM or an older one, it will run on MegaETH. This means you can use any Solidity version that supports Prague or earlier as the compilation target.  

## Does MegaETH support transient storage (`STORE`)?

Yes, MegaETH supports `TSTORE` as part of its compatibility with the Cancun upgrade. 

## Should I expect race conditions to affect simulations?

Some applications simulate transactions before submitting them to the
blockchain for actual execution. Race conditions occur if the chain state
changes after a transaction is simulated and before it is executed on-chain,
e.g., because of a conflicting transaction sent in parallel. This may lead to
disagreeing results between simulation and on-chain execution. Hence, we
strongly suggest you write proper error handling for this scenario, and only
regard on-chain execution results as authoritative.

## Are there any edge cases I should be aware of that may cause an L2 pre-confirmation to be reverted because of an L1 reorganization?

Given that each MegaETH block anchors to an L1 block, an L1 reorganization
("reorg") can invalidate the anchor and roll back any corresponding MegaETH
blocks. The likelihood depends on how aggressively the sequencer chooses
anchors, but should be overall very low. (Ethereum almost never experiences
finality violation.)

Nevertheless, we suggest you write error handling for rollbacks of preconfirmed
blocks.

## What is the contract size limit?

512KB, rather than Ethereum's 24KB. 

# Transaction Lifecycle & Txpool

## What is the gas limit of `eth_call` / `eth_EstimateGas`?

10,000,000 (increased on 28/03/2025 from 5,000,000).

Note that this gas limit is _different_ from the limit for on-chain transactions,
which is 1,000,000,000.  It applies only to RPC calls.

## What is the maximum number of transactions I can have in the txpool?

**Each account can have up to 500 pending transactions in the pool.** If you
exceed this limit, new transactions will be rejected with a `txpool is full`
error. To free up space in the queue, try replacing existing pending
transactions. To avoid leaving transactions stuck in the pool, pay attention to
send transactions with nonces that increase one by one, as required by the EVM.

## What is the maximum number of transactions I can send per second per account?

Although MegaETH does not exercise a per account transaction rate limit, there
are two main constraints: 

1. **Block gas limit.** Each EVM block has a maximum gas limit of 2 Giga
   (2,000,000,000) gas. Given that the minimum gas cost per transaction is
21,000 gas, the theoretical maximum number of transactions per block is 2,000,000,000 / 21,000 = 95,238.
2. **Execution throughput.** The practical limit is also dependent on the
   number of transactions the EVM can process per second. For native ETH
transfers, this number is estimated to be around 100,000 transactions per
second under ideal conditions.

## How do I check how many transactions are in the txpool?

There is currently no way to check the contents of the txpool. 

## Is the txpool cleared when I reconnect or restart my sender?

No. The txpool is persistent and is not cleared when you reconnect to the RPC
or restart your sender. If you are observing nonce-related issues after
reconnecting, it is likely because your sender is re-initializing the nonce
from the latest executed block (`latest`) instead of tracking the `pending`
state.

To avoid creating gaps or collisions in nonces, use
`eth_getTransactionCount(..., "pending")` or manage nonce state locally when
sending multiple transactions concurrently.

## My transactions are stuck in the txpool. How can I clear the blockage?

This usually happens when there is a gap in your nonce sequence. For example,
if your last executed transaction had nonce _x_, but the txpool contains
transactions starting at _x+2_, those transactions will remain stuck until a
transaction with nonce _x+1_ is submitted and executed.

Previously, the txpool would reject this corrective _x+1_ transaction if the
per-account limit (500 transactions) had already been reached. This would block
the sender permanently. After a recent update, transactions with the next
sequential nonce (_x+1_) are always admissible, even when the account has hit
the txpool cap. To recover:

1. Identify the last executed nonce _x_.
2. Send a transaction with nonce _x+1_.
3. Wait for it to be executed and included in a block.
4. Repeat the process if necessary.

This unblocks the stuck transactions and allows your sender logic to resume.

## My wallet transfers keep getting stuck and don't go through. What should I do?

This is usually caused by a pending transaction with nonce conflict or
underpriced gas. Try replacing the stuck transaction with a higher gas price. 

# Miniblocks & Realtime API

## Does `block.timestamp` return the timestamp of the EVM block or the miniblock?

It returns the timestamp of the EVM block. 

## Can smart contracts access miniblock metadata?

Not currently. Mini blocks are intentionally compact and do not include the
same metadata fields as EVM blocks, so there is currently no way to access
their metadata. 

## Do miniblocks have the same guarantees as EVM blocks?

Yes. Preconfirmation of miniblocks by the sequencer have the same level of
guarantees as that of EVM blocks.

## Does the performance dashboard (uptime.megaeth.com) display the block height in miniblocks or EVM blocks?

Miniblocks.

## Why am I seeing `null` `blockHash` in a realtime transaction receipt, particularly when I do get a valid `blockNumber`?

In the realtime RPC, if a transaction receipt has a `null` `blockHash` but a
valid `blockNumber`, it means the transaction was included in a miniblock and
is preconfirmed by the sequencer, but not yet part of an EVM block.

The presence or absence of `blockHash` does not affect the level of finality,
as the sequencer guarantees inclusion from the moment it is included in a
miniblock.

Full finality still depends on the transaction being submitted and finalized on
the L1.

## Why does `eth_subscribe` return an internal error?

`eth_subscribe` must be called over a WebSocket (`ws`) connection. You will
receive the error when trying it over HTTP because HTTP transport does not
support persistent, bidirectional communication required for subscriptions. 

# RPC and Websocket behavior 

## Which WebSocket methods are unavailable or rate-limited?

Currently all WebSocket methods other than `eth_chainId` (rate-limited at 5
reqs/s) are unavailable. We hope to lift these restrictions soon and will make
a notice as soon as we do.  

## Can I setup my own RPC node?

Not yet. Currently, all RPC endpoints are operated by the MegaETH team and
support for externally hosted or self-run nodes is not available. We hope to
change this in the very near future, so keep an eye out on the infra page for
updates. 

## Where are the RPC endpoints located?

Miami, FL

## I'm having trouble accessing the RPC without a VPN. Is this related to SSL support?

The issue is unlikely to be SSL-related unless your router is blocking TLS
handshakes using deprecated protocol versions, which we have seen in exactly
one case. We only disable outdated ciphers and protocol versions, so modern
routers and firewalls should have no problem establishing a connection.

# Developer Tooling & Support 

## Where can I find standard token contract addresses?

On the community run [wiki](https://megaeth-1.gitbook.io/untitled). 

## How do I wrap the native (gas) token?

To wrap the native token (ETH), you can use the canonical WETH contract
deployed at: `0x4eB2Bd7beE16F38B1F4a0A5796Fffd028b6040e9`

This contract uses the standard WETH interface, with the `deposit()` function
wrapping native ETH into WETH. Simply send ETH to the contract, and you'll
receive an equivalent amount of WETH. While the deposit function appears to
take no parameters, it accepts a `msg.value` parameter implicitly, and the
explorer may not fully display its signature.

## How can I get my contract verified on the MegaExplorer?

Please open a pull request with the contract address and ABI at:
[https://github.com/princesinha19/megaeth-abis/tree/main](https://github.com/princesinha19/megaeth-abis/tree/main).
It should then automatically be reflected on the
[MegaExplorer](https://www.megaexplorer.xyz).

*Please note that both this repo, and the MegaExplorer are community created and managed.*

# Errors

## Why am I seeing `null` `blockHash` when calling `getTransactionReceipt`?

To avoid adding latency, MegaETH does not force global synchronization across
all RPC servers. As a result, it is possible that the RPC server handling your
request has not yet received the transaction receipt from the sequencer, even
if the transaction has already been processed. 

## Why am I getting a `403` error saying "Enable JavaScript and cookies to continue" when using Foundry?

This error typically comes from Cloudflare's protection layers. Consider
retrying with a low-risk IP address.

## Why am I getting a `405` error when clicking on the RPC endpoint link?

RPC endpoints are not meant to be opened directly in the browser. They only
accept `POST` requests with properly formatted JSON-RPC payloads, and will
return a `405 Method Not Allowed` error if accessed via a browser, which
typically sends a `GET` request. To use the RPC, connect through a wallet, dApp
or developer tool. 

## Why am I getting a TLS handshake failure when using Alloy.rs?

This error typically occurs because Alloy's WebSocket transport forces the use
of `rustls` for TLS. To fix this, make sure you do the following:

1. Install `reqwest` with the `rustls-tls` feature in your `Cargo.toml`:

    ```
    reqwest = { version = "...", features = ["rustls-tls"] }
    ```
    
2. Use a custom transport to build your HTTP provider:

    ```
    let client = reqwest::Client::builder()
    .use_rustls_tls()
    .build()
    .unwrap();

    let http_client = Http::with_client(client, Url::parse(&self.http_url).unwrap());
    let is_local = http_client.guess_local();
    let http_client = ClientBuilder::default().transport(http_client, is_local);
    let http_provider = ProviderBuilder::new().on_client(http_client);
    ```
    
3. Install the default TLS provider early in your `main.rs`:

    ```
    let _ = rustls::crypto::ring::default_provider().install_default();
    ```
    
## What does "rabbit hole is full. Please try again later" mean?

It means you are hitting a rate limit. 

## What does "rpc method is not whitelisted" mean?

It means you are calling a method which is currently restricted. If this is a blocker, please reach out to the team to come up with a solution. 
    
## Why do I get a `502 Bad Gateway` error?

A `502` usually indicates a temporary upstream issue or stale DNS resolution. The latter case is especially common in long-running processes (e.g. bots, indexers or backends) that reuse DNS lookups for too long. Restarting your process typically resolves it. If the issue persists, reach out to the team.

# Testnet ETH

## How can I get testnet ETH to interact with the chain?

You can use the [official faucet](https://testnet.megaeth.com) to request testnet ETH. 

If you are on the Fluffle whitelist, registered via Discord, active in telegram or have interacted with us on Twitter, you may already be prefunded and can start using the chain right away. 

## Is the faucet capped?

Yes. The faucet provides a maximum of 0.005 testnet ETH per user every 24 hours.  

## Can I use different wallets to get more ETH from the faucet?

No. Requests are tracked by IP address, meaning that switching wallets will not bypass the request limit.

## The testnet ETH from the faucet is not enough for me to deploy and test my protocol. How can I get more?

Please reach out to the team!

## Can I set up my own faucet in my dApp?

No, we ask dApp's not to set up their own faucets, and instead direct users to the official MegaETH faucet. 

## Why is testnet ETH distribution controlled?

We have not put these limits in place to create artificial scarcity or out of concern of inflation. They exist purely as a last line of defense against abuse and to maintain network stability. 

## Will the faucet stay open after mainnet? 

Yes, it will remain operational after mainnet launch but will continue to distribute tokens only for the testnet.

It will not be possible to bridge testnet ETH onto mainnet. 
