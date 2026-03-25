# eth_maxPriorityFeePerGas

## Summary
Returns a node-suggested max priority fee per gas for EIP-1559 transactions.

This method is part of the standard Ethereum JSON-RPC API and takes no parameters.

## Parameters
- None

  Send `params: []` for maximum interoperability.

  Do not rely on omitted `params` or extra positional parameters being accepted by other providers.

## Returns
- `result` (string)

  A `0x`-prefixed hex `QUANTITY` representing the suggested max priority fee per gas in wei.

  Notes:
  - No leading zeros, except `0x0`.
  - Treat the value as wei and convert to gwei or another unit in client code as needed.
  - The value is a node suggestion, not a protocol minimum.
  - `0x0` is a valid response.

## Examples

### curl: standard request
```bash
curl -sS https://mainnet.megaeth.com/rpc \
  -H 'content-type: application/json' \
  --data '{"jsonrpc":"2.0","id":1,"method":"eth_maxPriorityFeePerGas","params":[]}'
```

### JSON-RPC request: standard
```json
{"jsonrpc":"2.0","id":1,"method":"eth_maxPriorityFeePerGas","params":[]}
```

### Response: standard
```json
{"jsonrpc":"2.0","id":1,"result":"0x0"}
```

### JSON-RPC request: extra parameter (MegaETH behavior)
```json
{"jsonrpc":"2.0","id":2,"method":"eth_maxPriorityFeePerGas","params":["extra"]}
```

### Response: extra parameter
```json
{"jsonrpc":"2.0","id":2,"result":"0x0"}
```

## MegaETH Behavior
- On the MegaETH public endpoint, `eth_maxPriorityFeePerGas` currently returns `0x0`.
- MegaETH currently also returns a result when `params` is omitted or extra parameter values are sent, but this is non-standard and should not be relied on.
- Public endpoints may enforce rate limits.

## Errors
- `-32005` Rate limited

  When it happens: The request exceeds the applicable public-endpoint rate limit.

  Client handling: Retry with backoff. MegaETH may also return HTTP `429`.

## Best Practices
- Always send `params: []`.
- Treat the result as wei, not gwei.
- Do not assume the result is non-zero.
- Apply your own fee policy if you need a minimum or network-specific tip strategy.
- Do not depend on MegaETH's tolerance for omitted or extra parameters if you need cross-provider compatibility.

## Compatibility
- The method itself is standard Ethereum JSON-RPC.
- Providers can return different fee suggestions for the same network conditions.
- MegaETH public endpoint behavior for parameter tolerance is not standard and may differ from other providers.
- The example response `0x0` is specific to `https://mainnet.megaeth.com/rpc`.
