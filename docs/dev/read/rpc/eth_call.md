---
description: "eth_call JSON-RPC reference for MegaETH."
---

# eth_call

## Summary

Simulates a transaction against a given block's state and returns the result without creating an on-chain transaction.

The public MegaETH endpoint supports this method. The standard, node, and gateway layers below identify behavior that differs from a generic Ethereum endpoint.

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

  Calldata; `data` is also accepted but `input` is preferred.
  If both are present they must be identical.

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

Hex block number or tag (`latest`, `safe`, `finalized`, `earliest`, `pending`).
The default is `"latest"`.

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

## Result

**`result`** Data

Raw return bytes.
Calls to non-contract addresses return `0x`.
Reverts surface as JSON-RPC errors, not as a normal result.

## Comparison with Ethereum Standard JSON-RPC

### Ethereum Standard

The canonical Ethereum method uses the parameter and result contract documented above, including the stated `null`, `false`, or zero-value semantics where applicable.

### MegaETH Node Behavior

The node simulates the call against the selected state without persisting changes. MegaETH's execution model applies its multidimensional execution limits in addition to the gas field.

### MegaETH Public Gateway

The gateway routes the request to the compute pool, rewrites it to `mega_callWithBlock`, buffers the rewritten response, and does not cache it.
It preserves the caller's `gas` field and separately supplies an internal compute-gas limit of 60,000,000; the internal limit caps compute gas without replacing the total gas budget.
The public endpoint permits a 1.5 MiB single-request body.

## Errors

The `| Scope |` column distinguishes method failures from gateway policy errors.

| Code     | Scope            | Message             | When it happens                                              |
| -------- | ---------------- | ------------------- | ------------------------------------------------------------ |
| `-32602` | Request          | Invalid params      | Malformed call object, block selector, or override object    |
| `3`      | Method           | Execution reverted  | Simulated execution reverted                                 |
| `-32000` | Method           | Server error        | Simulation failed or hit an execution limit                  |
| `-32005` | Transport/policy | Rate limit exceeded | The caller exceeds the public gateway's compute read budget. |
| `-32099` | Transport/policy | Payload too large   | The request body exceeds the 1.5 MiB public endpoint limit.  |

See also [Error Codes](./error-codes.md).

## Examples

Endpoint: `https://mainnet.megaeth.com/rpc`

Capture date: July 24, 2026

Outcome: success

```json
{
  "jsonrpc": "2.0",
  "id": 46,
  "method": "eth_call",
  "params": [
    {
      "to": "0x0000000000000000000000000000000000000004",
      "input": "0x11223344"
    },
    "latest"
  ]
}
```

```json
{
  "jsonrpc": "2.0",
  "id": 46,
  "result": "0x11223344"
}
```

## Sources

- Spec: `git@github.com:ethereum/execution-apis.git @ d24f58b56dcd16ab0f0c70ec609bcc1c42750b51: src/eth/execute.yaml`
- Code: `git@github.com:megaeth-labs/mega-reth.git @ ab60376631228edab3a6df180f295280bad26e93: crates/megaeth/rpc/src/eth/api.rs`
- Code: `git@github.com:megaeth-labs/mega-rpc.git @ 06aa35aa95d569c227cc25d2aa12834eb0458aa0: workers/src/processors/mega-call-with-block-processor.ts`
- Probe: MegaETH Mainnet public endpoint, July 24, 2026
