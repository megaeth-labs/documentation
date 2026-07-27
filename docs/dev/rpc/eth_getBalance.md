---
description: "eth_getBalance JSON-RPC reference for MegaETH."
---

# eth_getBalance

## Summary

Returns the ETH balance of an account in wei at a given block.

The public MegaETH endpoint supports this method. The standard, node, and gateway layers below identify behavior that differs from a generic Ethereum endpoint.

## Parameters

**`address`** Address **REQUIRED**

Target account or contract address.

---

**`block`** string

Hex block number or tag (`latest`, `safe`, `finalized`, `earliest`, `pending`).
The default is `"latest"`.

## Result

**`result`** Quantity

Balance in wei.
The method returns a zero quantity for unknown accounts and zero-balance accounts alike.

## Comparison with Ethereum Standard JSON-RPC

### Ethereum Standard

The canonical Ethereum method uses the parameter and result contract documented above, including the stated `null`, `false`, or zero-value semantics where applicable.

### MegaETH Node Behavior

The node reads the account balance from the selected state. `latest` and `pending` can include state already visible through MegaETH's real-time mini-block pipeline.

### MegaETH Public Gateway

For `latest` or `pending`, the gateway rewrites the request to `mega_getAccountInfo`, treats `pending` as `latest`, and compares rollback-aware cached metadata with the upstream result. It can return cached data when the upstream fails; historical selectors bypass this account cache.

## Errors

The `| Scope |` column distinguishes method failures from gateway policy errors.

| Code     | Scope            | Message                    | When it happens                                              |
| -------- | ---------------- | -------------------------- | ------------------------------------------------------------ |
| `-32602` | Request          | Invalid params             | Malformed address or block selector                          |
| `-32001` | Method           | Resource not found         | Block selector cannot be resolved                            |
| `4444`   | Method           | Pruned history unavailable | Requested historical state is not available                  |
| `-32005` | Transport/policy | Rate limit exceeded        | The caller exceeds the public gateway's instant read budget. |
| `-32099` | Transport/policy | Payload too large          | The request body exceeds the 128 KiB public endpoint limit.  |

See also [Error Codes](./error-codes.md).

## Examples

Endpoint: `https://mainnet.megaeth.com/rpc`

Capture date: July 27, 2026

Outcome: success

```json
{
  "jsonrpc": "2.0",
  "id": 1,
  "method": "eth_getBalance",
  "params": ["0x0000000000000000000000000000000000000000", "pending"]
}
```

```json
{
  "jsonrpc": "2.0",
  "id": 1,
  "result": "0x7b0ecf3e28d5"
}
```

## Sources

- Spec: `git@github.com:ethereum/execution-apis.git @ d24f58b56dcd16ab0f0c70ec609bcc1c42750b51: src/eth/state.yaml`
- Code: `git@github.com:megaeth-labs/mega-reth.git @ ab60376631228edab3a6df180f295280bad26e93: crates/rpc/rpc-eth-api/src/core.rs`
- Code: `git@github.com:megaeth-labs/mega-rpc.git @ 06aa35aa95d569c227cc25d2aa12834eb0458aa0: workers/src/processors/account-query-processor.ts`
- Probe: MegaETH Mainnet public endpoint, July 27, 2026
