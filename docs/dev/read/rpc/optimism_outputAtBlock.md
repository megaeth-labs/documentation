---
description: "Returns the OP Stack output-root data for a MegaETH block."
---

# optimism_outputAtBlock

Returns the same output-root data as [`mega_outputAtBlock`](./mega_outputAtBlock.md).
The two names are aliases on MegaETH.

## Parameters

| Position | Name          | Type       | Required | Description                                                     |
| -------- | ------------- | ---------- | -------- | --------------------------------------------------------------- |
| `0`      | `blockNumber` | `QUANTITY` | Yes      | Concrete hexadecimal block number; block tags are not accepted. |

## Returns

An output object containing `version`, `outputRoot`, `blockRef`, `withdrawalStorageRoot`, `stateRoot`, and `syncStatus`.
See [`mega_outputAtBlock`](./mega_outputAtBlock.md#returns) for every field.

## Errors

The validation and backend errors are identical to [`mega_outputAtBlock`](./mega_outputAtBlock.md#errors).

## Example

```json
{
  "jsonrpc": "2.0",
  "id": 1,
  "method": "optimism_outputAtBlock",
  "params": ["0x100"]
}
```
