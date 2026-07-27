---
description: "eth_sendRawTransactionSync JSON-RPC reference for MegaETH."
---

# eth_sendRawTransactionSync

## Summary

Submits a signed transaction and returns a receipt once the transaction is included in a block.
The public gateway routes this method and [`realtime_sendRawTransaction`](./realtime_sendRawTransaction.md) through the same synchronous submission handler, with the same parameters and receipt result.

The public MegaETH endpoint supports this method. The standard, node, and gateway layers below identify behavior that differs from a generic Ethereum endpoint.

## Parameters

**`data`** Data **REQUIRED**

Signed raw transaction bytes.

---

**`timeoutMs`** number

Client wait budget in milliseconds.
When omitted, the node uses its 5-second default; the public gateway caps explicit values at `3000` (3 s).

## Result

- **`transactionHash`** Hash32

  Transaction hash.

- **`status`** Quantity

  A nonzero status indicates success; zero means the transaction reverted but was included on-chain.

- **`blockHash`** Hash32

  Containing block hash.
  A receipt produced from a streaming mini-block can temporarily contain the all-`ff` placeholder hash until the enclosing EVM block is committed.
  Refetch the receipt with `eth_getTransactionReceipt` after block sealing when a canonical block hash is required.

- **`blockNumber`** Quantity

  Containing block number.

- **`from`** Address

  Sender.

- **`to`** Address | null

  Recipient; `null` for contract creation.

- **`gasUsed`** Quantity

  Gas consumed by this transaction.

- **`effectiveGasPrice`** Quantity

  Effective gas price.

- **`contractAddress`** Address | null

  Created contract address when applicable.

- **`logs`** Log[]

  Emitted log entries.

Additional fields include `cumulativeGasUsed`, `logsBloom`, `type`, and L1 fee fields (`l1Fee`, `l1GasPrice`, `l1GasUsed`, etc.).

## Comparison with Ethereum Standard JSON-RPC

### Ethereum Standard

`eth_sendRawTransactionSync` is not part of the core Ethereum execution JSON-RPC API. It is a compatibility extension exposed by the MegaETH public gateway.

### MegaETH Node Behavior

The current MegaETH node does not register this `eth_*` alias. Its native synchronous submission method is `realtime_sendRawTransaction`; the node waits up to 5 seconds by default for a real-time receipt.

### MegaETH Public Gateway

The gateway exposes this compatibility name and routes it and `realtime_sendRawTransaction` through the same handler. Both are rewritten to the node's `realtime_sendRawTransactionWithSender` method after gateway-side validation. The gateway caps explicit waits at 3,000 milliseconds and accepts request bodies up to 2.5 MiB. An expiry is inconclusive: the transaction may still land.

## Errors

The `| Scope |` column distinguishes method failures from gateway policy errors.

| Code     | Scope            | Message           | When it happens                                                                            |
| -------- | ---------------- | ----------------- | ------------------------------------------------------------------------------------------ |
| `-32602` | Request          | Invalid params    | Raw transaction is malformed, undecodable, or `timeoutMs` is invalid                       |
| `-32000` | Method           | Server error      | Receipt not available before the wait window expired, or the node rejected the transaction |
| `-32099` | Transport/policy | Payload too large | The request body exceeds the 2.5 MiB public endpoint limit.                                |

See also [Error Codes](../error-codes.md).

## Examples

Endpoint: `https://mainnet.megaeth.com/rpc`

Capture date: July 24, 2026

Outcome: success

```json
{
  "jsonrpc": "2.0",
  "id": 91,
  "method": "eth_sendRawTransactionSync",
  "params": [
    "0xf86480830f424082ea6094cc4b43ab7230cc5913801a746c1834aa06c4e7e780808231b2a0b8126d2c41a6c7dbd0a9e219233497057bb391e7ee1d628370f9c1456f82b054a06663fde9daa2fae784c3dac1c9a5a973d538e3a12ec9c0e4d3cee9c70ba2b239",
    3000
  ]
}
```

```json
{
  "jsonrpc": "2.0",
  "id": 91,
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

## Sources

- Spec: EIP-1474 for JSON-RPC framing and error conventions; this method is an extension or legacy compatibility method.
- Code: `git@github.com:megaeth-labs/mega-reth.git @ ab60376631228edab3a6df180f295280bad26e93: crates/megaeth/rpc/src/realtime.rs`
- Code: `git@github.com:megaeth-labs/mega-rpc.git @ 06aa35aa95d569c227cc25d2aa12834eb0458aa0: workers/src/sequencer-guard/single-tx.ts`
- Probe: MegaETH Mainnet public endpoint, July 24, 2026
