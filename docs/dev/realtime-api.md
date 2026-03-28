---
description: MegaETH Realtime API — low-latency extensions to Ethereum JSON-RPC including WebSocket subscriptions, realtime_sendRawTransaction, eth_callAfter, and eth_getLogsWithCursor.
---

# Realtime API

MegaETH executes transactions as soon as they arrive at the sequencer.
The sequencer emits _preconfirmations_ and _execution results_ of the transactions within 10 milliseconds of their arrival.

Such information is exposed through MegaETH's _Realtime API_, an extension to Ethereum JSON-RPC optimized for low-latency access.
This API queries against the most recent _mini-block_.
Receipts and state changes associated with a transaction are reflected in this API as soon as the transaction is packaged into a mini-block, which usually happens within 10 milliseconds of its arrival at the sequencer.
In comparison, the vanilla Ethereum JSON-RPC API queries against the most recent _EVM block_, which leads to much longer delay before execution results are reflected.

Mini-blocks in MegaETH are preconfirmed by the sequencer just like EVM blocks are.
The sequencer makes as much effort not to roll back mini-blocks as it does EVM blocks.
Results returned by the Realtime API still fall under the preconfirmation guarantee by the sequencer.

{% hint style="info" %}
The Realtime API is an evolving standard.
Additional functionality will be added based on feedback.
This document will be kept up to date.
{% endhint %}

## Overview of Changes

The Realtime API introduces three types of changes to the vanilla Ethereum JSON-RPC API:

1. Most methods that query chain and account states return values as of the most recent mini-block, when invoked with `pending` or `latest` as the block tag.
2. Most methods that query transaction data are able to "see" a transaction and return results as soon as the transaction of interest is packaged into a mini-block.
3. `eth_subscribe`, when invoked over WebSocket, streams transaction logs, state changes, and block content as soon as the corresponding mini-block is produced.
4. `realtime_sendRawTransaction` submits a transaction and returns the receipt in a single call — without requiring polling.
5. `eth_getLogsWithCursor` supports paginated log queries using a cursor, allowing applications to retrieve large datasets incrementally and reliably.
6. `eth_callAfter` allows executing `eth_call` after waiting for an account's nonce to reach a target value.

## Querying Account and Chain States

The following methods, when invoked with `pending` or `latest` as the block tag, return results up to the most recent mini-block.

| Method |
| ------ |
| `eth_getBalance` |
| `eth_getStorageAt` |
| `eth_getTransactionCount` |
| `eth_getCode` |
| `eth_call` |
| `eth_callMany` |
| `eth_createAccessList` |
| `eth_estimateGas` |

### Example

At 5pm, the height of the most recent mini-block is 10000, and the height of the most recent EVM block is 100.
At this point, Alice's account has a balance of 10 Ether.

At 100 milliseconds past 5pm, the height of the most recent mini-block is 10010, and the height of the most recent EVM block is still 100.
Now, Alice sends a transaction that transfers 1 Ether to Bob.
This transaction will decrease her account balance by 1 Ether.

At 110 milliseconds past 5pm, the transaction is picked up and executed by the sequencer, and packaged into the mini-block at height 10011.
Now, Bob invokes `eth_getBalance` on Alice's account with `latest` as the block tag; he gets a response of 9 Ether, because the transaction has been packaged into a mini-block and is thus reflected in the Realtime API.
However, Charlie, who makes the same query with `100` as the block tag, still sees 10 Ether, because the transaction has not been packaged into an EVM block, which will not happen until 1 second past 5pm.

## Querying Transactions

The following methods are able to locate a transaction in the database and return results as soon as the transaction is packaged into a mini-block.
No special parameters are needed when invoking the methods.

| Method |
| ------ |
| `eth_getTransactionByHash` |
| `eth_getTransactionReceipt` |

### Example

Continuing the previous example, Alice invokes `eth_getTransactionReceipt` on her transaction at 110 milliseconds past 5pm.
The API responds with the correct receipt, even though no EVM block has been produced since she sent her transaction.
This is because her transaction is already packaged into the mini-block at height 10011 and the Realtime API can thus see the transaction.

