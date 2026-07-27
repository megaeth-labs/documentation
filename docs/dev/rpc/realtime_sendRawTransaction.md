---
description: realtime_sendRawTransaction — submit a transaction and receive the receipt in a single call without polling.
---

# realtime_sendRawTransaction

## Summary

Submits a signed transaction and returns the receipt directly once the transaction is executed — no polling required.
This is a drop-in replacement for `eth_sendRawTransaction` that eliminates the need to poll `eth_getTransactionReceipt`.
When no timeout is supplied, the node uses its 5-second default wait.
The public gateway accepts an optional timeout but caps it at 3,000 milliseconds.
The gateway routes this method and [`eth_sendRawTransactionSync`](./eth_sendRawTransactionSync.md) through the same synchronous submission handler, so their parameters and receipt behavior are equivalent.

The public MegaETH endpoint supports this method. The standard, node, and gateway layers below identify behavior that differs from a generic Ethereum endpoint.

## Parameters

| Position | Type     | Required | Notes                                                         |
| -------- | -------- | -------- | ------------------------------------------------------------- |
| `0`      | `Data`   | Yes      | Hex-encoded signed transaction                                |
| `1`      | `number` | No       | Wait timeout in milliseconds; capped at `3000` by the gateway |

## Result

A transaction receipt object on success:

| Field             | Type              | Notes                                            |
| ----------------- | ----------------- | ------------------------------------------------ |
| `transactionHash` | `Data` (32 bytes) | Hash of the submitted transaction                |
| `blockHash`       | `Data` (32 bytes) | Block containing the transaction                 |
| `blockNumber`     | `Quantity`        | Block containing the transaction                 |
| `from`            | `Data` (20 bytes) | Sender address                                   |
| `to`              | `Data` (20 bytes) | Recipient address (`null` for contract creation) |
| `gasUsed`         | `Quantity`        | Gas consumed by the transaction                  |
| `status`          | `Quantity`        | Nonzero for success; zero for revert             |
| `logs`            | `Log[]`           | Event logs emitted during execution              |
| `contractAddress` | `Data` (20 bytes) | Deployed contract address, or `null`             |

For receipts produced from a streaming mini-block, `blockHash` can temporarily be the all-`ff` placeholder until the enclosing EVM block is committed.
Refetch the receipt with `eth_getTransactionReceipt` after block sealing when a canonical block hash is required.

## Comparison with Ethereum Standard JSON-RPC

### Ethereum Standard

`realtime_sendRawTransaction` is not part of the core Ethereum execution JSON-RPC API. It is a MegaETH extension.

### MegaETH Node Behavior

MegaETH adds this synchronous submission method. It returns a real-time receipt and uses the same node implementation as `eth_sendRawTransactionSync`.

### MegaETH Public Gateway

The gateway routes this name and `eth_sendRawTransactionSync` through the same synchronous handler. After gateway-side validation, both names are rewritten to the node's `realtime_sendRawTransactionWithSender` method. The gateway caps explicit waits at 3,000 milliseconds and accepts request bodies up to 2.5 MiB.

## Errors

The `| Scope |` column distinguishes method failures from gateway policy errors.

| Code     | Scope            | Message           | When it happens                                                                |
| -------- | ---------------- | ----------------- | ------------------------------------------------------------------------------ |
| `-32000` | Method           | Server error      | `realtime transaction expired` — receipt not available before the wait expired |
| `-32099` | Transport/policy | Payload too large | The request body exceeds the 2.5 MiB public endpoint limit.                    |

See also [Error Codes](./error-codes.md).

## Examples

Endpoint: `https://mainnet.megaeth.com/rpc`

Capture date: July 24, 2026

Outcome: success

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

## Sources

- Spec: EIP-1474 for JSON-RPC framing and error conventions; this method is an extension or legacy compatibility method.
- Code: `git@github.com:megaeth-labs/mega-reth.git @ ab60376631228edab3a6df180f295280bad26e93: crates/megaeth/rpc/src/realtime.rs`
- Code: `git@github.com:megaeth-labs/mega-rpc.git @ 06aa35aa95d569c227cc25d2aa12834eb0458aa0: workers/src/sequencer-guard/single-tx.ts`
- Probe: MegaETH Mainnet public endpoint, July 24, 2026
