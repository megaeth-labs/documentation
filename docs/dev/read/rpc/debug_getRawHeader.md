---
description: "Returns the RLP-encoded header for a MegaETH block."
---

# debug_getRawHeader

## Summary

Returns a block header encoded with Recursive Length Prefix (RLP).
The public MegaETH endpoint supports this standard debug method.

## Parameters

| Position | Name    | Type                    | Required | Description                                                              |
| -------- | ------- | ----------------------- | -------- | ------------------------------------------------------------------------ |
| `0`      | `block` | `QUANTITY` or block tag | Yes      | Block number or `latest`, `safe`, `finalized`, `earliest`, or `pending`. |

## Result

The result is a `DATA` value containing the RLP-encoded header.
Decode the bytes as an Ethereum block header rather than treating them as a JSON block object.

## MegaETH Behavior

### Ethereum Standard

The method returns the canonical RLP representation of the selected block header.

### MegaETH Node Behavior

MegaETH exposes the method through its debug namespace and accepts a block number or tag.
The encoded header includes the fields used by the selected MegaETH hardfork.

### MegaETH Public Gateway

The public gateway forwards this method through its compute pool and may cache immutable block selections.
Support and a successful historical lookup were observed on July 24, 2026.

## Errors

The `| Scope |` column distinguishes method failures from gateway policy errors.

| Code     | Scope            | Message           | When it happens                                     |
| -------- | ---------------- | ----------------- | --------------------------------------------------- |
| `-32602` | Method           | Invalid params    | The block selector is missing or malformed.         |
| `-32000` | Method           | Server error      | The block is unavailable or cannot be encoded.      |
| `-32099` | Transport/policy | Payload too large | The request exceeds the public endpoint body limit. |

## Examples

Endpoint: `https://mainnet.megaeth.com/rpc`

Capture date: July 24, 2026

Outcome: success

```json
{
  "jsonrpc": "2.0",
  "id": 1,
  "method": "debug_getRawHeader",
  "params": ["0x1"]
}
```

The RLP value is abbreviated below.

```json
{
  "jsonrpc": "2.0",
  "id": 1,
  "result": "0xf9026ba09425ed45fa0843e257166258f69bced9ef9eb2d0bb23c6b5a901fba3…"
}
```

## Sources

- Spec: [Ethereum Execution APIs, `src/debug/getters.yaml`](https://github.com/ethereum/execution-apis/blob/50d1e5e0b6f5a5046e45421e5c84497ab6e55e6c/src/debug/getters.yaml)
- Probe: MegaETH Mainnet public endpoint, July 24, 2026
