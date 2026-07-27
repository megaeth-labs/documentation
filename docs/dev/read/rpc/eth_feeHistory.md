---
description: "eth_feeHistory JSON-RPC reference for MegaETH."
---

# eth_feeHistory

## Summary

Returns historical gas fee data for a range of blocks.

The public MegaETH endpoint supports this method. The standard, node, and gateway layers below identify behavior that differs from a generic Ethereum endpoint.

## Parameters

**`blockCount`** Quantity **REQUIRED**

Number of blocks (`1`–`256`).

---

**`newestBlock`** string **REQUIRED**

Hex block number or tag: `latest`, `safe`, `finalized`, `earliest`, `pending`.

---

**`rewardPercentiles`** number[]

Monotonically increasing values from `0` to `100`; omit to exclude `reward` from the result.

## Result

- **`oldestBlock`** Quantity

  First block in the returned range.

- **`baseFeePerGas`** Quantity[]

  Base fee per block; length is `blockCount + 1`.

- **`gasUsedRatio`** number[]

  Gas utilization ratio per block.

- **`reward`** Quantity[][]

  Percentile reward values; present only when `rewardPercentiles` was provided.

- **`baseFeePerBlobGas`** Quantity[]

  Blob base fee per block when available.

- **`blobGasUsedRatio`** number[]

  Blob gas utilization ratio per block when available.

## MegaETH Behavior

### Ethereum Standard

The canonical Ethereum method uses the parameter and result contract documented above, including the stated `null`, `false`, or zero-value semantics where applicable.

### MegaETH Node Behavior

The node implements the standard fee-history shape. The public gateway does not forward this method to the node, so node-derived fee history must not be inferred from public results.

### MegaETH Public Gateway

The gateway synthesizes this response locally instead of querying a node. It accepts 1 to 256 blocks and currently fills the response with a 1,000,000-wei base fee, 0.1 gas-used ratio, 1-wei blob base fee, zero blob utilization, and zero rewards. Treat these as gateway policy values, not measured historical blocks.

This public behavior was confirmed from gateway source and the example was observed on July 27, 2026. Gateway policy and operational values may change.

## Errors

The `| Scope |` column distinguishes method failures from gateway policy errors.

| Code     | Scope            | Message             | When it happens                                                 |
| -------- | ---------------- | ------------------- | --------------------------------------------------------------- |
| `-32602` | Request          | Invalid params      | Invalid request shape or `blockCount` outside the allowed range |
| `-32005` | Transport/policy | Rate limit exceeded | The caller exceeds the public gateway's simple read budget.     |
| `-32099` | Transport/policy | Payload too large   | The request body exceeds the 128 KiB public endpoint limit.     |

See also [Error Codes](./error-codes.md).

## Examples

Endpoint: `https://mainnet.megaeth.com/rpc`

Capture date: July 27, 2026

Outcome: success

```json
{
  "jsonrpc": "2.0",
  "id": 66,
  "method": "eth_feeHistory",
  "params": ["0x2", "latest", [25, 75]]
}
```

```json
{
  "jsonrpc": "2.0",
  "id": 66,
  "result": {
    "oldestBlock": "0xfffff",
    "baseFeePerGas": ["0xf4240", "0xf4240", "0xf4240"],
    "gasUsedRatio": [0.1, 0.1],
    "reward": [
      ["0x0", "0x0"],
      ["0x0", "0x0"]
    ],
    "baseFeePerBlobGas": ["0x1", "0x1", "0x1"],
    "blobGasUsedRatio": [0, 0]
  }
}
```

## Sources

- Spec: `git@github.com:ethereum/execution-apis.git @ d24f58b56dcd16ab0f0c70ec609bcc1c42750b51: src/eth/fee_market.yaml`
- Code: `git@github.com:megaeth-labs/mega-reth.git @ ab60376631228edab3a6df180f295280bad26e93: crates/rpc/rpc-eth-api/src/core.rs`
- Code: `git@github.com:megaeth-labs/mega-rpc.git @ 06aa35aa95d569c227cc25d2aa12834eb0458aa0: workers/src/processors/fee-history-processor.ts`
- Probe: MegaETH Mainnet public endpoint, July 27, 2026
