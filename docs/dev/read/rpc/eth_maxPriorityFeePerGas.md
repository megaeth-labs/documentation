---
description: "eth_maxPriorityFeePerGas JSON-RPC reference for MegaETH."
---

# eth_maxPriorityFeePerGas

## Summary

Returns the recommended priority fee per gas in wei.
MegaETH returns a zero-wei priority fee because priority fees are not needed under the current fee policy.

The public MegaETH endpoint supports this method. The standard, node, and gateway layers below identify behavior that differs from a generic Ethereum endpoint.

## Parameters

None.

## Result

**`result`** Quantity

Always a zero-wei quantity.

## MegaETH Behavior

### Ethereum Standard

The canonical Ethereum method uses the parameter and result contract documented above, including the stated `null`, `false`, or zero-value semantics where applicable.

### MegaETH Node Behavior

The node fee policy does not require a priority fee, but the public result is synthesized by the gateway rather than used as evidence of a node query.

### MegaETH Public Gateway

The gateway synthesizes a zero-wei priority fee without calling a node. This is a current MegaETH fee-policy response, not a market estimate.

## Errors

The `| Scope |` column distinguishes method failures from gateway policy errors.

No method-specific errors were observed.

| Code     | Scope            | Message             | When it happens                                             |
| -------- | ---------------- | ------------------- | ----------------------------------------------------------- |
| `-32005` | Transport/policy | Rate limit exceeded | The caller exceeds the public gateway's simple read budget. |
| `-32099` | Transport/policy | Payload too large   | The request body exceeds the 128 KiB public endpoint limit. |

See also [Error Codes](./error-codes.md).

## Examples

Endpoint: `https://mainnet.megaeth.com/rpc`

Capture date: July 27, 2026

Outcome: success

```json
{
  "jsonrpc": "2.0",
  "id": 1,
  "method": "eth_maxPriorityFeePerGas",
  "params": []
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

- Spec: `git@github.com:ethereum/execution-apis.git @ d24f58b56dcd16ab0f0c70ec609bcc1c42750b51: src/eth/fee_market.yaml`
- Code: `git@github.com:megaeth-labs/mega-reth.git @ ab60376631228edab3a6df180f295280bad26e93: crates/rpc/rpc-eth-api/src/core.rs`
- Code: `git@github.com:megaeth-labs/mega-rpc.git @ 06aa35aa95d569c227cc25d2aa12834eb0458aa0: workers/src/processors/hardcoded-processor.ts`
- Probe: MegaETH Mainnet public endpoint, July 27, 2026
