# mega_outputAtBlock

## Summary
Returns the OP Stack output information for a specified L2 block.

This is a MegaETH-specific JSON-RPC method. `optimism_outputAtBlock` is a supported alias with the same behavior.

## Parameters
- `blockNumber` (required): `string`

  Accepted values:
  - a `0x`-prefixed hex block number such as `0x100`

  Notes:
  - Send exactly one positional parameter.
  - Use a concrete block number, not a block tag.
  - Use a lowercase `0x` prefix.

## Returns
- `result` (`object`)

  On success, returns an object with fields such as:
  - `version`
  - `outputRoot`
  - `blockRef`
  - `withdrawalStorageRoot`
  - `stateRoot`
  - `syncStatus`

  Notes:
  - `outputRoot`, `withdrawalStorageRoot`, and `stateRoot` are `0x`-prefixed 32-byte hex strings.
  - `blockRef` identifies the requested L2 block.
  - `syncStatus` reflects the node's current synchronization state and can change between calls.
  - On the MegaETH public endpoint, numeric fields in `blockRef` and `syncStatus` are currently returned as JSON numbers rather than hex strings.
  - `version` may appear in successful responses; clients should not depend on it being present.

## Examples

### curl: by block number
```bash
curl -sS https://mainnet.megaeth.com/rpc \
  -H 'content-type: application/json' \
  --data '{"jsonrpc":"2.0","id":301,"method":"mega_outputAtBlock","params":["0x100"]}'
```

### JSON-RPC request: by block number
```json
{"jsonrpc":"2.0","id":301,"method":"mega_outputAtBlock","params":["0x100"]}
```

### Response: by block number
```json
{"jsonrpc":"2.0","id":301,"result":{"version":"0x0000000000000000000000000000000000000000000000000000000000000000","outputRoot":"0xe41251ac90623f6a303572f9abea7d48a259fdb5812d36fdc3102abc69a62f97","blockRef":{"hash":"0x716a59d9fa50a9c225cbd4319bde1f1eccb9e8c3cacee8d7bda0dec17e1d9b34","number":256,"parentHash":"0x6388332c56f0e05a6b68986bebaa5512ccea02a90b46698078d31d809712b95b","timestamp":1762797267,"l1origin":{"hash":"0xca2aee05418e2037cd3d7d72ec79615b8409ce53ed87b02a47894122c7766f24","number":23770478},"sequenceNumber":4},"withdrawalStorageRoot":"0x8ed4baae3a927be3dea54996b4d5899f8c01e7594bf50b17dc1e741388ce3d12","stateRoot":"0xf5e1d1c08df99fabc86c73c2f88f137f63a880e9776315964f0c8ac77ae86305","syncStatus":{"current_l1":{"hash":"0x537c8d816f0d83a549abb4bba46c6e7cc892d14b98bec1900700363b2125b09a","number":24732192,"parentHash":"0xd40e2239ec148589cc8fd3a99f03d353f586c11731ab4aed67c16b41828cc9b0","timestamp":1774413083},"safe_l2":{"hash":"0xe51ccde8a6cc62cd0fadfe82babcba80efe7adfd01ccefd16ca7fc2e01194002","number":11615881,"parentHash":"0x965d712e73cf735220d1ffbea2f187ad6e037eae46faf8519a0ac84b7f0f1dee","timestamp":1774412892,"l1origin":{"hash":"0xaa1e7337977f970bc2f07d39d939fbba82a6fdf866d058cf06227b723e856cf1","number":24732133},"sequenceNumber":99},"finalized_l2":{"hash":"0x9534b0523afadcdbc5048f74327eb2c840cf285c59cd0dfcdedcafa1b9712322","number":11614356,"parentHash":"0xcf3e53ea5b0e413368420ea587c127fd943c9449aa4e994ff2eb32a47ed6ad36","timestamp":1774411367,"l1origin":{"hash":"0x9df703768cb5f5e1eac8570bbfe3b7d66db9da457b8e6c654e4284be85ac4005","number":24732006},"sequenceNumber":110}}}}
```

### JSON-RPC request: block tag not supported
```json
{"jsonrpc":"2.0","id":302,"method":"mega_outputAtBlock","params":["latest"]}
```

### Error response: block tag not supported
```json
{"jsonrpc":"2.0","error":{"code":-32602,"message":"mega_outputAtBlock does not support block tags, only hex block numbers"},"id":302}
```

### JSON-RPC request: missing block number
```json
{"jsonrpc":"2.0","id":304,"method":"mega_outputAtBlock","params":[]}
```

### Error response: missing block number
```json
{"jsonrpc":"2.0","error":{"code":-32602,"message":"mega_outputAtBlock expects exactly 1 parameter"},"id":304}
```

## MegaETH Behavior
- The public endpoint accepts `mega_outputAtBlock` and `optimism_outputAtBlock`.
- The method requires a concrete hex block number and rejects block tags such as `latest`.
- `syncStatus` is live status data and may differ across repeated calls for the same block.
- Public endpoints may enforce rate limits.

## Errors
- `-32602` Invalid params

  When it happens: The request has the wrong number of parameters or uses a block tag or invalid block-number format.

  Example:
  ```json
  {"jsonrpc":"2.0","error":{"code":-32602,"message":"mega_outputAtBlock expects exactly 1 parameter"},"id":304}
  ```

  Client handling: Send exactly one concrete `0x`-prefixed hex block number.

- `-32603` Internal error

  When it happens: The upstream output service fails, returns malformed data, or cannot produce a valid response for the request.

  Client handling: Retry transient failures with backoff and inspect the returned message for upstream details.

- `-32005` Rate limited

  When it happens: The request exceeds the applicable public-endpoint rate limit.

  Client handling: Retry with backoff. MegaETH may also return HTTP `429`.

## Best Practices
- Always pass a concrete block number such as `0x100`.
- Treat `syncStatus` as live node status, not block-stable data.
- Handle the response object permissively so additional fields do not break your client.
- Do not rely on `version` always being present.
- If you need alias compatibility with OP tooling, `optimism_outputAtBlock` currently behaves the same way.

## Compatibility
- `mega_outputAtBlock` is not part of the standard Ethereum JSON-RPC API.
- `optimism_outputAtBlock` is currently a supported alias on the MegaETH public endpoint.
- The example response values above are specific to `https://mainnet.megaeth.com/rpc`.
- Response field naming and numeric encoding may differ from other providers or OP-node deployments.
