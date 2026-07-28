---
description: "Returns a withdrawal-storage proof for MegaETH's L2-to-L1 message passer contract."
---

# eth_getWithdrawalProof

## Summary

Returns the same proof as [`mega_getWithdrawalProof`](./mega_getWithdrawalProof.md).
The gateway routes both method names to the same node implementation.

The public MegaETH endpoint supports this method. The standard, node, and gateway layers below identify behavior that differs from a generic Ethereum endpoint.

## Parameters

| Position | Name          | Type                | Required | Description                                                                                              |
| -------- | ------------- | ------------------- | -------- | -------------------------------------------------------------------------------------------------------- |
| `0`      | `address`     | `Address`           | Yes      | Contract address to prove; use `0x4200000000000000000000000000000000000016` for withdrawal verification. |
| `1`      | `storageKeys` | `Bytes32[]`         | Yes      | Withdrawal-message storage keys to prove; an empty array is valid.                                       |
| `2`      | `block`       | block number or tag | Yes      | State against which to build the proof.                                                                  |

## Result

An EIP-1186-style account proof containing `accountProof`, `balance`, `codeHash`, `nonce`, `storageHash`, and one `storageProof` entry per requested key.

## Comparison with Ethereum Standard JSON-RPC

### Ethereum Standard

`eth_getWithdrawalProof` is not part of the core Ethereum execution JSON-RPC API. It is a MegaETH compatibility extension for the withdrawal-proof API.

### MegaETH Node Behavior

MegaETH implements this OP Stack withdrawal-proof extension for the L2-to-L1 message passer. It returns an EIP-1186-style account and storage proof.

### MegaETH Public Gateway

The public gateway exposes this method and caches successful proofs for 30 minutes. All three positional parameters are required at the gateway.

## Errors

The `| Scope |` column distinguishes method failures from gateway policy errors.

No method-specific errors were observed.

| Code     | Scope            | Message             | When it happens                                             |
| -------- | ---------------- | ------------------- | ----------------------------------------------------------- |
| `-32005` | Transport/policy | Rate limit exceeded | The caller exceeds the public gateway's simple read budget. |
| `-32099` | Transport/policy | Payload too large   | The request body exceeds the 128 KiB public endpoint limit. |

See also [Error Codes](../error-codes.md).

## Examples

Endpoint: `https://mainnet.megaeth.com/rpc`

Capture date: July 27, 2026

Outcome: success

```json
{
  "jsonrpc": "2.0",
  "id": 1,
  "method": "eth_getWithdrawalProof",
  "params": ["0x4200000000000000000000000000000000000016", [], "latest"]
}
```

```json
{
  "jsonrpc": "2.0",
  "id": 1,
  "result": {
    "address": "0x4200000000000000000000000000000000000016",
    "accountProof": [],
    "balance": "0x0",
    "codeHash": "0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470",
    "nonce": "0x0",
    "storageHash": "0x891f4462376be7ecac17a67a0ee5be7bc0c35979c182e5f7f19ebb2b1e320cc3",
    "storageProof": []
  }
}
```

## Sources

- Spec: EIP-1474 for JSON-RPC framing and error conventions; this method is an extension or legacy compatibility method.
- Code: `git@github.com:megaeth-labs/mega-reth.git @ ab60376631228edab3a6df180f295280bad26e93: crates/megaeth/rpc/src/eth/ext.rs`
- Code: `git@github.com:megaeth-labs/mega-rpc.git @ 06aa35aa95d569c227cc25d2aa12834eb0458aa0: workers/src/spec/methods.ts`
- Probe: MegaETH Mainnet public endpoint, July 27, 2026
