# Type Reference

This page defines the shared wire encodings, selectors, and reusable object shapes used across the MegaETH RPC docs.

Use this page when you need to:

- validate one field exactly
- decode a shared type name used by a method page
- understand a reusable request or response object

Method pages remain the source of truth for parameter order, defaults, MegaETH-specific runtime behavior, and method-specific errors.

Unless a field is explicitly typed as `number`, numeric-looking Ethereum RPC values are encoded as `Quantity` strings.

## At A Glance

| If you need to validate... | Shared type | What it means |
|---|---|---|
| balance, gas, nonce, block number | `Quantity` | Hex-encoded unsigned integer in minimal form |
| calldata, bytecode, raw bytes | `Data` | `0x`-prefixed even-length hex bytes |
| account or contract address | `Address` | 20-byte `Data` value |
| tx hash, block hash, code hash | `Hash32` | 32-byte `Data` value |
| block tag or block number | `BlockNumberOrTag` | `latest`, `safe`, `0x1234`, and similar selectors |
| block-hash selector object | `BlockHashSelector` | EIP-1898-style object with `blockHash` |
| transaction-like request object | `TransactionCall` | Shared object used by simulation-style methods |
| log filter object | `LogFilter` | Shared object used by `eth_getLogs` |
| common block, tx, receipt, and log responses | `Block`, `Transaction`, `Receipt`, `Log` | Shared response object families |

## Core Wire Types

### `Quantity`

- JSON type: `string`
- Pattern: `^0x(?:0|[1-9a-fA-F][0-9a-fA-F]*)$`
- Meaning: non-negative integer encoded in hexadecimal with no leading zeroes except `0x0`

Valid examples:

- `0x0`
- `0x1`
- `0x2a`

Invalid examples:

- `0`
- `42`
- `0x00`
- `0x0001`

Reader rules:

- Decimal strings are not valid `Quantity` values.
- `0x0` is the only valid zero encoding.
- Most balances, gas values, nonces, indexes, and block numbers use `Quantity`.

### `Data`

- JSON type: `string`
- Pattern: `^0x(?:[0-9a-fA-F]{2})*$`
- Meaning: arbitrary byte string encoded as hex pairs after `0x`

Valid examples:

- `0x`
- `0x12`
- `0xdeadbeef`

Invalid examples:

- `deadbeef`
- `0x1`
- `0x123`

Reader rules:

- `Data` can be empty; `0x` is valid.
- Hex length after `0x` must be even.
- Method pages narrow `Data` further when they need fixed sizes such as addresses, hashes, or bloom filters.

### `Address`

- JSON type: `string`
- Pattern: `^0x[0-9a-fA-F]{40}$`
- Meaning: 20-byte account or contract address
- Alias of: `Data` with fixed length 20 bytes

Reader rules:

- Wire format is case-insensitive.
- EIP-55 checksum casing is useful for humans but not required unless a method page says otherwise.

### `Hash32`

- JSON type: `string`
- Pattern: `^0x[0-9a-fA-F]{64}$`
- Meaning: 32-byte hash value
- Alias of: `Data` with fixed length 32 bytes

Reader rules:

- Use `Hash32` when the value is semantically a hash such as a block hash, transaction hash, or state root.

### `Bytes32`

- JSON type: `string`
- Pattern: `^0x[0-9a-fA-F]{64}$`
- Meaning: 32-byte fixed-width byte string
- Alias of: `Data` with fixed length 32 bytes

Reader rules:

- Use `Bytes32` when the value is fixed-width bytes but not specifically a hash.

### `Data[N]`

- JSON type: `string`
- Meaning: fixed-width byte string with exactly `N` bytes
- Alias of: `Data` with exact length constraint

Common examples:

- `Address` is `Data[20]`
- `Hash32` and `Bytes32` are `Data[32]`
- `BlockNonce` is `Data[8]`
- `LogsBloom` is `Data[256]`

### Primitive JSON Types

These are plain JSON primitives used only when a method does not narrow the value to a stronger Ethereum-specific alias.

| Type | JSON type | Use when |
|---|---|---|
| `boolean` | `boolean` | The contract returns or accepts `true` or `false` directly |
| `number` | `number` | A MegaETH or output-style object explicitly uses JSON numbers instead of Ethereum `Quantity` strings |

