# eth_getStorageAt

## Summary
Returns the 32-byte value stored at a position in an account's storage at a specified block.

This method is part of the standard Ethereum JSON-RPC API. On MegaETH, omitting the `block` parameter is accepted and treated as `latest`, but that behavior is not standard and should not be relied on for portable integrations.

## Parameters
- `address` (required): `string`

  Accepted values:
  - a `0x`-prefixed 20-byte Ethereum address
  - 40 hex characters after the `0x` prefix

  Notes:
  - Address matching is case-insensitive.
  - EIP-55 checksum formatting is not required.

- `slot` (required): `string`

  Accepted values:
  - a `0x`-prefixed hex storage slot up to 32 bytes
  - for portable behavior, prefer a 32-byte left-padded value such as `0x0000000000000000000000000000000000000000000000000000000000000000`

  Notes:
  - This parameter is a raw storage key, not a decimal index.
  - Values longer than 32 bytes are rejected with `-32602`.
  - `0x0` is accepted on MegaETH for slot zero, but a 32-byte form is safer across providers.

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

  A `0x`-prefixed 32-byte hex value containing the raw storage word at the selected address, slot, and block.

  Notes:
  - The result is always exactly 32 bytes.
  - A zero result can mean an empty slot, a non-existent account, or an explicitly stored zero value.
  - Decode the word as `uint256`, `address`, `bytes32`, or another expected type in client code.

## Examples

### curl: by block number
```bash
curl -sS https://mainnet.megaeth.com/rpc \
  -H 'content-type: application/json' \
  --data '{"jsonrpc":"2.0","id":63,"method":"eth_getStorageAt","params":["0x4200000000000000000000000000000000000011","0x0000000000000000000000000000000000000000000000000000000000000000","0xb11048"]}'
```

### JSON-RPC request: by block number
```json
{"jsonrpc":"2.0","id":63,"method":"eth_getStorageAt","params":["0x4200000000000000000000000000000000000011","0x0000000000000000000000000000000000000000000000000000000000000000","0xb11048"]}
```

### Response: by block number
```json
{"jsonrpc":"2.0","id":63,"result":"0x000000000000000000000000000000000000000000000001bce8287cf283cc16"}
```

### JSON-RPC request: unknown account
```json
{"jsonrpc":"2.0","id":64,"method":"eth_getStorageAt","params":["0xc1cadaffffffffffffffffffffffffffffffffff","0x0000000000000000000000000000000000000000000000000000000000000000","0xb11048"]}
```

### Response: unknown account
```json
{"jsonrpc":"2.0","id":64,"result":"0x0000000000000000000000000000000000000000000000000000000000000000"}
```

### JSON-RPC request: malformed storage slot
```json
{"jsonrpc":"2.0","id":54,"method":"eth_getStorageAt","params":["0x4200000000000000000000000000000000000011","0xasdf","0xb11048"]}
```

### Error response: malformed storage slot
```json
{"jsonrpc":"2.0","id":54,"error":{"code":-32602,"message":"Invalid params"}}
```

### JSON-RPC request: unknown block number
```json
{"jsonrpc":"2.0","id":61,"method":"eth_getStorageAt","params":["0x4200000000000000000000000000000000000011","0x0","0xdeadbeef"]}
```

### Error response: unknown block number
```json
{"jsonrpc":"2.0","id":61,"error":{"code":-32001,"message":"block not found: 0xdeadbeef"}}
```

## MegaETH Behavior
- If `block` is omitted, MegaETH treats it as `latest`.
- Public endpoints may enforce rate limits.

## Errors
- `-32602` Invalid params

  When it happens: The request is missing required parameters, uses a malformed address, uses a malformed or too-long storage slot, or uses an invalid block selector.

  Example:
  ```json
  {"jsonrpc":"2.0","id":54,"error":{"code":-32602,"message":"Invalid params"}}
  ```

  Client handling: Validate the address, slot encoding, and block selector before sending the request.

- `-32001` Block not found

  When it happens: The specified block number or block hash cannot be resolved.

  Example:
  ```json
  {"jsonrpc":"2.0","id":61,"error":{"code":-32001,"message":"block not found: 0xdeadbeef"}}
  ```

  Client handling: Treat this as an unresolved block selector. Retry only if you expect the block to become available.

- `-32005` Rate limited

  When it happens: The request exceeds the applicable public-endpoint rate limit.

  Client handling: Retry with backoff. MegaETH may also return HTTP `429`.

## Best Practices
- Send all three parameters explicitly: `address`, `slot`, and `block`.
- Prefer a 32-byte left-padded slot value for cross-provider compatibility.
- Use a fixed block number or block hash for reproducible results.
- Treat a zero word as ambiguous between an empty slot and an explicitly stored zero.
- Derive mapping and dynamic-storage keys from the contract's storage layout rather than guessing slot positions.

## Compatibility
- The method is standard Ethereum JSON-RPC.
- For portable clients, send `address`, `slot`, and an explicit `block` selector.
