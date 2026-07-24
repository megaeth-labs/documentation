---
description: "mega_getBlockWitness JSON-RPC reference for MegaETH."
---

# mega_getBlockWitness

Returns the execution witness for a block.

## Parameters

**`keys`** object **REQUIRED**

Block lookup key.

- **`blockNumber`** Quantity **REQUIRED**

  Target block number.

- **`blockHash`** Hash32

  Block hash for the same block number.
  Always include it when available so the lookup is pinned to a specific fork.

{% hint style="warning" %}
A `blockNumber`-only lookup returns the first stored witness at that height and is not reorg-safe.
Use `blockNumber` together with `blockHash` for production verification.
{% endhint %}

## Returns

**`result`** string

`v0:` followed by a base64-encoded zstd-compressed witness blob.

## Errors

| Code     | Cause                                                                       | Fix                                                                       |
| -------- | --------------------------------------------------------------------------- | ------------------------------------------------------------------------- |
| `-32602` | `blockNumber` missing, invalid hex value, or invalid hash field combination | Fix the request                                                           |
| `-32603` | No witness exists for the requested keys, or the witness service failed     | Inspect the message; `Witness not found` is an expected availability miss |

See also [Error reference](error-codes.md).

## Example

```bash
curl -sS https://mainnet.megaeth.com/rpc \
  -H 'content-type: application/json' \
  --data '{"jsonrpc":"2.0","id":1,"method":"mega_getBlockWitness","params":[{"blockNumber":"0x7fd","blockHash":"0x262206173864c1e597ab9fcf2f718f95f942907207f4fed97dda66d272c5d4a6"}]}'
```

```jsonc
{ "jsonrpc": "2.0", "id": 1, "result": "v0:KLUv/QBgzVUAZJwh…" } // base64-encoded zstd blob, truncated
```

For decoding details and network coverage, see [Get block witness](../../../node/witness.md).
