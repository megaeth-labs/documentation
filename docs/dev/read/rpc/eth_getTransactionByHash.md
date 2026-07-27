---
description: "eth_getTransactionByHash JSON-RPC reference for MegaETH."
---

# eth_getTransactionByHash

## Summary

Returns a transaction by its hash.

The public MegaETH endpoint supports this method. The standard, node, and gateway layers below identify behavior that differs from a generic Ethereum endpoint.

## Parameters

**`transactionHash`** Hash32 **REQUIRED**

Target transaction hash.

## Result

`Transaction | null` — `null` when the transaction cannot be found.

- **`hash`** Hash32

  Transaction hash.

- **`type`** Quantity

  Transaction type identifier.

- **`from`** Address

  Sender.

- **`to`** Address | null

  Recipient; `null` for contract creation.

- **`value`** Quantity

  Transfer value in wei.

- **`nonce`** Quantity

  Sender nonce.

- **`gas`** Quantity

  Gas limit.

- **`input`** Data

  Calldata.

- **`blockHash`** Hash32 | null

  `null` for pending transactions.

- **`blockNumber`** Quantity | null

  `null` for pending transactions.

- **`transactionIndex`** Quantity | null

  `null` for pending transactions.

Additional fields vary by transaction type (`gasPrice`, `maxFeePerGas`, `accessList`, `chainId`, `v`, `r`, `s`, etc.).

## MegaETH Behavior

### Ethereum Standard

The canonical Ethereum method uses the parameter and result contract documented above, including the stated `null`, `false`, or zero-value semantics where applicable.

### MegaETH Node Behavior

The node returns a transaction known to canonical storage or the live transaction view; an unknown hash produces `null`.

### MegaETH Public Gateway

The gateway caches included transactions for 30 minutes. A `null` result is not cached, so a later request can observe a transaction that has since become available.

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
  "id": 79,
  "method": "eth_getTransactionByHash",
  "params": [
    "0x89f0ccba20d5bbbe1cb6b44fb8d1f9a9e14b620a0b947a3de81cff684462f60c"
  ]
}
```

```json
{
  "jsonrpc": "2.0",
  "id": 79,
  "result": {
    "type": "0x0",
    "hash": "0x89f0ccba20d5bbbe1cb6b44fb8d1f9a9e14b620a0b947a3de81cff684462f60c",
    "from": "0xa887dcb9d5f39ef79272801d05abdf707cfbbd1d",
    "to": "0x6342000000000000000000000000000000000001",
    "nonce": "0x597ac57",
    "gas": "0x3d5720",
    "value": "0x0",
    "blockHash": "0xf773491fd24617452b30c3ed626bf440b5846b9c818ec7d8d7f71c9a02993c8b",
    "blockNumber": "0xb120c6",
    "transactionIndex": "0x1"
  }
}
```

## Sources

- Spec: `git@github.com:ethereum/execution-apis.git @ d24f58b56dcd16ab0f0c70ec609bcc1c42750b51: src/eth/transaction.yaml`
- Code: `git@github.com:megaeth-labs/mega-reth.git @ ab60376631228edab3a6df180f295280bad26e93: crates/rpc/rpc-eth-api/src/core.rs`
- Code: `git@github.com:megaeth-labs/mega-rpc.git @ 06aa35aa95d569c227cc25d2aa12834eb0458aa0: workers/src/processors/get-tx-by-hash-processor.ts`
- Probe: MegaETH Mainnet public endpoint, July 24, 2026
