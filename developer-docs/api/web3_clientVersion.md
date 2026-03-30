# web3_clientVersion

Returns the current client version string.

## Ethereum Standard

`web3_clientVersion() -> string`

## Request

No parameters.

## Response

| Field | Type | Notes |
|---|---|---|
| `result` | `string` | Client name, version, and build target |

## Example

```bash
curl -sS https://mainnet.megaeth.com/rpc \
  -H 'content-type: application/json' \
  --data '{"jsonrpc":"2.0","id":1,"method":"web3_clientVersion","params":[]}'
```

```json
{"jsonrpc":"2.0","id":1,"result":"mega-reth/v2.0.17-97ab2f0@mnet-sgp-rpc-2"}
```
