# mega_getWithdrawalProof

Returns a Merkle proof for the L2ToL1MessagePasser contract at a given block, used to prove withdrawal state to L1.

## Parameters

| Position | Name | Type | Required | Notes |
|---|---|---|---|---|
| `0` | `address` | `Address` | Yes | Must be `0x4200000000000000000000000000000000000016` (L2ToL1MessagePasser) |
| `1` | `storageKeys` | `Bytes32[]` | Yes | Storage keys to prove; empty array is valid |
| `2` | `block` | `string` | No | Hex block number or tag (`latest`, `safe`, `finalized`, `earliest`, `pending`). Default: `"latest"` |

## Returns

| Field | Type | Notes |
|---|---|---|
| `address` | `Address` | Proved address |
| `accountProof` | `Data[]` | Account trie proof nodes |
| `balance` | `Quantity` | Account balance |
| `codeHash` | `Hash32` | Account code hash |
| `nonce` | `Quantity` | Account nonce |
| `storageHash` | `Hash32` | Storage trie root |
| `storageProof` | `object[]` | Per-key storage proofs; each entry has `key` (`Bytes32`), `value` (`Bytes32`), `proof` (`Data[]`) |

## Errors

| Code | Cause | Fix |
|---|---|---|
| `-32602` | A storage key is not a valid 32-byte hex string, or required parameters are missing | Fix the request |
| `-32000` | The requested block cannot be resolved | Verify the block reference |

See also [Error reference](../errors.md).

## Example

```bash
curl -sS https://mainnet.megaeth.com/rpc \
  -H 'content-type: application/json' \
  --data '{"jsonrpc":"2.0","id":1,"method":"mega_getWithdrawalProof","params":["0x4200000000000000000000000000000000000016",[],"latest"]}'
```

```jsonc
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
