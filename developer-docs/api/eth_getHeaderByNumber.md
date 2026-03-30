# eth_getHeaderByNumber

Returns a header-only view of a block selected by block number or canonical block tag.

## Ethereum Standard

This method is not part of the standard Ethereum JSON-RPC method set.

## MegaETH Differences

- `eth_getHeaderByNumber(block) -> Header | null`
- This is a MegaETH-specific header method.
- The response omits `transactions`, `uncles`, and `size`.
- On the public MegaETH endpoint, `pending` can return `null`.
- If you need wider provider compatibility, use [`eth_getBlockByNumber`](./eth_getBlockByNumber.md) and read header fields from the block object.

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
| `result` | [`Header`](../types.md#header) or `null` | Header-only block data |

- `result: null` when the block cannot be resolved or is not available.

## Common Errors

| Code | When it usually happens | What to do |
|---|---|---|
| `-32602` | The selector is malformed, uses a decimal string, or uses an unsupported object form | Fix the request before retrying |
| `-32005` | The public endpoint rate-limited the request | Back off and retry later |

See also [Error reference](../errors.md).

## Example

```bash
curl -sS https://mainnet.megaeth.com/rpc \
  -H 'content-type: application/json' \
  --data '{"jsonrpc":"2.0","id":27,"method":"eth_getHeaderByNumber","params":["0xb11048"]}'
```

```json
{
  "jsonrpc": "2.0",
  "id": 27,
  "result": {
    "hash": "0x235d80b5e91125a1a1d6da6776c6a9ee087d1818c494f71736b09bed61b1411e",
    "parentHash": "0x6fc0412abfba89bbfab17b2d8bd36cb1c214c1d53ed213fa8958439d0c4f9c18",
    "stateRoot": "0x301d7b77a74893451bd76e5d1672aaaa493cd78c06d59e885218d48917a35c03",
    "number": "0xb11048",
    "timestamp": "0x69c3361b",
    "baseFeePerGas": "0xf4240"
  }
}
```
