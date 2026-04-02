# eth_createAccessList

Generates an access list for a transaction.

## Parameters

**`transaction`** object **REQUIRED**

> Transaction to simulate.

- **`from`** Address

  > Caller.

- **`to`** Address

  > Target; `null` for contract-creation simulation.

- **`value`** Quantity

  > Wei value sent.

- **`input`** Data

  > Calldata; prefer over `data`.

- **`gas`** Quantity

  > Gas cap.

- **`gasPrice`** Quantity

  > Legacy gas price; do not combine with EIP-1559 fields.

- **`maxFeePerGas`** Quantity

  > EIP-1559 max fee.

- **`maxPriorityFeePerGas`** Quantity

  > EIP-1559 priority fee.

- **`nonce`** Quantity

  > Caller nonce override.

- **`accessList`** array

  > EIP-2930 access list; each entry: `{ "address": Address, "storageKeys": [Bytes32] }`.

---

**`block`** string

> Hex block number or tag (`latest`, `safe`, `finalized`, `earliest`, `pending`). Default: `"latest"`.

## Returns

- **`accessList`** array

  > Generated EIP-2930 access list; each entry: `{ "address": Address, "storageKeys": [Bytes32] }`.

- **`gasUsed`** Quantity

  > Gas with the generated access list applied.

- **`error`** string

  > Execution error when the call reverts; may coexist with `accessList` and `gasUsed`.

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
