# eth_getStorageAt

Returns the 32-byte value stored at a contract storage slot at a selected block.

## Ethereum Standard

`eth_getStorageAt(address, slot, block) -> Data`

## MegaETH Differences

- The public MegaETH endpoint currently accepts an omitted `block` parameter and treats it as `latest`.
- That omitted-`block` behavior is a MegaETH convenience, not portable Ethereum JSON-RPC behavior.
- MegaETH accepts shorthand slot forms such as `0x0` for slot zero, but portable clients should prefer a 32-byte left-padded slot key.

## Request

Send `params` as `[address, slot, block]`.

| Position | Type | Required | Notes |
|---|---|---|---|
| `0` | [`Address`](../types.md#address) | Yes | Contract address |
| `1` | [`StorageSlotIndex`](../types.md#storageslotindex) or [`StorageKey32`](../types.md#storagekey32) | Yes | Raw storage key |
| `2` | [`BlockReferenceString`](../types.md#blockreferencestring) | Yes for portable clients | Accepts `earliest`, `latest`, `pending`, `safe`, `finalized`, a hex block number, or a block hash string |

Reader notes:

- `slot` is a raw storage key, not a decimal field name or ABI parameter index.
- For portable behavior, prefer a 32-byte left-padded slot key such as `0x0000000000000000000000000000000000000000000000000000000000000000`.
- Slot values longer than 32 bytes are invalid and usually return `-32602`.
- Use a fixed block number or block hash for reproducible reads.

## Response

| Field | Type | Notes |
|---|---|---|
| `result` | [`Bytes32`](../types.md#bytes32) | Raw 32-byte storage word at the selected address, slot, and block |

- A zero word can mean an empty slot, a non-existent account, or an explicitly stored zero value.

## Common Errors

| Code | When it usually happens | What to do |
|---|---|---|
| `-32602` | The address, slot encoding, or block selector is malformed | Fix the request before retrying |
| `-32001` | The block selector cannot be resolved | Check the block number, block hash, or network |
| `4444` | The endpoint cannot serve the requested historical state | Keep the request unchanged and verify historical-state availability for that endpoint |
| `-32005` | The public endpoint rate-limited the request | Back off and retry later |

See also [Error reference](../errors.md).

## Example

```bash
curl -sS https://mainnet.megaeth.com/rpc \
  -H 'content-type: application/json' \
  --data '{"jsonrpc":"2.0","id":63,"method":"eth_getStorageAt","params":["0x4200000000000000000000000000000000000011","0x0000000000000000000000000000000000000000000000000000000000000000","0xb11048"]}'
```

```json
{"jsonrpc":"2.0","id":63,"result":"0x000000000000000000000000000000000000000000000001bce8287cf283cc16"}
```
