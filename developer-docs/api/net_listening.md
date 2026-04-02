# net_listening

Returns `true` if the client is actively listening for network connections.

## Parameters

None.

## Returns

**`result`** boolean

Always `true`.

## Errors

Standard JSON-RPC errors only. See [Error reference](../errors.md).

## Example

```bash
curl -sS https://mainnet.megaeth.com/rpc \
  -H 'content-type: application/json' \
  --data '{"jsonrpc":"2.0","id":1,"method":"net_listening","params":[]}'
```

```json
{"jsonrpc":"2.0","id":1,"result":true}
```
