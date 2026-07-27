---
description: "eth_getTransactionCount JSON-RPC reference for MegaETH."
---

# eth_getTransactionCount

## Summary

Returns the number of transactions sent from an address at a given block.

The public MegaETH endpoint supports this method. The standard, node, and gateway layers below identify behavior that differs from a generic Ethereum endpoint.

## Parameters

**`address`** Address **REQUIRED**

Target account address.

---

**`block`** string

Hex block number or tag (`latest`, `safe`, `finalized`, `earliest`, `pending`).
The default is `"latest"`.

## Result

**`result`** Quantity

Transaction count at the requested block.
The method returns a zero quantity for both unknown accounts and accounts with zero transactions.

## MegaETH Behavior

### Ethereum Standard

The canonical Ethereum method uses the parameter and result contract documented above, including the stated `null`, `false`, or zero-value semantics where applicable.

### MegaETH Node Behavior

The node returns the account nonce at the selected state. Unknown accounts and accounts that have not sent transactions both produce a zero quantity.

### MegaETH Public Gateway

For `latest` or `pending`, the gateway rewrites to `mega_getAccountInfo`, treats `pending` as `latest`, and can return a fresh cached nonce immediately. Historical selectors bypass the account cache; a nonce read in the same outer batch as submissions need not include those submissions.

This public behavior was confirmed from gateway source and the example was observed on July 24, 2026. Gateway policy and operational values may change.

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
  "id": 91,
  "method": "eth_getTransactionCount",
  "params": ["0xa344fb2d117501ee379d2ea9c0c016959ad94f1e", "0xb120c6"]
}
```

```json
{
  "jsonrpc": "2.0",
  "id": 91,
  "result": "0xfa8c"
}
```

## Sources

- Spec: `git@github.com:ethereum/execution-apis.git @ d24f58b56dcd16ab0f0c70ec609bcc1c42750b51: src/eth/state.yaml`
- Code: `git@github.com:megaeth-labs/mega-reth.git @ ab60376631228edab3a6df180f295280bad26e93: crates/rpc/rpc-eth-api/src/core.rs`
- Code: `git@github.com:megaeth-labs/mega-rpc.git @ 06aa35aa95d569c227cc25d2aa12834eb0458aa0: workers/src/processors/account-query-processor.ts`
- Probe: MegaETH Mainnet public endpoint, July 24, 2026
