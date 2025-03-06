# Architecture Overview

The complete MegaETH system will consist of the following logical components:

**Sequencers.** Users’ transactions (write requests) coming into the system end up with them. They execute users’ transactions, assemble executed transactions into blocks, and disseminate execution results such as transaction receipts and state changes. They also submit the blocks to the L1 for finality.

**Read replicas.** They maintain replicas of the chain’s state and (recent) history to service read requests. They may also choose to screen write requests by validating them against local replicas of the chain’s state. Depending on how a replica maintains the state and the history, there are two types of nodes.
- *Replica nodes.* They receive new blocks and execution results and apply them to local replicas of the chain’s state and history without validation.
- *Full nodes.* They receive new blocks, locally re-execute the blocks, and update local replicas of the chain’s state and history.

**Provers.** They receive new blocks, locally re-execute the blocks, and generate proofs for the blocks. These proofs might be fault proofs or validity proofs, depending on how the chain is operated.

**Data availability (DA) service.** When a sequencer produces a block, it must submit to the DA service any associated data that the rest of the network depends on to process the block; the DA service will return a receipt certifying that the data is received and make the data publicly available for a finite period of time. Without the receipt, the sequencer cannot submit the block to the L1. The DA service ensures that replica nodes and full nodes can keep up with the chain’s state, and prover nodes can produce proofs for any block that is submitted to the L1, even if the sequencer maliciously withholds data.

The current phase of the MegaETH Testnet contains the following components:
- One sequencer
- Multiple replica nodes maintained by MegaETH to serve RPC requests
- EigenDA devnet as the DA service
- An Ethereum devnet as the L1

Upcoming phases of the Testnet will introduce
- Multiple sequencers for failover and rotation
- Permissionless full nodes
- Permissionless replica nodes
- Permissionless prover nodes running in optimistic (fault proof) mode
- Ethereum Testnet as the L1