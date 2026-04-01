# mega_getBlockWitness

Returns the execution witness for a block.

## Parameters

| Position | Name | Type | Required | Notes |
|---|---|---|---|---|
| `0` | `keys` | `object` | Yes | Block lookup key; see fields below |

### `keys`

| Field | Type | Required | Notes |
|---|---|---|---|
| `blockNumber` | `Quantity` | Yes | Target block number |
| `blockHash` | `Hash32` | No | Block hash; mutually exclusive with `parentHash` + `attributesHash` |
| `parentHash` | `Hash32` | No | Parent hash; must pair with `attributesHash` |
| `attributesHash` | `Hash32` | No | Attributes hash; must pair with `parentHash` |

## Returns

| Field | Type | Notes |
|---|---|---|
| `result` | `string` | `v0:` followed by a base64-encoded zstd-compressed witness blob |

## Errors

| Code | Cause | Fix |
|---|---|---|
| `-32602` | `blockNumber` missing, invalid hex value, or invalid hash field combination | Fix the request |
| `-32603` | No witness data exists for the requested block | The block may be too old or witness not yet generated |
| `-32005` | Rate limit hit or batch size exceeded | Reduce batch size or retry later |

See also [Error reference](../errors.md).

## Example

```bash
curl -sS https://mainnet.megaeth.com/rpc \
  -H 'content-type: application/json' \
  --data '{"jsonrpc":"2.0","id":1,"method":"mega_getBlockWitness","params":[{"blockNumber":"0x1"}]}'
```

```jsonc
{"jsonrpc":"2.0","id":1,"result":"v0:KLUv/QBgzVUAZJwh…"}  // base64-encoded zstd blob, truncated
```
