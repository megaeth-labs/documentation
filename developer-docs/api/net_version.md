# net_version

Returns the current network ID as a decimal string. On MegaETH mainnet the result is `"4326"`; on testnet, `"6343"`. The value is a decimal string, not a hex `Quantity` — use [`eth_chainId`](./eth_chainId.md) when you need the chain ID for transaction signing.

## Parameters

None.

## Returns

| Field | Type | Notes |
|---|---|---|
| `result` | `string` | Network ID as a decimal integer string |

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
