# net_version

Returns the current network ID as a decimal string.

## Parameters

None.

## Returns

**`result`** string

Network ID as a decimal integer string.

## Errors

Standard JSON-RPC errors only. See [Error reference](../errors.md).

## Example

```bash
curl -sS https://mainnet.megaeth.com/rpc \
  -H 'content-type: application/json' \
  --data '{"jsonrpc":"2.0","id":1,"method":"net_version","params":[]}'
```

```json
{"jsonrpc":"2.0","id":1,"result":"4326"}
```
