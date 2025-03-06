# Mini Blocks and EVM Blocks

MegaETH has two types of blocks: mini blocks and EVM blocks. EVM blocks are identical to their counterparts in other EVM chains, ensuring compatibility with existing tools and applications. Mini blocks are specific to MegaETH and anchor an ecosystem of applications, tools, and infrastructure propose-built for minimum end-to-end latency.

## Why Mini Blocks

Handling blocks at 10 millisecond intervals requires a significant amount of resources. While software optimizations and powerful hardware give the sequencer ample headroom to produce 100 blocks per second, pushing the data to the other nodes, especially ones with limited connectivity, quickly becomes a bottleneck.

The key issue with standard EVM blocks is that their headers take up quite some space—more than 500 bytes per block. In comparison, at 10,000 transactions per second, each block is expected to contain 100 transactions, so the block header adds 5 bytes of overhead per transaction. The overhead is even higher at lower throughput.

Besides the resource overhead, the standard EVM block header is designed for chains whose block times are seconds or higher as well as light clients who use block headers as the sole root of trust. For example, timestamps have one second resolution, and the multiple Merkle roots optimize for succinctness of Merkle proofs rather than compactness of the headers. We believe that interactions with a chain in realtime—at tens of milliseconds of latency—will take on a different paradigm, and it is the opportunity to redesign the block for compactness and low latency. 

## What Are Mini Blocks

## Comparison with EVM Blocks

### Similarities

- Both mini blocks and EVM blocks are totally ordered. Just like EVM blocks, mini blocks are ordered by their heights. There is at most one mini block  

### Differences

## Quick Facts