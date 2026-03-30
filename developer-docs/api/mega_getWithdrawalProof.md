# mega_getWithdrawalProof

Returns the Merkle proof for the L2-to-L1 message passer contract at a given block.

## Ethereum Standard

This method is not part of the standard Ethereum JSON-RPC method set.

## MegaETH Differences

- This is a MegaETH L2 method used to prove withdrawal state to L1.
- The `address` parameter should be `0x4200000000000000000000000000000000000016` (the L2ToL1MessagePasser contract). The proof is only meaningful for this contract.
- `eth_getWithdrawalProof` is an alias for this method with identical behavior.

## Request

Send `params` as `[address, storageKeys, block]`.

| Position | Type | Required | Notes |
|---|---|---|---|
| `0` | [`Data`](../types.md#data) | Yes | L2ToL1MessagePasser address: `0x4200000000000000000000000000000000000016` |
| `1` | `Data[]` | Yes | Storage keys to prove; each must be a `0x`-prefixed 32-byte hex string. Empty array is valid. |
| `2` | [`BlockReferenceString`](../types.md#blockreferencestring) | No | Block to query; defaults to `"latest"` |

## Response

| Field | Type | Notes |
|---|---|---|
| `result.address` | [`Data`](../types.md#data) | The queried contract address |
| `result.accountProof` | `Data[]` | Merkle proof nodes for the account in the state trie |
| `result.balance` | [`Quantity`](../types.md#quantity) | Account balance |
| `result.codeHash` | [`Data`](../types.md#data) | Keccak256 hash of the account bytecode |
| `result.nonce` | [`Quantity`](../types.md#quantity) | Account nonce |
| `result.storageHash` | [`Data`](../types.md#data) | Root hash of the account storage trie |
| `result.storageProof` | `Object[]` | One entry per requested storage key |
| `result.storageProof[].key` | [`Data`](../types.md#data) | Storage key |
| `result.storageProof[].value` | [`Quantity`](../types.md#quantity) | Value at the storage slot |
| `result.storageProof[].proof` | `Data[]` | Merkle proof nodes for this storage slot |

## Common Errors

| Code | When it usually happens | What to do |
|---|---|---|
| `-32602` | A storage key is not a valid 32-byte hex string, or required parameters are missing | Fix the request before retrying |
| `-32000` | The requested block cannot be resolved | Check the block selector and retry |
| `-32005` | The public endpoint rate-limited the request | Back off and retry later |

See also [Error reference](../errors.md).

## Example

Reader notes:

- The example uses an empty `storageKeys` array and `"latest"`, so `accountProof` and `storageProof` are empty. Pass specific storage keys and a finalized block number to receive populated Merkle proof nodes.

```bash
curl -sS https://mainnet.megaeth.com/rpc \
  -H 'content-type: application/json' \
  --data '{"jsonrpc":"2.0","id":1,"method":"mega_getWithdrawalProof","params":["0x4200000000000000000000000000000000000016",[],"latest"]}'
```

```json
{
  "jsonrpc": "2.0",
  "id": 1,
  "result": {
    "address": "0x4200000000000000000000000000000000000016",
    "balance": "0x0",
    "codeHash": "0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470",
    "nonce": "0x0",
    "storageHash": "0xddd6dcaf75eeb81fb4701c2a39b3132bd60bf9602e2fcbe5852f5d07e14c8084",
    "accountProof": [],
    "storageProof": []
  }
}
```
