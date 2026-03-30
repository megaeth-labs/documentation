# net_version

Returns the network ID as a decimal string.

## Ethereum Standard

`net_version() -> string`

## MegaETH Differences

- Returns `"4326"` on mainnet and `"6343"` on testnet.
- The return value is a decimal string, not a hex `Quantity`. Use [`eth_chainId`](./eth_chainId.md) when you need the chain ID for transaction signing.

## Request

No parameters.

## Response

| Field | Type | Notes |
|---|---|---|
| `result` | `string` | Network ID as a decimal integer string |

## Example

```bash
curl -sS https://mainnet.megaeth.com/rpc \
  -H 'content-type: application/json' \
  --data '{"jsonrpc":"2.0","id":1,"method":"net_version","params":[]}'
```

```json
{"jsonrpc":"2.0","id":1,"result":"4326"}
```