## `eth_subscribe` over WebSocket

When invoked over WebSocket, `eth_subscribe` streams data as soon as the corresponding mini-block is produced.
This is the mechanism to get transaction preconfirmation and execution results with the minimum amount of latency.
Please call `eth_unsubscribe` when a subscription is no longer needed.

{% hint style="warning" %}
WebSocket connections require periodic client activity to remain open.
Clients should send `eth_chainId` at least once every 30 seconds to keep the WebSocket connection alive.
Idle connections may be closed by the server.
{% endhint %}

### Logs

When both `fromBlock` and `toBlock` are set to `pending`, the API returns logs as soon as transactions are packaged into mini-blocks.

```json
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

It is also possible to filter the logs by contract addresses and topics:

```json
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

### State Changes

`stateChanges` is a new subscription type that streams state changes of an account as soon as the transactions making the changes are packaged into mini-blocks.
It takes a list of account addresses to monitor as a parameter.

```json
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

Each response shows the latest account balance, nonce, and values of storage slots that changed.
The schema is:

```json
{
    "address": "Address",
    "nonce": "number",
    "balance": "U256",
    "storage": {
       "U256": "U256"
    }
}
```

Example response:

```json
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

### Mini-Blocks

`miniBlocks` is a new subscription type that streams mini-blocks as they are produced.

```json
{
    "jsonrpc": "2.0",
    "method": "eth_subscribe",
    "params": [
        "miniBlocks"
    ],
    "id": 83
}
```

The returned mini-blocks use the following schema:

```json
{
    "block_number": "HexString",
    "block_timestamp": "HexString",
    "index": "HexString",
    "mini_block_number": "HexString",
    "mini_block_timestamp": "HexString",
    "gas_used": "HexString",
    "transactions": [],
    "receipts": []
}
```

| Field | Description |
| ----- | ----------- |
| `block_number` | The block number of the EVM block that this mini-block belongs to |
| `block_timestamp` | Timestamp of the EVM block |
| `index` | Index of this mini-block in the EVM block |
| `mini_block_number` | The number of this mini-block in blockchain history |
| `mini_block_timestamp` | The timestamp when this mini-block was created (Unix timestamp in microseconds) |
| `gas_used` | Gas used inside this mini-block |
| `transactions` | Transactions included in this mini-block (same schema as `eth_getTransactionByHash`) |
| `receipts` | Receipts of the transactions in this mini-block (same schema as `eth_getTransactionReceipt`) |

## `realtime_sendRawTransaction`

### Overview

`realtime_sendRawTransaction` simplifies realtime dApp development by returning the transaction receipt directly, without requiring polling `eth_getTransactionReceipt`.
It accepts the same parameters as `eth_sendRawTransaction` but waits for the transaction to be executed and returns its receipt as the response.
This method times out after 10 seconds, in which case it returns a `realtime transaction expired` error, indicating that the user should revert to querying `eth_getTransactionReceipt`.

`realtime_sendRawTransaction` is a drop-in replacement for `eth_sendRawTransaction`.

### Request

```json
{
  "jsonrpc": "2.0",
  "method": "realtime_sendRawTransaction",
  "params": [
    "0x<hex-encoded-signed-tx>"
  ],
  "id": 1
}
```

### Successful Response

If the submitted transaction is executed within 10 seconds, it returns the receipt of the executed transaction.

