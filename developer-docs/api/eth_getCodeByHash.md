

# eth_getCodeByHash

Returns runtime bytecode for a given code hash.

## Parameters

| Position | Name | Type | Required | Notes |
|---|---|---|---|---|
| `0` | `codeHash` | [`CodeHash`](../types.md#codehash) | Yes | Target runtime code hash |

## Returns

| Field | Type | Notes |
|---|---|---|
| `result` | [`Data`](../types.md#data) | Runtime bytecode; `0x` when no bytecode is stored for that hash |

## Errors

| Code | Cause | Fix |
|---|---|---|
| `-32602` | Code hash is missing or malformed | Fix the request |

See also [Error reference](../errors.md).

## Example

```bash
curl -sS https://mainnet.megaeth.com/rpc \
  -H 'content-type: application/json' \
  --data '{"jsonrpc":"2.0","id":43,"method":"eth_getCodeByHash","params":["0xfa8c9db6c6cab7108dea276f4cd09d575674eb0852c0fa3187e59e98ef977998"]}'
```

```json
{"jsonrpc":"2.0","id":43,"result":"0x60806040526004361061005e57..."}
```
