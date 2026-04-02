# eth_getTransactionCount

Returns the number of transactions sent from an address at a given block.

## Parameters

**`address`** Address **REQUIRED**

Target account address.

---

**`block`** string

Hex block number or tag (`latest`, `safe`, `finalized`, `earliest`, `pending`). Default: `"latest"`.

## Returns

**`result`** Quantity

Transaction count at the requested block. Returns `0x0` for both unknown accounts and accounts with zero transactions.

## Errors

| Code | Cause | Fix |
|---|---|---|
| `-32602` | Malformed address or block selector | Fix the request |
| `-32001` | Block selector cannot be resolved | Verify the block number or hash |
| `4444` | Requested historical state is unavailable | Verify historical-state availability for the endpoint |

See also [Error reference](../errors.md).

## Example

```bash
curl -sS https://mainnet.megaeth.com/rpc \
  -H 'content-type: application/json' \
  --data '{"jsonrpc":"2.0","id":91,"method":"eth_getTransactionCount","params":["0xa344fb2d117501ee379d2ea9c0c016959ad94f1e","0xb120c6"]}'
```

```jsonc
{"jsonrpc":"2.0","id":91,"result":"0xfa8c"}  // 64,140 transactions (block 11,608,262)
```