## Semantic Aliases And Opaque IDs

Aliases do not change wire encoding. They only give a narrower meaning to a value that is already encoded as `Hash32`, `Data`, `Quantity`, or `string`.

### `Hash32`-Derived Aliases

| Alias | Same wire format as | Meaning |
|---|---|---|
| `TransactionHash` | `Hash32` | Transaction identifier |
| `BlockHash` | `Hash32` | Block or header identifier |
| `CodeHash` | `Hash32` | Code identifier used by code-by-hash methods |
| `StateRoot` | `Hash32` | World-state trie root |
| `StorageRoot` | `Hash32` | Storage trie root |
| `TransactionsRoot` | `Hash32` | Transactions trie root |
| `ReceiptsRoot` | `Hash32` | Receipts trie root |
| `WithdrawalsRoot` | `Hash32` | Withdrawals trie root |
| `BeaconBlockRoot` | `Hash32` | Beacon-chain block root reference |
| `OutputRoot` | `Hash32` | Output commitment returned by output-style methods |
| `OutputVersion` | `Hash32` | Output version identifier |
| `AttributesHash` | `Hash32` | Optimism-style attributes hash when a method exposes it explicitly |
| `RequestsHash` | `Hash32` | EIP-7685 requests commitment |
| `UnclesHash` | `Hash32` | Uncle or ommer-list commitment |
| `MixHash` | `Hash32` | Legacy PoW mix-hash or post-Merge randomness field |

### `TransactionHash`

`Hash32` — transaction identifier used by lookup and receipt methods.

### `BlockHash`

`Hash32` — block identifier used by block and header lookup methods.

### `CodeHash`

`Hash32` — code identifier used by `eth_getCodeByHash`.

### `Data`-Derived Aliases

| Alias | Same wire format as | Meaning |
|---|---|---|
| `LogsBloom` | `Data[256]` | 256-byte log bloom filter |
| `BlockNonce` | `Data[8]` | 8-byte block-header nonce field |
| `ExtraData` | `Data` | Header extra-data bytes |
| `ProofNode` | `Data` | Encoded trie or Merkle proof node |

### `StorageSlotIndex`

- JSON type: `string`
- Wire format: `Quantity`
- Meaning: storage slot index used by legacy storage access methods such as `eth_getStorageAt`

### `StorageKey32`

- JSON type: `string`
- Wire format: `Bytes32`
- Meaning: fixed-width storage key used by override maps and proof-style objects

### `FilterId`

- JSON type: `string`
- Meaning: opaque string token returned by filter lifecycle methods such as `eth_newFilter`

Reader rules:

- Treat filter IDs as opaque.
- Do not assume numeric meaning, stable formatting, or portability across servers.
- Filter lifetime and validity are method- and server-dependent.

## Block Selectors

Selectors identify a block or block context, not just a wire format.

Many methods support only string selectors. Some methods also support hash-based selector forms. Always check the method page before assuming a broader selector family is accepted.

### `BlockTag`

- JSON type: `string`
- Canonical values used in this docs set: `latest`, `pending`, `safe`, `finalized`, `earliest`
- Meaning: symbolic block selector resolved by the serving node or gateway

Reader rules:

- `latest` is the current head and can change between calls.
- `pending` may behave differently across methods and providers.
- Use `safe` or `finalized` when you want stronger consistency near head.

### `BlockNumberOrTag`

- JSON type: `string`
- Allowed values:
  - a `Quantity` block number such as `0x10`
  - a `BlockTag`

This is the most common selector family in the MegaETH RPC docs.

### `BlockReferenceString`

- JSON type: `string`
- Allowed values:
  - a `Quantity` block number
  - a `BlockTag`
  - a `BlockHash` when the method page explicitly allows it

Use this name when a method accepts only string block selectors, but supports more than just number-or-tag.

### `BlockHashSelector`

- JSON type: `object`
- Meaning: EIP-1898-style hash-based block selector

Canonical shape:

```json
{
  "blockHash": "0x0123456789abcdef0123456789abcdef0123456789abcdef0123456789abcdef"
}
```

