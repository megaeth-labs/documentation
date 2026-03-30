# eth_getCodeByHash

Returns runtime bytecode for a code hash.

## Ethereum Standard

This method is not part of the standard Ethereum JSON-RPC method set.

## MegaETH Differences

- This is a MegaETH-specific extension.
- Use it when your workflow already has a code hash.
- If you start from an address and block selector, use [eth_getCode](./eth_getCode.md) instead.

## Request

Send `params` as `[codeHash]`.

| Position | Type | Required | Notes |
|---|---|---|---|
| `0` | [`CodeHash`](../types.md#codehash) | Yes | Target runtime code hash |


## Response

| Field | Type | Notes |
|---|---|---|
| `result` | [`Data`](../types.md#data) | Runtime bytecode for the requested code hash |

- `0x` means no bytecode is stored for that hash.
- Non-empty results are runtime bytecode, not creation bytecode.

## Common Errors

| Code | When it usually happens | What to do |
|---|---|---|
| `-32602` | The code hash is missing or malformed | Fix the request before retrying |
| `-32005` | The public endpoint rate-limited the request | Back off and retry later |

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
