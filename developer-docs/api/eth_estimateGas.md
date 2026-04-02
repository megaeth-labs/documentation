# eth_estimateGas

Estimates the gas required to execute a transaction.

## Parameters

**`transaction`** object **REQUIRED**

Transaction to simulate.

- **`from`** Address

  Caller.

- **`to`** Address

  Target; `null` for contract-creation simulation.

- **`value`** Quantity

  Wei value sent.

- **`input`** Data

  Calldata; prefer over `data`.

- **`gas`** Quantity

  Gas cap.

- **`gasPrice`** Quantity

  Legacy gas price; do not combine with EIP-1559 fields.

- **`maxFeePerGas`** Quantity

  EIP-1559 max fee.

- **`maxPriorityFeePerGas`** Quantity

  EIP-1559 priority fee.

- **`nonce`** Quantity

  Caller nonce override.

- **`accessList`** array

  EIP-2930 access list; each entry: `{ "address": Address, "storageKeys": [Bytes32] }`.

---

**`block`** string

Hex block number or tag (`latest`, `safe`, `finalized`, `earliest`, `pending`). Default: `"latest"`.

## Returns

**`result`** Quantity

Estimated execution gas.

## Errors

| Code | Cause | Fix |
|---|---|---|
| `-32602` | Malformed transaction fields, fee model, or block selector | Fix the request |
| `-32000` | Estimation failed, hit a provider-side execution limit, or used a rejected explicit gas cap | Inspect `error.message` and adjust gas or call shape |
| `3` | Simulated execution reverted | Decode `error.data` and fix the call conditions |

See also [Error reference](../errors.md).

## Example

```bash
curl -sS https://mainnet.megaeth.com/rpc \
  -H 'content-type: application/json' \
  --data '{"jsonrpc":"2.0","id":57,"method":"eth_estimateGas","params":[{"to":"0x0000000000000000000000000000000000000000","value":"0x0"},"latest"]}'
```

```jsonc
{"jsonrpc":"2.0","id":57,"result":"0xea60"}  // 60,000 gas
```
