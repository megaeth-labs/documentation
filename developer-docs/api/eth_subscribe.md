# eth_subscribe

Opens a real-time event stream over WebSocket.

## Parameters

**`subscriptionType`** string **REQUIRED**

One of the types listed below.

**Subscription types:**

| Type | Filter | Notes |
|---|---|---|
| `newHeads` | — | Block headers as blocks are sealed |
| `logs` | `object` | Log entries matching address/topic criteria |
| `newPendingTransactions` | `boolean` | `false` (default): transaction hashes only; `true`: full transaction objects |
| `syncing` | — | Sync status changes |
| `miniBlocks` | — | Sub-block updates at ~10 ms granularity |
| `stateChanges` | `Address[]` | Per-mini-block account/storage diffs. Default: all accounts |

---

**`filter`** varies

Shape depends on `subscriptionType`.

When `subscriptionType` is `logs`, the filter object contains:

- **`fromBlock`** string

  Hex block number or tag.

- **`toBlock`** string

  Hex block number or tag.

- **`blockHash`** Hash32

  Single-block mode; mutually exclusive with `fromBlock`/`toBlock`.

- **`address`** Address | Address[]

  Filter by emitting address(es).

- **`topics`** array

  Positional topic filter; positions are AND, values within a position are OR.

## Returns

`Data` — subscription ID.

Events are delivered as `eth_subscription` notifications:

```json
{
  "jsonrpc": "2.0",
  "method": "eth_subscription",
  "params": {
    "subscription": "<subscriptionId>",
    "result": { }
  }
}
```

The shape of `result` depends on the subscription type.

### `newHeads`

- **`number`** Quantity

  Block number.

- **`hash`** Hash32

  Block hash.

- **`parentHash`** Hash32

  Parent block hash.

- **`timestamp`** Quantity

  Block timestamp.

- **`miner`** Address

  Fee recipient.

- **`gasLimit`** Quantity

  Block gas limit.

- **`gasUsed`** Quantity

  Gas consumed.

- **`baseFeePerGas`** Quantity

  Base fee.

- **`stateRoot`** Hash32

  State trie root.

- **`miniBlockCount`** Quantity

  Mini-block count for this block.

- **`miniBlockOffset`** Quantity

  Mini-block offset.

Additional standard header fields (`logsBloom`, `transactionsRoot`, `receiptsRoot`, …) are also included.

### `logs`

- **`address`** Address

  Emitting contract.

- **`topics`** Hash32[]

  Indexed topics.

- **`data`** Data

  Unindexed payload.

- **`blockNumber`** Quantity | null

  Containing block number.

- **`transactionHash`** Hash32 | null

  Containing transaction hash.

- **`transactionIndex`** Quantity | null

  Transaction position in block.

- **`logIndex`** Quantity | null

  Log position in block.

- **`removed`** boolean

  `true` if removed during reorg.

- **`blockTimestamp`** Quantity

  Block timestamp.

### `newPendingTransactions`

`Hash32` by default. When `true` is passed as the filter, each event is a full transaction object:

- **`hash`** Hash32

  Transaction hash.

- **`type`** Quantity

  Transaction type identifier.

- **`from`** Address

  Sender.

- **`to`** Address | null

  Recipient; `null` for contract creation.

- **`value`** Quantity

  Transfer value in wei.

- **`nonce`** Quantity

  Sender nonce.

- **`gas`** Quantity

  Gas limit.

- **`input`** Data

  Calldata.

- **`blockHash`** Hash32 | null

  `null` for pending transactions.

- **`blockNumber`** Quantity | null

  `null` for pending transactions.

- **`transactionIndex`** Quantity | null

  `null` for pending transactions.

Additional fields vary by transaction type (`gasPrice`, `maxFeePerGas`, `accessList`, `chainId`, `v`, `r`, `s`, etc.).

### `syncing`

`false` when not syncing. When syncing, a `SyncProgress` object:

- **`startingBlock`** Quantity

  Sync start point.

- **`currentBlock`** Quantity

  Current progress.

- **`highestBlock`** Quantity

  Target block.

### `miniBlocks`

Uses `snake_case` field names.

- **`block_number`** Quantity

  Parent full-block number.

- **`block_timestamp`** Quantity

  Parent full-block timestamp.

