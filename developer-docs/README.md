# MegaETH RPC

Use these docs to make correct MegaETH RPC requests with as little guesswork as possible.

## Endpoints

| Network | HTTP | WebSocket | Use when |
|---------|------|-----------|----------|
| Mainnet | `https://mainnet.megaeth.com/rpc` | `wss://mainnet.megaeth.com/ws` | Production traffic |
| Testnet | `https://carrot.megaeth.com/rpc` | `wss://carrot.megaeth.com/ws` | Development and testing |

If you are unsure which network you reached, verify it with [`eth_chainId`](api/eth_chainId.md).

## Public Access

Published public HTTP endpoints currently accept anonymous JSON-RPC requests.

- A basic POST request succeeds without an API key or `Authorization` header.
- The public HTTP endpoint currently returns `Access-Control-Allow-Origin: *`.
- Public-gateway rate limits and availability still apply. This docs set does not currently publish a private authenticated tier or SLA.

## First Request

Use [Quickstart](QUICKSTART.md) to make your first read-only request, verify the connected chain, and confirm the basic response shapes before moving to heavier methods.

## Start Here

If you are new to MegaETH RPC, read these in roughly this order:

1. [Quickstart](QUICKSTART.md)
2. [Choose Network And Endpoint](guides/choose-an-endpoint.md)
3. [JSON-RPC Basics](json-rpc-basics.md)
4. [Error reference](errors.md)
5. [API Reference](api/README.md)

Keep these shared references nearby:

- [Type reference](types.md)
- [Operations and limits](operations/limits.md)
- [Handle rate limits and large queries](guides/rate-limits.md)
- [Realtime development guide](guides/realtime.md)

## Common Tasks

- [Read an account balance](api/eth_getBalance.md)
- [Read contract state](api/eth_call.md)
- [Estimate a transaction](api/eth_estimateGas.md)
- [Query logs safely](api/eth_getLogs.md)
- [Send a signed transaction and wait for its receipt](api/eth_sendRawTransactionSync.md)
- [Subscribe to realtime events (WebSocket)](api/eth_subscribe.md)
- [Build with realtime state](guides/realtime.md)
- [Diagnose older-state failures](guides/choose-an-endpoint.md#2-when-older-state-reads-fail)
- [Handle rate limits and large queries](guides/rate-limits.md)
