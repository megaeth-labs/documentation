# eth_getBlockReceipts

Returns all receipts for a selected block.

## Ethereum Standard

`eth_getBlockReceipts(block) -> Receipt[] | null`

## MegaETH Differences

- The public MegaETH endpoint currently accepts the standard string selector forms plus an EIP-1898-style [`BlockHashSelector`](../types.md#blockhashselector) object such as `{"blockHash":"0x..."}`.
- On the public MegaETH endpoint, `pending` currently returns `null`.
- This method is `io_heavy` on public MegaETH gateways. Large blocks can still hit response-size and rate-limit constraints. See [Operations and limits](../operations/limits.md).

## Request

Send `params` as `[block]`.

| Position | Type | Required | Notes |
|---|---|---|---|
| `0` | [`BlockNumberOrTagOrHash`](../types.md#blocknumberortagorhash) | Yes | Accepts `earliest`, `latest`, `pending`, `safe`, `finalized`, a hex block number, a 32-byte block hash string, or a MegaETH-supported `{blockHash}` selector object |

Reader notes:

- Use a fixed block number or block hash when you need deterministic results.
- Portable clients should prefer the standard string forms first.
- `pending` is not a portable way to fetch speculative receipts; on the public MegaETH endpoint it currently returns `null`.

## Response

| Field | Type | Notes |
|---|---|---|
| `result` | [`Receipt`](../types.md#receipt)`[]` or `null` | Receipts for every transaction in the selected block |

Reader notes:

- `result: []` is a normal success when the selected block exists but contains no transactions. `0x0` and `earliest` can return `[]`.
- `result: null` is a normal success when the selector is well-formed but does not resolve to an available block. On public MegaETH this includes `pending`, future block numbers, and unknown block hashes.
- Each array item is a full receipt object. Receipt fields can include MegaETH fee-accounting extensions such as `l1GasPrice` and `l1Fee`.
- Nested log objects can include MegaETH `blockTimestamp` fields when exposed by the serving layer.

## Common Errors

| Code | When it usually happens | What to do |
|---|---|---|
| `-32602` | The block selector is malformed, missing, or uses an unsupported object shape | Fix the selector before retrying |
| `4444` | The endpoint cannot serve the requested historical block data | Keep the request unchanged and verify historical-state availability for that endpoint |
| `-32005` | The public endpoint rate-limited the request | Back off and retry later |

See also [Error reference](../errors.md) and [Operations and limits](../operations/limits.md).

## Examples

### Empty block by number

```bash
curl -sS https://mainnet.megaeth.com/rpc \
  -H 'content-type: application/json' \
  --data '{"jsonrpc":"2.0","id":12,"method":"eth_getBlockReceipts","params":["0x0"]}'
```

```json
{"jsonrpc":"2.0","id":12,"result":[]}
```

### By block hash selector object

```bash
curl -sS https://mainnet.megaeth.com/rpc \
  -H 'content-type: application/json' \
  --data '{"jsonrpc":"2.0","id":16,"method":"eth_getBlockReceipts","params":[{"blockHash":"0x57804c21b747137075b29ce153b4f559345a3624273660c87e81bd57e7cbbc3d"}]}'
```

```json
{
  "jsonrpc": "2.0",
  "id": 16,
  "result": [
    {
      "type": "0x7e",
      "status": "0x1",
      "cumulativeGasUsed": "0xb9d56c",
      "logs": [],
      "depositNonce": "0x0",
      "depositReceiptVersion": "0x1",
      "logsBloom": "0x00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000",
      "transactionHash": "0xecc262f36652019b75f4cb7315ff19f430fc92efd5a8048948400407d55fd904",
      "transactionIndex": "0x0",
      "blockHash": "0x57804c21b747137075b29ce153b4f559345a3624273660c87e81bd57e7cbbc3d",
      "blockNumber": "0x1",
      "gasUsed": "0xb9d56c",
      "effectiveGasPrice": "0x0",
      "from": "0xdeaddeaddeaddeaddeaddeaddeaddeaddead0001",
      "to": "0x4200000000000000000000000000000000000015",
      "contractAddress": null,
      "l1GasPrice": "0x22ba611d",
      "l1GasUsed": "0x6e7",
      "l1Fee": "0x0",
      "l1BaseFeeScalar": "0x558",
      "l1BlobBaseFee": "0x7",
      "l1BlobBaseFeeScalar": "0xc5fc5"
    }
  ]
}
```
