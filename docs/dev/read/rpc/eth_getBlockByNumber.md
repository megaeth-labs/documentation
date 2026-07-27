---
description: "eth_getBlockByNumber JSON-RPC reference for MegaETH."
---

# eth_getBlockByNumber

## Summary

Returns a block by number or tag.

The public MegaETH endpoint supports this method. The standard, node, and gateway layers below identify behavior that differs from a generic Ethereum endpoint.

## Parameters

**`block`** string **REQUIRED**

Hex block number or tag: `latest`, `safe`, `finalized`, `earliest`, `pending`.

---

**`fullTransactions`** boolean **REQUIRED**

`false` returns transaction hashes; `true` returns full transaction objects.

## Result

`Block | null` — `null` when the requested block does not exist or is not yet available.

- **`number`** Quantity

  Block number.

- **`hash`** Hash32

  Block hash.

- **`parentHash`** Hash32

  Parent block hash.

- **`timestamp`** Quantity

  Block timestamp.

- **`miner`** Address

  Fee recipient / coinbase.

- **`gasLimit`** Quantity

  Block gas limit.

- **`gasUsed`** Quantity

  Gas consumed by the block.

- **`transactions`** Hash32[] | Transaction[]

  Hashes when `fullTransactions = false`; full objects when `true`.

Additional standard fields (`stateRoot`, `logsBloom`, `transactionsRoot`, `receiptsRoot`, `baseFeePerGas`, …) are also included.

## Comparison with Ethereum Standard JSON-RPC

### Ethereum Standard

The canonical Ethereum method uses the parameter and result contract documented above, including the stated `null`, `false`, or zero-value semantics where applicable.

### MegaETH Node Behavior

The node resolves a block number or tag and honors the `fullTransactions` response-shape flag. A missing block is represented by `null`.

### MegaETH Public Gateway

The gateway returns `null` immediately for `pending`. Other responses are streamed and cached; head-following tags use short-lived entries while fixed blocks are treated as immutable.

## Errors

The `| Scope |` column distinguishes method failures from gateway policy errors.

| Code     | Scope            | Message                    | When it happens                                                 |
| -------- | ---------------- | -------------------------- | --------------------------------------------------------------- |
| `-32602` | Request          | Invalid params             | Malformed block selector or `fullTransactions` is not a boolean |
| `4444`   | Method           | Pruned history unavailable | Requested historical block is not available on this endpoint    |
| `-32005` | Transport/policy | Rate limit exceeded        | The caller exceeds the public gateway's simple read budget.     |
| `-32099` | Transport/policy | Payload too large          | The request body exceeds the 128 KiB public endpoint limit.     |

See also [Error Codes](./error-codes.md).

## Examples

Endpoint: `https://mainnet.megaeth.com/rpc`

Capture date: July 24, 2026

Outcome: success

```json
{
  "jsonrpc": "2.0",
  "id": 81,
  "method": "eth_getBlockByNumber",
  "params": ["0x100000", false]
}
```

```json
{
  "jsonrpc": "2.0",
  "id": 81,
  "result": {
    "hash": "0xe0b5b2b8222c00dcbe9f359fc917a9190127bd1b958e11b6caa2035dd03952f1",
    "number": "0x100000",
    "timestamp": "0x692225d3",
    "transactions": [
      "0x243d39c7f6cd74a9a081a6fe4bdfce37ac6136b9454691aeeb9ed77998450cbc"
    ]
  }
}
```

Pending-block edge case:

Endpoint: `https://mainnet.megaeth.com/rpc`

Capture date: July 27, 2026

Outcome: null

```json
{
  "jsonrpc": "2.0",
  "id": 82,
  "method": "eth_getBlockByNumber",
  "params": ["pending", false]
}
```

```json
{
  "jsonrpc": "2.0",
  "id": 82,
  "result": null
}
```

## Sources

- Spec: `git@github.com:ethereum/execution-apis.git @ d24f58b56dcd16ab0f0c70ec609bcc1c42750b51: src/eth/block.yaml`
- Code: `git@github.com:megaeth-labs/mega-reth.git @ ab60376631228edab3a6df180f295280bad26e93: crates/rpc/rpc-eth-api/src/core.rs`
- Code: `git@github.com:megaeth-labs/mega-rpc.git @ 06aa35aa95d569c227cc25d2aa12834eb0458aa0: workers/src/processors/simple-cache-processor.ts`
- Probe: MegaETH Mainnet public endpoint, July 24 and July 27, 2026
