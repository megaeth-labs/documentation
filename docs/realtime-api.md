---
title: Realtime API
owner: sami, william
rank: 30
---

MegaETH executes transactions as soon as they arrive at the sequencer. The sequencer emits _preconfirmations_ and _execution results_ of the transactions within 10 milliseconds of their arrival at the sequencer.

Such information is exposed through MegaETH’s _Realtime API_, an extension to Ethereum JSON-RPC API optimized for low-latency access. This API queries against the most recent _mini block_. In other words, receipts and state changes associated with a transaction are reflected in this API as soon as the transaction is packaged into a mini block, which usually happens within 10 milliseconds of its arrival at the sequencer. In comparison, the vanilla Ethereum JSON-RPC API queries against the most recent _EVM block_, which leads to much longer delay before execution results are reflected.

It is important to note that mini blocks in MegaETH are preconfirmed by the sequencer just like EVM blocks are. The sequencer makes as much effort not to roll back mini blocks as it does EVM blocks. Thus, results returned by the Realtime API still fall under the preconfirmation guarantee by the sequencer.

This document specifies the Realtime API. Note that the Realtime API is an evolving standard. Additional functionalities will be added to the API based on feedbacks. This document will be kept up to date.

# Overview of the Changes

The Realtime API introduces three types of changes to the vanilla Ethereum JSON-RPC API:

1. Most methods that query chain and account states return values as of the most recent mini block, when invoked with `pending` or `latest` as the block tag.
2. Most methods that query transaction data are able to “see” a transaction and return results as soon as the transaction of interest is packaged into a mini block.
3. `eth_subscribe`, when invoked over WebSocket, streams transaction logs, state changes, and block content as soon as the corresponding mini block is produced.
4. `realtime_sendRawTransaction` submits a transaction and returns the receipt in a single call — without requiring polling.
5. `eth_getLogsWithCursor` supports paginated log queries using a cursor, allowing applications to retrieve large datasets incrementally and reliably.

# Querying Account and Chain States

The following API methods that query account and chain states, when invoked with `pending` or `latest` as the block tag, return results up to the most recent mini block.

| Method                  |
| ----------------------- |
| eth_getBalance          |
| eth_getStorageAt        |
| eth_getTransactionCount |
| eth_getCode             |
| eth_call                |
| eth_callMany            |
| eth_createAccessList    |
| eth_estimateGas         |

## Example

At 5pm, the height of the most recent mini block is 10000, and the height of the most recent EVM block is 100. At this point, Alice’s account has a balance of 10 Ether.

At 100 milliseconds past 5pm, the height of the most recent mini block is 10010, and the height of the most recent EVM block is still 100. Now, Alice sends a transaction that transfers 1 Ether to Bob. This transaction will decrease her account balance by 1 Ether.

At 110 milliseconds past 5pm, the transaction is picked up and executed by the sequencer, and packaged into the mini block at height 10011. Now, Bob invokes `eth_getBalance` on Alice’s account with `latest` as the block tag; he get a response of 9 Ether, because the transaction has been packaged into a mini block and is thus reflected in the Realtime API. However, Charlie, who makes the same query with `100` as the block tag, still sees 10 Ether, because the transaction has not been packaged into an EVM block, which will not happen until 1 second past 5pm.

# Querying Transactions

The following API methods that query transaction data are able to locate a transaction in the database and return results as soon as the transaction is packaged into a mini block. No special parameters are needed when invoking the methods.

| Method                    |
| ------------------------- |
| eth_getTransactionByHash  |
| eth_getTransactionReceipt |

## Example

Continuing the previous example, Alice invokes `eth_getTransactionReceipt` on her transaction at 110 milliseconds past 5pm. The API responds with the correct receipt, even though no EVM block has been produced since she sent her transaction. This is because her transaction is already packaged into the mini block at height 10011 and the Realtime API can thus see the transaction.

