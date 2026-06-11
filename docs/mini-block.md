---
description: MegaETH mini-blocks — what they are, how they differ from EVM blocks, and what they mean for your application.
---

# Mini-Blocks

MegaETH produces two types of blocks: **Mini-blocks** and **EVM blocks**.

- **Mini-blocks** are produced every ~10 milliseconds.
  They are MegaETH-specific and designed for sub-second transaction confirmations.
- **EVM blocks** are produced every ~1 second.
  They are identical to standard Ethereum blocks and compatible with all existing tools, wallets, and indexers.

Every transaction appears in exactly one mini-block and exactly one EVM block.
Mini-blocks give you the result faster; EVM blocks give you the standard Ethereum data format.

## Why Mini-Blocks Exist

Handling blocks at 10 millisecond intervals requires significant resources.
Software optimizations and powerful hardware give the sequencer ample headroom to produce 100 blocks per second, but pushing the data to other nodes — especially ones with limited connectivity — quickly becomes a bottleneck.

The key issue is that standard EVM block headers take up quite some space — more than 500 bytes per block.
At 100 blocks per second, this translates to 1.57 TB of data per year just for the headers, a significant burden for lightweight setups.

Beyond the resource overhead, the standard EVM block header is designed for chains whose block times are seconds or higher, as well as light clients who use block headers as the sole root of trust.
Timestamps have one-second resolution, and the multiple Merkle roots optimize for succinctness of Merkle proofs rather than compactness of the headers.

Interacting with a chain in realtime — at tens of milliseconds of latency — calls for a different paradigm.
Mini-blocks redesign the block format for compactness and low latency: compact headers, microsecond-resolution timestamps, and only the data needed for real-time streaming.

## What This Means in Practice

For most users and developers, mini-blocks are invisible — your wallet, your toolchain, and your contracts all work with standard EVM blocks as they would on any other chain.
No code changes are needed.

Where mini-blocks matter is latency.
A transaction is confirmed in ~10 milliseconds, not 1 second.
Wallets and applications that subscribe to mini-blocks via the [Realtime API](dev/read/realtime-api.md) can show results almost instantly — useful for trading, gaming, real-time feeds, and anything where milliseconds count.

## How Mini-Blocks Work

The sequencer executes transactions continuously.
Every ~10ms, it seals the executed transactions into a mini-block and streams the results — receipts, state changes, event logs — to RPC nodes across the network.
RPC nodes make these results available to applications immediately, before the EVM block is sealed.

Every ~1 second, the sequencer seals an EVM block containing all the mini-blocks produced during that interval.
The EVM block includes a standard Ethereum block header with Merkle roots, bloom filters, and all the fields that Ethereum tooling expects.

```
Time ──────────────────────────────────────────────────────────►
│ mini-block 0 │ mini-block 1 │ ... │ mini-block ~99 │
└──────────────────────── EVM block N ──────────────────────────┘
```

## Properties of Mini-Blocks

Mini-blocks share the core properties you would expect from any block:

