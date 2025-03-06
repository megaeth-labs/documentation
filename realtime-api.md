---
title: Realtime API
---

# Realtime API

MegaETH executes transactions as soon as they arrive at the sequencer. The sequencer emits _preconfirmations_ and _execution results_ of the transactions within 10 milliseconds of their arrival at the sequencer.

Such information is exposed through MegaETH’s *Realtime API*, an extension to Ethereum JSON-RPC API optimized for low-latency access. This API queries against the most recent _mini block_. In other words, receipts and state changes associated with a transaction is reflected in this API as soon as the transaction is packaged into a mini block, which usually happens within 10 milliseconds of its arrival at the sequencer. In comparison, the vanilla Ethereum JSON-RPC API queries against the most recent _EVM block_, which leads to much longer delay before execution results are reflected.

It is important to point out that mini blocks in MegaETH are preconfirmed by the sequencer just like EVM blocks are. The sequencer makes as much effort not to roll back mini blocks as it does EVM blocks. As a result, results returned by the Realtime API still fall under the preconfirmation guarantee by the sequencer.  

This document specifies the Realtime API. Note that the Realtime API is an evolving standard. Additional functionalities will be added to the API based on feedbacks. This document will be kept up to date.

## Overview of the Changes

The Realtime API introduces three types of changes to the vanilla Ethereum JSON-RPC API:

1. Most methods that query chain and account states return values as of the most recent mini block, when invoked with `pending` or `latest` as the block tag.
2. Most methods that query transaction data are able to “see” a transaction and return results as soon as the transaction of interest is packaged into a mini block.
3. `eth_subscribe`, when invoked over WebSocket, streams transaction logs, state changes, and block content as soon as the corresponding mini block is produced.
 
## Querying Account and Chain States

The following API methods that query account and chain states, when invoked with `pending` or `latest` as the block tag, return results up to the most recent mini block.

| Method | 
| -------- |
| eth_getBalance     |
| eth_getStorageAt |
| eth_getTransactionCount |
| eth_getCode |
| eth_call |
| eth_callMany |
| eth_createAccessList |
| eth_estimateGas |

### Example

At 5pm, the height of the most recent mini block is 10000, and the height of the most recent EVM block is 100. At this point, Alice’s account has a balance of 10 Ether.

At 100 milliseconds past 5pm, the height of the most recent mini block is 10010, and the height of the most recent EVM block is still 100. Now, Alice sends a transaction that transfers 1 Ether to Bob. This transaction will decrease her account balance by 1 Ether.

At 110 milliseconds past 5pm, the transaction is picked up and executed by the sequencer, and packaged into the mini block at height 10011. Now, Bob invokes `eth_getBalance` on Alice’s account with `latest` as the block tag; he get a response of 9 Ether, because the transaction has been packaged into a mini block and is thus reflected in the Realtime API. However, Charlie, who makes the same query with `100` as the block tag, still sees 10 Ether, because the transaction has not been packaged into an EVM block, which will not happen until 1 second past 5pm.

## Querying Transactions

The following API methods that query transaction data are able to locate a transaction in the database and return results as soon as the transaction is packaged into a mini block. No special parameters are needed when invoking the methods.

| Method | 
| -------- |
| eth_getTransactionByHash |
| eth_getTransactionReceipt |

### Example

Continuing the previous example, Alice invokes `eth_getTransactionReceipt` on her transaction at 110 milliseconds past 5pm. The API responds with the correct receipt, even though no EVM block has been produced since she sent her transaction. This is because her transaction is already packaged into the mini block at height 10011 and the Realtime API can thus see the transaction.  

## `eth_subscribe` over WebSocket

When invoked over WebSocket, `eth_subscribe` streams data as soon as the corresponding mini block is produced. This is the mechanism to get transaction preconfirmation and execution results with the minimum amount of latency. As a reminder, please call `eth_unsubscribe` when a subscription is no longer needed.

### Logs

When both `startBlock` and `endBlock` are set to `pending`, the API returns logs as soon as transactions are packaged into mini blocks. The following query is an example.

```
{
    "jsonrpc": "2.0",
    "method": "eth_subscribe",
    "params": [
        "logs",
        {
            "fromBlock": "pending",
            "toBlock": "pending"
        }
    ],
    "id": 83
}
```

It is also possible to filter the logs by contract addresses and topics. Here is an example.

```
{
    "jsonrpc": "2.0",
    "method": "eth_subscribe",
    "params": [
        "logs",
        {
            "address": "0x8320fe7702b96808f7bbc0d4a888ed1468216cfd",
            "topics": ["0xd78a0cb8bb633d06981248b816e7bd33c2a35a6089241d099fa519e361cab902"],
            "fromBlock": "pending",
            "toBlock": "pending"
        }
    ],
    "id": 83
}
```

### State Changes

`stateChange` is a new type of subscription that streams state changes of an account as soon as the transactions making the changes are packaged into mini blocks. It takes a list of account addresses to monitor as a parameter. Here is an example.

```
{
    "jsonrpc": "2.0",
    "method": "eth_subscribe",
    "params": [
        "stateChange",
        ["0x2ef038991d64c72646d4f06ba78d93f4f1654e3f"]
    ],
    "id": 83
}
```

Here is an example of the response. It shows the latest account balance, nonce, and values of storage slots that are changed.

```
{
    "address": "0x2ef038991d64c72646d4f06ba78d93f4f1654e3f",
    "nonce": 1,
    "balance": "0x16345785d8a0000",
    "storage": {
    "0xb6318d15e99499c465cc5e3d630975bf37b5641a8beb2614b018219310f4ea12": "0x68836e425f5",
    "0xbf0f571b7368c19b53ab5ef0ff767ed8e0aef55a462778a6119b7871b017ce8f": "0x71094412456b0"
    }
}
```

### Mini Blocks

`fragment` is a new type of subscription that streams mini blocks as they are produced. Here is an example.

```
{
    "jsonrpc": "2.0",
    "method": "eth_subscribe",
    "params": [
        "fragment"
    ],
    "id": 83
}
```

The returned mini blocks contain the following fields

| Field Name | Description | 
| -------- | -------- |
| timestamp | The UNIX timestamp in milliseconds when the mini block is created. This field is set by the sequencer and is not verifiable.  | 
| gas_used | The amount of gas consumed by the mini block. | 
| transactions | Transactions in the mini block. |
