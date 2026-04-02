# eth_getCode

Returns the runtime bytecode stored at an address at a given block.

## Parameters

**`address`** Address **REQUIRED**

Target account or contract address.

---

**`block`** string

Hex block number, block hash, or tag (`latest`, `safe`, `finalized`, …). Default: `"latest"`.

## Returns

**`result`** Data

Runtime bytecode (not creation bytecode) at the address; `0x` when no code is deployed.

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
  --data '{"jsonrpc":"2.0","id":2,"method":"eth_getCode","params":["0x4200000000000000000000000000000000000011","latest"]}'
```

```jsonc
{"jsonrpc":"2.0","id":2,"result":"0x6080604052…"}  // bytecode truncated
```
