# eth_unsubscribe

Cancels an existing subscription so that no further events are sent.

## Parameters

**`subscriptionId`** Data **REQUIRED**

Subscription ID returned by `eth_subscribe`.

## Returns

**`result`** boolean

`true` if the subscription was found and cancelled; `false` if the ID was not active.

## Errors

| Code | Cause | Fix |
|---|---|---|
| `-32602` | Subscription ID parameter is missing | Provide the subscription ID returned by `eth_subscribe` |
| `-32600` | Subscription was created by a different connection | Cancel from the connection that created the subscription |

See also [Error reference](../errors.md).

## Example

```bash
wscat -c wss://mainnet.megaeth.com/ws
> {"jsonrpc":"2.0","id":1,"method":"eth_unsubscribe","params":["0xaec58cfc2dc41f873fc37d6c871230c1"]}
```

```json
{"jsonrpc":"2.0","id":1,"result":true}
```
