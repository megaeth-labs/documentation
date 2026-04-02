# eth_call

Simulates a transaction against a given block's state and returns the result without creating an on-chain transaction.

## Parameters

**`transaction`** object **REQUIRED**

Transaction to simulate.

- **`from`** Address

  Caller; set explicitly when `msg.sender` matters.

- **`to`** Address

  Target; `null` for contract-creation simulation.

- **`value`** Quantity

  Wei value sent.

- **`input`** Data

  Calldata; `data` is also accepted but `input` is preferred. If both are present they must be identical.

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

---

**`stateOverride`** object

Per-address state overrides for this simulation.

Object keyed by address. Each value:

- **`balance`** Quantity

  Override the account balance.

- **`nonce`** Quantity

  Override the account nonce.

- **`code`** Data

  Override the account bytecode.

- **`state`** object

  Replace full storage (slot → value); mutually exclusive with `stateDiff`.

- **`stateDiff`** object

  Patch individual storage slots; mutually exclusive with `state`.

- **`movePrecompileToAddress`** Address

  Move a precompile to the specified address before `code` is applied.

---

**`blockOverrides`** object

Block environment overrides for this simulation.

- **`number`** Quantity

  Override `block.number`.

- **`time`** Quantity

  Override `block.timestamp`.

- **`gasLimit`** Quantity

  Override `block.gasLimit`.

- **`feeRecipient`** Address

  Override `block.coinbase`.

- **`prevRandao`** Quantity

  Override randomness.

- **`baseFeePerGas`** Quantity

  Override `block.baseFee`.

- **`blobBaseFee`** Quantity

  Override blob base fee.

## Returns

**`result`** Data

Raw return bytes. `0x` for calls to non-contract addresses. Reverts surface as JSON-RPC errors, not as a normal result.

## Errors

| Code | Cause | Fix |
|---|---|---|
| `-32602` | Malformed call object, block selector, or override object | Fix the request |
| `3` | Simulated execution reverted | Decode `error.data` and fix call conditions |
| `-32000` | Simulation failed or hit an execution limit | Inspect `error.message`; adjust gas or call shape |

See also [Error reference](../errors.md).

## Example

```bash
curl -sS https://mainnet.megaeth.com/rpc \
  -H 'content-type: application/json' \
  --data '{"jsonrpc":"2.0","id":46,"method":"eth_call","params":[{"to":"0x0000000000000000000000000000000000000004","input":"0x11223344"},"latest"]}'
```

```json
{"jsonrpc":"2.0","id":46,"result":"0x11223344"}
```