- **Ordered.** Mini-blocks are totally ordered by height, starting from 0 at genesis.
- **Complete.** Every transaction processed by the sequencer appears in exactly one mini-block.
- **Preconfirmed.** A transaction included in a mini-block carries the same preconfirmation guarantee as one included in an EVM block — the sequencer has committed to its ordering and result, and [signs every mini-block header](#sequencer-signatures) to make that commitment verifiable.

Where they differ from EVM blocks:

| Property                       | EVM Block   | Mini-Block                                                                                               |
| ------------------------------ | ----------- | -------------------------------------------------------------------------------------------------------- |
| Production interval            | ~1 second   | ~10 milliseconds                                                                                         |
| Header size                    | ~500+ bytes | Compact (no state root, no bloom filter)                                                                 |
| Timestamp resolution           | 1 second    | Microsecond (via [High-Precision Timestamp](dev/execution/system-contracts.md#high-precision-timestamp)) |
| Compatible with standard tools | Yes         | Requires [Realtime API](dev/read/realtime-api.md)                                                        |
| Contains state root            | Yes         | No                                                                                                       |

## Sequencer signatures

The preconfirmation guarantee is not just a promise — it is cryptographically enforced.
The sequencer signs every mini-block header with its sequencer key, and the signature is delivered alongside the mini-block in the [Realtime API](dev/read/realtime-api.md) stream.
A signed mini-block is a binding commitment: if the sequencer ever sealed an EVM block that contradicts a mini-block it signed, anyone holding the signed header could prove the misbehavior.

The signing key is registered onchain in the [SequencerRegistry](https://docs.megaeth.com/spec/system-contracts/sequencer-registry) system contract at `0x6342000000000000000000000000000000000006`, introduced in Rex5.
The key can be rotated by scheduling a change in the registry; rotations take effect at an EVM block boundary, and the full change history remains queryable onchain.

The signature is a standard secp256k1 ECDSA signature over `keccak256(rlp(header))`, where the header is the following eight fields of the [`miniBlocks` subscription payload](dev/read/rpc/eth_subscribe.md#miniblocks), RLP-encoded in this order:

| #   | Payload field          | Type         |
| --- | ---------------------- | ------------ |
| 1   | `block_number`         | integer      |
| 2   | `block_timestamp`      | integer      |
| 3   | `index`                | integer      |
| 4   | `mini_block_number`    | integer      |
| 5   | `mini_block_timestamp` | integer      |
| 6   | `gas_used`             | integer      |
| 7   | `transaction_root`     | 32-byte hash |
| 8   | `receipt_root`         | 32-byte hash |

Integers are RLP-encoded in their minimal big-endian form.
The signature is verifiable onchain with `ecrecover`.
The `signature` field of the payload carries the components as an object: `r`, `s`, and `yParity`.

{% hint style="info" %}
Mini-blocks produced before Rex5 are unsigned — the `signature` field is absent from their payloads.
{% endhint %}

### Verifying a mini-block signature

To verify a mini-block, rebuild the header hash, recover the signer from the signature, and compare it against the sequencer key registered onchain.

The example below uses [viem](https://viem.sh) and takes a notification payload `mb` exactly as delivered by the [`miniBlocks` subscription](dev/read/rpc/eth_subscribe.md#miniblocks).

```typescript
import {
  createPublicClient,
  http,
  keccak256,
  toRlp,
  recoverAddress,
  parseAbi,
} from "viem";

const client = createPublicClient({
  transport: http("https://mainnet.megaeth.com/rpc"),
});

// RLP integer form: minimal big-endian bytes; zero is the empty byte string
const int = (hex: `0x${string}`): `0x${string}` => {
  let h = BigInt(hex).toString(16);
  if (h === "0") return "0x";
  return `0x${h.length % 2 ? "0" + h : h}`;
};

// `mb` is a notification payload from the `miniBlocks` subscription
async function isSignedBySequencer(mb: any): Promise<boolean> {
  // 1. Rebuild the signed digest: keccak256(rlp(header))
  const hash = keccak256(
    toRlp([
      int(mb.block_number),
      int(mb.block_timestamp),
      int(mb.index),
      int(mb.mini_block_number),
      int(mb.mini_block_timestamp),
      int(mb.gas_used),
      mb.transaction_root,
      mb.receipt_root,
    ]),
  );
  // 2. Recover the signer from the raw digest (no EIP-191 prefix)
  const signer = await recoverAddress({ hash, signature: mb.signature });
  // 3. Look up the sequencer key that was active for this block
  const sequencer = await client.readContract({
    address: "0x6342000000000000000000000000000000000006",
    abi: parseAbi(["function sequencerAt(uint256) view returns (address)"]),
    functionName: "sequencerAt",
    args: [BigInt(mb.block_number)],
  });
  return signer.toLowerCase() === sequencer.toLowerCase();
}
```

When verifying historical mini-blocks, use `sequencerAt(blockNumber)` rather than `currentSequencer()` — the sequencer key can rotate, and the registry resolves which key was active at any block.
`currentSequencer()` is sufficient when verifying live mini-blocks as they stream in.

{% hint style="warning" %}
A valid signature proves the sequencer committed to the mini-block's contents — it does not by itself prove finality.
Full finality still depends on the containing EVM block being posted to and finalized on the L1.
{% endhint %}

## Relationship to EVM Blocks

Every mini-block belongs to exactly one EVM block — its transactions never span multiple EVM blocks.
The ratio is roughly 1 EVM block to ~100 mini-blocks, but the exact count varies.
To get the precise number, use the `miniBlockCount` field in the `newHeads` subscription response:

```json
{
  "number": "0x57f898",
  "miniBlockCount": "0x57"
}
```

## Subscribing to Mini-Blocks

To take advantage of mini-block latency, subscribe over WebSocket using the [Realtime API](dev/read/realtime-api.md):

```json
{
  "jsonrpc": "2.0",
  "id": 1,
  "method": "eth_subscribe",
  "params": ["miniBlocks"]
}
```

Each notification delivers the mini-block's transactions, receipts, and state changes — everything your application needs to react immediately, without waiting for the next EVM block.

## Related Pages

- [Architecture](architecture.md) — how transactions flow through the MegaETH network
- [Realtime API](dev/read/realtime-api.md) — subscribe to mini-blocks and get execution results with minimum latency
- [eth_subscribe](dev/read/rpc/eth_subscribe.md) — full reference of the `miniBlocks` subscription payload
- [High-Precision Timestamp](dev/execution/system-contracts.md#high-precision-timestamp) — microsecond timestamps available within mini-blocks
- [SequencerRegistry (spec)](https://docs.megaeth.com/spec/system-contracts/sequencer-registry) — onchain registry of the sequencer signing key
