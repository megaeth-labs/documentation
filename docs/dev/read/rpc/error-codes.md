---
description: MegaETH JSON-RPC error codes — HTTP status codes, RPC error codes, explanations, and mitigations.
---

# Error Codes

| HTTP Error Code | RPC Error Code | Error Message                                                  | Explanation                                                           | Mitigation                                                                                                               |
| --------------- | -------------- | -------------------------------------------------------------- | --------------------------------------------------------------------- | ------------------------------------------------------------------------------------------------------------------------ |
| 400             | -32700         | `parse error`                                                  | The request body contains invalid JSON.                               | Check the request format and ensure valid JSON syntax.                                                                   |
| 413             | -32099         | `payload too large`                                            | The request body exceeds the size limit for the method being called.  | Stay within the body-size limit for the method class. See [Request Body Limits](../overview.md#request-body-limits).     |
| 403             | -32601         | `rpc method is not whitelisted`                                | The requested RPC method is not allowed by the proxy configuration.   | Use only whitelisted RPC methods. Contact MegaETH if you need access to additional methods.                              |
| 200             | -32001         | `Resource not found`                                           | The requested block, header, or other resource could not be resolved. | Verify the block number or hash and retry.                                                                               |
| 200             | 4444           | `pruned history unavailable`                                   | The node no longer retains the requested historical state or data.    | Use a newer block or an endpoint with the required historical-state retention.                                           |
| 400             | -32019         | `block is out of range`                                        | The requested block number is out of range.                           | Check the block number and ensure it's within the valid range.                                                           |
| 500             | -32020         | `backend response too large`                                   | The backend response is too large.                                    | Reduce the scope of the request or contact MegaETH for assistance.                                                       |
| 429             | -32005         | `Rate limit exceeded`                                          | The request exceeds the rate limit for its method category.           | Reduce request frequency, or use batching or WebSocket subscriptions. See [Rate Limiting](../overview.md#rate-limiting). |
| 200             | -32000         | `permanent error forwarding request context deadline exceeded` | The API proxy cannot connect to the backend RPC server.               | Pause for a while and retry. Notify MegaETH if the error persists.                                                       |

Older references to `-32021` or `-32022` refer to the previous rate-limit codes.
The public gateway now returns `-32005` for rate-limited requests.

## Related Pages

- [RPC Reference](../overview.md) — full method availability table
