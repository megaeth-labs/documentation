# eth_getHeaderByHash

Returns a header-only view of a block selected by block hash.

## Ethereum Standard

This method is not part of the standard Ethereum JSON-RPC method set.

## MegaETH Differences

- `eth_getHeaderByHash(blockHash) -> Header | null`
- This is a MegaETH-specific header method.
- The response omits `transactions`, `uncles`, and `size`.
- If you need transactions or block size, use [`eth_getBlockByHash`](./eth_getBlockByHash.md).

## Request

Send `params` as `[blockHash]`.

| Position | Type | Required | Notes |
|---|---|---|---|
| `0` | [`BlockHash`](../types.md#blockhash) | Yes | Target block hash |

- Block tags such as `latest` or `pending` do not apply here.

## Response

| Field | Type | Notes |
|---|---|---|
| `result` | [`Header`](../types.md#header) or `null` | Header-only block data |

- `result: null` when the hash does not resolve to a block.

## Common Errors

| Code | When it usually happens | What to do |
|---|---|---|
| `-32602` | The block hash is missing or malformed | Fix the request before retrying |
| `-32005` | The public endpoint rate-limited the request | Back off and retry later |

See also [Error reference](../errors.md).

## Example

```bash
curl -sS https://mainnet.megaeth.com/rpc \
  -H 'content-type: application/json' \
  --data '{"jsonrpc":"2.0","id":26,"method":"eth_getHeaderByHash","params":["0x6f3fcff78eefe9591d2ad590b8a78738b8ad80d9646eccd302618cd9198b73e0"]}'
```

```json
{
  "jsonrpc": "2.0",
  "id": 26,
  "result": {
    "hash": "0x6f3fcff78eefe9591d2ad590b8a78738b8ad80d9646eccd302618cd9198b73e0",
    "parentHash": "0x6b6b52368c21dcdba7348fa37edae3e945013627a83a96b64d55217696899d30",
    "stateRoot": "0xf328fa2752aea1c211a73067d17c25d09a416b4b6a7785441f39bcc930028717",
    "number": "0xb10f64",
    "timestamp": "0x69c33537",
    "baseFeePerGas": "0xf4240"
  }
}
```
