# Type Reference

This page defines the basic wire types used across the MegaETH JSON-RPC API. Method pages are self-contained — you do not need this page to call any method.

## Core Wire Types

### `Quantity`

- JSON type: `string`
- Pattern: `^0x(?:0|[1-9a-fA-F][0-9a-fA-F]*)$`
- Meaning: non-negative integer in hexadecimal with no leading zeroes except `0x0`

Valid: `0x0`, `0x1`, `0x2a`

Invalid: `0`, `42`, `0x00`, `0x0001`

### `Data`

- JSON type: `string`
- Pattern: `^0x(?:[0-9a-fA-F]{2})*$`
- Meaning: arbitrary byte string encoded as hex pairs after `0x`

Valid: `0x`, `0x12`, `0xdeadbeef`

Invalid: `deadbeef`, `0x1`, `0x123`

`Data` can be empty (`0x` is valid). Hex length after `0x` must be even.

### `Address`

- JSON type: `string`
- Pattern: `^0x[0-9a-fA-F]{40}$`
- Meaning: 20-byte account or contract address
- Wire format is case-insensitive

### `Hash32`

- JSON type: `string`
- Pattern: `^0x[0-9a-fA-F]{64}$`
- Meaning: 32-byte hash (block hash, transaction hash, state root, etc.)

### `Bytes32`

- JSON type: `string`
- Pattern: `^0x[0-9a-fA-F]{64}$`
- Meaning: 32-byte fixed-width value (storage slots, proof values, etc.)

## Common Validation Mistakes

| Mistake | Wrong | Right | Why it fails |
|---|---|---|---|
| Decimal quantity | `21000` | `"0x5208"` | `Quantity` must be hex string |
| Leading zeroes in quantity | `"0x0001"` | `"0x1"` | Minimal form is required |
| Odd-length data | `"0x123"` | `"0x0123"` | `Data` must use full byte pairs |
| Short address | `"0x742d35"` | full 20-byte address | `Address` must be exactly 20 bytes |
| Mixed log-filter modes | `{"blockHash":"0x...","fromBlock":"0x1"}` | choose one mode | `blockHash` cannot be combined with range fields |
| Mixed fee models | `{"gasPrice":"0x1","maxFeePerGas":"0x2"}` | choose one fee model | Not portable and often rejected |
