# eth_gasPrice

Returns a gas price suggestion in wei.

`eth_gasPrice() -> Quantity` — no parameters.

## MegaETH Differences

- On the public MegaETH gateway, a standalone request currently returns a fixed value: `0xf4240`.
- On the public MegaETH gateway, a batch request returns a network-derived gas price instead.
- That standalone-vs-batch behavior is public-gateway-specific and is not part of standard Ethereum JSON-RPC.

## Response

| Field | Type | Notes |
|---|---|---|
| `result` | [`Quantity`](../types.md#quantity) | Gas price suggestion in wei |

- If your application builds EIP-1559 transactions, do not use this as your only fee input.

For error handling, see [Error reference](../errors.md).

## Example

```bash
curl -sS https://mainnet.megaeth.com/rpc \
  -H 'content-type: application/json' \
  --data '{"jsonrpc":"2.0","id":1,"method":"eth_gasPrice","params":[]}'
```

```json
{"jsonrpc":"2.0","id":1,"result":"0xf4240"}
```
