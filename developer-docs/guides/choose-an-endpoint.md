# Choose Network And Endpoint

Use this guide before you wire a client to MegaETH, or when the same request behaves differently depending on where you send it.

## Make The Decision In This Order

1. Choose the network.
2. Verify that the endpoint you chose can serve the state range you need.

## 1. Choose The Network

| Network | HTTP | WebSocket | Use when |
|---|---|---|---|
| Mainnet | `https://mainnet.megaeth.com/rpc` | `wss://mainnet.megaeth.com/ws` | Production traffic on the live chain |
| Testnet | `https://carrot.megaeth.com/rpc` | `wss://carrot.megaeth.com/ws` | Development, testing, and first integrations |

Reader rules:

- Mainnet and testnet are the published public HTTP and WebSocket endpoints in this docs set.
- If you are still validating a client, prefer testnet first unless you specifically need mainnet state.
- Verify the connected chain with [`eth_chainId`](../api/eth_chainId.md) instead of assuming the URL tells the whole story.

### WebSocket

WebSocket connections support only [`eth_subscribe`](../api/eth_subscribe.md), [`eth_unsubscribe`](../api/eth_unsubscribe.md), [`eth_sendRawTransaction`](../api/eth_sendRawTransaction.md), [`eth_sendRawTransactionSync`](../api/eth_sendRawTransactionSync.md), and [`eth_chainId`](../api/eth_chainId.md). Use HTTP for all other methods.

Per-IP connection limit is 5. Each connection supports up to 5 concurrent subscriptions and idles out after 60 seconds without activity. See [`eth_subscribe`](../api/eth_subscribe.md) for full details.

## 2. When Older-State Reads Fail

Use this section when the same request works at `latest` but fails on an older block, or when an older-state backfill behaves differently from newer reads.

This matters most for:

- [`eth_getBalance`](../api/eth_getBalance.md)
- [`eth_getCode`](../api/eth_getCode.md)
- [`eth_getStorageAt`](../api/eth_getStorageAt.md)
- [`eth_getTransactionCount`](../api/eth_getTransactionCount.md)

Signals that the issue is older-state support on that endpoint rather than request shape:

| What you are seeing | What it usually means | Next move |
|---|---|---|
| Error code `4444` | The endpoint cannot serve the requested older state | Keep the request unchanged and treat it as an older-state support issue first |
| The same state read works at `latest` but fails on an older block | The issue is likely older-state support, not request shape | Keep the explicit block selector and re-check the same request carefully |
| You are reading clearly old balances, code, storage, or nonces | Older-state support can differ from latest-state reads | Confirm that this endpoint really serves the older range you need |
| A historical backfill is forcing wide scans | Availability and query shape both matter | Page the work into smaller units and verify older ranges separately |

Reader rules:

- Do not assume a dedicated older-state endpoint exists unless product docs explicitly publish one.
- Older-state support is a property of the endpoint you are already using, not a request-shape question.
- A malformed request is still malformed even when the failure is about older-state support.
- Older-state support does not remove response-size limits or rate limits by itself.

## Fast Decision Table

| If you are building... | Network | What to do next |
|---|---|---|
| First integration check | Testnet | Start with `https://carrot.megaeth.com/rpc` |
| Production read path | Mainnet | Start with `https://mainnet.megaeth.com/rpc` |
| Historical balance or storage reader | Match your target network | Verify older-state support before depending on older-block results |
| Historical backfill job | Match your target network | Page aggressively and verify older-state support first |

## Verify The Choice Before You Build On It

Before you move to a heavier method:

1. Call [`eth_blockNumber`](../api/eth_blockNumber.md).
2. Call [`eth_chainId`](../api/eth_chainId.md).
3. Only then move to your target method or workflow.

## Worked Example: Keep The Request Fixed While Diagnosing Older-State Failures

Do not change the method shape and the selector at the same time.

```bash
curl -sS https://mainnet.megaeth.com/rpc \
  -H 'content-type: application/json' \
  --data '{"jsonrpc":"2.0","id":1,"method":"eth_getBalance","params":["0x0000000000000000000000000000000000000000","0x1"]}'
```

If this fails with `4444` while the same method works at `latest`, first treat it as an older-state support issue on that endpoint, not as a parameter-shape issue.

## Common Mistakes

- hardcoding network assumptions instead of checking `eth_chainId`
- assuming a dedicated older-state endpoint exists when the product has not published one
- treating older-state support problems as random instability
- changing endpoint and request shape at the same time instead of isolating one variable
