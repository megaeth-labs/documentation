---
title: Mini Blocks
---

MegaETH has two types of blocks: mini blocks and EVM blocks. EVM blocks are identical to their counterparts in other EVM chains, ensuring compatibility with existing tools and applications. Mini blocks are specific to MegaETH and anchor an ecosystem of applications, tools, and infrastructure propose-built for minimum end-to-end latency.

# Motivation 

Handling blocks at 10 millisecond intervals requires a significant amount of resources. While software optimizations and powerful hardware give the sequencer ample headroom to produce 100 blocks per second, pushing the data to other nodes, especially ones with limited connectivity, quickly becomes a bottleneck.

The key issue with standard EVM blocks is that their headers take up quite some space—more than 500 bytes per block. At 100 blocks per second, this translates to 1.57 TB of data per year just for the headers, a significant burden for lightweight setups.

Besides the resource overhead, the standard EVM block header is designed for chains whose block times are seconds or higher as well as light clients who use block headers as the sole root of trust. For example, timestamps have one second resolution, and the multiple Merkle roots optimize for succinctness of Merkle proofs rather than compactness of the headers. We believe that interactions with a chain in realtime—at tens of milliseconds of latency—will take on a different paradigm, and it is the right opportunity to redesign blocks for compactness and low latency.

# Properties of Mini Blocks 

Mini blocks share a lot of similarities with EVM blocks. Like EVM blocks,

- Mini blocks are ordered lists of transactions executed and preconfirmed by the sequencer.
- Mini blocks contain every transaction that has been processed by the system. That is, every transaction appears in one mini block and one EVM block.
- Mini blocks are totally ordered by their block height, starting with 0 at the genesis.
- Preconfirmation of mini blocks by the sequencer has the same level of guarantees as EVM blocks.

On the other hand, there are some key differences

- Mini blocks contain a different set of metadata fields compared to EVM blocks.
- To make effective use of mini blocks, such as retrieving mini blocks with minimum latency, applications should use the [Realtime API](realtime-api.md)—MegaETH’s extension to the standard Ethereum JSON-RPC API.

Transactions in a mini block never span multiple EVM blocks. In other words, for every mini block, the transactions it contains all appear in the same EVM block. Naturally, this establishes a mapping between mini blocks and EVM blocks; we say a mini block is _included_ in an EVM block if the former contains transactions that appear in the latter.

MegaETH produces an EVM block roughly every second and a mini block roughly every 10 milliseconds. This implies a rough 1-to-100 ratio between the number of EVM blocks and the number of mini blocks. However, there is no guarantee on the number of mini blocks included in an EVM block. To get the precise number, developers should use the `miniBlockCount` field in the responses when calling `eth_subscribe` to subscribe to `newHeads`. This is an example of the responses:

```json
{
  ...
  "number": "0x57f898",
  "miniBlockCount": "0x57"
  ...
}
```
