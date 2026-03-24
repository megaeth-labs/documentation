# eth_getBlockByNumber

## Summary
Returns a block by its number or by a canonical block tag.

This method is part of the standard Ethereum JSON-RPC API. The second parameter controls whether the `transactions` array contains transaction hashes or full transaction objects. If the requested block is not available, the method returns `null`.

On the MegaETH public endpoint, omitting the second parameter is currently accepted and behaves like `false`, but that is not standard Ethereum JSON-RPC behavior and should not be relied on for portable integrations.

## Parameters
- `block` (required): `string`

  Accepted values:
  - hex block number as a `0x`-prefixed `QUANTITY`
  - one of: `earliest`, `finalized`, `safe`, `latest`, `pending`

  Notes:
  - Use an explicit block number for reproducible results.
  - Fixed block numbers are stable and deterministic.
  - Tag-based selectors such as `latest` and `pending` can change over time.
  - EIP-1898 block-object selectors are not accepted here; this method expects a string block number or tag.

- `fullTransactions` (required by the Ethereum JSON-RPC specification): `boolean`

  Accepted values:
  - `false`: `result.transactions` is an array of transaction hashes
  - `true`: `result.transactions` is an array of full transaction objects

  Notes:
  - For portable client behavior, always send this parameter explicitly.
  - On the MegaETH public endpoint, omitting this parameter is currently accepted and behaves like `false`, but that is a non-standard convenience.

## Returns
- `result` (`object | null`)

  If the block is found, `result` is a block object.

  Common fields include:
  - `hash`
  - `parentHash`
  - `number`
  - `timestamp`
  - `gasLimit`
  - `gasUsed`
  - `baseFeePerGas`
  - `transactions`
  - `uncles`

  Notes:
  - If `fullTransactions = false`, `transactions` is an array of transaction hashes.
  - If `fullTransactions = true`, `transactions` is an array of transaction objects.
  - Additional standard fields such as `withdrawals`, `blobGasUsed`, `excessBlobGas`, and `parentBeaconBlockRoot` may be present depending on chain and fork support.
  - Transaction object fields can vary by transaction type.
  - If the requested block is unavailable, the method returns `null` rather than a JSON-RPC error.

## Examples

### curl: specific block, transactions as hashes
```bash
curl -sS https://mainnet.megaeth.com/rpc \
  -H 'content-type: application/json' \
  --data '{"jsonrpc":"2.0","id":81,"method":"eth_getBlockByNumber","params":["0x100000",false]}'
```

### JSON-RPC request: specific block, transactions as hashes
```json
{"jsonrpc":"2.0","id":81,"method":"eth_getBlockByNumber","params":["0x100000",false]}
```

### Response: specific block, transactions as hashes (actual response excerpt)
```json
{"jsonrpc":"2.0","id":81,"result":{"hash":"0xe0b5b2b8222c00dcbe9f359fc917a9190127bd1b958e11b6caa2035dd03952f1","parentHash":"0x5c7a381d50edca155ad666b64122bdaf6ec009f2404d602ec958b257d53c75fb","number":"0x100000","timestamp":"0x692225d3","gasLimit":"0x2540be400","gasUsed":"0xfe56","baseFeePerGas":"0xf4240","size":"0x384","uncles":[],"transactions":["0x243d39c7f6cd74a9a081a6fe4bdfce37ac6136b9454691aeeb9ed77998450cbc"],"withdrawals":[],"miniBlockCount":"0x64","miniBlockOffset":"0x5b54822","signature":"0xef8e862b759eee17d944dcc765c8556d9d6427bce0a5a14a2f57d681c1e9f71f1ee47f9ca379f6a402488cb5c4f0925639e472765aa6895e72580dae8290b5c81b","txOffset":"0x101ffe"}}
```

### JSON-RPC request: specific block, full transaction objects
```json
{"jsonrpc":"2.0","id":82,"method":"eth_getBlockByNumber","params":["0x100000",true]}
```

