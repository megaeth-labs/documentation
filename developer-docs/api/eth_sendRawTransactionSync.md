# eth_sendRawTransactionSync

Submits a signed transaction and waits until the endpoint can return a receipt.

## Ethereum Standard

`eth_sendRawTransactionSync(rawTx[, timeoutMs]) -> Receipt`

This method is defined by draft EIP-7966. It is not part of the standard Ethereum execution-apis method set. The result is a [`Receipt`](../types.md#receipt), not a transaction hash.

## MegaETH Differences

- MegaETH supports this method as an extension.
- Success means the transaction has a receipt in a canonical block at response time, not that it is finalized.
- Invalid `timeoutMs` values currently return `-32602`.
- On timeout, MegaETH currently returns `-32000` with a timeout message instead of an EIP-specific timeout code.

## Request

Send `params` as `[rawTx]` or `[rawTx, timeoutMs]`.

| Position | Type | Required | Notes |
|---|---|---|---|
| `0` | [`Data`](../types.md#data) | Yes | Signed raw transaction bytes as a `0x`-prefixed hex string |
| `1` | `number` | No | Positive client wait budget in milliseconds |

Reader notes:

- `rawTx` must already be fully signed for the target chain.
- Precompute and store the transaction hash before sending the request.
- `timeoutMs` only limits how long the call waits for inclusion feedback.

## Response

| Field | Type | Notes |
|---|---|---|
| `result` | [`Receipt`](../types.md#receipt) | Receipt for the included transaction |

Reader notes:

- `status: 0x0` still means the JSON-RPC call succeeded and the transaction reached chain execution; the transaction itself reverted.
- A returned receipt reflects canonical inclusion at response time, not finality.
- A timeout error is inconclusive. The transaction can still be included later.

## Common Errors

| Code | When it usually happens | What to do |
|---|---|---|
| `-32602` | The raw transaction is malformed, undecodable, or `timeoutMs` is invalid | Fix the request before retrying |
| `-32000` | The receipt was not available before the wait window expired, or the node rejected the signed transaction | Treat timeout as inconclusive; otherwise inspect the error message and fix or replace the transaction |

See also [Error reference](../errors.md).

## Example

```bash
curl -sS https://mainnet.megaeth.com/rpc \
  -H 'content-type: application/json' \
  --data '{
    "jsonrpc": "2.0",
    "id": 91,
    "method": "eth_sendRawTransactionSync",
    "params": [
      "0xf86480830f424082ea6094cc4b43ab7230cc5913801a746c1834aa06c4e7e780808231b2a0b8126d2c41a6c7dbd0a9e219233497057bb391e7ee1d628370f9c1456f82b054a06663fde9daa2fae784c3dac1c9a5a973d538e3a12ec9c0e4d3cee9c70ba2b239",
      3000
    ]
  }'
```

```json
{
  "jsonrpc": "2.0",
  "id": 91,
  "result": {
    "type": "0x0",
    "status": "0x1",
    "transactionHash": "0x8d3b1e22e7a9026c8658b5d922293d59e4de7c3382bb832d6890e6ab23ad7ec7",
    "transactionIndex": "0x5",
    "blockHash": "0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff",
    "blockNumber": "0xe7133c",
    "from": "0xcc4b43ab7230cc5913801a746c1834aa06c4e7e7",
    "to": "0xcc4b43ab7230cc5913801a746c1834aa06c4e7e7",
    "gasUsed": "0xea60",
    "effectiveGasPrice": "0xf4240",
    "cumulativeGasUsed": "0x143043",
    "contractAddress": null,
    "logs": [],
    "logsBloom": "0x000...000",
    "l1GasPrice": "0x3216",
    "l1GasUsed": "0x640",
    "l1Fee": "0x6da0",
    "l1BaseFeeScalar": "0x558",
    "l1BlobBaseFee": "0x1",
    "l1BlobBaseFeeScalar": "0x0"
  }
}
```
