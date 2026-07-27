---
description: "Returns an uncle block by parent block hash and uncle index."
---

# eth_getUncleByBlockHashAndIndex

## Summary

Returns an uncle block selected by its parent block hash and index.
MegaETH blocks do not contain proof-of-work uncles, so the method returns `null` for valid MegaETH blocks.

## Parameters

| Position | Name        | Type             | Required | Description                                      |
| -------- | ----------- | ---------------- | -------- | ------------------------------------------------ |
| `0`      | `blockHash` | `DATA`, 32 bytes | Yes      | Hash of the block whose uncle list is inspected. |
| `1`      | `index`     | `QUANTITY`       | Yes      | Zero-based uncle index.                          |

## Result

The result is a block object or `null` when no uncle exists at the selected index.
On MegaETH, `null` is expected and does not mean that the parent block itself is missing.

## Comparison with Ethereum Standard JSON-RPC

### Ethereum Standard

The method returns the uncle header at the selected index as a block object without transactions.

### MegaETH Node Behavior

MegaETH inherits the compatibility method, but its proof-of-stake L2 blocks do not contain proof-of-work uncles.

### MegaETH Public Gateway

The gateway may cache immutable hash selections.
A lookup at index zero for a valid Mainnet block returned `null` on July 24, 2026.

## Errors

The `| Scope |` column distinguishes method failures from gateway policy errors.

| Code     | Scope            | Message           | When it happens                                     |
| -------- | ---------------- | ----------------- | --------------------------------------------------- |
| `-32602` | Method           | Invalid params    | The block hash or index is missing or malformed.    |
| `-32099` | Transport/policy | Payload too large | The request exceeds the public endpoint body limit. |

No method-specific errors were observed for a canonical lookup.

## Examples

Endpoint: `https://mainnet.megaeth.com/rpc`

Capture date: July 24, 2026

Outcome: null

```json
{
  "jsonrpc": "2.0",
  "id": 1,
  "method": "eth_getUncleByBlockHashAndIndex",
  "params": [
    "0x57804c21b747137075b29ce153b4f559345a3624273660c87e81bd57e7cbbc3d",
    "0x0"
  ]
}
```

```json
{
  "jsonrpc": "2.0",
  "id": 1,
  "result": null
}
```

## Sources

- Probe: MegaETH Mainnet public endpoint, July 24, 2026
