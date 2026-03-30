# mega_getBlockWitness

Returns the execution witness for a MegaETH block, used for stateless verification.

## Ethereum Standard

This method is not part of the standard Ethereum JSON-RPC method set.

## MegaETH Differences

- This is a MegaETH-specific method. The witness data is returned as a zstd-compressed, base64-encoded string with a `v0:` version prefix.
- Three lookup modes are supported depending on which hash fields are provided alongside `blockNumber`.

## Request

Send `params` as `[keys]`.

| Position | Type | Required | Notes |
|---|---|---|---|
| `0` | `Object` | Yes | Lookup key object; see fields below |

**`keys` object fields:**

| Field | Type | Required | Notes |
|---|---|---|---|
| `blockNumber` | [`Quantity`](../types.md#quantity) | Yes | Hex block number |
| `blockHash` | [`Data`](../types.md#data) | No | 32-byte block hash. Mutually exclusive with `parentHash` and `attributesHash`. |
| `parentHash` | [`Data`](../types.md#data) | No | 32-byte parent block hash. Must be provided together with `attributesHash`. |
| `attributesHash` | [`Data`](../types.md#data) | No | 32-byte payload attributes hash. Must be provided together with `parentHash`. |

Reader notes:

- Omitting all hash fields looks up the witness by block number only.
- `blockHash` and `parentHash`/`attributesHash` are mutually exclusive; providing both in the same request is an error.
- `parentHash` and `attributesHash` must always appear together.
- In a batch containing more than 4 `mega_getBlockWitness` calls, the entire batch is rejected with `-32005` if any call targets a block below `0x70B5A9`.

## Response

| Field | Type | Notes |
|---|---|---|
| `result` | `string` | `v0:` followed by a base64-encoded zstd-compressed witness blob |

## Common Errors

| Code | When it usually happens | What to do |
|---|---|---|
| `-32602` | The parameter is not an object, `blockNumber` is missing or not a hex string, an invalid hash field combination is provided, or a hash value is not a valid hex string | Fix the request before retrying |
| `-32603` | No witness data exists for the requested block | The block may be too old or witness generation may not have completed |
| `-32005` | The public endpoint rate-limited the request | Back off and retry later |

See also [Error reference](../errors.md).

## Example

```bash
curl -sS https://mainnet.megaeth.com/rpc \
  -H 'content-type: application/json' \
  --data '{"jsonrpc":"2.0","id":1,"method":"mega_getBlockWitness","params":[{"blockNumber":"0x1"}]}'
```

```json
{"jsonrpc":"2.0","id":1,"result":"v0:KLUv/QBgzVUAZJwhAOwAAAAAWQ8AAQwBAKUAAAAAo4+wiKODG8b6ecnFi9Ip+NRWEtWQL91gIt5k+uNsCOkr9O021u/H7FkP..."}
```

The `result` string is a full base64-encoded zstd-compressed blob; the value above is truncated for display.
