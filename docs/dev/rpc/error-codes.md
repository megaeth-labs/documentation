---
description: Standard JSON-RPC, Ethereum, MegaETH, and public-gateway errors with retry guidance.
---

# Error reference

HTTP status and JSON-RPC status describe different layers.
An HTTP `200` response can contain either a JSON-RPC `result` or a JSON-RPC `error`.

## Error surfaces

| Surface              | Shape                                         | Meaning                                                                                     |
| -------------------- | --------------------------------------------- | ------------------------------------------------------------------------------------------- |
| Transport failure    | No valid JSON-RPC body                        | The HTTP, routing, connectivity, or gateway layer failed.                                   |
| JSON-RPC error       | Top-level `error` object                      | The request envelope, method, parameters, or server execution failed.                       |
| Method-defined error | A successful `result` contains an error field | The JSON-RPC call succeeded, but the method reports an execution outcome inside its result. |
| Empty success        | `result` is `null`, `"0x0"`, or `[]`          | The method succeeded and returned its documented empty value.                               |

Check the method page before treating an empty success as a failure.
See [JSON-RPC basics](./json-rpc-basics.md#error-response) for the complete error envelope.

## Standard JSON-RPC errors

| Code     | Name             | Meaning                                                                        | Retry |
| -------- | ---------------- | ------------------------------------------------------------------------------ | ----- |
| `-32700` | Parse error      | The request body is not valid JSON.                                            | No    |
| `-32600` | Invalid Request  | The JSON-RPC envelope is invalid.                                              | No    |
| `-32601` | Method not found | The method is unknown, disabled, or unavailable on this endpoint or transport. | No    |
| `-32602` | Invalid params   | The parameters do not satisfy the method contract.                             | No    |
| `-32603` | Internal error   | The server failed while processing a valid request.                            | Maybe |

Malformed JSON and unknown methods on the public HTTP endpoint return a JSON-RPC error body with HTTP `200`.
Client logic should therefore inspect `error.code` instead of inferring success from the HTTP status.

## Ethereum server errors

EIP-1474 assigns the following server-error codes:

| Code     | Meaning                                        | Typical action                                                 |
| -------- | ---------------------------------------------- | -------------------------------------------------------------- |
| `-32000` | Invalid input or a general server-side failure | Inspect the message and method context before retrying.        |
| `-32001` | Resource not found                             | Verify the block, transaction, or other selector.              |
| `-32002` | Resource unavailable                           | Retry later if the requested resource should become available. |
| `-32003` | Transaction rejected                           | Correct the transaction or its fees before retrying.           |
| `-32004` | Method not supported                           | Use a supported method or endpoint.                            |
| `-32005` | Limit exceeded                                 | Reduce load or request scope, then retry with backoff.         |
| `-32006` | JSON-RPC version not supported                 | Send JSON-RPC `"2.0"`.                                         |

Providers can reuse `-32000` for several failures.
Use both the numeric code and message for diagnostics, but avoid matching only on message text.

## MegaETH and gateway errors

| Code     | Meaning                    | Typical cause                                                                          | Action                                                                         |
| -------- | -------------------------- | -------------------------------------------------------------------------------------- | ------------------------------------------------------------------------------ |
| `3`      | Execution reverted         | `eth_call` or `eth_estimateGas` reached an EVM revert.                                 | Inspect and decode `error.data`, then change the call inputs or state context. |
| `4444`   | Pruned history unavailable | The serving node does not retain the requested historical state.                       | Use a newer block or an endpoint with the required history.                    |
| `-32005` | Limit exceeded             | A public rate limit, WebSocket subscription cap, or server-capacity limit was reached. | Reduce concurrency or scope and retry with exponential backoff and jitter.     |
| `-32099` | Payload too large          | The HTTP request body exceeds the applicable gateway limit.                            | Reduce the body or batch size.                                                 |

See [Operations and limits](./operations-and-limits.md) for the public gateway thresholds.

### Execution revert example

```json
{
  "jsonrpc": "2.0",
  "id": 1,
  "error": {
    "code": 3,
    "message": "execution reverted",
    "data": "0x08c379a0..."
  }
}
```

The first four bytes of `error.data` identify the revert payload format.
Decode the payload when possible before retrying.

### Historical state unavailable

Code `4444` applies to historical state that the node has pruned or never retained.
It commonly affects state reads such as `eth_getBalance`, `eth_getCode`, `eth_getStorageAt`, and `eth_getTransactionCount` at an old block.

Keep the request and selector unchanged while testing another endpoint.
Do not retry the same endpoint repeatedly because retention is not a transient condition.

## HTTP status handling

| HTTP status    | Meaning at the transport layer        | Client action                                                    |
| -------------- | ------------------------------------- | ---------------------------------------------------------------- |
| `200`          | The HTTP exchange completed.          | Inspect the JSON-RPC body for `result` or `error`.               |
| `413`          | The request body is too large.        | Handle JSON-RPC `-32099` when present and reduce the payload.    |
| `429`          | The gateway rate-limited the request. | Handle JSON-RPC `-32005` when present and retry with backoff.    |
| `500` or `503` | The gateway or upstream failed.       | Retry sparingly after checking request size and endpoint health. |

Do not hardcode a one-to-one mapping between every JSON-RPC code and an HTTP status.

## What to record

Capture these fields before retrying or escalating a failure:

- endpoint and transport
- method name
- block or resource selector
- HTTP status
- JSON-RPC code, message, and data
- request ID
- retry count and delay

Never log private keys or unsigned transaction secrets.
Redact raw signed transactions unless the transaction is already public and your logging policy allows them.

## Sources

- [JSON-RPC 2.0 Specification](https://www.jsonrpc.org/specification)
- [EIP-1474: Remote procedure call specification](https://eips.ethereum.org/EIPS/eip-1474)
- `mega-reth`: `crates/rpc/rpc-eth-types/src/error/mod.rs`