Fields:

| Field | Type | Required | Notes |
|---|---|---|---|
| `blockHash` | `BlockHash` | Yes | Selected block hash |
| `requireCanonical` | `boolean` | No | Supported only on methods that document it |

### `BlockNumberOrTagOrHash`

- JSON type: `string | object`
- Allowed values:
  - `BlockReferenceString`
  - `BlockHashSelector`

Reader rules:

- This is the broadest shared selector family in this docs set.
- Support for the full union is method-specific.
- Do not assume every state method accepts block hashes just because another method does.

## Shared Request Objects

### `TransactionCall`

Used by methods such as `eth_call`, `eth_estimateGas`, and `eth_createAccessList`.

| Field | Type | Required | Notes |
|---|---|---|---|
| `from` | `Address` | No | Caller context |
| `to` | `Address | null` | No | Target contract or `null` for create-style simulation |
| `gas` | `Quantity` | No | Explicit gas cap |
| `gasPrice` | `Quantity` | No | Legacy fee field |
| `maxFeePerGas` | `Quantity` | No | EIP-1559 max fee |
| `maxPriorityFeePerGas` | `Quantity` | No | EIP-1559 tip cap |
| `value` | `Quantity` | No | Native value sent with the call |
| `input` | `Data` | No | Calldata field; prefer over `data` |
| `data` | `Data` | No | Legacy alias for `input` |
| `nonce` | `Quantity` | No | Caller nonce override |
| `accessList` | `AccessListEntry[]` | No | EIP-2930 access list |

Reader rules:

- Prefer `input` over `data`.
- Do not mix `gasPrice` with EIP-1559 fee fields unless the method page explicitly says the combination is accepted.
- Omit `to` or set `to: null` only for create-style simulation.
- If `from` is omitted, caller context is method-specific and may not match what your application expects.

### `AccessListEntry`

| Field | Type | Required | Notes |
|---|---|---|---|
| `address` | `Address` | Yes | Accessed account |
| `storageKeys` | `Bytes32[]` | Yes | Accessed storage slots |

### `LogFilter`

Used by `eth_getLogs`.

| Field | Type | Required | Notes |
|---|---|---|---|
| `fromBlock` | `BlockNumberOrTag` | No | Inclusive start |
| `toBlock` | `BlockNumberOrTag` | No | Inclusive end |
| `blockHash` | `BlockHash` | No | Single-block selector; cannot be combined with range fields |
| `address` | `Address | Address[] | null` | No | Single address or OR-matched address array |
| `topics` | `Array<Hash32 | Hash32[] | null> | null` | No | Positional topic selector |

Topic matching rules:

- Different topic positions are `AND`.
- Multiple values inside one position are `OR`.
- `null` means wildcard for that position.
- Trailing topic positions may be omitted.

Contract rules:

- `blockHash` mode and `fromBlock` / `toBlock` range mode are mutually exclusive.
- Omitted range defaults are method-specific; do not guess them from this page.
- An empty result array is a normal no-match result, not an error.

## Shared Response Objects

The field tables below summarize stable, commonly used fields. Method pages may document additional fields, provider-specific fields, or narrower presence rules.

### `Block`

