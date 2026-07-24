---
description: "Returns the number of uncle blocks referenced by a MegaETH block selected by number."
---

# eth_getUncleCountByBlockNumber

## Summary

Returns the number of uncle blocks referenced by a block selected by number or tag.
MegaETH does not produce proof-of-work uncles, so valid MegaETH blocks return zero.

## Parameters

| Position | Name    | Type                    | Required | Description                                                              |
| -------- | ------- | ----------------------- | -------- | ------------------------------------------------------------------------ |
| `0`      | `block` | `QUANTITY` or block tag | Yes      | Block number or `latest`, `safe`, `finalized`, `earliest`, or `pending`. |

## Result

The result is a hexadecimal `QUANTITY` containing the uncle count.
For a valid MegaETH block this is zero.

## MegaETH Behavior

### Ethereum Standard

The method returns the number of uncles referenced by the selected block.

### MegaETH Node Behavior

MegaETH inherits the compatibility method, but its proof-of-stake L2 blocks do not contain proof-of-work uncles.

### MegaETH Public Gateway

The gateway may cache immutable selections and treats head tags as dynamic.
The `latest` block returned an uncle count of zero on July 24, 2026.

## Errors

The `| Scope |` column distinguishes method failures from gateway policy errors.

| Code     | Scope            | Message           | When it happens                                     |
| -------- | ---------------- | ----------------- | --------------------------------------------------- |
| `-32602` | Method           | Invalid params    | The block selector is missing or malformed.         |
| `-32099` | Transport/policy | Payload too large | The request exceeds the public endpoint body limit. |

No method-specific errors were observed for a valid block.

## Examples

Endpoint: `https://mainnet.megaeth.com/rpc`

Capture date: July 24, 2026

Outcome: success

```json
{
  "jsonrpc": "2.0",
  "id": 1,
  "method": "eth_getUncleCountByBlockNumber",
  "params": ["latest"]
}
```

```json
{
  "jsonrpc": "2.0",
  "id": 1,
  "result": "0x0"
}
```

## Sources

- Spec: [Ethereum Execution APIs method reference](https://github.com/ethereum/execution-apis/blob/50d1e5e0b6f5a5046e45421e5c84497ab6e55e6c/docs-api/api/methods/eth_getUncleCountByBlockNumber.mdx)
- Node: [mega-reth block-query RPC implementation](https://github.com/megaeth-labs/mega-reth/blob/0264d0821a8fe14ac6c7f710e9452edef7407b3f/crates/rpc/rpc-eth-api/src/core.rs)
- Gateway: [mega-rpc method registry](https://github.com/megaeth-labs/mega-rpc/blob/06aa35aa95d569c227cc25d2aa12834eb0458aa0/workers/src/spec/methods.ts)
- Probe: MegaETH Mainnet public endpoint, July 24, 2026
