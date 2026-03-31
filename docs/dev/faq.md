---
description: Frequently asked questions for MegaETH developers — EVM compatibility, gas, transactions, mini-blocks, RPC, and tooling.
---

# Developer FAQ

## Chain Behavior & EVM Compatibility

### Which EIPs are supported or enforced on MegaETH?

| EIP | Title | Enforced / Supported | Notes |
| --- | ----- | -------------------- | ----- |
| **EIP-55** | Mixed-case checksum address encoding | Not enforced | Addresses may appear in lowercase, especially in logs and WebSocket responses. |
| **EIP-170** | Contract code size limit | Not enforced | MegaETH raises the contract size limit to **512 KB** to support larger deployments. |
| **EIP-1559** | Fee market change for ETH 1.0 chain | Supported | MegaETH uses a dynamically adjusting base fee model with a different set of parameters. |
| **EIP-7702** | Account abstraction via temporary smart contract accounts | Supported | EOAs can be delegated to smart contracts and behave like smart contract wallets. See compatible tools on the [tooling page](tooling.md). |

### What versions of Solidity does MegaETH support?

As long as the output bytecode targets the Prague EVM or an older one, it will run on MegaETH.
This means you can use any Solidity version that supports Prague or earlier as the compilation target.

### Does MegaETH support transient storage (`TSTORE`)?

Yes, MegaETH supports `TSTORE` as part of its compatibility with the Cancun upgrade.

### Should I expect race conditions to affect simulations?

Some applications simulate transactions before submitting them to the blockchain for actual execution.
Race conditions occur if the chain state changes after a transaction is simulated and before it is executed on-chain — for example, because of a conflicting transaction sent in parallel.
This may lead to disagreeing results between simulation and on-chain execution.
Write proper error handling for this scenario, and only regard on-chain execution results as authoritative.

### Are there any edge cases that may cause an L2 preconfirmation to be reverted because of an L1 reorganization?

Given that each MegaETH block anchors to an L1 block, an L1 reorganization ("reorg") can invalidate the anchor and roll back any corresponding MegaETH blocks.
The likelihood depends on how aggressively the sequencer chooses anchors, but should be overall very low.
(Ethereum almost never experiences finality violation.)

Write error handling for rollbacks of preconfirmed blocks.

### What is the contract size limit?

512 KB, rather than Ethereum's 24 KB.
See the [Contract Limits specification](../spec/evm/contract-limits.md) for details.

## Transaction Lifecycle & Txpool

### What is the gas limit of `eth_call` / `eth_estimateGas`?

60,000,000 compute gas on the public RPC endpoint.

Note that this limit is _different_ from the on-chain transaction gas limit of 1,000,000,000.
It applies only to RPC simulation calls.
Managed RPC providers may allow higher limits.

### What is the maximum number of transactions I can have in the txpool?

Each account can have up to **500 pending transactions** in the pool.
If you exceed this limit, new transactions will be rejected with a `txpool is full` error.
To free up space in the queue, try replacing existing pending transactions.
To avoid leaving transactions stuck in the pool, send transactions with nonces that increase one by one, as required by the EVM.

### What is the maximum number of transactions I can send per second per account?

MegaETH does not exercise a per-account transaction rate limit, but there are two main constraints:

1. **Block gas limit.** Each EVM block has a maximum gas limit of 10 billion (10,000,000,000) gas. Given that the minimum gas cost per transaction is 60,000 gas (21,000 compute gas + 39,000 storage gas), the theoretical maximum number of transactions per block is 10,000,000,000 / 60,000 = 166,666.
2. **Execution throughput.** The practical limit also depends on the number of transactions the EVM can process per second. For native ETH transfers, this number is estimated to be around 100,000 transactions per second under ideal conditions.

### How do I check how many transactions are in the txpool?

There is currently no way to check the contents of the txpool.

### Is the txpool cleared when I reconnect or restart my sender?

No.
The txpool is persistent and is not cleared when you reconnect to the RPC or restart your sender.
If you are observing nonce-related issues after reconnecting, it is likely because your sender is re-initializing the nonce from the latest executed block (`latest`) instead of tracking the `pending` state.

To avoid creating gaps or collisions in nonces, use `eth_getTransactionCount(..., "pending")` or manage nonce state locally when sending multiple transactions concurrently.

### My transactions are stuck in the txpool. How can I clear the blockage?

This usually happens when there is a gap in your nonce sequence.
For example, if your last executed transaction had nonce _x_, but the txpool contains transactions starting at _x+2_, those transactions will remain stuck until a transaction with nonce _x+1_ is submitted and executed.

Previously, the txpool would reject this corrective _x+1_ transaction if the per-account limit (500 transactions) had already been reached.
After a recent update, transactions with the next sequential nonce (_x+1_) are always admissible, even when the account has hit the txpool cap.
To recover:

{% stepper %}
{% step %}
## Identify the last executed nonce

Find the last nonce that was successfully executed and included in a block.
{% endstep %}
{% step %}
## Send a transaction with nonce x+1

Submit a transaction with the next sequential nonce.
{% endstep %}
{% step %}
## Wait for execution

Wait for it to be executed and included in a block.
{% endstep %}
{% step %}
## Repeat if necessary

If there are more gaps, repeat the process until the queue is unblocked.
{% endstep %}
{% endstepper %}

## Mini-Blocks & Realtime API

### Does `block.timestamp` return the timestamp of the EVM block or the mini-block?

