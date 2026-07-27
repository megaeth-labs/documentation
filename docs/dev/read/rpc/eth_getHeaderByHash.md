---
description: "eth_getHeaderByHash JSON-RPC reference for MegaETH."
---

# eth_getHeaderByHash

## Summary

Returns a block header by its hash.

The public MegaETH endpoint supports this method. The standard, node, and gateway layers below identify behavior that differs from a generic Ethereum endpoint.

## Parameters

**`blockHash`** Hash32 **REQUIRED**

Target block hash.

## Result

`Header | null` — `null` when the hash does not match any known block.

- **`number`** Quantity

  Block number.

- **`hash`** Hash32

  Block hash.

- **`parentHash`** Hash32

  Parent block hash.

- **`timestamp`** Quantity

  Block timestamp.

- **`miner`** Address

  Fee recipient / coinbase.

- **`gasLimit`** Quantity

  Block gas limit.

- **`gasUsed`** Quantity

  Gas consumed.

Additional standard header fields (`stateRoot`, `logsBloom`, `transactionsRoot`, `receiptsRoot`, `baseFeePerGas`, …) are also included.

## Comparison with Ethereum Standard JSON-RPC

### Ethereum Standard

`eth_getHeaderByHash` is not part of the core Ethereum execution JSON-RPC API. It is an implementation-specific extension.

### MegaETH Node Behavior

MegaETH exposes a header-only lookup. It returns `null` when the hash is unknown and avoids serializing the block body.

### MegaETH Public Gateway

The gateway streams successful responses, caches them for 30 minutes, and records a hash-to-number mapping. A `null` result is deliberately not cached.

## Errors

The `| Scope |` column distinguishes method failures from gateway policy errors.

| Code     | Scope            | Message             | When it happens                                             |
| -------- | ---------------- | ------------------- | ----------------------------------------------------------- |
| `-32602` | Request          | Invalid params      | Block hash is missing or malformed                          |
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
  "id": 26,
  "method": "eth_getHeaderByHash",
  "params": [
    "0x6f3fcff78eefe9591d2ad590b8a78738b8ad80d9646eccd302618cd9198b73e0"
  ]
}
```

```json
{
  "jsonrpc": "2.0",
  "id": 26,
  "result": {
    "hash": "0x6f3fcff78eefe9591d2ad590b8a78738b8ad80d9646eccd302618cd9198b73e0",
    "parentHash": "0x6b6b52368c21dcdba7348fa37edae3e945013627a83a96b64d55217696899d30",
    "stateRoot": "0xf328fa2752aea1c211a73067d17c25d09a416b4b6a7785441f39bcc930028717",
    "number": "0xb10f64",
    "timestamp": "0x69c33537",
    "baseFeePerGas": "0xf4240"
  }
}
```

## Sources

- Spec: EIP-1474 for JSON-RPC framing and error conventions; this method is an extension or legacy compatibility method.
- Code: `git@github.com:megaeth-labs/mega-reth.git @ ab60376631228edab3a6df180f295280bad26e93: crates/megaeth/rpc/src/eth/ext.rs`
- Code: `git@github.com:megaeth-labs/mega-rpc.git @ 06aa35aa95d569c227cc25d2aa12834eb0458aa0: workers/src/processors/get-header-by-hash-processor.ts`
- Probe: MegaETH Mainnet public endpoint, July 24, 2026