### Response: specific block, full transaction objects (actual response excerpt)
```json
{"jsonrpc":"2.0","id":82,"result":{"hash":"0xe0b5b2b8222c00dcbe9f359fc917a9190127bd1b958e11b6caa2035dd03952f1","number":"0x100000","transactions":[{"type":"0x7e","sourceHash":"0x79ab34de993de378f15eafd864cab321ca382dc65b7aa82d0cc10618e68041e6","from":"0xdeaddeaddeaddeaddeaddeaddeaddeaddead0001","to":"0x4200000000000000000000000000000000000015","mint":"0x0","value":"0x0","gas":"0x5f5e100","input":"0x098999be00000558000c5fc50000000000000053000000006922225700000000016c074600000000000000000000000000000000000000000000000000000000041577640000000000000000000000000000000000000000000000000000000000000001f7c63d3b8cb8f194b5ac53452faf9f8c0d14f790e43e85a12558906bbe6a5adf000000000000000000000000b98c6b1a805b96707a43e1f1acfa163b68098fa6000000000000000000000000","hash":"0x243d39c7f6cd74a9a081a6fe4bdfce37ac6136b9454691aeeb9ed77998450cbc","blockHash":"0xe0b5b2b8222c00dcbe9f359fc917a9190127bd1b958e11b6caa2035dd03952f1","blockNumber":"0x100000","transactionIndex":"0x0","depositReceiptVersion":"0x1","gasPrice":"0x0","nonce":"0xfffff"}],"uncles":[]}}
```

### JSON-RPC request: future block number
```json
{"jsonrpc":"2.0","id":84,"method":"eth_getBlockByNumber","params":["0xffffffffffffffff",false]}
```

### Response: future block number
```json
{"jsonrpc":"2.0","id":84,"result":null}
```

### JSON-RPC request: MegaETH-only convenience example
```json
{"jsonrpc":"2.0","id":85,"method":"eth_getBlockByNumber","params":["0x100000"]}
```

### Response: MegaETH-only convenience example (actual response excerpt)
```json
{"jsonrpc":"2.0","id":85,"result":{"hash":"0xe0b5b2b8222c00dcbe9f359fc917a9190127bd1b958e11b6caa2035dd03952f1","number":"0x100000","transactions":["0x243d39c7f6cd74a9a081a6fe4bdfce37ac6136b9454691aeeb9ed77998450cbc"]}}
```

### JSON-RPC request: invalid block selector object
```json
{"jsonrpc":"2.0","id":88,"method":"eth_getBlockByNumber","params":[{"blockNumber":"0x100000"},false]}
```

### Error response: invalid block selector object
```json
{"jsonrpc":"2.0","error":{"code":-32602,"message":"eth_getBlockByNumber block identifier must be a string (hex number or tag), not an object"},"id":88}
```

## MegaETH Behavior
- On the MegaETH public endpoint, omitting `fullTransactions` was accepted and behaved like `false`.
- On the MegaETH public endpoint, the `pending` tag returned `null` in the tested request.
- On the MegaETH public endpoint, a future block number returned `result: null` rather than a JSON-RPC error.
- In the tested block responses above, MegaETH returned additional provider-specific fields such as `miniBlockCount`, `miniBlockOffset`, `signature`, and `txOffset`.
- In the tested `fullTransactions = true` response above, the transaction object included type-specific fields such as `sourceHash`, `mint`, and `depositReceiptVersion`.
- Public endpoints may enforce rate limits.

## Errors
- `-32602` Invalid params

  When it happens: The request has the wrong parameter shape, the block selector is malformed, or the first parameter is not a string block number or tag.

  Example:
  ```json
  {"jsonrpc":"2.0","error":{"code":-32602,"message":"eth_getBlockByNumber block identifier must be a string (hex number or tag), not an object"},"id":88}
  ```

  Client handling: Fix the request shape or parameter values before retrying.

- `result: null` Block not found / unavailable

  When it happens: The selected block does not exist or is not available for that selector.

  Example:
  ```json
  {"jsonrpc":"2.0","id":84,"result":null}
  ```

  Client handling: Treat this as a not-found or unavailable-block condition, not as a transport or server failure.

- `4444` Pruned history unavailable

  When it happens: A pruned node cannot serve the requested historical block data.

  Client handling: Retry against a node that retains the required history.

- `-32005` Rate limited

  When it happens: The request exceeds the public endpoint's rate limit.

  Client handling: Retry with backoff and reduce burst rate.

## Best Practices
- Always send both parameters explicitly; do not rely on MegaETH's omitted-boolean convenience.
- Use `fullTransactions = false` unless you actually need full transaction objects.
- Use explicit block numbers when you need reproducible results.
- Treat `result: null` as a normal not-found or unavailable-block response.
- Validate block selectors client-side before sending requests.
- Handle optional and provider-specific block fields defensively.
- Do not assume every transaction object has the same field set; transaction type can change the shape.

## Compatibility
- `eth_getBlockByNumber` is standard Ethereum JSON-RPC.
- The portable parameter shape is `[block, fullTransactions]`.
- MegaETH public endpoint behavior observed here is not fully standard:
  - omitted `fullTransactions` -> accepted and behaves like `false`
  - `pending` -> returned `null` in the tested request
  - block objects may include additional provider-specific fields
- Do not assume other providers behave the same way.
