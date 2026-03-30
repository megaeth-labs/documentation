# eth_getTransactionCount

Returns the account nonce at a selected block.

## Ethereum Standard

`eth_getTransactionCount(address, block) -> Quantity`

## MegaETH Differences

- The public MegaETH endpoint currently accepts an omitted `block` parameter and treats it as `latest`.
- That omitted-`block` behavior is a MegaETH convenience, not portable Ethereum JSON-RPC behavior.
- On MegaETH, `pending` currently behaves the same as `latest` for this method.

## Request

Send `params` as `[address, block]`.

| Position | Type | Required | Notes |
|---|---|---|---|
| `0` | [`Address`](../types.md#address) | Yes | Target account address |
| `1` | [`BlockReferenceString`](../types.md#blockreferencestring) | Yes for portable clients | Accepts `earliest`, `latest`, `pending`, `safe`, `finalized`, a hex block number, or a block hash string |

- This is the account nonce stored in state, not a count of externally observed transactions.

## Response

| Field | Type | Notes |
|---|---|---|
| `result` | [`Quantity`](../types.md#quantity) | Account nonce at the selected block |

- Unknown accounts and zero-nonce accounts both return `0x0`.

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
  --data '{"jsonrpc":"2.0","id":91,"method":"eth_getTransactionCount","params":["0xa344fb2d117501ee379d2ea9c0c016959ad94f1e","0xb120c6"]}'
```

```json
{"jsonrpc":"2.0","id":91,"result":"0xfa8c"}
```
