# eth_getTransactionCount

Returns the account nonce for a given address at a specified block.

## Parameters

| Position | Name | Type | Required | Notes |
|---|---|---|---|---|
| `0` | `address` | [`Address`](../types.md#address) | Yes | Target account address |
| `1` | `block` | [`BlockNumberOrTag`](../types.md#blocknumberortag) | No | Default: `latest` |

## Returns

| Field | Type | Notes |
|---|---|---|
| `result` | [`Quantity`](../types.md#quantity) | Account nonce at the requested block. Returns `0x0` for both unknown accounts and zero-nonce accounts. |

## Errors

| Code | Cause | Fix |
|---|---|---|
| `-32602` | Malformed address or block selector | Fix the request |
| `-32001` | Block selector cannot be resolved | Verify the block number or hash |
| `4444` | Requested historical state is unavailable | Verify historical-state availability for the endpoint |

See also [Error reference](../errors.md).

## Example

```bash
curl -sS https://mainnet.megaeth.com/rpc \
  -H 'content-type: application/json' \
  --data '{"jsonrpc":"2.0","id":91,"method":"eth_getTransactionCount","params":["0xa344fb2d117501ee379d2ea9c0c016959ad94f1e","0xb120c6"]}'
```

```jsonc
{"jsonrpc":"2.0","id":91,"result":"0xfa8c"}  // nonce 64,140 (block 11,608,262)
```
