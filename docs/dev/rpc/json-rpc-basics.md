---
description: Shared JSON-RPC 2.0 request, notification, batch, success, and error conventions used by MegaETH.
---

# JSON-RPC basics

MegaETH uses JSON-RPC 2.0 for HTTP requests and WebSocket messages.
Method pages define the parameter order, result shape, and method-specific behavior.

## Request envelope

| Field     | JSON type        | Required                      | Rule                                                  |
| --------- | ---------------- | ----------------------------- | ----------------------------------------------------- |
| `jsonrpc` | string           | Yes                           | Must be `"2.0"`.                                      |
| `id`      | string or number | Unless sending a notification | Correlates the response with the request.             |
| `method`  | string           | Yes                           | Names the RPC method.                                 |
| `params`  | array or object  | Method-defined                | Method pages in this reference use positional arrays. |

Use a unique string or number for `id` when you expect a response.
JSON-RPC permits a `null` request ID, but clients should avoid it because a response may also use `null` when the request ID cannot be determined.

```json
{
  "jsonrpc": "2.0",
  "id": 1,
  "method": "eth_chainId",
  "params": []
}
```

## Notifications

A notification omits `id`.
The server does not return a response, including when the notification is invalid.

```json
{
  "jsonrpc": "2.0",
  "method": "eth_blockNumber",
  "params": []
}
```

Use notifications only when your application intentionally does not need a result or error.

## Batch requests

A batch is a JSON array containing request or notification objects.
The public gateway accepts at most 100 items in one batch.

```json
[
  {
    "jsonrpc": "2.0",
    "id": "block",
    "method": "eth_blockNumber",
    "params": []
  },
  {
    "jsonrpc": "2.0",
    "id": "chain",
    "method": "eth_chainId",
    "params": []
  }
]
```

Batch responses may arrive in a different order from their requests.
Match each response by `id`, and remember that notification items do not produce response items.
See [Operations and limits](./operations-and-limits.md#http-request-and-response-limits) for batch accounting and body-size limits.

## Success response

A successful response contains `result` and does not contain `error`.
The result type is defined by the method.

```json
{
  "jsonrpc": "2.0",
  "id": 1,
  "result": "0x10e6"
}
```

Values such as `null`, `"0x0"`, and `[]` can be successful results when documented by the method.

## Error response

A failed call contains `error` and does not contain `result`.

| Field           | JSON type                 | Required | Description                     |
| --------------- | ------------------------- | -------- | ------------------------------- |
| `jsonrpc`       | string                    | Yes      | Always `"2.0"`.                 |
| `id`            | string, number, or `null` | Yes      | Usually matches the request ID. |
| `error.code`    | number                    | Yes      | Machine-readable error code.    |
| `error.message` | string                    | Yes      | Human-readable summary.         |
| `error.data`    | any                       | No       | Additional structured details.  |

```json
{
  "jsonrpc": "2.0",
  "id": 1,
  "error": {
    "code": -32602,
    "message": "Invalid params"
  }
}
```

HTTP `200` only means the HTTP exchange completed.
Always inspect the JSON-RPC body for `result` or `error`.
See [Error reference](./error-codes.md) for standard, Ethereum, gateway, and MegaETH-specific codes.

## Sources

- [JSON-RPC 2.0 Specification](https://www.jsonrpc.org/specification)
- [EIP-1474: Remote procedure call specification](https://eips.ethereum.org/EIPS/eip-1474)