It returns the timestamp of the EVM block.

### Can smart contracts access mini-block metadata?

Not currently.
Mini-blocks are intentionally compact and do not include the same metadata fields as EVM blocks, so there is currently no way to access their metadata from within a smart contract.

### Do mini-blocks have the same guarantees as EVM blocks?

Yes.
Preconfirmation of mini-blocks by the sequencer has the same level of guarantees as that of EVM blocks.

### Does the performance dashboard (uptime.megaeth.com) display the block height in mini-blocks or EVM blocks?

Mini-blocks.

### Why am I seeing `0xfff[...]fff` `blockHash` in a realtime transaction receipt, even though I get a valid `blockNumber`?

In the realtime RPC, if a transaction receipt has a `null` `blockHash` but a valid `blockNumber`, it means the transaction was included in a mini-block and is preconfirmed by the sequencer, but not yet part of an EVM block.

The presence or absence of `blockHash` does not affect the level of finality, as the sequencer guarantees inclusion from the moment it is included in a mini-block.

Full finality still depends on the transaction being submitted and finalized on the L1.

### Why does `eth_subscribe` return an internal error?

`eth_subscribe` must be called over a WebSocket (`ws`) connection.
You will receive the error when trying it over HTTP because HTTP transport does not support the persistent, bidirectional communication required for subscriptions.

## RPC and WebSocket Behavior

### Which methods are available over WebSocket?

The public WebSocket endpoint supports the following methods:

- `eth_subscribe`
- `eth_unsubscribe`
- `eth_sendRawTransaction`
- `realtime_sendRawTransaction`
- `eth_chainId`

WebSocket connections are rate-limited to 5 messages per second per connection.
Send `eth_chainId` at least once every 30 seconds to keep the connection alive — idle connections may be closed by the server.

### Can I set up my own RPC node?

Not yet.
Currently, all RPC endpoints are operated by the MegaETH team and support for externally hosted or self-run nodes is not available.
Keep an eye on the [tooling page](tooling.md) for updates.

### Where are the RPC endpoints located?

Miami, FL.

### I'm having trouble accessing the RPC without a VPN. Is this related to SSL support?

The issue is unlikely to be SSL-related unless your router is blocking TLS handshakes using deprecated protocol versions.
MegaETH only disables outdated ciphers and protocol versions, so modern routers and firewalls should have no problem establishing a connection.

## Developer Tooling

### Where can I find standard token contract addresses?

On the community-run [wiki](https://megaeth-1.gitbook.io/untitled).

### How do I wrap the native (gas) token?

To wrap the native token (ETH), use the WETH contract at [`0x4200000000000000000000000000000000000006`](https://megaeth.blockscout.com/address/0x4200000000000000000000000000000000000006) (OP Stack predeploy).

Call `deposit()` and send ETH as `msg.value` — you'll receive an equivalent amount of WETH.
See [Contracts & Tokens](send-tx/contracts.md#core) for the full list of core contract addresses.

### How can I get my contract verified on the MegaExplorer?

Open a pull request with the contract address and ABI at [https://github.com/princesinha19/megaeth-abis/tree/main](https://github.com/princesinha19/megaeth-abis/tree/main).
It should then automatically be reflected on the [MegaExplorer](https://www.megaexplorer.xyz).

Note that both this repo and the MegaExplorer are community-created and managed.

## Errors

### Why am I seeing `null` `blockHash` when calling `getTransactionReceipt`?

To avoid adding latency, MegaETH does not force global synchronization across all RPC servers.
As a result, it is possible that the RPC server handling your request has not yet received the transaction receipt from the sequencer, even if the transaction has already been processed.

### Why am I getting a `403` error saying "Enable JavaScript and cookies to continue" when using Foundry?

This error typically comes from Cloudflare's protection layers.
Consider retrying with a low-risk IP address.

### Why am I getting a TLS handshake failure when using Alloy.rs?

This error typically occurs because Alloy's WebSocket transport forces the use of `rustls` for TLS.
To fix this:

{% stepper %}
{% step %}
## Install `reqwest` with the `rustls-tls` feature

Add to your `Cargo.toml`:

```toml
reqwest = { version = "...", features = ["rustls-tls"] }
```
{% endstep %}
{% step %}
## Use a custom transport to build your HTTP provider

```rust
let client = reqwest::Client::builder()
    .use_rustls_tls()
    .build()
    .unwrap();

let http_client = Http::with_client(client, Url::parse(&self.http_url).unwrap());
let is_local = http_client.guess_local();
let http_client = ClientBuilder::default().transport(http_client, is_local);
let http_provider = ProviderBuilder::new().on_client(http_client);
```
{% endstep %}
{% step %}
## Install the default TLS provider early in `main.rs`

```rust
let _ = rustls::crypto::ring::default_provider().install_default();
```
{% endstep %}
{% endstepper %}

### What does "rabbit hole is full. Please try again later" mean?

It means you are hitting a rate limit.

### What does "rpc method is not whitelisted" mean?

It means you are calling a method that is currently restricted.
If this is a blocker, please reach out to the team to come up with a solution.

### Why do I get a `502 Bad Gateway` error?

A `502` usually indicates a temporary upstream issue or stale DNS resolution.
The latter case is especially common in long-running processes (e.g., bots, indexers, or backends) that reuse DNS lookups for too long.
Restarting your process typically resolves it.
If the issue persists, reach out to the team.
