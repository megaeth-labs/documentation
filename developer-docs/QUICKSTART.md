# Quickstart

Make your first successful MegaETH RPC requests without touching live assets.

This guide stays read-only on purpose. It is meant to confirm connectivity, show the basic response shapes, and get you to the right next page quickly.

For request-envelope, batch, notification, and shared response rules, use [JSON-RPC Basics](json-rpc-basics.md).

## Before You Start

Use one endpoint:

- Mainnet: `https://mainnet.megaeth.com/rpc`
- Testnet: `https://testnet.megaeth.com/rpc`

If you are testing new code, prefer testnet first.

## 1. Confirm The Endpoint Works

```bash
curl -sS https://mainnet.megaeth.com/rpc \
  -H 'content-type: application/json' \
  --data '{"jsonrpc":"2.0","id":1,"method":"eth_blockNumber","params":[]}'
```

Success looks like:

```json
{"jsonrpc":"2.0","id":1,"result":"0x..."}
```

You do not need a specific block number here. You only need a successful JSON-RPC response with a hex `result`.

## 2. Verify The Connected Network

Do not assume the chain. Ask the endpoint.

```bash
curl -sS https://mainnet.megaeth.com/rpc \
  -H 'content-type: application/json' \
  --data '{"jsonrpc":"2.0","id":2,"method":"eth_chainId","params":[]}'
```

```json
{"jsonrpc":"2.0","id":2,"result":"0x10e6"}
```

`0x10e6` (4326) is MegaETH mainnet. If you see a different value, check your endpoint URL.

## 3. Read Account State

Replace the address below with the account you care about.

```bash
curl -sS https://mainnet.megaeth.com/rpc \
  -H 'content-type: application/json' \
  --data '{"jsonrpc":"2.0","id":3,"method":"eth_getBalance","params":["0x0000000000000000000000000000000000000000","latest"]}'
```

Expected result shape:

```json
{"jsonrpc":"2.0","id":3,"result":"0x..."}
```

## 4. Before Querying Logs Or Running Backfills

Before you query logs or run older-state backfills, read the operating limits first. On public MegaETH RPC, large scans can fail because of range, response-size, or rate-limit constraints.

- [eth_getLogs reference](api/eth_getLogs.md)
- [Operations and limits](operations/limits.md)

## 5. Next Steps

Pick the next page based on what you are building:

- Understand request envelopes, batch requests, and error bodies: [JSON-RPC Basics](json-rpc-basics.md)
- Read contract state: [eth_call](api/eth_call.md)
- Estimate a transaction: [eth_estimateGas](api/eth_estimateGas.md)
- Query logs: [eth_getLogs](api/eth_getLogs.md)
- Send transactions: [eth_sendRawTransactionSync](api/eth_sendRawTransactionSync.md)
- Choose the right network and endpoint: [Choose Network And Endpoint](guides/choose-an-endpoint.md)
- Handle rate limits and large queries: [Handle Rate Limits And Large Queries](guides/rate-limits.md)
- Debug failures: [Error reference](errors.md)