```json
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

### Timeout Error Response

If the transaction is not executed within 10 seconds (e.g., because of congestion at the sequencer), it returns an error.

```json
{
  "jsonrpc": "2.0",
  "id": 1,
  "error": {
    "code": -32000,
    "message": "realtime transaction expired"
  }
}
```

## `eth_callAfter`

### Overview

`eth_callAfter` is a specialized version of `eth_call` that waits for an account's nonce to reach a target value before executing the call.
This is useful for simulating transactions that depend on the completion of prior transactions, such as checking the result of a swap after a preceding approval transaction has been confirmed.

### Parameters

| Parameter | Type | Required | Description |
| --------- | ---- | -------- | ----------- |
| `request` | Object | Yes | Standard `eth_call` request object (same as `eth_call`) |
| `condition` | Object | Yes | Condition that must be met before executing the call |
| `state_override` | Object | No | State overrides to apply (same as `eth_call`) |
| `block_overrides` | Object | No | Block overrides to apply (same as `eth_call`) |

#### Condition Object

| Field | Type | Required | Description |
| ----- | ---- | -------- | ----------- |
| `account` | Address | Yes | The account address whose nonce to monitor |
| `nonce` | Hex Number | Yes | The target nonce value to wait for |
| `timeout` | Number | No | Maximum time to wait in milliseconds (default: 3000, max: 60000) |

### Returns

Returns the same result as `eth_call` — the return data from the executed call.

### Error Codes

| Code | Message | Description |
| ---- | ------- | ----------- |
| -32000 | `Timeout: timeout waiting for nonce condition` | The nonce condition was not met within the timeout period |
| -32000 | `InternalError` | An internal error occurred while processing the request |

### Example

Execute an `eth_call` after waiting for an account's nonce to reach 5:

```json
{
  "jsonrpc": "2.0",
  "method": "eth_callAfter",
  "params": [
    {
      "from": "0xf39fd6e51aad88f6f4ce6ab8827279cfffb92266",
      "to": "0x1234567890abcdef1234567890abcdef12345678",
      "data": "0x70a08231000000000000000000000000f39fd6e51aad88f6f4ce6ab8827279cfffb92266"
    },
    {
      "account": "0xf39fd6e51aad88f6f4ce6ab8827279cfffb92266",
      "nonce": "0x5",
      "timeout": 30000
    }
  ],
  "id": 1
}
```

Successful response:

```json
{
  "jsonrpc": "2.0",
  "id": 1,
  "result": "0x0000000000000000000000000000000000000000000000000de0b6b3a7640000"
}
```

Error response (condition not met):

```json
{
  "jsonrpc": "2.0",
  "id": 1,
  "error": {
    "code": -32000,
    "message": "Timeout: timeout waiting for nonce condition"
  }
}
```

## `eth_getLogsWithCursor`

### Overview

`eth_getLogsWithCursor` is an enhanced version of `eth_getLogs` that adds support for pagination via a cursor.
This allows applications to query large sets of logs while gracefully handling execution or memory limits on the RPC server.
When a query exceeds server-side resource caps, the server returns a partial result and a cursor that marks where it left off.
The client can then continue the query from that point.

This method accepts the same parameters as `eth_getLogs`, with an additional optional `cursor` (an opaque string).
If the query is too large and hits the server-side caps, it returns a partial list of logs and a `cursor` pointing to the next log to fetch.
Clients can resume the query using the provided `cursor`.
Absence of a `cursor` in the request indicates that the server should start the query at `fromBlock` as usual.
Absence of a returned `cursor` indicates the query is complete.
The cursor is derived from `(blockNumber + logIndex)` of the last log in the current batch, but users should treat it as an opaque string.

### Example: Initial Request

Start with a standard `eth_getLogs`-style query.
Set `fromBlock` and `toBlock` (or `blockHash`) and do not include a cursor.

```json
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

### Example: Partial Response with Cursor

If the server reaches its processing limit (e.g., max logs or execution time), it returns the logs retrieved so far and includes a `cursor` indicating the last log processed.

```json
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

### Example: Continuation Request

Submit a second request with the same filter and the `cursor` from the previous response.
The server will resume the query from where it left off.

```json
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

### Example: Complete Response (No Cursor)

When the server returns a response without a `cursor`, all matching logs have been retrieved and no further requests are needed.

```json
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
  }
}
```

## Related Pages

- [Mini-Blocks](miniblocks.md) — understanding the two block types
- [RPC Reference](rpc/README.md) — full method availability table
