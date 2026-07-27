---
description: "eth_getTransactionReceipt JSON-RPC reference for MegaETH."
---

# eth_getTransactionReceipt

## Summary

Returns a transaction receipt by hash.

The public MegaETH endpoint supports this method. The standard, node, and gateway layers below identify behavior that differs from a generic Ethereum endpoint.

## Parameters

**`transactionHash`** Hash32 **REQUIRED**

Hash of the target transaction.

## Result

`Receipt | null` — `null` when the transaction is unknown or not yet mined.

- **`transactionHash`** Hash32

  Transaction hash.

- **`status`** Quantity

  A nonzero status indicates success; zero indicates that execution reverted.

- **`blockHash`** Hash32

  Containing block hash.

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

The canonical Ethereum method uses the parameter and result contract documented above, including the stated `null`, `false`, or zero-value semantics where applicable.

### MegaETH Node Behavior

The node returns `null` until a receipt is visible. Receipts produced from a real-time mini-block may temporarily use the all-`ff` block-hash placeholder until the EVM block seals.

### MegaETH Public Gateway

The gateway first checks its receipt cache, forwards misses upstream, and caches non-null receipts for 30 minutes. A `null` result is not cached.

## Errors

The `| Scope |` column distinguishes method failures from gateway policy errors.

| Code     | Scope            | Message             | When it happens                                             |
| -------- | ---------------- | ------------------- | ----------------------------------------------------------- |
| `-32602` | Request          | Invalid params      | Transaction hash is missing or malformed                    |
| `-32005` | Transport/policy | Rate limit exceeded | The caller exceeds the public gateway's simple read budget. |
| `-32099` | Transport/policy | Payload too large   | The request body exceeds the 128 KiB public endpoint limit. |

See also [Error Codes](./error-codes.md).

## Examples

Endpoint: `https://mainnet.megaeth.com/rpc`

Capture date: July 24, 2026

Outcome: success

```json
{
  "jsonrpc": "2.0",
  "id": 120,
  "method": "eth_getTransactionReceipt",
  "params": [
    "0xf3473347041eb4ccc045ee58e6c79c80d98ee4aa783d49e49c69d0a0e50d8ed6"
  ]
}
```

```json
{
  "jsonrpc": "2.0",
  "id": 120,
  "result": {
    "type": "0x2",
    "status": "0x1",
    "transactionHash": "0xf3473347041eb4ccc045ee58e6c79c80d98ee4aa783d49e49c69d0a0e50d8ed6",
    "blockHash": "0xf773491fd24617452b30c3ed626bf440b5846b9c818ec7d8d7f71c9a02993c8b",
    "blockNumber": "0xb120c6",
    "gasUsed": "0x215ec",
    "effectiveGasPrice": "0xf4241",
    "from": "0xa344fb2d117501ee379d2ea9c0c016959ad94f1e",
    "to": "0x5e3ae52eba0f9740364bd5dd39738e1336086a8b",
    "contractAddress": null,
    "l1Fee": "0x4ab5901"
  }
}
```

## Sources

- Spec: `git@github.com:ethereum/execution-apis.git @ d24f58b56dcd16ab0f0c70ec609bcc1c42750b51: src/eth/transaction.yaml`
- Code: `git@github.com:megaeth-labs/mega-reth.git @ ab60376631228edab3a6df180f295280bad26e93: crates/rpc/rpc-eth-api/src/core.rs`
- Code: `git@github.com:megaeth-labs/mega-rpc.git @ 06aa35aa95d569c227cc25d2aa12834eb0458aa0: workers/src/processors/tx-receipt-processor.ts`
- Probe: MegaETH Mainnet public endpoint, July 24, 2026
