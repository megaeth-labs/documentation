---
description: Make your first read-only MegaETH JSON-RPC requests and verify the connected network.
---

# Quickstart

Use these read-only requests to confirm connectivity and learn the basic response shape.
The public HTTP endpoint accepts JSON-RPC `POST` requests without an API key.

## Endpoints

| Network | HTTP                              | WebSocket                      |
| ------- | --------------------------------- | ------------------------------ |
| Mainnet | `https://mainnet.megaeth.com/rpc` | `wss://mainnet.megaeth.com/ws` |
| Testnet | `https://carrot.megaeth.com/rpc`  | `wss://carrot.megaeth.com/ws`  |

Use HTTP for standard requests and WebSocket for [`eth_subscribe`](./reference/eth_subscribe.md) and [`eth_unsubscribe`](./reference/eth_unsubscribe.md).

## Check the latest block

```bash
curl -sS https://mainnet.megaeth.com/rpc \
  -H 'content-type: application/json' \
  --data '{"jsonrpc":"2.0","id":1,"method":"eth_blockNumber","params":[]}'
```

A successful response contains a hexadecimal block number:

```json
{
  "jsonrpc": "2.0",
  "id": 1,
  "result": "0x..."
}
```

## Verify the network

```bash
curl -sS https://mainnet.megaeth.com/rpc \
  -H 'content-type: application/json' \
  --data '{"jsonrpc":"2.0","id":2,"method":"eth_chainId","params":[]}'
```

MegaETH Mainnet returns `0x10e6` (4326), and MegaETH Testnet returns `0x18c7` (6343).

## Read account state

Replace the zero address with the account you want to query.

```bash
curl -sS https://mainnet.megaeth.com/rpc \
  -H 'content-type: application/json' \
  --data '{"jsonrpc":"2.0","id":3,"method":"eth_getBalance","params":["0x0000000000000000000000000000000000000000","latest"]}'
```

The result is a hexadecimal [`Quantity`](./types.md#quantity) denominated in wei.

## Next steps

- Use [JSON-RPC basics](./json-rpc-basics.md) for envelopes, notifications, and batches.
- Use [Operations and limits](./operations-and-limits.md) before sending large batches or historical queries.
- Use [Error reference](./error-codes.md) to distinguish transport failures from JSON-RPC errors.
- Browse the [RPC Reference](./reference/README.md) for request and response schemas.
