# eth_createAccessList

Simulates a transaction and returns the accessed addresses and storage keys.

## Ethereum Standard

`eth_createAccessList(transaction, block?) -> CreateAccessListResult`

## MegaETH Differences

- MegaETH currently accepts both `input` and `data` as calldata field names.
- The public MegaETH endpoint currently accepts an omitted `block` parameter.
- If you provide an `accessList`, MegaETH uses it as a seed and augments it with any additional addresses and storage slots discovered during simulation.
- MegaETH can report some execution failures inside `result.error` while still returning `accessList` and `gasUsed`.

## Request

Portable clients should send `params` as `[transaction, block]`.

| Position | Type | Required | Notes |
|---|---|---|---|
| `0` | [`TransactionCall`](../types.md#transactioncall) | Yes | Simulation transaction object |
| `1` | [`BlockReferenceString`](../types.md#blockreferencestring) | No | Execution context |

Reader notes:

- Prefer `input` for portable client behavior.
- Use either `gasPrice` or EIP-1559 fee fields, not both.
- For contract creation, omit `to` and place init code in `input`.
- Do not set `gas` unless you intentionally want to cap the simulation.
- Use an explicit block selector when you need portable or reproducible behavior.

## Response

| Field | Type | Notes |
|---|---|---|
| `result` | [`CreateAccessListResult`](../types.md#createaccesslistresult) | Generated access list, gas used, and possibly `error` |

- Check both top-level JSON-RPC errors and `result.error`. Not all failures use the same channel.

## Common Errors

| Code | When it usually happens | What to do |
|---|---|---|
| `-32602` | The transaction object or block selector is malformed | Fix the request before retrying |
| `-32000` | A pre-execution check failed, such as intrinsic gas being too low | Raise or remove the gas cap and retry only after fixing the request |
| `-32003` | The sender cannot cover gas and value in the selected state | Fund the sender or lower the value or fee requirements |
| `-32005` | The public endpoint rate-limited the request | Back off and retry later |

See also [Error reference](../errors.md).

## Examples

### Successful simulation

```bash
curl -sS https://mainnet.megaeth.com/rpc \
  -H 'content-type: application/json' \
  --data '{"jsonrpc":"2.0","id":7,"method":"eth_createAccessList","params":[{"to":"0x1111111111111111111111111111111111111111","input":"0x"},"latest"]}'
```

```json
{"jsonrpc":"2.0","id":7,"result":{"accessList":[],"gasUsed":"0xea60"}}
```

### Execution failure carried inside `result.error`

Some simulations still return a normal top-level `result` object even when execution halts after it starts:

```json
{
  "jsonrpc": "2.0",
  "id": 8,
  "result": {
    "accessList": [
      {
        "address": "0x1111111111111111111111111111111111111111",
        "storageKeys": []
      }
    ],
    "gasUsed": "0x186a0",
    "error": "execution reverted"
  }
}
```

