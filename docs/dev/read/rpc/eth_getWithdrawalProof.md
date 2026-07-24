---
description: "Returns a withdrawal-storage proof for MegaETH's L2-to-L1 message passer contract."
---

# eth_getWithdrawalProof

Returns the same proof as [`mega_getWithdrawalProof`](./mega_getWithdrawalProof.md).
The gateway routes both method names to the same node implementation.

## Parameters

| Position | Name          | Type                | Required | Description                                                        |
| -------- | ------------- | ------------------- | -------- | ------------------------------------------------------------------ |
| `0`      | `address`     | `Address`           | Yes      | Must be `0x4200000000000000000000000000000000000016`.              |
| `1`      | `storageKeys` | `Bytes32[]`         | Yes      | Withdrawal-message storage keys to prove; an empty array is valid. |
| `2`      | `block`       | block number or tag | Yes      | State against which to build the proof.                            |

## Returns

An EIP-1186-style account proof containing `accountProof`, `balance`, `codeHash`, `nonce`, `storageHash`, and one `storageProof` entry per requested key.

## Errors

The parameters, errors, and response fields are identical to [`mega_getWithdrawalProof`](./mega_getWithdrawalProof.md#errors).

## Example

```json
{
  "jsonrpc": "2.0",
  "id": 1,
  "method": "eth_getWithdrawalProof",
  "params": ["0x4200000000000000000000000000000000000016", [], "latest"]
}
```
