---
description: Hexadecimal quantities, byte strings, addresses, hashes, block selectors, and transaction call objects used by MegaETH JSON-RPC.
---

# Type reference

This page defines wire types shared by MegaETH JSON-RPC methods.
Method pages remain self-contained and specify the types accepted in each position.

## Core wire types

### `Quantity`

A `Quantity` is a non-negative integer encoded as a `0x`-prefixed hexadecimal string.
It uses the shortest representation, so leading zeroes are not allowed except in `0x0`.

| Valid    | Invalid |
| -------- | ------- |
| `0x0`    | `0`     |
| `0x1`    | `0x01`  |
| `0x5208` | `21000` |

### `Data`

`Data` is an arbitrary byte sequence encoded as a `0x`-prefixed hexadecimal string.
It contains exactly two hexadecimal digits per byte and may be empty.

| Valid        | Invalid    |
| ------------ | ---------- |
| `0x`         | `0`        |
| `0x12`       | `0x1`      |
| `0xdeadbeef` | `deadbeef` |

### `Address`

An `Address` is a 20-byte value encoded as `0x` followed by 40 hexadecimal digits.
The wire format accepts upper- or lowercase hexadecimal digits.

Example: `0x0000000000000000000000000000000000000000`.

### `Hash32`

A `Hash32` is a 32-byte hash encoded as `0x` followed by 64 hexadecimal digits.
Block hashes, transaction hashes, and trie roots use this representation.

### `Bytes32`

`Bytes32` has the same wire width as `Hash32` but represents a fixed-width value rather than necessarily a hash.
Storage keys and proof values commonly use this representation.

## Block selectors

Methods that read block or state data may accept a block number encoded as `Quantity` or one of these tags:

| Tag         | Meaning on MegaETH                                           |
| ----------- | ------------------------------------------------------------ |
| `earliest`  | The genesis block.                                           |
| `latest`    | The latest streaming state, including committed mini-blocks. |
| `pending`   | The latest streaming state.                                  |
| `safe`      | The latest safe EVM block known to the node.                 |
| `finalized` | The latest finalized EVM block known to the node.            |

Some methods also accept an EIP-1898 block selector object containing `blockHash` or `blockNumber`.
Check the method page before using the object form because support is method-specific.

## Transaction call object

Simulation methods such as [`eth_call`](./reference/eth_call.md), [`eth_estimateGas`](./reference/eth_estimateGas.md), and [`eth_createAccessList`](./reference/eth_createAccessList.md) accept a transaction call object.
Common fields include:

| Field                  | Type                | Description                                 |
| ---------------------- | ------------------- | ------------------------------------------- |
| `from`                 | `Address`           | Simulated sender.                           |
| `to`                   | `Address` or `null` | Recipient, or `null` for contract creation. |
| `gas`                  | `Quantity`          | Gas limit supplied to the simulation.       |
| `gasPrice`             | `Quantity`          | Legacy gas price.                           |
| `maxFeePerGas`         | `Quantity`          | EIP-1559 maximum fee.                       |
| `maxPriorityFeePerGas` | `Quantity`          | EIP-1559 priority fee.                      |
| `value`                | `Quantity`          | Value transferred in wei.                   |
| `input` or `data`      | `Data`              | Calldata or contract creation bytecode.     |
| `nonce`                | `Quantity`          | Sender nonce when the method supports it.   |
| `accessList`           | array               | EIP-2930 access list.                       |

Do not combine `gasPrice` with EIP-1559 fee fields.
Use the relevant method page for accepted fields and defaults.

## Common validation mistakes

| Mistake                  | Wrong                          | Correct                |
| ------------------------ | ------------------------------ | ---------------------- |
| Decimal quantity         | `21000`                        | `"0x5208"`             |
| Leading zeroes           | `"0x0001"`                     | `"0x1"`                |
| Odd-length data          | `"0x123"`                      | `"0x0123"`             |
| Short address            | `"0x1234"`                     | A full 20-byte address |
| Mixed log selector modes | `blockHash` with `fromBlock`   | Use one selector mode  |
| Mixed fee models         | `gasPrice` with `maxFeePerGas` | Use one fee model      |

## Source

- [EIP-1474: Value encoding](https://eips.ethereum.org/EIPS/eip-1474#value-encoding)
