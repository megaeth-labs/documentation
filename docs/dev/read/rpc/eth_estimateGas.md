---
description: "eth_estimateGas JSON-RPC reference for MegaETH."
---

# eth_estimateGas

## Summary

Estimates the gas required to execute a transaction.

The public MegaETH endpoint supports this method. The standard, node, and gateway layers below identify behavior that differs from a generic Ethereum endpoint.

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

## Result

**`result`** Quantity

Estimated execution gas.

## MegaETH Behavior

### Ethereum Standard

The canonical Ethereum method uses the parameter and result contract documented above, including the stated `null`, `false`, or zero-value semantics where applicable.

### MegaETH Node Behavior

MegaETH's estimator uses a 60,000-gas intrinsic floor for a basic transfer and supports state overrides. The node also exposes a CPU-limited variant used by the public gateway.

### MegaETH Public Gateway

The gateway routes the request to the compute pool and rewrites it to the node's `eth_estimateGasWithCpuLimit` method.
It does not cache the result and supplies an internal CPU-time limit whose source default is 500,000,000 nanoseconds (0.5 seconds).
This is distinct from `eth_call`'s 60,000,000 compute-gas limit.
The public endpoint permits a 1.5 MiB single-request body.

## Errors

The `| Scope |` column distinguishes method failures from gateway policy errors.

| Code     | Scope            | Message             | When it happens                                                                             |
| -------- | ---------------- | ------------------- | ------------------------------------------------------------------------------------------- |
| `-32602` | Request          | Invalid params      | Malformed transaction fields, fee model, or block selector                                  |
| `-32000` | Method           | Server error        | Estimation failed, hit a provider-side execution limit, or used a rejected explicit gas cap |
| `3`      | Method           | Execution reverted  | Simulated execution reverted                                                                |
| `-32005` | Transport/policy | Rate limit exceeded | The caller exceeds the public gateway's compute read budget.                                |
| `-32099` | Transport/policy | Payload too large   | The request body exceeds the 1.5 MiB public endpoint limit.                                 |

See also [Error Codes](./error-codes.md).

## Examples

Endpoint: `https://mainnet.megaeth.com/rpc`

Capture date: July 24, 2026

Outcome: success

```json
{
  "jsonrpc": "2.0",
  "id": 57,
  "method": "eth_estimateGas",
  "params": [
    {
      "to": "0x0000000000000000000000000000000000000000",
      "value": "0x0"
    },
    "latest"
  ]
}
```

```json
{
  "jsonrpc": "2.0",
  "id": 57,
  "result": "0xea60"
}
```

## Sources

- Spec: `git@github.com:ethereum/execution-apis.git @ d24f58b56dcd16ab0f0c70ec609bcc1c42750b51: src/eth/execute.yaml`
- Code: `git@github.com:megaeth-labs/mega-reth.git @ ab60376631228edab3a6df180f295280bad26e93: crates/megaeth/rpc/src/eth/replace.rs`
- Code: `git@github.com:megaeth-labs/mega-rpc.git @ 06aa35aa95d569c227cc25d2aa12834eb0458aa0: workers/src/spec/methods.ts`
- Probe: MegaETH Mainnet public endpoint, July 24, 2026
