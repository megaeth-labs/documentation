---
description: "eth_getBlockReceipts JSON-RPC reference for MegaETH."
---

# eth_getBlockReceipts

## Summary

Returns all transaction receipts for a block.

The public MegaETH endpoint supports this method. The standard, node, and gateway layers below identify behavior that differs from a generic Ethereum endpoint.

## Parameters

**`block`** string | object **REQUIRED**

Block number, tag (`earliest`, `latest`, `safe`, `finalized`, `pending`), block hash, or `{"blockHash":"0x…"}` selector object.

## Result

`Receipt[] | null` — receipts for every transaction in the block.
The method returns `null` when the block is not found.
It returns `[]` when the block exists but contains no transactions.

Each array element contains:

- **`transactionHash`** Hash32

  Transaction hash.

- **`status`** Quantity

  A nonzero status indicates success; zero indicates that execution reverted.

- **`blockHash`** Hash32

  Containing block hash.

- **`blockNumber`** Quantity

  Containing block number.

- **`from`** Address

  Sender.

- **`to`** Address | null

  Recipient; `null` for contract creation.

- **`gasUsed`** Quantity

  Gas consumed by this transaction.

- **`effectiveGasPrice`** Quantity

  Effective gas price.

- **`contractAddress`** Address | null

  Created contract address when applicable.

- **`logs`** Log[]

  Emitted log entries.

Additional fields include `cumulativeGasUsed`, `logsBloom`, `type`, and L1 fee fields (`l1Fee`, `l1GasPrice`, `l1GasUsed`, etc.).

## MegaETH Behavior

### Ethereum Standard

The canonical Ethereum method uses the parameter and result contract documented above, including the stated `null`, `false`, or zero-value semantics where applicable.

### MegaETH Node Behavior

The node returns all receipts for the selected block. The response can be large because MegaETH blocks can contain many transactions.

### MegaETH Public Gateway

The gateway returns `null` immediately for `pending`, streams large responses, and caches successful results for up to 30 minutes. The method is in the IO-heavy read tier.

## Errors

The `| Scope |` column distinguishes method failures from gateway policy errors.

| Code     | Scope            | Message                    | When it happens                                               |
| -------- | ---------------- | -------------------------- | ------------------------------------------------------------- |
| `-32602` | Request          | Invalid params             | Malformed or unsupported block selector                       |
| `4444`   | Method           | Pruned history unavailable | Historical block data unavailable on this endpoint            |
| `-32005` | Transport/policy | Rate limit exceeded        | The caller exceeds the public gateway's IO-heavy read budget. |
| `-32099` | Transport/policy | Payload too large          | The request body exceeds the 128 KiB public endpoint limit.   |

See also [Error Codes](./error-codes.md).

## Examples

Endpoint: `https://mainnet.megaeth.com/rpc`

Capture date: July 24, 2026

Outcome: success

```json
{
  "jsonrpc": "2.0",
  "id": 16,
  "method": "eth_getBlockReceipts",
  "params": [
    {
      "blockHash": "0x57804c21b747137075b29ce153b4f559345a3624273660c87e81bd57e7cbbc3d"
    }
  ]
}
```

```json
{
  "jsonrpc": "2.0",
  "id": 16,
  "result": [
    {
      "type": "0x7e",
      "status": "0x1",
      "cumulativeGasUsed": "0xb9d56c",
      "logs": [],
      "depositNonce": "0x0",
      "depositReceiptVersion": "0x1",
      "transactionHash": "0xecc262f36652019b75f4cb7315ff19f430fc92efd5a8048948400407d55fd904",
      "transactionIndex": "0x0",
      "blockHash": "0x57804c21b747137075b29ce153b4f559345a3624273660c87e81bd57e7cbbc3d",
      "blockNumber": "0x1",
      "gasUsed": "0xb9d56c",
      "effectiveGasPrice": "0x0",
      "from": "0xdeaddeaddeaddeaddeaddeaddeaddeaddead0001",
      "to": "0x4200000000000000000000000000000000000015",
      "contractAddress": null,
      "l1GasPrice": "0x22ba611d",
      "l1GasUsed": "0x6e7",
      "l1Fee": "0x0",
      "l1BaseFeeScalar": "0x558",
      "l1BlobBaseFee": "0x7",
      "l1BlobBaseFeeScalar": "0xc5fc5"
    }
  ]
}
```

## Sources

- Spec: `git@github.com:ethereum/execution-apis.git @ d24f58b56dcd16ab0f0c70ec609bcc1c42750b51: src/eth/block.yaml`
- Code: `git@github.com:megaeth-labs/mega-reth.git @ ab60376631228edab3a6df180f295280bad26e93: crates/rpc/rpc-eth-api/src/core.rs`
- Code: `git@github.com:megaeth-labs/mega-rpc.git @ 06aa35aa95d569c227cc25d2aa12834eb0458aa0: workers/src/processors/simple-cache-processor.ts`
- Probe: MegaETH Mainnet public endpoint, July 24, 2026
