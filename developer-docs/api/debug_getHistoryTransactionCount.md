# debug_getHistoryTransactionCount

Returns the chain-wide cumulative transaction count at a selected block.

## Ethereum Standard

This method is not part of the standard Ethereum JSON-RPC method set.

## MegaETH Differences

- This is a MegaETH-specific debug method.
- The result is a global cumulative chain counter, not an account nonce.
- Accepted selectors on the public MegaETH mainnet endpoint are hex block numbers and the tags `earliest`, `latest`, `safe`, and `finalized`.
- `pending` is not supported for this method on the public MegaETH mainnet endpoint.
- Block hashes are not accepted.

## Request

Send `params` as `[block]`.

| Position | Type | Required | Notes |
|---|---|---|---|
| `0` | [`BlockReferenceString`](../types.md#blockreferencestring) | Yes | For this method, use a hex block number or one of `earliest`, `latest`, `safe`, `finalized` |

- Do not confuse with [eth_getTransactionCount](./eth_getTransactionCount.md) which returns per-account nonce.

## Response

| Field | Type | Notes |
|---|---|---|
| `result` | [`Quantity`](../types.md#quantity) | Total number of transactions recorded on chain up to and including the selected block |

- Chain-wide cumulative counter. An empty block can return the same value as the previous block.

## Common Errors

| Code | When it usually happens | What to do |
|---|---|---|
| `-32001` | The requested block selector cannot be resolved, or an unsupported tag such as `pending` was used | Check the selector before retrying |
| `-32602` | The request uses the wrong parameter shape, such as a block hash | Fix the request before retrying |
| `-32005` | The public endpoint rate-limited the request | Back off and retry later |

See also [Error reference](../errors.md).

## Example

```bash
curl -sS https://mainnet.megaeth.com/rpc \
  -H 'content-type: application/json' \
  --data '{"jsonrpc":"2.0","id":1,"method":"debug_getHistoryTransactionCount","params":["0x12a05f"]}'
```

```json
{"jsonrpc":"2.0","id":1,"result":"0x12cbab"}
```
