# eth_getCode

## Summary
Returns the runtime bytecode stored at an address for a specified block.

This method is part of the standard Ethereum JSON-RPC API. On MegaETH, omitting the `block` parameter is treated as `latest`, but that behavior is not standard and should not be relied on for portable integrations.

## Parameters
- `address` (required): `string`

  Accepted values:
  - a `0x`-prefixed 20-byte Ethereum address
  - 40 hex characters after the `0x` prefix

  Notes:
  - Malformed addresses are rejected with `-32602`.
  - Accounts without deployed code are valid inputs and return `0x`.

- `block` (required by the Ethereum JSON-RPC specification): `string`

  Accepted values:
  - hex block number as a `0x`-prefixed `QUANTITY`
  - one of: `earliest`, `finalized`, `safe`, `latest`, `pending`
  - a `0x`-prefixed 32-byte block hash

  Notes:
  - For portable behavior, send an explicit block selector.
  - On MegaETH, omitting this parameter is accepted and treated as `latest`.
  - Fixed block numbers and block hashes are stable and deterministic.
  - Tag-based selectors such as `latest` and `pending` may change over time.
  - Unknown block numbers or hashes return `-32001`.

## Returns
- `result` (string)

  A `0x`-prefixed hex string containing the runtime bytecode at the selected address and block.

  Notes:
  - `0x` means the address has no deployed code at the selected block.
  - Non-empty results are runtime bytecode, not creation bytecode.
  - Large contracts can produce large response bodies.

## Examples

### curl: contract code at `latest`
```bash
curl -sS https://mainnet.megaeth.com/rpc \
  -H 'content-type: application/json' \
  --data '{"jsonrpc":"2.0","id":2,"method":"eth_getCode","params":["0x4200000000000000000000000000000000000011","latest"]}'
```

### JSON-RPC request: contract code at `latest`
```json
{"jsonrpc":"2.0","id":2,"method":"eth_getCode","params":["0x4200000000000000000000000000000000000011","latest"]}
```

### Response: contract code at `latest`
```json
{"jsonrpc":"2.0","id":2,"result":"0x60806040526004361061005e5760003560e01c80635c60da1b116100435780635c60da1b146100be5780638f283970146100f8578063f851a440146101185761006d565b80633659cfe6146100755780634f1ef286146100955761006d565b3661006d5761006b61012d565b005b61006b61012d565b34801561008157600080fd5b5061006b6100903660046106dd565b610224565b6100a86100a33660046106f8565b610296565b6040516100b5919061077b565b60405180910390f35b3480156100ca57600080fd5b506100d3610419565b60405173ffffffffffffffffffffffffffffffffffffffff90911681526020016100b5565b34801561010457600080fd5b5061006b6101133660046106dd565b6104b0565b34801561012457600080fd5b506100d3610517565b60006101577f360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc5490565b905073ffffffffffffffffffffffffffffffffffffffff8116610201576040517f08c379a000000000000000000000000000000000000000000000000000000000815260206004820152602560248201527f50726f78793a20696d706c656d656e746174696f6e206e6f7420696e6974696160448201527f6c697a656400000000000000000000000000000000000000000000000000000060648201526084015b60405180910390fd5b3660008037600080366000845af43d6000803e8061021e573d6000fd5b503d6000f35b7fb53127684a568b3173ae13b9f8a6016e243e63b6e8ee1178d6a717850b5d61035473ffffffffffffffffffffffffffffffffffffffff163373ffffffffffffffffffffffffffffffffffffffff16148061027d575033155b1561028e5761028b816105a3565b50565b61028b61012d565b60606102c07fb53127684a568b3173ae13b9f8a6016e243e63b6e8ee1178d6a717850b5d61035490565b73ffffffffffffffffffffffffffffffffffffffff163373ffffffffffffffffffffffffffffffffffffffff1614806102f7575033155b1561040a57610305846105a3565b6000808573ffffffffffffffffffffffffffffffffffffffff16858560405161032f9291906107ee565b600060405180830381855af49150503d806000811461036a576040519150601f19603f3d011682016040523d82523d6000602084013e61036f565b606091505b509150915081610401576040517f08c379a000000000000000000000000000000000000000000000000000000000815260206004820152603960248201527f50726f78793a2064656c656761746563616c6c20746f206e657720696d706c6560448201527f6d656e746174696f6e20636f6e7472616374206661696c65640000000000000060648201526084016101f8565b91506104129050565b61041261012d565b9392505050565b60006104437fb53127684a568b3173ae13b9f8a6016e243e63b6e8ee1178d6a717850b5d61035490565b73ffffffffffffffffffffffffffffffffffffffff163373ffffffffffffffffffffffffffffffffffffffff16148061047a575033155b156104a557507f360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc5490565b6104ad61012d565b90565b7fb53127684a568b3173ae13b9f8a6016e243e63b6e8ee1178d6a717850b5d61035473ffffffffffffffffffffffffffffffffffffffff163373ffffffffffffffffffffffffffffffffffffffff161480610509575033155b1561028e5761028b8161060c565b60006105417fb53127684a568b3173ae13b9f8a6016e243e63b6e8ee1178d6a717850b5d61035490565b73ffffffffffffffffffffffffffffffffffffffff163373ffffffffffffffffffffffffffffffffffffffff161480610578575033155b156104a557507fb53127684a568b3173ae13b9f8a6016e243e63b6e8ee1178d6a717850b5d61035490565b7f360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc81815560405173ffffffffffffffffffffffffffffffffffffffff8316907fbc7cd75a20ee27fd9adebab32041f755214dbc6bffa90cc0225b39da2e5c2d3b90600090a25050565b60006106367fb53127684a568b3173ae13b9f8a6016e243e63b6e8ee1178d6a717850b5d61035490565b7fb53127684a568b3173ae13b9f8a6016e243e63b6e8ee1178d6a717850b5d61038381556040805173ffffffffffffffffffffffffffffffffffffffff80851682528616602082015292935090917f7e644d79422f17c01e4894b5f4f588d331ebfa28653d42ae832dc59e38c9798f910160405180910390a1505050565b803573ffffffffffffffffffffffffffffffffffffffff811681146106d857600080fd5b919050565b6000602082840312156106ef57600080fd5b610412826106b4565b60008060006040848603121561070d57600080fd5b610716846106b4565b9250602084013567ffffffffffffffff8082111561073357600080fd5b818601915086601f83011261074757600080fd5b81358181111561075657600080fd5b87602082850101111561076857600080fd5b6020830194508093505050509250925092565b600060208083528351808285015260005b818110156107a85785810183015185820160400152820161078c565b818111156107ba576000604083870101525b50601f017fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffe016929092016040019392505050565b818382376000910190815291905056fea164736f6c634300080f000a"}
```

