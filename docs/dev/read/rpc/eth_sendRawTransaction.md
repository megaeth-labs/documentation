---
description: "eth_sendRawTransaction JSON-RPC reference for MegaETH."
---

# eth_sendRawTransaction

## Summary

Submits a signed transaction to the network and returns its transaction hash.

The public MegaETH endpoint supports this method. The standard, node, and gateway layers below identify behavior that differs from a generic Ethereum endpoint.

## Parameters

**`rawTx`** Data **REQUIRED**

Signed, RLP-encoded transaction bytes.
Supported envelope types are legacy, EIP-2930, EIP-1559, EIP-4844, and EIP-7702.

## Result

**`result`** Data

32-byte transaction hash.

## MegaETH Behavior

### Ethereum Standard

The canonical Ethereum method uses the parameter and result contract documented above, including the stated `null`, `false`, or zero-value semantics where applicable.

### MegaETH Node Behavior

The node decodes and validates the signed transaction before admitting it to the transaction pool. Successful submission returns the transaction hash, not an inclusion receipt.

### MegaETH Public Gateway

The gateway validates chain ID, signature, intrinsic gas, fee floor, nonce, balance, and policy checks before forwarding. The method is exempt from read-rate limits and accepts request bodies up to 2.5 MiB.

## Errors

The `| Scope |` column distinguishes method failures from gateway policy errors.

| Code     | Scope            | Message              | When it happens                                                                      |
| -------- | ---------------- | -------------------- | ------------------------------------------------------------------------------------ |
| `-32602` | Request          | Invalid params       | Parameter missing, hex malformed, or bytes cannot be decoded as a signed transaction |
| `-32000` | Method           | Server error         | Pool or gateway rule violation                                                       |
| `-32003` | Method           | Transaction rejected | Insufficient sender funds, pool at capacity, or unsupported transaction type         |
| `-32099` | Transport/policy | Payload too large    | The request body exceeds the 2.5 MiB public endpoint limit.                          |

See also [Error Codes](./error-codes.md).

## Examples

Endpoint: `https://mainnet.megaeth.com/rpc`

Capture date: July 24, 2026

Outcome: success

```json
{
  "jsonrpc": "2.0",
  "id": 1,
  "method": "eth_sendRawTransaction",
  "params": [
    "0xf86c808405763d658261a894aa000000000000000000000000000000000000000a8255448718e5bb3abd109fa0c8e3b4a0087357bd49d80a0ac24daf0c91191e71086c1e355fc62cfab2218873a074f4636f740fa4d1697b6e736e5982b700be2c8b63031a24fa531ae4814b3af8"
  ]
}
```

```json
{
  "jsonrpc": "2.0",
  "id": 1,
  "result": "0x66734e85ef096167acb887cf445946a1ed57b90b66ffe38af87e11294febbfa9"
}
```

## Sources

- Spec: `git@github.com:ethereum/execution-apis.git @ d24f58b56dcd16ab0f0c70ec609bcc1c42750b51: src/eth/submit.yaml`
- Code: `git@github.com:megaeth-labs/mega-reth.git @ ab60376631228edab3a6df180f295280bad26e93: crates/megaeth/rpc/src/eth/api.rs`
- Code: `git@github.com:megaeth-labs/mega-rpc.git @ 06aa35aa95d569c227cc25d2aa12834eb0458aa0: workers/src/sequencer-guard/single-tx.ts`
- Probe: MegaETH Mainnet public endpoint, July 24, 2026
