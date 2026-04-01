# eth_createAccessList

Simulates a transaction and returns the EIP-2930 access list of addresses and storage keys touched during execution, along with the gas estimate.

## Parameters

| Position | Name | Type | Required | Notes |
|---|---|---|---|---|
| `0` | `transaction` | `object` | Yes | Transaction to simulate |
| `1` | `block` | [`BlockNumberOrTag`](../types.md#blocknumberortag) | No | Default: `"latest"` |

### `transaction`

| Field | Type | Required | Notes |
|---|---|---|---|
| `from` | `Address` | No | Caller |
| `to` | `Address \| null` | No | Target; `null` for create simulation |
| `value` | `Quantity` | No | Native value sent |
| `input` | `Data` | No | Calldata; prefer over `data` |
| `gas` | `Quantity` | No | Gas cap |
| `gasPrice` | `Quantity` | No | Legacy fee; do not mix with EIP-1559 fields |
| `maxFeePerGas` | `Quantity` | No | EIP-1559 max fee |
| `maxPriorityFeePerGas` | `Quantity` | No | EIP-1559 tip cap |
| ... | | | See [`TransactionCall`](../types.md#transactioncall) for the complete field list |

### `block`

Execution context. Accepts a hex block number or one of: `"earliest"`, `"latest"`, `"pending"`, `"safe"`, `"finalized"`. Default: `"latest"`.

## Returns

| Field | Type | Notes |
|---|---|---|
| `accessList` | [`AccessListEntry[]`](../types.md#accesslistentry) | Generated EIP-2930 access list |
| `gasUsed` | `Quantity` | Gas with the generated access list applied |
| `error` | `string` | Execution error when the call reverts; may coexist with `accessList` and `gasUsed` |

## Errors

| Code | Cause | Fix |
|---|---|---|
| `-32602` | Malformed transaction object or block selector | Fix the request |
| `-32000` | Pre-execution check failed (e.g. intrinsic gas too low) | Raise or remove the gas cap |
| `-32003` | Sender cannot cover gas and value in the selected state | Fund the sender or lower the value/fee |

See also [Error reference](../errors.md).

## Example

```bash
curl -sS https://mainnet.megaeth.com/rpc \
  -H 'content-type: application/json' \
  --data '{"jsonrpc":"2.0","id":7,"method":"eth_createAccessList","params":[{"to":"0x1111111111111111111111111111111111111111","input":"0x"},"latest"]}'
```

```json
{
  "jsonrpc": "2.0",
  "id": 7,
  "result": {
    "accessList": [],
    "gasUsed": "0xea60"
  }
}
```