# `eth_subscribe` over WebSocket

When invoked over WebSocket, `eth_subscribe` streams data as soon as the corresponding mini block is produced. This is the mechanism to get transaction preconfirmation and execution results with the minimum amount of latency. As a reminder, please call `eth_unsubscribe` when a subscription is no longer needed.

## Logs

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

The schema of each log entry is the same as in `eth_getLogs`.

## State Changes

`stateChanges` is a new type of subscription that streams state changes of an account as soon as the transactions making the changes are packaged into mini blocks. It takes a list of account addresses to monitor as a parameter. Here is an example.

```
{
    "jsonrpc": "2.0",
    "method": "eth_subscribe",
    "params": [
        "stateChanges",
        ["0x2ef038991d64c72646d4f06ba78d93f4f1654e3f"]
    ],
    "id": 83
}
```

Here is an example of the response. It shows the latest account balance, nonce, and values of storage slots that are changed. The schema is as the following.

```
{
    "address": Address, // The address of the account that is changed.
    "nonce": number, // The latest nonce of the account.
    "balance": U256, // The latest balance of the account.
    "storage": { // Updated storage slots and new values of the account.
       U256: U256,
       ... 
    }
}

```

Here is an example.

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

## Mini Blocks

`miniBlocks` is a new type of subscription that streams mini blocks as they are produced. Here is an example.

```
{
    "jsonrpc": "2.0",
    "method": "eth_subscribe",
    "params": [
        "miniBlocks"
    ],
    "id": 83
}
```

The returned mini blocks use the following schema.

```
{
     "payload_id": HexString, // EngineAPI payload ID of the EVM block that this mini-block belongs to
     "block_number": number, // The block number of that EVM block that this mini-block belongs to
     "index": number, // Index of this mini-block in the EVM block.
     "tx_offset": number, // The number of transactions in all previous mini-blocks of the same EVM block.
     "log_offset": number, // The number of logs in all previous mini-blocks of the same EVM block.
     "gas_offset": number, // The gas used in all previous mini-blocks of the same EVM block.
     "timestamp": number, // The timestamp when this mini-block is created. Unix timestamp in milliseconds.
     "gas_used": number, // Gas used inside this mini-block
     "transactions": [ ... ], // Transactions included in this mini-block. The schema of each transaction is the same as `eth_getTransactionByHash`.
     "receipts": [ ... ] // Receipts of the transactions in this mini-block. The schema of each receipt is the same as `eth_getTransactionReceipt`.
}
```

# Sending and Confirming Transactions in One Round Trip

## Overview

`realtime_sendRawTransaction` simplifies realtime dApp development by returning
the transaction receipt directly, without requiring polling
`eth_getTransactionReceipt`. It accepts the same parameters as
`eth_sendRawTransaction` but waits for the transaction to be executed and
returns its receipt as the response. This method times out after 10 seconds, in
which case it returns a `realtime transaction expired` error, indicating that
the user should revert to querying `eth_getTransactionReceipt`.


## Example

`realtime_sendRawTransaction` is a drop-in replacement of `eth_sendRawTransaction`.

```
{
  "jsonrpc": "2.0",
  "method": "realtime_sendRawTransaction",
  "params": [
    "0x<hex-encoded-signed-tx>"
  ],
  "id": 1
}
```

If the submitted transaction is executed within 10 seconds, it returns the receipt
of the executed transaction.

```
{
  "jsonrpc": "2.0",
  "id": 1,
  "result": {
    "blockHash": "0x0000000000000000000000000000000000000000000000000000000000000000",
    "blockNumber": "0x10",
    "contractAddress": null,
    "cumulativeGasUsed": "0x11dde",
    "effectiveGasPrice": "0x23ebdf",
    "from": "0xf39fd6e51aad88f6f4ce6ab8827279cfffb92266",
    "gasUsed": "0x5208",
    "logs": [],
    "logsBloom": "0x00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000",
    "status": "0x1",
    "to": "0xa7b8c275b3dde39e69a5c0ffd9f34f974364941a",
    "transactionHash": "0xf98a6b5de84ee59666d0ff3d8c361f308c3a22fc0bb94466810777d60a3ed7a7",
    "transactionIndex": "0x1",
    "type": "0x0"
  }
}
```

