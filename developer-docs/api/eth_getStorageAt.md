# eth_getStorageAt

Returns the 32-byte value stored at a given contract storage slot at a specified block.

## Parameters

| Position | Name | Type | Required | Notes |
|---|---|---|---|---|
| `0` | `address` | [`Address`](../types.md#address) | Yes | Contract address |
| `1` | `slot` | [`StorageSlotIndex`](../types.md#storageslotindex) or [`StorageKey32`](../types.md#storagekey32) | Yes | Raw storage key, not a Solidity field index; prefer a 32-byte left-padded hex value for portability |
| `2` | `block` | [`BlockReferenceString`](../types.md#blockreferencestring) | No | Default: `latest` |

## Returns

| Field | Type | Notes |
|---|---|---|
| `result` | [`Bytes32`](../types.md#bytes32) | Raw 32-byte storage word; a zero value can mean an empty slot, a non-existent account, or an explicitly stored zero |

## Errors

| Code | Cause | Fix |
|---|---|---|
| `-32602` | Address, slot encoding, or block selector is malformed | Fix the request |
| `-32001` | Block selector cannot be resolved | Verify the block number or hash |
| `4444` | Requested historical state is unavailable | Verify historical-state availability for the endpoint |

See also [Error reference](../errors.md).

## Example

```bash
curl -sS https://mainnet.megaeth.com/rpc \
  -H 'content-type: application/json' \
  --data '{"jsonrpc":"2.0","id":63,"method":"eth_getStorageAt","params":["0x4200000000000000000000000000000000000011","0x0000000000000000000000000000000000000000000000000000000000000000","0xb11048"]}'
```

```jsonc
{"jsonrpc":"2.0","id":63,"result":"0x000000000000000000000000000000000000000000000001bce8287cf283cc16"}  // raw 32-byte word at slot 0, block 11,604,040
```
