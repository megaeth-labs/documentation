# Operations And Limits

Use this page when you need the current public MegaETH RPC gateway limits, not the base Ethereum method definition.

These limits matter because a method can be standard at the protocol level and still be constrained by the public gateway you are calling.

Use the method pages for request and response contracts. Use [Handle Rate Limits And Large Queries](../guides/rate-limits.md) when you need recovery steps instead of just the current numbers.

Last verified for this docs set: March 30, 2026.

If you depend on exact public-gateway numbers in production, re-check this page before hardcoding them into client limits or alert thresholds.

## HTTP Request Limits

Current public gateway limits:

| Limit | Value | Why it matters |
|-------|-------|----------------|
| Non-transaction request body | `128 KiB` | Large batch or trace-style requests can be rejected before execution |
| Transaction request body | `2.5 MiB` | Raw transaction submission has a higher payload allowance |
| Batch size | `500` requests | Larger JSON-RPC batches are rejected |
| Batch subrequest budget | `950` | Large logical batches can still be rejected even below 500 items |
| Response size | `50 MiB` | Large block or log queries can fail even when the method is otherwise valid |

## Method-Specific Gateway Limits

| Method or family | Current public gateway behavior |
|------------------|---------------------------------|
| `eth_getLogs` | Default max range `100` blocks |
| `eth_feeHistory` | `blockCount` capped at `256` |
| `eth_call` | Compute gas cap `60,000,000` |
| `eth_estimateGas` | Gateway CPU time limit `500 ms`; no gas cap |

If your application needs wider ranges or heavier historical reads, paginate aggressively and verify that the endpoint you are using serves that older range.

## Read Rate Limits

Current public gateway targets use 10-second windows:

| Category | Limit per 10s | Typical methods |
|----------|---------------|-----------------|
| `instant` | `2,000` | `eth_chainId`, `eth_blockNumber` |
| `simple` | `500` | Most basic reads |
| `compute` | `200` | `eth_call`, `eth_estimateGas`, `eth_createAccessList` |
| `io_heavy` | `200` | `eth_getLogs`, `eth_getBlockReceipts` |

Reader guidance:

- If you burst through a tier, expect HTTP `429` and JSON-RPC error code `-32005`.
- Moving from one method family to another can change the rate-limit tier even if the request count stays the same.

## Reader Notes

- Treat this page as a gateway contract, not a protocol contract.
- Deployment-specific settings can change over time; method pages call out the limits that most often affect application code.
- When in doubt, build clients that degrade gracefully: small pages, explicit ranges, retries with backoff, and clear error handling.
