---
description: "eth_getCode JSON-RPC reference for MegaETH."
---

# eth_getCode

## Summary

Returns the runtime bytecode stored at an address at a given block.

The public MegaETH endpoint supports this method. The standard, node, and gateway layers below identify behavior that differs from a generic Ethereum endpoint.

## Parameters

**`address`** Address **REQUIRED**

Target account or contract address.

---

**`block`** string

Hex block number, block hash, or tag (`latest`, `safe`, `finalized`, …).
The default is `"latest"`.

## Result

**`result`** Data

Runtime bytecode (not creation bytecode) at the address; `0x` when no code is deployed.

## MegaETH Behavior

### Ethereum Standard

The canonical Ethereum method uses the parameter and result contract documented above, including the stated `null`, `false`, or zero-value semantics where applicable.

### MegaETH Node Behavior

The node returns runtime bytecode from the selected state. A missing account and an account with no code are both represented by empty bytecode.

### MegaETH Public Gateway

The gateway streams bytecode responses and caches successful fixed-state lookups for up to 30 minutes. The exact cache key follows the address and block selector.

## Errors

The `| Scope |` column distinguishes method failures from gateway policy errors.

| Code     | Scope            | Message                    | When it happens                                             |
| -------- | ---------------- | -------------------------- | ----------------------------------------------------------- |
| `-32602` | Request          | Invalid params             | Malformed address or block selector                         |
| `-32001` | Method           | Resource not found         | Block selector cannot be resolved                           |
| `4444`   | Method           | Pruned history unavailable | Requested historical state is unavailable                   |
| `-32005` | Transport/policy | Rate limit exceeded        | The caller exceeds the public gateway's simple read budget. |
| `-32099` | Transport/policy | Payload too large          | The request body exceeds the 128 KiB public endpoint limit. |

See also [Error Codes](./error-codes.md).

## Examples

Endpoint: `https://mainnet.megaeth.com/rpc`

Capture date: July 24, 2026

Outcome: success

```json
{
  "jsonrpc": "2.0",
  "id": 2,
  "method": "eth_getCode",
  "params": ["0x4200000000000000000000000000000000000011", "latest"]
}
```

```json
{
  "jsonrpc": "2.0",
  "id": 2,
  "result": "0x6080604052\u2026"
}
```

## Sources

- Spec: `git@github.com:ethereum/execution-apis.git @ d24f58b56dcd16ab0f0c70ec609bcc1c42750b51: src/eth/state.yaml`
- Code: `git@github.com:megaeth-labs/mega-reth.git @ ab60376631228edab3a6df180f295280bad26e93: crates/rpc/rpc-eth-api/src/core.rs`
- Code: `git@github.com:megaeth-labs/mega-rpc.git @ 06aa35aa95d569c227cc25d2aa12834eb0458aa0: workers/src/spec/methods.ts`
- Probe: MegaETH Mainnet public endpoint, July 24, 2026