### JSON-RPC request: address with no code
```json
{"jsonrpc":"2.0","id":3,"method":"eth_getCode","params":["0x0000000000000000000000000000000000000000","latest"]}
```

### Response: address with no code
```json
{"jsonrpc":"2.0","id":3,"result":"0x"}
```

### JSON-RPC request: MegaETH-only convenience with omitted `block`
```json
{"jsonrpc":"2.0","id":24,"method":"eth_getCode","params":["0x0000000000000000000000000000000000000000"]}
```

### Response: MegaETH-only convenience
```json
{"jsonrpc":"2.0","id":24,"result":"0x"}
```

### JSON-RPC request: unknown block hash
```json
{"jsonrpc":"2.0","id":11,"method":"eth_getCode","params":["0x4200000000000000000000000000000000000011","0x0000000000000000000000000000000000000000000000000000000000000000"]}
```

### Error response: unknown block hash
```json
{"jsonrpc":"2.0","id":11,"error":{"code":-32001,"message":"block not found: hash 0x0000000000000000000000000000000000000000000000000000000000000000"}}
```

## MegaETH Behavior
- Omitting the `block` parameter is accepted and treated as `latest`.
- Public endpoints may enforce rate limits.

## Errors
- `-32602` Invalid params

  When it happens: The request is missing the required `address`, uses a malformed address, or uses an invalid parameter type.

  Example:
  ```json
  {"jsonrpc":"2.0","id":12,"error":{"code":-32602,"message":"Invalid params","data":"invalid string length at line 1 column 8"}}
  ```

  Client handling: Validate the address and block selector before sending the request.

- `-32001` Block not found

  When it happens: The specified block number or block hash cannot be resolved.

  Example:
  ```json
  {"jsonrpc":"2.0","id":22,"error":{"code":-32001,"message":"block not found: 0xdeadbeef"}}
  ```

  Client handling: Treat this as an unresolved block selector. Retry only if you expect the block to become available.

- `-32005` Rate limited

  When it happens: The request exceeds the applicable public-endpoint rate limit.

  Client handling: Retry with backoff. MegaETH may also return HTTP `429`.

## Best Practices
- Always send an explicit block selector for portability across providers.
- Use a fixed block number or block hash for reproducible results.
- Treat `0x` as a valid success result meaning the address has no deployed code.
- Handle `-32001` separately from `0x`; they mean different things.
- Do not depend on an omitted `block` parameter if you need cross-provider compatibility.

## Compatibility
- The method is standard Ethereum JSON-RPC.
- For portable clients, always send an explicit `block` selector.