| Field | Type | Notes |
|---|---|---|
| `number` | `Quantity | null` | Block number; may be `null` for pending-like results |
| `hash` | `BlockHash | null` | Block hash |
| `parentHash` | `BlockHash` | Parent block hash |
| `nonce` | `BlockNonce | null` | Header nonce where applicable |
| `sha3Uncles` | `UnclesHash` | Uncle-list commitment |
| `logsBloom` | `LogsBloom | null` | Block bloom filter when available |
| `transactionsRoot` | `TransactionsRoot` | Transaction trie root |
| `stateRoot` | `StateRoot` | State trie root |
| `receiptsRoot` | `ReceiptsRoot` | Receipt trie root |
| `miner` | `Address` | Beneficiary or coinbase |
| `difficulty` | `Quantity` | Difficulty field where exposed |
| `totalDifficulty` | `Quantity` | Cumulative difficulty where exposed |
| `extraData` | `ExtraData` | Header extra-data bytes |
| `mixHash` | `MixHash` | Legacy PoW mix-hash or post-Merge randomness field |
| `size` | `Quantity` | Block size in bytes |
| `gasLimit` | `Quantity` | Block gas limit |
| `gasUsed` | `Quantity` | Block gas used |
| `timestamp` | `Quantity` | Block timestamp |
| `transactions` | `Hash32[] | Transaction[]` | Hash-only or hydrated transactions depending on the method parameter |
| `uncles` | `BlockHash[]` | Uncle hashes when exposed |
| `baseFeePerGas` | `Quantity` | Present on post-London blocks when available |
| `withdrawals` | `Withdrawal[]` | Present when withdrawals are supported for the block |
| `withdrawalsRoot` | `WithdrawalsRoot` | Withdrawal trie root when available |
| `blobGasUsed` | `Quantity` | Present on blob-enabled blocks when available |
| `excessBlobGas` | `Quantity` | Present on blob-enabled blocks when available |
| `parentBeaconBlockRoot` | `BeaconBlockRoot` | Present when beacon-root linkage is exposed |
| `requestsHash` | `RequestsHash` | Present when EIP-7685 request commitments are exposed |

Possible MegaETH block metadata fields:

| Field | Type | Notes |
|---|---|---|
| `txOffset` | `Quantity` | MegaETH transaction-offset metadata |
| `miniBlockOffset` | `Quantity` | MegaETH mini-block offset metadata |
| `miniBlockCount` | `Quantity` | MegaETH mini-block count metadata |
| `signature` | `Data` | MegaETH block metadata signature |

### `Header`

