# eth_feeHistory

Returns recent fee market history ending at a selected block.

## Ethereum Standard

`eth_feeHistory(blockCount, newestBlock, rewardPercentiles?) -> object`

## MegaETH Differences

- The public MegaETH endpoint currently accepts an omitted `rewardPercentiles` parameter and omits `reward` from the result.
- The public MegaETH endpoint currently limits `blockCount` to `1..256`.
- Non-increasing `rewardPercentiles` can be accepted on MegaETH, but portable clients should still send them in increasing order.

## Request

Send `params` as `[blockCount, newestBlock, rewardPercentiles]`.

| Position | Type | Required | Notes |
|---|---|---|---|
| `0` | [`Quantity`](../types.md#quantity) | Yes | Number of recent blocks to include |
| `1` | [`BlockNumberOrTag`](../types.md#blocknumberortag) | Yes | Inclusive upper bound of the returned range |
| `2` | `number[]` | No | Reward percentiles from `0` to `100` |

Reader notes:

- If `blockCount = N`, `gasUsedRatio` has length `N` and `baseFeePerGas` has length `N + 1`.
- Keep `rewardPercentiles` in increasing order for portable behavior.
- Use an explicit block number when you need reproducible results.
- Keep `blockCount` modest on public endpoints and page if you need a longer window.

## Response

| Field | Type | Notes |
|---|---|---|
| `oldestBlock` | [`Quantity`](../types.md#quantity) | First block in the returned range |
| `baseFeePerGas` | [`Quantity`](../types.md#quantity)`[]` | Length `N + 1`, includes one extra value for the block after `newestBlock` |
| `gasUsedRatio` | `number[]` | Length `N` |
| `reward` | [`Quantity`](../types.md#quantity)`[][]` | Optional. Present only when reward percentiles are requested and supported |
| `baseFeePerBlobGas` | [`Quantity`](../types.md#quantity)`[]` | Optional blob-fee history |
| `blobGasUsedRatio` | `number[]` | Optional blob-gas utilization history |

- `reward` is omitted when `rewardPercentiles` is omitted.
- Blob-related fields are optional and chain-dependent.

## Common Errors

| Code | When it usually happens | What to do |
|---|---|---|
| `-32602` | The request shape is invalid or `blockCount` is outside the allowed range | Fix the request before retrying |
| `-32000` | `blockCount` exceeds the public-endpoint limit | Reduce `blockCount` and retry |
| `-32005` | The public endpoint rate-limited the request | Back off and retry later |

See also [Error reference](../errors.md).

## Examples

### With `rewardPercentiles`

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

### Omit `rewardPercentiles`

When you omit the third parameter, MegaETH can omit `reward` from the result entirely:

```json
{
  "jsonrpc": "2.0",
  "id": 67,
  "result": {
    "oldestBlock": "0xfffff",
    "baseFeePerGas": ["0xf4240", "0xf4240", "0xf4240"],
    "gasUsedRatio": [0.1, 0.1],
    "baseFeePerBlobGas": ["0x1", "0x1", "0x1"],
    "blobGasUsedRatio": [0, 0]
  }
}
```

