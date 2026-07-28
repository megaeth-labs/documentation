---
description: "mega_getWithdrawalProof JSON-RPC reference for MegaETH."
---

# mega_getWithdrawalProof

## Summary

Returns a Merkle proof for the L2ToL1MessagePasser contract at a given block.

The public MegaETH endpoint supports this method. The standard, node, and gateway layers below identify behavior that differs from a generic Ethereum endpoint.

## Parameters

**`address`** Address **REQUIRED**

The contract address to prove.
For withdrawal verification, use the L2-to-L1 message passer address `0x4200000000000000000000000000000000000016`.

---

**`storageKeys`** Bytes32[] **REQUIRED**

Storage keys to prove; empty array is valid.

---

**`block`** string **REQUIRED ON THE PUBLIC GATEWAY**

Hex block number or tag (`latest`, `safe`, `finalized`, `earliest`, `pending`).
The node defaults an omitted value to `latest`, but the public endpoint requires all three positional parameters.

## Result

- **`address`** Address

  Proved address.

- **`accountProof`** Data[]

  Account trie proof nodes.

- **`balance`** Quantity

  Account balance.

- **`codeHash`** Hash32

  Account code hash.

- **`nonce`** Quantity

  Account nonce.

- **`storageHash`** Hash32

  Storage trie root.

- **`storageProof`** object[]

  Per-key storage proofs; each entry has `key` (`Bytes32`), `value` (`Bytes32`), `proof` (`Data[]`).

## Comparison with Ethereum Standard JSON-RPC

### Ethereum Standard

`mega_getWithdrawalProof` is not part of the core Ethereum execution JSON-RPC API. It is a MegaETH extension for OP Stack withdrawal proofs.

### MegaETH Node Behavior

The current MegaETH node registers the withdrawal-proof implementation as `eth_getWithdrawalProof`; it does not register this `mega_*` alias.

### MegaETH Public Gateway

The gateway rewrites this alias to `eth_getWithdrawalProof` and caches successful proofs for 30 minutes. Callers receive the same result shape under either name.

## Errors

The `| Scope |` column distinguishes method failures from gateway policy errors.

| Code     | Scope            | Message             | When it happens                                                                     |
| -------- | ---------------- | ------------------- | ----------------------------------------------------------------------------------- |
| `-32602` | Request          | Invalid params      | A storage key is not a valid 32-byte hex string, or required parameters are missing |
| `-32000` | Method           | Server error        | The requested block cannot be resolved                                              |
| `-32005` | Transport/policy | Rate limit exceeded | The caller exceeds the public gateway's simple read budget.                         |
| `-32099` | Transport/policy | Payload too large   | The request body exceeds the 128 KiB public endpoint limit.                         |

See also [Error Codes](../error-codes.md).

## Examples

Endpoint: `https://mainnet.megaeth.com/rpc`

Capture date: July 24, 2026

Outcome: success

```json
{
  "jsonrpc": "2.0",
  "id": 1,
  "method": "mega_getWithdrawalProof",
  "params": ["0x4200000000000000000000000000000000000016", [], "latest"]
}
```

```json
{
  "jsonrpc": "2.0",
  "id": 1,
  "result": {
    "address": "0x4200000000000000000000000000000000000016",
    "balance": "0x0",
    "codeHash": "0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470",
    "nonce": "0x0",
    "storageHash": "0xddd6dcaf75eeb81fb4701c2a39b3132bd60bf9602e2fcbe5852f5d07e14c8084",
    "accountProof": [],
    "storageProof": []
  }
}
```

## Sources

- Spec: EIP-1474 for JSON-RPC framing and error conventions; this method is an extension or legacy compatibility method.
- Code: `git@github.com:megaeth-labs/mega-reth.git @ ab60376631228edab3a6df180f295280bad26e93: crates/megaeth/rpc/src/eth/ext.rs`
- Code: `git@github.com:megaeth-labs/mega-rpc.git @ 06aa35aa95d569c227cc25d2aa12834eb0458aa0: workers/src/spec/methods.ts`
- Probe: MegaETH Mainnet public endpoint, July 24, 2026
