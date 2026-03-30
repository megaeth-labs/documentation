# eth_getCode

Returns the runtime bytecode stored at an address at a selected block.

## Ethereum Standard

`eth_getCode(address, block) -> Data`

## MegaETH Differences

- The public MegaETH endpoint currently accepts an omitted `block` parameter and treats it as `latest`.
- That omitted-`block` behavior is a MegaETH convenience, not portable Ethereum JSON-RPC behavior.

## Request

Send `params` as `[address, block]`.

| Position | Type | Required | Notes |
|---|---|---|---|
| `0` | [`Address`](../types.md#address) | Yes | Target account or contract address |
| `1` | [`BlockReferenceString`](../types.md#blockreferencestring) | Yes for portable clients | Accepts `earliest`, `latest`, `pending`, `safe`, `finalized`, a hex block number, or a block hash string |

## Response

| Field | Type | Notes |
|---|---|---|
| `result` | [`Data`](../types.md#data) | Runtime bytecode at the selected address and block |

- `0x` means the address has no deployed runtime bytecode at the selected block.
- Non-empty results are runtime bytecode, not creation bytecode.

## Common Errors

| Code | When it usually happens | What to do |
|---|---|---|
| `-32602` | The address or block selector is malformed | Fix the request before retrying |
| `-32001` | The block selector cannot be resolved | Check the block number, block hash, or network |
| `4444` | The endpoint cannot serve the requested historical state | Keep the request unchanged and verify historical-state availability for that endpoint |
| `-32005` | The public endpoint rate-limited the request | Back off and retry later |

See also [Error reference](../errors.md).

## Example

```bash
curl -sS https://mainnet.megaeth.com/rpc \
  -H 'content-type: application/json' \
  --data '{"jsonrpc":"2.0","id":2,"method":"eth_getCode","params":["0x4200000000000000000000000000000000000011","latest"]}'
```

```json
{"jsonrpc":"2.0","id":2,"result":"0x60806040526004361061005e57..."}
```