If the transaction is not executed within 10 seconds, e.g., because of congestion at
the sequencer, it returns an error.

```
{
  "jsonrpc": "2.0",
  "id": 1,
  "error": {
    "code": -32000,
    "message": "realtime transaction expired"
  }
}
```

# Paginated Log Queries with Cursors

## Overview

`eth_getLogsWithCursor` is an enhanced version of `eth_getLogs` that adds
support for pagination via a cursor. This allows applications to query large
sets of logs while gracefully handing execution or memory limits on the RPC
server. When a query exceeds server-side resource caps, the server returns a
partial result and a cursor that marks where it left off. The client can then
continue the query from that point.

This method accepts the same parameters as `eth_getLogs`, with an additional
optional `cursor`, which is an opaque string. If the query is too large and
hits the server-side caps, it returns a partial list of logs and a `cursor`
pointing to the next log to fetch. Clients can resume the query using the
provided `cursor`. Absence of a `cursor` in the request indicates that the
server should start the query at `fromBlock` as usual. Absence of a returned
`cursor` indicates the query is complete. The cursor is derived from
`(blockNumber + logIndex)` of the last log in the current batch, but users
should treat it as an opaque string.

## Example

To send an initial request, start with a standard `eth_getLogs`-style query.
Set `fromBlock` and `toBlock` (or `blockHash`) and do *not* include a cursor.

```
{
  "jsonrpc": "2.0",
  "method": "eth_getLogsWithCursor",
  "params": [
    {
      "fromBlock": "0x100",
      "toBlock": "0x200",
      "address": "0x1234567890abcdef1234567890abcdef12345678",
      "topics": ["0xddf252ad..."]
    }
  ],
  "id": 1
}
```

If the server reaches its processing limit (e.g. max logs or execution time),
it will return the logs retrieved so far and include a `cursor` indicating the
last log processed.

```
{
  "jsonrpc": "2.0",
  "id": 1,
  "result": {
    "logs": [
      {
        "address": "0x1234567890abcdef1234567890abcdef12345678",
        "blockNumber": "0x101",
        "logIndex": "0x0",
        "topics": ["0xddf252ad..."],
        "data": "0x...",
        "transactionHash": "0x...",
        "transactionIndex": "0x0",
        "blockHash": "0x...",
        "removed": false
      }
    ],
    "cursor": "0x0000010100000000"  
  }
}
```

The client should submit a second request with the same filter (e.g. address, topics, block range) and the `cursor` from the previous response (mandatory). The server will resume the query from where it left off.
   
```
{
  "jsonrpc": "2.0",
  "method": "eth_getLogsWithCursor",
  "params": [
    {
      "fromBlock": "0x100",
      "toBlock": "0x200",
      "address": "0x1234567890abcdef1234567890abcdef12345678",
      "topics": ["0xddf252ad..."],
      "cursor": "0x0000010100000000"
    }
  ],
  "id": 2
}
```

When the server returns a response *without* a `cursor`, it means that all matching logs have been retrieved and no further requests are needed

```
{
  "jsonrpc": "2.0",
  "id": 2,
  "result": {
    "logs": [
      {
        "address": "0x1234567890abcdef1234567890abcdef12345678",
        "blockNumber": "0x102",
        "logIndex": "0x3",
        "topics": ["0xddf252ad..."],
        "data": "0x...",
        "transactionHash": "0x...",
        "transactionIndex": "0x2",
        "blockHash": "0x...",
        "removed": false
      }
    ]
    // No cursor field — query is complete
  }
}
```




