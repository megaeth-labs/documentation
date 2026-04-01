---
description: realtime_sendRawTransaction — submit a transaction and receive the receipt in a single call without polling.
---

# realtime_sendRawTransaction

Submits a signed transaction and returns the receipt directly once the transaction is executed — no polling required.
This is a drop-in replacement for `eth_sendRawTransaction` that eliminates the need to poll `eth_getTransactionReceipt`.
The method times out after 10 seconds if the transaction has not been executed.

## Parameters

| Position | Type   | Required | Notes                          |
| -------- | ------ | -------- | ------------------------------ |
| `0`      | `Data` | Yes      | Hex-encoded signed transaction |

## Returns

A transaction receipt object on success:

| Field             | Type              | Notes                                            |
| ----------------- | ----------------- | ------------------------------------------------ |
| `transactionHash` | `Data` (32 bytes) | Hash of the submitted transaction                |
| `blockNumber`     | `Quantity`        | Block containing the transaction                 |
| `from`            | `Data` (20 bytes) | Sender address                                   |
| `to`              | `Data` (20 bytes) | Recipient address (`null` for contract creation) |
| `gasUsed`         | `Quantity`        | Gas consumed by the transaction                  |
| `status`          | `Quantity`        | `0x1` for success, `0x0` for revert              |
| `logs`            | `Log[]`           | Event logs emitted during execution              |
| `contractAddress` | `Data` (20 bytes) | Deployed contract address, or `null`             |

## Errors

| Code     | Cause                                                                       | Fix                                              |
| -------- | --------------------------------------------------------------------------- | ------------------------------------------------ |
| `-32000` | `realtime transaction expired` — transaction not executed within 10 seconds | Fall back to polling `eth_getTransactionReceipt` |

See also [Error reference](error-codes.md).

## Example

```bash
curl -sS https://mainnet.megaeth.com/rpc \
  -X POST -H "Content-Type: application/json" \
  -d '{"jsonrpc":"2.0","id":1,"method":"realtime_sendRawTransaction","params":["0x<hex-encoded-signed-tx>"]}'
```

Successful response:

```json
{
  "jsonrpc": "2.0",
  "id": 1,
  "result": {
    "transactionHash": "0xf98a6b5de84ee59666d0ff3d8c361f308c3a22fc0bb94466810777d60a3ed7a7",
    "blockNumber": "0x10",
    "from": "0xf39fd6e51aad88f6f4ce6ab8827279cfffb92266",
    "to": "0xa7b8c275b3dde39e69a5c0ffd9f34f974364941a",
    "gasUsed": "0x5208",
    "status": "0x1",
    "logs": [],
    "contractAddress": null
  }
}
```

Timeout response:

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
