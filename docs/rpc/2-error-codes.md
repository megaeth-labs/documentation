---
owners: krabat
---

# Error Codes

| HTTP Error Code | RPC Error Code | Error Message | Explanation | Mitigation |
| --------------- | -------------- | ------------- | ----------- | ---------- |
| | | server is busy | The backend RPC server handling the request is congested and cannot serve the request. | Pause for a while and retry. Notify MegaETH if the error persists. |
| | -32000 | permanent error forwarding request context deadline exceeded | The API proxy cannot connect to the backend RPC server. | Pause for a while and retry. Notify MegaETH if the error persists. |
| 429 | -32022 | over compute unit limit | The user is incurring too much computation on the backend RPC server. | Pause for a while and retry. Reduce the number of requests sent per second. Computation cost varies by RPC methods. |
| 429 | -32022 | over network traffic limit | The user is incurring too much network traffic. | Pause for a while and retry. Reduce the number of requests sent per second. Network traffic varies by RPC methods. |
| 429 | -32016 | over rate limit | The user has exceeded its rate limit. | Pause for a while and retry. Reduce the number of requests sent per second. |
| 500 | -32000 | internal error | An error has occurred at the backend RPC server handling the request. | Log the raw RPC request that triggered the error and submit it to MegaETH. |
