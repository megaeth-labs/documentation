# eth_sendRawTransaction

Submits a signed transaction to the network and returns its transaction hash.

## Parameters

| Position | Name | Type | Required | Notes |
|---|---|---|---|---|
| `0` | `rawTx` | `Data` | Yes | Signed, RLP-encoded transaction bytes. Supported envelope types: legacy, EIP-2930 (`0x01`), EIP-1559 (`0x02`), EIP-4844 (`0x03`), EIP-7702 (`0x04`) |

## Returns

| Field | Type | Notes |
|---|---|---|
| `result` | `Data` | 32-byte transaction hash |

## Errors

| Code | Cause | Fix |
|---|---|---|
| `-32602` | Parameter missing, hex malformed, or bytes cannot be decoded as a signed transaction | Fix the transaction |
| `-32000` | Pool or gateway rule violation | Fix the field identified in `error.message` |
| `-32003` | Insufficient sender funds, pool at capacity, or unsupported transaction type | Fund the sender or wait for pool capacity |

See also [Error reference](../errors.md).

## Example

```bash
curl -sS https://mainnet.megaeth.com/rpc \
  -H 'content-type: application/json' \
  --data '{"jsonrpc":"2.0","id":1,"method":"eth_sendRawTransaction","params":["0xf86c808405763d658261a894aa000000000000000000000000000000000000000a8255448718e5bb3abd109fa0c8e3b4a0087357bd49d80a0ac24daf0c91191e71086c1e355fc62cfab2218873a074f4636f740fa4d1697b6e736e5982b700be2c8b63031a24fa531ae4814b3af8"]}'
```

```json
{"jsonrpc":"2.0","id":1,"result":"0x66734e85ef096167acb887cf445946a1ed57b90b66ffe38af87e11294febbfa9"}
```
