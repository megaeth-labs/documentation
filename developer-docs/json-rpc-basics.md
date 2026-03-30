# JSON-RPC Basics

Shared JSON-RPC conventions used across the MegaETH RPC docs.

Use this page when you need to:

- build a valid request body
- understand when to include `id`
- send batch requests safely
- distinguish a successful response from a failed one

Method pages remain the source of truth for method-specific parameter order, result types, and MegaETH-specific runtime behavior.

## Request Envelope

Every non-batch JSON-RPC request uses the following shape:

| Field | JSON type | Required | Rule |
|---|---|---|---|
| `jsonrpc` | `string` | Yes | Must equal `"2.0"` |
| `id` | `string \| number` | Yes, unless using a notification | Correlates the response to the request |
| `method` | `string` | Yes | RPC method name such as `eth_call` |
| `params` | `array \| object` | Method-defined | Unless a method page explicitly says otherwise, send params as a positional array |

Reader rules:

- A single non-batch request payload is a JSON object.
- Most method pages in this docs set use positional array params.
- `id` must be a string or number when you expect a response.
- Do not use `null` as a request `id`.
- Omit `id` only for notifications.

Canonical request example:

```json
{
  "jsonrpc": "2.0",
  "id": 1,
  "method": "eth_chainId",
  "params": []
}
```

## Notifications

A notification is a request without `id`.

Reader rules:

- Notifications do not receive a response body.
- Use them only when you intentionally do not need a success result or a JSON-RPC error body.
- For normal client integrations, send an `id`.

Example notification:

```json
{
  "jsonrpc": "2.0",
  "method": "eth_blockNumber",
  "params": []
}
```

## Batch Requests

A batch request sends multiple request objects in one JSON array.

Reader rules:

- A batch request payload is a JSON array of request objects.
- A batch response payload is a JSON array of response objects.
- Response order is not guaranteed. Match by `id`, not by array position.
- Each request that expects a response should use a unique `id`.
- Notification items inside a batch do not produce response items.
- For current public-gateway batch size and body limits, use [Operations and Limits](operations/limits.md).

Canonical batch example:

```json
[
  {
    "jsonrpc": "2.0",
    "id": "bn",
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

```json
[
  {
    "jsonrpc": "2.0",
    "id": "chain",
    "result": "0x1"
  },
  {
    "jsonrpc": "2.0",
    "id": "bn",
    "result": "0x9d9e94"
  }
]
```

## Success Response

A successful response uses the following shape:

| Field | JSON type | Required | Rule |
|---|---|---|---|
| `jsonrpc` | `string` | Yes | Must equal `"2.0"` |
| `id` | `string \| number` | Yes | Must equal the request `id` |
| `result` | Method-defined | Yes | Success payload defined by the method contract |

Reader rules:

- `result` shape is method-defined.
- A successful result can still be `null`, `0x0`, `[]`, or another documented empty value.
- Treat top-level `result` vs top-level `error` as the primary success or failure split.

Canonical success example:

```json
{
  "jsonrpc": "2.0",
  "id": 1,
  "result": "0x1"
}
```

## Error Response

A failed response uses the following shape:

| Field | JSON type | Required | Rule |
|---|---|---|---|
| `jsonrpc` | `string` | Yes | Must equal `"2.0"` |
| `id` | `string \| number \| null` | Yes | Usually echoes the request `id`; may be `null` if the request is rejected before the `id` can be trusted |
| `error.code` | `number` | Yes | Signed integer error code |
| `error.message` | `string` | Yes | Human-readable failure summary |
| `error.data` | `any` | No | Optional structured detail |

Reader rules:

- HTTP `200` does not mean the RPC call succeeded.
- Check `error.code` before you rely on `error.message`.
- When `error.data` is present, inspect it before retrying.
- Provider-specific and method-specific errors are documented in [Error reference](errors.md) and the relevant method page.

Canonical error example:

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

## Standard JSON-RPC Error Codes

| Code | Name | Meaning |
|---|---|---|
| `-32700` | Parse error | The payload is not valid JSON |
| `-32600` | Invalid Request | The JSON-RPC envelope itself is malformed |
| `-32601` | Method not found | The requested method is unknown or disabled on that endpoint |
| `-32602` | Invalid params | The method arguments do not satisfy that method's contract |
| `-32603` | Internal error | The server failed after accepting a valid request envelope |

For Ethereum-client, gateway, and MegaETH-specific error handling such as `-32005`, `3`, or `4444`, use [Error reference](errors.md).
