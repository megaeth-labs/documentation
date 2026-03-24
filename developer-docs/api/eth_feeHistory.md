# eth_feeHistory

## Summary
Returns recent fee market history for a given number of blocks ending at a specified block.

This method is part of the standard Ethereum JSON-RPC API. The response includes recent `baseFeePerGas` values, per-block `gasUsedRatio`, and optionally `reward` percentile samples when `rewardPercentiles` is provided.

On MegaETH, the public endpoint currently accepts an omitted `rewardPercentiles` parameter and omits `reward` from the response. The public endpoint currently enforces `blockCount` in the range `1..256`.

## Parameters
- `blockCount` (required): `string`

  Accepted values:
  - `0x`-prefixed hex `QUANTITY`

  Notes:
  - This is the number of recent blocks to include.
  - If `blockCount = N`, per-block arrays have length `N`, and base-fee arrays have length `N + 1`.
  - On the MegaETH public endpoint, `blockCount` currently must be between `0x1` and `0x100` inclusive.

- `newestBlock` (required): `string`

  Accepted values:
  - hex block number as a `0x`-prefixed `QUANTITY`
  - one of: `earliest`, `finalized`, `safe`, `latest`, `pending`

  Notes:
  - This selects the newest block at the end of the returned range.
  - Use an explicit block number when you need reproducible results.
  - Tag-based selectors such as `latest` and `pending` can change over time.

- `rewardPercentiles` (optional on MegaETH public endpoint): `array<number>`

  Accepted values:
  - JSON numbers between `0` and `100`

  Notes:
  - When provided, the response includes `reward`.
  - For portable client behavior, send values in increasing order.
  - On MegaETH, omitting this parameter is currently accepted and omits `reward` from the result.

## Returns
- `result` (`object`)

  Fields:
  - `oldestBlock`: `0x`-prefixed hex block number for the first block in the returned range
  - `baseFeePerGas`: array of `0x`-prefixed hex `QUANTITY` values, length `N + 1`
  - `gasUsedRatio`: array of JSON numbers in `[0, 1]`, length `N`
  - `reward` (optional): 2D array of `0x`-prefixed hex `QUANTITY` values, shape `N x K`
  - `baseFeePerBlobGas` (optional): array of `0x`-prefixed hex `QUANTITY` values, length `N + 1`
  - `blobGasUsedRatio` (optional): array of JSON numbers in `[0, 1]`, length `N`

  Notes:
  - `baseFeePerGas` and `reward` values are wei-per-gas quantities.
  - `baseFeePerBlobGas` values are wei-per-blob-gas quantities.
  - `baseFeePerGas` and `baseFeePerBlobGas` include one extra element for the block immediately after `newestBlock`.
  - If `rewardPercentiles` is omitted, `reward` may be omitted from the result.
  - Blob-related fields are provider- and chain-dependent; some providers may omit them when not applicable.

## Examples

### curl: explicit `latest` with `rewardPercentiles`
```bash
curl -sS https://mainnet.megaeth.com/rpc \
  -H 'content-type: application/json' \
  --data '{"jsonrpc":"2.0","id":66,"method":"eth_feeHistory","params":["0x2","latest",[25,75]]}'
```

### JSON-RPC request: explicit `latest` with `rewardPercentiles`
```json
{"jsonrpc":"2.0","id":66,"method":"eth_feeHistory","params":["0x2","latest",[25,75]]}
```

### Response: explicit `latest` with `rewardPercentiles`
```json
{"jsonrpc":"2.0","id":66,"result":{"oldestBlock":"0xfffff","baseFeePerGas":["0xf4240","0xf4240","0xf4240"],"gasUsedRatio":[0.1,0.1],"baseFeePerBlobGas":["0x1","0x1","0x1"],"blobGasUsedRatio":[0,0],"reward":[["0x0","0x0"],["0x0","0x0"]]}}
```

