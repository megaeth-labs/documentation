# mega_getBlockWitness

Returns the execution witness for a block as a zstd-compressed, base64-encoded string with a `v0:` version prefix. This is a MegaETH-specific method used for stateless verification.

## Parameters

| Position | Name | Type | Required | Notes |
|---|---|---|---|---|
| `0` | `keys` | `object` | Yes | Block lookup key; see fields below |

**`keys` fields:**

| Field | Type | Required | Notes |
|---|---|---|---|
| `blockNumber` | `Quantity` | Yes | Target block number |
| `blockHash` | `Data` | No | 32-byte block hash; mutually exclusive with `parentHash` + `attributesHash` |
| `parentHash` | `Data` | No | 32-byte parent hash; must pair with `attributesHash` |
| `attributesHash` | `Data` | No | 32-byte attributes hash; must pair with `parentHash` |

## Returns

| Field | Type | Notes |
|---|---|---|
| `result` | `string` | `v0:` followed by a base64-encoded zstd-compressed witness blob |

## Errors

| Code | Cause | Fix |
|---|---|---|
| `-32602` | `blockNumber` missing, invalid hex value, or invalid hash field combination | Fix the request |
| `-32603` | No witness data exists for the requested block | The block may be too old or witness not yet generated |
| `-32005` | Batch contains more than 4 `mega_getBlockWitness` calls targeting a block below `0x70B5A9`, or public endpoint rate limit hit | Reduce batch size or retry later |

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
