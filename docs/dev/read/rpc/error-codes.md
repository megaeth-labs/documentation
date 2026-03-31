---
description: MegaETH JSON-RPC error codes — HTTP status codes, RPC error codes, explanations, and mitigations.
---

# Error Codes

| HTTP Error Code | RPC Error Code | Error Message | Explanation | Mitigation |
| --------------- | -------------- | ------------- | ----------- | ---------- |
| 400 | -32700 | `parse error` | The request body contains invalid JSON. | Check the request format and ensure valid JSON syntax. |
| 403 | -32601 | `rpc method is not whitelisted` | The requested RPC method is not allowed by the proxy configuration. | Use only whitelisted RPC methods. Contact MegaETH if you need access to additional methods. |
| 400 | -32019 | `block is out of range` | The requested block number is out of range. | Check the block number and ensure it's within the valid range. |
| 500 | -32020 | `backend response too large` | The backend response is too large. | Reduce the scope of the request or contact MegaETH for assistance. |
| 429 | -32021 | `over network traffic limit, retry in X seconds` | The user is incurring too much network traffic. | Wait for the specified number of seconds before retrying. Reduce the number of requests sent per second. |
| 429 | -32022 | `over compute unit limit, retry in X seconds` | The user is incurring too much computation on the backend RPC server. | Wait for the specified number of seconds before retrying. Reduce the number of requests sent per second. |
| 200 | -32000 | `permanent error forwarding request context deadline exceeded` | The API proxy cannot connect to the backend RPC server. | Pause for a while and retry. Notify MegaETH if the error persists. |

## Related Pages

- [RPC Reference](overview.md) — full method availability table