### JSON-RPC request: omitted `rewardPercentiles`
```json
{"jsonrpc":"2.0","id":67,"method":"eth_feeHistory","params":["0x2","latest"]}
```

### Response: omitted `rewardPercentiles`
```json
{"jsonrpc":"2.0","id":67,"result":{"oldestBlock":"0xfffff","baseFeePerGas":["0xf4240","0xf4240","0xf4240"],"gasUsedRatio":[0.1,0.1],"baseFeePerBlobGas":["0x1","0x1","0x1"],"blobGasUsedRatio":[0,0]}}
```

### JSON-RPC request: invalid `blockCount` (`0x0`)
```json
{"jsonrpc":"2.0","id":63,"method":"eth_feeHistory","params":["0x0","latest"]}
```

### Error response: invalid `blockCount` (`0x0`)
```json
{"jsonrpc":"2.0","id":63,"error":{"code":-32602,"message":"Invalid block count: must be between 1 and 256"}}
```

### JSON-RPC request: `blockCount` exceeds MegaETH public limit
```json
{"jsonrpc":"2.0","id":64,"method":"eth_feeHistory","params":["0x101","latest"]}
```

### Error response: `blockCount` exceeds MegaETH public limit
```json
{"jsonrpc":"2.0","error":{"code":-32000,"message":"eth_feeHistory blockCount exceeds configured limit (256)"},"id":64}
```

## MegaETH Behavior
- On the MegaETH public endpoint, omitting `rewardPercentiles` was accepted and omitted `reward` from the result.
- On the MegaETH public endpoint, `blockCount = 0x0` returned JSON-RPC error `-32602`.
- On the MegaETH public endpoint, `blockCount = 0x101` returned JSON-RPC error `-32000` with configured limit `256`.
- In the tested public endpoint responses above, `baseFeePerBlobGas` and `blobGasUsedRatio` were present alongside the standard fee-history fields.
- In one tested request, a non-increasing `rewardPercentiles` array (`[75,25]`) was accepted rather than rejected. Treat that as MegaETH-specific leniency, not portable Ethereum JSON-RPC behavior.
- Public endpoints may enforce rate limits.

## Errors
- `-32602` Invalid params

  When it happens: The request has the wrong shape, `blockCount` is invalid, or parameter values are malformed.

  Example:
  ```json
  {"jsonrpc":"2.0","id":63,"error":{"code":-32602,"message":"Invalid block count: must be between 1 and 256"}}
  ```

  Client handling: Fix the request shape or parameter values before retrying.

- `-32000` Block count exceeds configured limit

  When it happens: `blockCount` exceeds the MegaETH public endpoint limit.

  Example:
  ```json
  {"jsonrpc":"2.0","error":{"code":-32000,"message":"eth_feeHistory blockCount exceeds configured limit (256)"},"id":64}
  ```

  Client handling: Reduce `blockCount` and retry.

- Block not found

  When it happens: `newestBlock` cannot be resolved to a known block.

  Client handling: Check the block number or tag and retry only if you expect it to become available.

- `-32005` Rate limited

  When it happens: The request exceeds the public endpoint rate limit.

  Client handling: Retry with backoff and reduce burst rate.

## Best Practices
- Keep `blockCount` modest and at or below `256` on the MegaETH public endpoint.
- Paginate if you need a longer history window.
- Pass `rewardPercentiles` only when you need `reward`.
- For portable behavior, keep `rewardPercentiles` within `[0,100]` and in increasing order.
- Use an explicit block number when you need reproducible results.
- Handle `reward` and blob-related fields defensively because provider behavior can differ.
- Remember that base-fee arrays include one extra entry for the block after `newestBlock`.

## Compatibility
- `eth_feeHistory` is standard Ethereum JSON-RPC.
- MegaETH public endpoint behavior observed here is not fully standard:
  - omitted `rewardPercentiles` -> accepted and `reward` omitted
  - `blockCount` currently limited to `1..256`
  - non-increasing `rewardPercentiles` may be accepted
- Do not assume other providers behave the same way.
