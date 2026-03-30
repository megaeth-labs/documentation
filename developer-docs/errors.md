# Error Reference

Use this page when a request fails and you need the shortest path to the real cause.

Method pages remain the source of truth for method-specific errors and edge cases. This page covers shared JSON-RPC failures, public-gateway failures, and the recovery decisions that matter across methods.

For request-envelope, notification, batch, and shared success-response rules, use [JSON-RPC Basics](json-rpc-basics.md).

## Start Here

| What you are seeing | Most likely layer | Start with |
|---|---|---|
| HTTP `400` with no useful JSON-RPC body | Request envelope or params | `-32700`, `-32600`, `-32602` |
| HTTP `200` but JSON body contains `error` | JSON-RPC or method failure | `error.code` and `error.message` |
| HTTP `200`, JSON-RPC success, but `result` contains its own `error` field | Method-specific result object | The method page and the result object contract such as [`CreateAccessListResult`](types.md#createaccesslistresult) |
| HTTP `429` or JSON-RPC `-32005` | Public gateway rate limiting | `-32005` |
| `block not found`, `resource not found`, or historical state unavailable | Selector or data availability | `-32001` or `4444` |
| `execution reverted` or top-level code `3` | EVM execution failure | `3` |
| Call works on one endpoint but not another | Transport or endpoint mismatch | `-32601`, `4444`, or endpoint choice |

## Failure Surfaces

Not every failed application outcome arrives in the same shape.

| Surface | What it looks like | What it means |
|---|---|---|
| Transport failure | No valid JSON-RPC body | HTTP, routing, connectivity, or gateway-layer failure |
| Top-level JSON-RPC error | Response body contains `error` | Standard JSON-RPC or server-side failure envelope |
| Embedded method-level failure | Response body has `result`, but the result object contains its own `error` field | Method-specific execution result; not a transport or JSON-RPC envelope failure. See the method page and shared result objects such as [`CreateAccessListResult`](types.md#createaccesslistresult) |
| Valid absence sentinel | Response succeeds with `null`, `0x0`, `[]`, or another documented empty value | The method completed successfully and found nothing or returned a zero value |

## Top-Level JSON-RPC Errors

For the exact top-level error-envelope fields and canonical examples, use [JSON-RPC Basics](json-rpc-basics.md#error-response).

For triage, remember:

- HTTP `200` does not mean the RPC call succeeded. Always inspect the JSON-RPC body.
- `error.message` is useful for triage, but client behavior should key primarily off `error.code`.
- When `error.data` is present, inspect it before retrying.

## Shared Error Codes And Retry Posture

Retry only when the same request has a reasonable chance to succeed later.

| Code | Origin | What it usually means | Retry |
|---|---|---|---|
| `-32700` | JSON-RPC standard | The payload is not valid JSON | No |
| `-32600` | JSON-RPC standard | The JSON-RPC envelope itself is malformed | No |
| `-32601` | JSON-RPC standard | The method is unknown, disabled, or not available on that transport | No |
| `-32602` | JSON-RPC standard | The method arguments do not satisfy the method contract | No |
| `-32603` | JSON-RPC standard | The server failed after accepting a valid request envelope | Maybe |
| `-32000` | Ethereum RPC ecosystem | A broad server-side failure bucket; inspect the message text and method context | Maybe |
| `-32001` | Ethereum RPC ecosystem | The requested block, transaction, or other resource cannot be resolved | Usually no |
| `-32002` | Ethereum RPC ecosystem | The serving node is temporarily not ready | Yes |
| `-32003` | Ethereum RPC ecosystem | Submitted transaction fees are too low | Yes, after changing fees |
| `-32005` | Public gateway behavior | The public gateway rejected the request because of current demand or request shape | Yes, with backoff |
| `3` | Ethereum client behavior | EVM execution reverted and returned revert-style failure data | No, not without changing inputs |
| `4444` | MegaETH or endpoint-specific behavior | The endpoint cannot serve the requested historical state | No, verify endpoint support for that historical range |

Reader rule:

- Do not assume every non-standard code is portable across providers. `3`, `-3200x` variants, and `4444` depend on the client, gateway, or endpoint behavior in front of you.

## Not Every Miss Is An Error

Some common outcomes look like failures at the application layer but are still valid successful RPC results.

| What you see | Meaning | Where to verify |
|---|---|---|
| `result: null` | The method completed successfully and did not find a matching resource | The method page |
| `result: "0x0"` | The method completed successfully and the value is actually zero | The method page |
| `result: []` | The method completed successfully and there were no matches | The method page |
| `result.error` inside a successful response object | The top-level JSON-RPC call succeeded, but the method-defined result object carries an execution-level error field | The method page and the shared result object definition such as [`CreateAccessListResult`](types.md#createaccesslistresult) |

Do not route these cases through the same client path as transport failures or top-level JSON-RPC errors.

## High-Value Failure Patterns

### `-32602` Invalid Params

Most often caused by:

- malformed address
- decimal instead of hex `Quantity`
- odd-length `Data`
- conflicting filter fields such as `blockHash` plus `fromBlock`
- unsupported selector shape for that specific method

What to do:

- validate the request against [Type reference](types.md)
- verify the parameter count and order on the method page
- check whether the method accepts only string block selectors or also accepts hash-based object form

### `-32601` Method Not Found

This often means one of three things:

- the method name is wrong
- the method is not enabled on that endpoint
- the request is going to the wrong RPC surface or URL

What to do:

- verify the exact method name
- verify the endpoint URL and RPC surface you are using
- confirm you are calling the intended endpoint and network

### `-32005` Rate Limited

This is usually a client-shape problem, not just a raw throughput problem.

Most common causes:

- switching from a cheap read method to a heavier method family
- retrying too aggressively
- using `eth_getLogs` with ranges that are too large
- repeating `eth_estimateGas` or `eth_call` in tight loops

What to do:

- reduce concurrency and burst size
- back off before retrying
- page large scans into smaller units
- separate heavy historical workloads from normal read traffic and verify historical-state availability separately
- read [Handle Rate Limits And Large Queries](guides/rate-limits.md)

### `-32001` Block Or Resource Not Found

This usually means the selector cannot be resolved, not that the server is temporarily unhealthy.

Typical causes:

- block hash does not exist on that endpoint
- transaction hash is wrong or not yet available
- the requested resource is not present on the selected network

What to do:

- verify the block hash, block number, tx hash, or network
- if you meant a historical state read rather than a missing resource, also check `4444`

### `3` Execution Reverted

This is an execution failure, not a transport failure.

When a simulated or on-chain execution reverts:

- inspect `error.data` if present
- decode standard revert payloads when possible
- compare the request against the actual chain state you are targeting
- treat this as a bad input or bad execution context until proven otherwise

Typical shape:

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

What to do next:

- if the failure is from `eth_call`, start from [eth_call](api/eth_call.md)
- if the failure is from `eth_estimateGas`, start from [eth_estimateGas](api/eth_estimateGas.md)

### `4444` Historical State Unavailable

This means the requested historical state is not available on the endpoint you used.

This matters most for state reads such as:

- `eth_getBalance`
- `eth_getCode`
- `eth_getStorageAt`
- `eth_getTransactionCount`

Typical fix:

- keep the request shape and block selector unchanged while you diagnose the failure
- verify whether the endpoint you are using serves the required historical range
- use [Choose Network And Endpoint](guides/choose-an-endpoint.md#2-when-older-state-reads-fail) if you need the decision workflow
- do not assume a dedicated older-state endpoint exists unless product docs explicitly publish one

Do not treat `4444` as a transient server failure. It is usually an endpoint-choice problem.

## HTTP Status And JSON-RPC Failures

HTTP status and JSON-RPC status answer different questions.

| HTTP | What it tells you | What to check next |
|---|---|---|
| `200` | The HTTP exchange succeeded | Inspect the JSON-RPC body for `result` vs `error` |
| `400` | The gateway rejected the request before or around method execution | Check JSON syntax, envelope fields, and params |
| `404` | Route or method surface is wrong for that URL or transport | Check endpoint URL and method/transport pairing |
| `429` | The gateway rate-limited the request | Treat like `-32005` |
| `500` | Internal server failure | Retry sparingly after checking whether the request is unusually heavy |
| `503` | Upstream or availability problem | Retry later and verify endpoint health |

Reader rules:

- JSON-RPC errors can arrive with HTTP `200`.
- HTTP `429` and JSON-RPC `-32005` should be handled the same way at the client strategy level.
- If the HTTP layer fails before a useful JSON-RPC body is returned, triage transport first.

## What To Log Before You Retry

When you escalate or retry, capture at least:

- endpoint URL
- method name
- block selector or other resource selector
- HTTP status
- `error.code`
- `error.message`
- `error.data`, if present

