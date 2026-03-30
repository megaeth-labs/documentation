# eth_unsubscribe

Cancels an active subscription created by [`eth_subscribe`](./eth_subscribe.md).

## Ethereum Standard

`eth_unsubscribe(subscriptionId) -> bool`

This method requires a persistent WebSocket connection. It is not available over HTTP.

## Request

Send `params` as `[subscriptionId]`.

| Position | Type | Required | Notes |
|---|---|---|---|
| `0` | [`Data`](../types.md#data) | Yes | Subscription ID returned by `eth_subscribe` |

## Response

| Field | Type | Notes |
|---|---|---|
| `result` | `bool` | `true` if the subscription was found and cancelled; `false` if the ID was not active |

## Common Errors

| Code | When it usually happens | What to do |
|---|---|---|
| `-32602` | The subscription ID parameter is missing | Provide the subscription ID returned by `eth_subscribe` |
| `-32600` | The subscription ID exists but was created by a different connection | Only the connection that created the subscription can cancel it |

See also [Error reference](../errors.md).

## Example

```bash
wscat -c wss://mainnet.megaeth.com/ws \
# wait for connection
{"jsonrpc":"2.0","id":1,"method":"eth_unsubscribe","params":["0xaec58cfc2dc41f873fc37d6c871230c1"]}
```

```json
{"jsonrpc":"2.0","id":1,"result":true}
```
