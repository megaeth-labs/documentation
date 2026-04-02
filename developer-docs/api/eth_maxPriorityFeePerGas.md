# eth_maxPriorityFeePerGas

Returns the max priority fee per gas in wei. Always `0x0` because MegaETH's single active sequencer orders all transactions — there is no tip-based priority auction.

## Parameters

None.

## Returns

**`result`** *Quantity*

Always `0x0`.

## Errors

Standard JSON-RPC errors only. See [Error reference](../errors.md).

## Example

```bash
curl -sS https://mainnet.megaeth.com/rpc \
  -H 'content-type: application/json' \
  --data '{"jsonrpc":"2.0","id":1,"method":"eth_maxPriorityFeePerGas","params":[]}'
```

```json
{"jsonrpc":"2.0","id":1,"result":"0x0"}
```