`Header` uses the header field set from [`Block`](#block) without the block-only container fields such as:

- `transactions`
- `uncles`
- `withdrawals`
- `size`
- `totalDifficulty`

Use `Header` when the method returns only header data and not a full block body.

### `Transaction`

The fields below summarize stable, commonly used transaction members. Presence varies by transaction type and by mined vs pending context.

| Field | Type | Notes |
|---|---|---|
| `type` | `Quantity` | Transaction type identifier when present |
| `hash` | `TransactionHash` | Transaction hash |
| `from` | `Address` | Sender |
| `to` | `Address | null` | Recipient, or `null` for contract creation |
| `nonce` | `Quantity` | Transaction nonce |
| `value` | `Quantity` | Transferred value |
| `gas` | `Quantity` | Gas limit |
| `gasPrice` | `Quantity` | Effective legacy gas price when present |
| `maxFeePerGas` | `Quantity` | EIP-1559 max fee when present |
| `maxPriorityFeePerGas` | `Quantity` | EIP-1559 tip cap when present |
| `maxFeePerBlobGas` | `Quantity` | Blob fee cap when present |
| `input` | `Data` | Calldata or initcode |
| `accessList` | `AccessListEntry[]` | Access list when present |
| `chainId` | `Quantity` | Chain ID when present |
| `v` | `Quantity` | Signature recovery field when present |
| `r` | `Quantity` | Signature `r` when present |
| `s` | `Quantity` | Signature `s` when present |
| `yParity` | `Quantity` | Explicit parity field when present |
| `blobVersionedHashes` | `Hash32[]` | Blob commitments when present |
| `blockHash` | `BlockHash | null` | Inclusion block hash; `null` for pending transactions |
| `blockNumber` | `Quantity | null` | Inclusion block number; `null` for pending transactions |
| `transactionIndex` | `Quantity | null` | Position in the block; `null` for pending transactions |

### `Receipt`

| Field | Type | Notes |
|---|---|---|
| `type` | `Quantity` | Transaction type identifier when present |
| `transactionHash` | `TransactionHash` | Transaction hash |
| `transactionIndex` | `Quantity` | Position in the block |
| `blockHash` | `BlockHash` | Containing block hash |
| `blockNumber` | `Quantity` | Containing block number |
| `from` | `Address` | Sender |
| `to` | `Address | null` | Recipient, or `null` for contract creation |
| `cumulativeGasUsed` | `Quantity` | Cumulative gas used through this transaction in the block |
| `gasUsed` | `Quantity` | Gas used by this transaction |
| `contractAddress` | `Address | null` | Created contract address when applicable |
| `logs` | `Log[]` | Emitted log entries |
| `logsBloom` | `LogsBloom` | Bloom filter |
| `status` | `Quantity` | `0x1` means success and `0x0` means execution failure |
| `root` | `StateRoot` | Legacy pre-Byzantium receipt field |
| `effectiveGasPrice` | `Quantity` | Effective gas price when available |
| `blobGasUsed` | `Quantity` | Blob gas used when available |
| `blobGasPrice` | `Quantity` | Blob gas price when available |

Receipt notes:

- Modern networks typically expose `status`, not `root`.

Possible MegaETH receipt extension fields:

| Field | Type | Notes |
|---|---|---|
| `l1GasPrice` | `Quantity` | L1 gas price used for fee accounting |
| `l1GasUsed` | `Quantity` | L1 gas used for fee accounting |
| `l1Fee` | `Quantity` | Derived L1 fee amount |
| `l1BaseFeeScalar` | `Quantity` | Scalar used for the L1 base-fee component |
| `l1BlobBaseFee` | `Quantity` | L1 blob base fee |
| `l1BlobBaseFeeScalar` | `Quantity` | Scalar used for the blob base-fee component |
| `depositNonce` | `Quantity` | Deposit transaction nonce when applicable |
| `depositReceiptVersion` | `Quantity` | Deposit receipt schema version when applicable |

### `Log`

| Field | Type | Notes |
|---|---|---|
| `address` | `Address` | Contract that emitted the log |
| `topics` | `Hash32[]` | Indexed topics |
| `data` | `Data` | Unindexed data payload |
| `blockHash` | `BlockHash | null` | Containing block hash |
| `blockNumber` | `Quantity | null` | Containing block number |
| `blockTimestamp` | `Quantity | null` | Containing block timestamp when exposed by the serving layer |
| `transactionHash` | `TransactionHash | null` | Containing transaction hash |
| `transactionIndex` | `Quantity | null` | Position of the containing transaction |
| `logIndex` | `Quantity | null` | Position of the log in the block |
| `removed` | `boolean` | Reorg removal flag |

### `SyncProgress`

| Field | Type | Required |
|---|---|---|
| `startingBlock` | `Quantity` | Yes |
| `currentBlock` | `Quantity` | Yes |
| `highestBlock` | `Quantity` | Yes |

### `Withdrawal`

| Field | Type | Notes |
|---|---|---|
| `index` | `Quantity` | Withdrawal index |
| `validatorIndex` | `Quantity` | Beacon-chain validator index |
| `address` | `Address` | Withdrawal recipient |
| `amount` | `Quantity` | Withdrawal amount in gwei |

### `CreateAccessListResult`

| Field | Type | Required | Notes |
|---|---|---|---|
| `accessList` | `AccessListEntry[]` | Yes | Generated EIP-2930 access list |
| `gasUsed` | `Quantity` | Yes | Gas used by the simulated transaction with the generated access list |
| `error` | `string` | No | Per-simulation execution error string when execution halts or reverts |

Contract notes:

- A successful JSON-RPC response may still contain `result.error`.
- `error` is part of the method result object, not a top-level JSON-RPC error envelope.
- `accessList` and `gasUsed` are still expected when `error` is present.

### `OutputAtBlockResult`

Shared by output-style MegaETH methods.

| Field | Type | Required | Notes |
|---|---|---|---|
| `version` | `OutputVersion` | No | Public gateways may omit it on cache-hit or partial-cache paths |
| `outputRoot` | `OutputRoot` | Yes | Output root for the requested block |
| `blockRef` | `OutputBlockRef` | Yes | Requested block reference |
| `withdrawalStorageRoot` | `StorageRoot` | Yes | Withdrawal storage root for the requested block |
| `stateRoot` | `StateRoot` | Yes | State root for the requested block |
| `syncStatus` | `object` | Yes | Backend sync-status snapshot at response time; see [`mega_outputAtBlock`](api/mega_outputAtBlock.md) for the full shape |

Contract notes:

- This object family is not part of the standard Ethereum execution-apis object set.
- Method pages remain authoritative for cache-related presence differences such as version omission.

### `OutputBlockRef`

| Field | Type | Required | Notes |
|---|---|---|---|
| `hash` | `BlockHash` | Yes | Block hash |
| `number` | `number` | Yes | JSON number, not an Ethereum `Quantity` string |
| `parentHash` | `BlockHash` | Yes | Parent block hash |
| `timestamp` | `number` | Yes | JSON number, not an Ethereum `Quantity` string |
| `l1origin` | `object` | Yes | Origin L1 block reference `{ hash, number }` |
| `sequenceNumber` | `number` | Yes | Sequence number |

Reader rules:

- `OutputBlockRef` is an output-method object, not a standard Ethereum execution-apis object.
- Numeric members in this object are JSON numbers in observed MegaETH responses.

## MegaETH Shared Extensions

These types are not portable by default. Use them only when a method page explicitly documents support.

### `StateOverride`

`StateOverride` is an object keyed by `Address`. Each property value is an `AccountOverride`.

Example shape:

```json
{
  "0x1111111111111111111111111111111111111111": {
    "balance": "0x1",
    "code": "0x6001600055"
  }
}
```

### `AccountOverride`

| Field | Type | Required | Notes |
|---|---|---|---|
| `balance` | `Quantity` | No | Temporary balance override |
| `nonce` | `Quantity` | No | Temporary nonce override |
| `code` | `Data` | No | Temporary bytecode override |
| `state` | `StorageMap` | No | Replaces the account's full storage view |
| `stateDiff` | `StorageMap` | No | Patches individual slots on top of canonical state |
| `movePrecompileToAddress` | `Address` | No | Advanced compatibility feature |

Contract notes:

- `state` and `stateDiff` are mutually exclusive.
- `state` replaces the account's full storage view for the duration of the simulation.
- `stateDiff` patches only the listed slots on top of canonical state.
- Unknown fields should be treated as invalid unless the method page says otherwise.
- These overrides affect only the current simulation request.

### `StorageMap`

| Element | Type | Rule |
|---|---|---|
| property name | `Bytes32` | Storage slot key |
| property value | `Bytes32` | Storage slot value |

### `BlockOverrides`

`BlockOverrides` is a shared MegaETH simulation object reused by methods such as `eth_call`.

Canonical fields:

| Field | Type | Notes |
|---|---|---|
| `number` | `Quantity` | Override block number |
| `difficulty` | `Quantity` | Override block difficulty |
| `time` | `Quantity` | Override block timestamp |
| `gasLimit` | `Quantity` | Override block gas limit |
| `coinbase` | `Address` | Override fee recipient |
| `random` | `Hash32` | Override post-Merge randomness |
| `baseFee` | `Quantity` | Override base fee |
| `blockHash` | `BlockHashMap` | Map used by the `BLOCKHASH` opcode |

Compatibility aliases:

| Alias field | Canonical field |
|---|---|
| `blockNumber` | `number` |
| `timestamp` | `time` |
| `feeRecipient` | `coinbase` |
| `prevRandao` | `random` |
| `baseFeePerGas` | `baseFee` |

Reader rules:

- An empty object is a valid no-op form.
- Method support for individual fields is not universal.
- Do not assume a field is accepted unless the method page documents it.

### `BlockHashMap`

| Element | Type | Rule |
|---|---|---|
| property name | JSON string | Use decimal-style JSON string keys such as `"1"` unless the method page says otherwise |
| property value | `Hash32` | Hash returned for that block number during simulation |

## Common Validation Mistakes

| Mistake | Wrong | Right | Why it fails |
|---|---|---|---|
| Decimal quantity | `21000` | `"0x5208"` | `Quantity` must be hex string |
| Leading zeroes in quantity | `"0x0001"` | `"0x1"` | Minimal form is required |
| Odd-length data | `"0x123"` | `"0x0123"` | `Data` must use full byte pairs |
| Short address | `"0x742d35"` | full 20-byte address | `Address` must be exactly 20 bytes |
| Mixed log-filter modes | `{"blockHash":"0x...","fromBlock":"0x1"}` | choose one mode | `blockHash` cannot be combined with range fields |
| Mixed fee models | `{"gasPrice":"0x1","maxFeePerGas":"0x2"}` | choose one fee model | Not portable and often rejected |
