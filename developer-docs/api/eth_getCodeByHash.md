# eth_getCodeByHash

Returns runtime bytecode for a given code hash.

## Parameters

**`codeHash`** Hash32 **REQUIRED**

Target runtime code hash.

## Returns

**`result`** Data

Runtime bytecode; `0x` when no bytecode is stored for that hash.

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

```jsonc
{"jsonrpc":"2.0","id":43,"result":"0x6080604052…"}  // bytecode truncated
```
