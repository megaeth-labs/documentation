# eth_getBalance

Returns the ETH balance of an account in wei at a given block.

## Parameters

**`address`** Address **REQUIRED**

Target account or contract address.

---

**`block`** string

Hex block number or tag (`latest`, `safe`, `finalized`, `earliest`, `pending`). Default: `"latest"`.

## Returns

**`result`** Quantity

Balance in wei. Returns `0x0` for unknown accounts and zero-balance accounts alike.

## Errors

| Code | Cause | Fix |
|---|---|---|
| `-32602` | Malformed address or block selector | Fix the request |
| `-32001` | Block selector cannot be resolved | Verify the block number or hash |
| `4444` | Requested historical state is not available | Verify historical-state availability for the endpoint |

See also [Error reference](../errors.md).

## Example

```bash
curl -sS https://mainnet.megaeth.com/rpc \
  -H 'content-type: application/json' \
  --data '{"jsonrpc":"2.0","id":1,"method":"eth_getBalance","params":["0x0000000000000000000000000000000000000000","latest"]}'
```

```jsonc
{"jsonrpc":"2.0","id":1,"result":"0xe7bc7211178"}  // 15,924,784,599,416 wei
```
