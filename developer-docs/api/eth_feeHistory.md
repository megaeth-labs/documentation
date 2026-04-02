# eth_feeHistory

Returns historical fee data for a range of recent blocks, including base fees, gas utilization ratios, and optional reward percentiles.

## Parameters

**`blockCount`** Quantity **REQUIRED**

Number of blocks (`1`–`256`).

---

**`newestBlock`** string **REQUIRED**

Hex block number or tag: `latest`, `safe`, `finalized`, `earliest`, `pending`.

---

**`rewardPercentiles`** number[]

Monotonically increasing values from `0` to `100`; omit to exclude `reward` from the result.

## Returns

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

## Errors

| Code | Cause | Fix |
|---|---|---|
| `-32602` | Invalid request shape or `blockCount` outside the allowed range | Fix the request |
| `-32000` | `blockCount` exceeds the endpoint limit | Reduce `blockCount` |

See also [Error reference](../errors.md).

## Example

```bash
curl -sS https://mainnet.megaeth.com/rpc \
  -H 'content-type: application/json' \
  --data '{"jsonrpc":"2.0","id":66,"method":"eth_feeHistory","params":["0x2","latest",[25,75]]}'
```

```json
{
  "jsonrpc": "2.0",
  "id": 66,
  "result": {
    "oldestBlock": "0xfffff",
    "baseFeePerGas": ["0xf4240", "0xf4240", "0xf4240"],
    "gasUsedRatio": [0.1, 0.1],
    "reward": [["0x0", "0x0"], ["0x0", "0x0"]],
    "baseFeePerBlobGas": ["0x1", "0x1", "0x1"],
    "blobGasUsedRatio": [0, 0]
  }
}
```
