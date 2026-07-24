---
description: "Removes an Ethereum log or block filter by ID."
---

# eth_uninstallFilter

## Summary

Removes a filter and releases the node resources associated with it.
The public MegaETH endpoint accepts this standard method even though filter-creation and filter-polling methods are not publicly supported.

## Parameters

| Position | Name       | Type       | Required | Description                                      |
| -------- | ---------- | ---------- | -------- | ------------------------------------------------ |
| `0`      | `filterId` | `QUANTITY` | Yes      | Identifier returned by a filter-creation method. |

## Result

Returns `true` when the filter existed and was removed.
Returns `false` when the filter ID was unknown or had already expired.
`false` does not mean that `eth_uninstallFilter` itself is unavailable.

## MegaETH Behavior

### Ethereum Standard

Clients should uninstall a filter when it is no longer needed so the node can release its resources.

### MegaETH Node Behavior

MegaETH inherits the standard filter-removal handler and returns a boolean indicating whether a filter was removed.

### MegaETH Public Gateway

The method returned `false` for an unknown filter ID on July 24, 2026.
The public endpoint returned method-not-found errors for `eth_newFilter`, `eth_newBlockFilter`, `eth_newPendingTransactionFilter`, `eth_getFilterChanges`, and `eth_getFilterLogs` on the same date, so public clients normally use [`eth_subscribe`](./eth_subscribe.md) instead of filter polling.

## Errors

The `| Scope |` column distinguishes method failures from gateway policy errors.

| Code     | Scope            | Message           | When it happens                                     |
| -------- | ---------------- | ----------------- | --------------------------------------------------- |
| `-32602` | Method           | Invalid params    | The filter ID is missing or malformed.              |
| `-32099` | Transport/policy | Payload too large | The request exceeds the public endpoint body limit. |

No method-specific error was observed for a canonical request.

## Examples

Endpoint: `https://mainnet.megaeth.com/rpc`

Capture date: July 24, 2026

Outcome: false

```json
{
  "jsonrpc": "2.0",
  "id": 1,
  "method": "eth_uninstallFilter",
  "params": ["0x1"]
}
```

```json
{
  "jsonrpc": "2.0",
  "id": 1,
  "result": false
}
```

## Sources

- Spec: [Ethereum Execution APIs, `src/eth/filter.yaml`](https://github.com/ethereum/execution-apis/blob/50d1e5e0b6f5a5046e45421e5c84497ab6e55e6c/src/eth/filter.yaml)
- Probe: MegaETH Mainnet public endpoint, July 24, 2026
