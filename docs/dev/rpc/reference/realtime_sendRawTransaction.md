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

See also [Error Codes](../error-codes.md).

## Examples

Endpoint: `https://mainnet.megaeth.com/rpc`

Capture date: July 24, 2026

Outcome: success

The gateway routes this method and `eth_sendRawTransactionSync` through the same handler, so their successful receipt responses have the same structure:

```json
{
  "jsonrpc": "2.0",
  "id": 1,
  "result": {
    "type": "0x0",
    "status": "0x1",
    "transactionHash": "0x8d3b1e22e7a9026c8658b5d922293d59e4de7c3382bb832d6890e6ab23ad7ec7",
    "transactionIndex": "0x5",
    "blockHash": "0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff",
    "blockNumber": "0xe7133c",
    "from": "0xcc4b43ab7230cc5913801a746c1834aa06c4e7e7",
    "to": "0xcc4b43ab7230cc5913801a746c1834aa06c4e7e7",
    "gasUsed": "0xea60",
    "effectiveGasPrice": "0xf4240",
    "cumulativeGasUsed": "0x143043",
    "contractAddress": null,
    "logs": [],
    "l1GasPrice": "0x3216",
    "l1GasUsed": "0x640",
    "l1Fee": "0x6da0",
    "l1BaseFeeScalar": "0x558",
    "l1BlobBaseFee": "0x1",
    "l1BlobBaseFeeScalar": "0x0"
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
