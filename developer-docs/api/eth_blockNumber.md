# eth_blockNumber

Returns the current head block number known to the endpoint.

`eth_blockNumber() -> Quantity` — no parameters.

## Response

| Field | Type | Notes |
|---|---|---|
| `result` | [`Quantity`](../types.md#quantity) | Current head block number |

- The value is a moving head, not a finality signal.

For error handling, see [Error reference](../errors.md).

## Example

```bash
curl -sS https://mainnet.megaeth.com/rpc \
  -H 'content-type: application/json' \
  --data '{"jsonrpc":"2.0","id":21,"method":"eth_blockNumber","params":[]}'
```

```json
{"jsonrpc":"2.0","id":21,"result":"0xaeb3d6"}
```
