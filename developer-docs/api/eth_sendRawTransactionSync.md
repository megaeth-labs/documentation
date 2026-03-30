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

```json
{
  "jsonrpc": "2.0",
  "id": 91,
  "method": "eth_sendRawTransactionSync",
  "params": [
    "0xf86480830f424082ea6094000000000000000000000000000000000000000080808231b1a050e782f95780eaaf16dfaa0c1294c6705ada7a97b525f119c924f35dd14e0165a05c57cf60cd5c818445d3b5c4f25488540a8af6b3214cf82758794933df5aa108",
    3000
  ]
}
```

```json
{
  "jsonrpc": "2.0",
  "id": 91,
  "result": {
    "transactionHash": "0xb7cb129026cdb9dc9f590386e5cb5ae469872acb188939d641491f123031f442",
    "blockHash": "0x6388332c56f0e05a6b68986bebaa5512ccea02a90b46698078d31d809712b95b",
    "blockNumber": "0x100",
    "status": "0x1",
    "gasUsed": "0x5208",
    "logs": []
  }
}
```
