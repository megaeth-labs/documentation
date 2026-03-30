# eth_getBlockTransactionCountByNumber

Returns the number of transactions in a block selected by block number or canonical block tag.

## Ethereum Standard

`eth_getBlockTransactionCountByNumber(block) -> Quantity | null`

## Request

Send `params` as `[block]`.

| Position | Type | Required | Notes |
|---|---|---|---|
| `0` | [`BlockNumberOrTag`](../types.md#blocknumberortag) | Yes | Accepts `earliest`, `latest`, `pending`, `safe`, `finalized`, or a hex block number |

Reader notes:

- Use a fixed block number when you need deterministic results.
- Decimal strings such as `"12345"` are invalid; block numbers must be hex [`Quantity`](../types.md#quantity) strings.
- EIP-1898-style block selector objects are not accepted here.

## Response

| Field | Type | Notes |
|---|---|---|
| `result` | [`Quantity`](../types.md#quantity) or `null` | Transaction count for the selected block |

- `0x0` means zero transactions; `null` means the block was not found. Treat them differently.
- On the public MegaETH endpoint, `pending` and future block numbers can return `null`.

## Common Errors

| Code | When it usually happens | What to do |
|---|---|---|
| `-32602` | The block selector is malformed, uses a decimal string, or uses an unsupported object form | Fix the request before retrying |
| `-32005` | The public endpoint rate-limited the request | Back off and retry later |

See also [Error reference](../errors.md).

## Example

```bash
curl -sS https://mainnet.megaeth.com/rpc \
  -H 'content-type: application/json' \
  --data '{"jsonrpc":"2.0","id":4,"method":"eth_getBlockTransactionCountByNumber","params":["0xb11362"]}'
```

```json
{"jsonrpc":"2.0","id":4,"result":"0x17"}
```
