---
description: "Returns the number of uncle blocks referenced by a MegaETH block selected by hash."
---

# eth_getUncleCountByBlockHash

## Summary

Returns the number of uncle blocks referenced by a block selected by hash.
MegaETH does not produce proof-of-work uncles, so valid MegaETH blocks return zero.

## Parameters

| Position | Name        | Type             | Required | Description                   |
| -------- | ----------- | ---------------- | -------- | ----------------------------- |
| `0`      | `blockHash` | `DATA`, 32 bytes | Yes      | Hash of the block to inspect. |

## Result

The result is a hexadecimal `QUANTITY` containing the uncle count.
For a valid MegaETH block this is zero.

## Comparison with Ethereum Standard JSON-RPC

### Ethereum Standard

The method returns the number of uncles referenced by the selected block.

### MegaETH Node Behavior

MegaETH inherits the compatibility method, but its proof-of-stake L2 blocks do not contain proof-of-work uncles.

### MegaETH Public Gateway

The gateway may cache the count for a block hash.
A valid Mainnet block returned an uncle count of zero on July 24, 2026.

## Errors

The `| Scope |` column distinguishes method failures from gateway policy errors.

| Code     | Scope            | Message           | When it happens                                     |
| -------- | ---------------- | ----------------- | --------------------------------------------------- |
| `-32602` | Method           | Invalid params    | The block hash is missing or malformed.             |
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
  "method": "eth_getUncleCountByBlockHash",
  "params": [
    "0x57804c21b747137075b29ce153b4f559345a3624273660c87e81bd57e7cbbc3d"
  ]
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

- Spec: [Ethereum Execution APIs method reference](https://github.com/ethereum/execution-apis/blob/50d1e5e0b6f5a5046e45421e5c84497ab6e55e6c/docs-api/api/methods/eth_getUncleCountByBlockHash.mdx)
- Probe: MegaETH Mainnet public endpoint, July 24, 2026