- **`index`** Quantity

  Mini-block index within the full block.

- **`mini_block_number`** Quantity

  Global mini-block number.

- **`mini_block_timestamp`** Quantity

  Mini-block timestamp (sub-millisecond).

- **`gas_used`** Quantity

  Gas consumed.

- **`transactions`** Data[]

  Raw transaction bytes.

- **`receipts`** object[]

  Mini-block receipts.

### `stateChanges`

- **`address`** Address

  Changed account.

- **`nonce`** Quantity

  Current nonce.

- **`balance`** Quantity

  Current balance.

- **`storage`** object

  Changed storage slots as `{ key: value }` pairs.

## Errors

| Code | Cause | Fix |
|---|---|---|
| `-32602` | Unknown subscription type or invalid `logs` filter | Correct the subscription type or filter |
| `-32600` | Duplicate subscription of the same type on this connection | Call `eth_unsubscribe` first, then resubscribe |
| `-32005` | Per-connection subscription limit (5) or server capacity reached | Unsubscribe from unused subscriptions |

See also [Error reference](../errors.md).

## Example

**newHeads**

```bash
wscat -c wss://mainnet.megaeth.com/ws
> {"jsonrpc":"2.0","id":1,"method":"eth_subscribe","params":["newHeads"]}
```

```json
{"jsonrpc":"2.0","id":1,"result":"0xaec58cfc2dc41f873fc37d6c871230c1"}
```

Pushed event:

```jsonc
{
  "jsonrpc": "2.0",
  "method": "eth_subscription",
  "params": {
    "subscription": "0xaec58cfc2dc41f873fc37d6c871230c1",
    "result": {
      "number": "0xb80319",
      "hash": "0x1318d1123d8ea6a86c8f7b231bc844c747d494cd338848108ea78cbf3361d7bd",
      "parentHash": "0x4d763feda26e3dcd6b249e16e1b348772b8b069e12bff7af16ba11862306db72",
      "miner": "0x4200000000000000000000000000000000000011",
      "timestamp": "0x69ca28ec",
      "gasLimit": "0x2540be400",
      "gasUsed": "0x66b213",
      "baseFeePerGas": "0xf4240",           // 1,000,000 wei
      "stateRoot": "0x3af0ce356d69e532bb42b711626ee718301a422d06e8ffb562e18d49420c7001",
      "miniBlockCount": "0x64",              // 100 mini-blocks in this block
      "miniBlockOffset": "0x456f4f30"
    }
  }
}
```

**miniBlocks**

```bash
wscat -c wss://mainnet.megaeth.com/ws
> {"jsonrpc":"2.0","id":1,"method":"eth_subscribe","params":["miniBlocks"]}
```

```json
{"jsonrpc":"2.0","id":1,"result":"0x356680421a092c5664549df8c6c8cb80"}
```

Pushed event:

```jsonc
{
  "jsonrpc": "2.0",
  "method": "eth_subscription",
  "params": {
    "subscription": "0x356680421a092c5664549df8c6c8cb80",
    "result": {
      "block_number": "0xb80336",
      "block_timestamp": "0x69ca2909",
      "index": "0xb",                       // 11th mini-block within the full block
      "mini_block_number": "0x456f5a6b",
      "mini_block_timestamp": "0x64e38f8980f50",
      "gas_used": "0x0",                    // empty mini-block
      "transactions": [],
      "receipts": []
    }
  }
}
```

**stateChanges**

```bash
wscat -c wss://mainnet.megaeth.com/ws
> {"jsonrpc":"2.0","id":1,"method":"eth_subscribe","params":["stateChanges",["0xaa000000000000000000000000000000000000aa"]]}
```

```json
{"jsonrpc":"2.0","id":1,"result":"0x9ce59a13059e417087c02d3236a0b1cc"}
```

Pushed event:

```jsonc
{
  "jsonrpc": "2.0",
  "method": "eth_subscription",
  "params": {
    "subscription": "0x9ce59a13059e417087c02d3236a0b1cc",
    "result": {
      "address": "0xaa000000000000000000000000000000000000aa",
      "nonce": "0x5",                       // 5
      "balance": "0xde0b6b3a7640000",       // 1 ETH
      "storage": {}
    }
  }
}
```
