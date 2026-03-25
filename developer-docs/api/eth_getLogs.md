# eth_getLogs

## Summary
Returns an array of log entries that match a filter.

This method is part of the standard Ethereum JSON-RPC API.

## Parameters
- `filter` (required): `object`

  Accepted forms:
  - range filter with `fromBlock` and `toBlock`
  - single-block filter with `blockHash`

  Common fields:
  - `address`: a single `0x`-prefixed 20-byte address, or an array of addresses
  - `topics`: an array of topic selectors

  Notes:
  - Send exactly one filter object.
  - `blockHash` cannot be combined with `fromBlock` or `toBlock`.
  - Block ranges are inclusive of both endpoints.
  - For `fromBlock` and `toBlock`, use a hex `QUANTITY` such as `0xb120c6`, or a standard block tag such as `latest` or `safe`.
  - Topic matching:
    - a single 32-byte topic matches that exact topic at the position
    - an array of 32-byte topics expresses OR matching at that position
    - `null` acts as a positional wildcard
    - MegaETH also accepts `[]` as a positional wildcard; for portable clients, prefer `null`
    - an empty `topics` array means no topic filtering
  - For portable behavior, provide explicit bounds instead of relying on provider defaults.

## Returns
- `result` (`object[]`)

  Returns an array of matching log objects.

  Common fields:
  - `address`
  - `topics`
  - `data`
  - `blockHash`
  - `blockNumber`
  - `transactionHash`
  - `transactionIndex`
  - `logIndex`
  - `removed`

  Notes:
  - An empty array means no logs matched the filter.
  - Matching log objects may include `blockTimestamp`.
  - `removed` is `false` for normal historical queries.

## Examples

### curl: by block range
```bash
curl -sS https://mainnet.megaeth.com/rpc \
  -H 'content-type: application/json' \
  --data '{"jsonrpc":"2.0","id":110,"method":"eth_getLogs","params":[{"fromBlock":"0xb120c6","toBlock":"0xb120c6","address":"0xf818c8da51f9a712cfbcddd44d0c445fa1a104e6","topics":["0x994d1f10d7d73f3765b557bce9826b2fafd1bad3862fa6192211b39a12183815","0x00000000000000000000000000000000000000000000000000000000000000d8"]}]}'
```

### JSON-RPC request: by block range
```json
{"jsonrpc":"2.0","id":110,"method":"eth_getLogs","params":[{"fromBlock":"0xb120c6","toBlock":"0xb120c6","address":"0xf818c8da51f9a712cfbcddd44d0c445fa1a104e6","topics":["0x994d1f10d7d73f3765b557bce9826b2fafd1bad3862fa6192211b39a12183815","0x00000000000000000000000000000000000000000000000000000000000000d8"]}]}
```

### Response: by block range
```json
{"jsonrpc":"2.0","id":110,"result":[{"address":"0xf818c8da51f9a712cfbcddd44d0c445fa1a104e6","topics":["0x994d1f10d7d73f3765b557bce9826b2fafd1bad3862fa6192211b39a12183815","0x00000000000000000000000000000000000000000000000000000000000000d8"],"data":"0x0000000000000000000954150000002f000000000000d6d800000000006ec9a2","blockNumber":"0xb120c6","blockTimestamp":"0x69c34699","transactionHash":"0xf3473347041eb4ccc045ee58e6c79c80d98ee4aa783d49e49c69d0a0e50d8ed6","transactionIndex":"0x9","blockHash":"0xf773491fd24617452b30c3ed626bf440b5846b9c818ec7d8d7f71c9a02993c8b","logIndex":"0x24","removed":false}]}
```

### JSON-RPC request: no matches
```json
{"jsonrpc":"2.0","id":111,"method":"eth_getLogs","params":[{"fromBlock":"0xb120c6","toBlock":"0xb120c6","address":"0x0000000000000000000000000000000000000000","topics":["0x994d1f10d7d73f3765b557bce9826b2fafd1bad3862fa6192211b39a12183815","0x00000000000000000000000000000000000000000000000000000000000000d8"]}]}
```

### Response: no matches
```json
{"jsonrpc":"2.0","id":111,"result":[]}
```

### JSON-RPC request: invalid `blockHash` and range combination
```json
{"jsonrpc":"2.0","id":105,"method":"eth_getLogs","params":[{"blockHash":"0xf773491fd24617452b30c3ed626bf440b5846b9c818ec7d8d7f71c9a02993c8b","fromBlock":"0xb120c6","toBlock":"0xb120c6"}]}
```

### Error response: invalid `blockHash` and range combination
```json
{"jsonrpc":"2.0","error":{"code":-32602,"message":"Invalid params","data":"cannot specify both blockHash and fromBlock/toBlock"},"id":105}
```

## MegaETH Behavior
- Unknown `blockHash` values return `-32001`.
- Public endpoints may enforce rate limits.

## Errors
- `-32602` Invalid params

  When it happens: The filter is missing, malformed, or combines `blockHash` with `fromBlock` / `toBlock`.

  Example:
  ```json
  {"jsonrpc":"2.0","error":{"code":-32602,"message":"Invalid params","data":"cannot specify both blockHash and fromBlock/toBlock"},"id":105}
  ```

  Client handling: Send exactly one filter object and choose either a block range or a single `blockHash`.

- `-32001` Block not found

  When it happens: The provided `blockHash` cannot be resolved.

  Example:
  ```json
  {"jsonrpc":"2.0","id":108,"error":{"code":-32001,"message":"block not found: hash 0x0000000000000000000000000000000000000000000000000000000000000000"}}
  ```

  Client handling: Treat this as an unresolved block selector.

- `-32005` Rate limited

  When it happens: The request exceeds the applicable public-endpoint rate limit.

  Client handling: Retry with backoff. MegaETH may also return HTTP `429`.

## Best Practices
- Bound queries explicitly with `fromBlock` / `toBlock`, or use a single `blockHash`.
- Narrow filters with `address` and `topics` to reduce response size.
- Treat an empty result array (`[]`) as a normal no-match result, not an error.
- Split wide queries into smaller ranges in client code.
- If you need maximum cross-provider compatibility, do not assume `blockTimestamp` is always present.

## Compatibility
- The method is standard Ethereum JSON-RPC.
- Provider defaults can differ when block bounds are omitted, so explicit filters are safer.
- For portable clients, prefer `null` over positional `[]` wildcards and treat `blockTimestamp` as optional.
