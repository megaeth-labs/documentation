---
description: "eth_getStorageAt JSON-RPC reference for MegaETH."
---

# eth_getStorageAt

## Summary

Returns the 32-byte value stored at a given contract storage slot at a specified block.

The public MegaETH endpoint supports this method. The standard, node, and gateway layers below identify behavior that differs from a generic Ethereum endpoint.

## Parameters

**`address`** Address **REQUIRED**

Contract address.

---

**`slot`** string **REQUIRED**

Hex storage slot; use a 32-byte zero-padded value for portability.

---

**`block`** string

Hex block number, block hash, or tag (`latest`, `safe`, `finalized`, …).
The default is `"latest"`.

## Result

**`result`** Bytes32

Raw 32-byte storage word; a zero value can mean an empty slot, a non-existent account, or an explicitly stored zero.

## Comparison with Ethereum Standard JSON-RPC

### Ethereum Standard

The canonical Ethereum method uses the parameter and result contract documented above, including the stated `null`, `false`, or zero-value semantics where applicable.

### MegaETH Node Behavior

The node reads a 32-byte storage word from the selected state. A zero word does not distinguish absent storage from an explicitly stored zero.

### MegaETH Public Gateway

The gateway exposes the method in the instant read tier and does not cache the response. Historical-state retention errors from the selected backend remain visible to callers.

## Errors

The `| Scope |` column distinguishes method failures from gateway policy errors.

| Code     | Scope            | Message                    | When it happens                                              |
| -------- | ---------------- | -------------------------- | ------------------------------------------------------------ |
| `-32602` | Request          | Invalid params             | Address, slot encoding, or block selector is malformed       |
| `-32001` | Method           | Resource not found         | Block selector cannot be resolved                            |
| `4444`   | Method           | Pruned history unavailable | Requested historical state is unavailable                    |
| `-32005` | Transport/policy | Rate limit exceeded        | The caller exceeds the public gateway's instant read budget. |
| `-32099` | Transport/policy | Payload too large          | The request body exceeds the 128 KiB public endpoint limit.  |

See also [Error Codes](../error-codes.md).

## Examples

Endpoint: `https://mainnet.megaeth.com/rpc`

Capture date: July 24, 2026

Outcome: success

```json
{
  "jsonrpc": "2.0",
  "id": 63,
  "method": "eth_getStorageAt",
  "params": [
    "0x4200000000000000000000000000000000000011",
    "0x0000000000000000000000000000000000000000000000000000000000000000",
    "0xb11048"
  ]
}
```

```json
{
  "jsonrpc": "2.0",
  "id": 63,
  "result": "0x000000000000000000000000000000000000000000000001bce8287cf283cc16"
}
```

## Sources

- Spec: `git@github.com:ethereum/execution-apis.git @ d24f58b56dcd16ab0f0c70ec609bcc1c42750b51: src/eth/state.yaml`
- Code: `git@github.com:megaeth-labs/mega-reth.git @ ab60376631228edab3a6df180f295280bad26e93: crates/rpc/rpc-eth-api/src/core.rs`
- Code: `git@github.com:megaeth-labs/mega-rpc.git @ 06aa35aa95d569c227cc25d2aa12834eb0458aa0: workers/src/spec/methods.ts`
- Probe: MegaETH Mainnet public endpoint, July 24, 2026
