# eth_sendRawTransaction

Submits a signed transaction to the network and returns its hash.

## Ethereum Standard

`eth_sendRawTransaction(rawTx) -> Data`

## MegaETH Differences

- EIP-155 replay protection is required. Transactions with a legacy `v` of `27` or `28` are rejected at the gateway before reaching the pool.
- Nonce gaps are rate-controlled. A gap of more than 5 above the current account nonce requires the sender to hold at least 0.1 ETH; smaller gaps are always accepted.

## Request

Send `params` as `[rawTx]`.

| Position | Type | Required | Notes |
|---|---|---|---|
| `0` | [`Data`](../types.md#data) | Yes | Fully signed transaction bytes as a `0x`-prefixed hex string |

Reader notes:

- Supported envelope types: legacy (`0x0`), EIP-2930 access list (`0x01`), EIP-1559 dynamic fee (`0x02`), EIP-4844 blob (`0x03`), EIP-7702 authorization (`0x04`).

## Response

| Field | Type | Notes |
|---|---|---|
| `result` | [`Data`](../types.md#data) | 32-byte transaction hash |

## Common Errors

| Code | When it usually happens | What to do |
|---|---|---|
| `-32602` | The parameter is missing, the hex string is malformed, or the bytes cannot be decoded as a signed transaction | Re-encode or re-sign the transaction before retrying |
| `-32000` | The transaction fails a pool or gateway rule: wrong chain ID, EIP-155 required, nonce too low, nonce gap too large, gas limit below intrinsic, gas price below minimum, or replacement fee bump insufficient. `already known` means the transaction is already pending — no action needed. | Read the error message and correct the specific field before retrying; ignore `already known` |
| `-32003` | The node rejects the transaction outright: insufficient sender funds, pool at capacity, or unsupported transaction type for this network | Fund the sender, wait before retrying if the pool is full, or switch to a supported transaction type |
| `-32005` | The public endpoint rate-limited the request | Back off and retry later |

See also [Error reference](../errors.md) and [`eth_sendRawTransactionSync`](./eth_sendRawTransactionSync.md) if you need to wait for the receipt in a single call.

## Example

```bash
curl -sS https://mainnet.megaeth.com/rpc \
  -H 'content-type: application/json' \
  --data '{"jsonrpc":"2.0","id":1,"method":"eth_sendRawTransaction","params":["0xf86c808405763d658261a894aa000000000000000000000000000000000000000a8255448718e5bb3abd109fa0c8e3b4a0087357bd49d80a0ac24daf0c91191e71086c1e355fc62cfab2218873a074f4636f740fa4d1697b6e736e5982b700be2c8b63031a24fa531ae4814b3af8"]}'
```

```json
{"jsonrpc":"2.0","id":1,"result":"0x66734e85ef096167acb887cf445946a1ed57b90b66ffe38af87e11294febbfa9"}
```
