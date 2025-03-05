# **State & Storage on MegaETH**


### Overview
Even at a conservative 10k TPS, MegaETH will be 1000x faster than Ethereum mainnet in terms of throughput, meaning we'll reach the same state size as Ethereum in just 1/1000th of the time. While we don't anticipate serious problems arising from this, we believe it would be short sighted not to have mitigation strategies in place to prevent state bloat and inefficient storage usage.


### Long Term Mitigation 
In the long run, developers will pay a periodic fee to store data on chain (state rent), helping prevent unnecessary data accumulation. As data becomes dormant, it will eventually be pruned (state expiry), freeing up storage space.

>**Why don't we start with this?** 
>MegaETH is and always will be Ethereum-aligned. The Ethereum Foundation eventually intends to implement state rent and expiry mechanisms, so we will wait for these mechanisms to be fully developed to ensure compatibility and avoid creating competing standards. 



### Short Term Mitigation 
By setting our fees to be significantly lower than any other blockchain, we run the risk that it may be 'cheap-enough' to store unnecessary data on chain. To address this, we will price certain ```sstore``` invocations differently (but always cheaper than ETH mainnet).
**1. Allocate new memory slots:** 
This is a high-risk area for abuse, as developers could allocate excessive storage. To mitigate this, we will make allocating new memory slots more expensive to discourage unnecessary allocation.
**2. Overwriting over their own storage:** 
Once a contract owns a storage slot, overwriting it with new logic will remain inexpensive. This promotes the reuse of storage rather than allocating new slots.
> **Note:** A contract can only write, or overwrite, to the storage space under its root, **so no one else can overwrite your contract.**

**3. Setting their own storage slots to 0:** 
If a contract no longer need storage space, setting the slot to 0 will free up the space for reuse, and the developer will recieve a refund proportionate to their sstore allocation fee.

### SSD Refund
When a contract sets its storage to 0 and frees up space, developers will automatically receive a refund for the storage they’ve released. This incentivizes the efficient use of storage.

### Best Practices
To prevent bloat and optimize performance, developers should be mindful of storage usage. Here are some best practices:
* **Minimize the Use of Storage Slots:** Only allocate storage when absolutely necessary.
* **Reuse Storage Slots:** Overwriting data in existing slots is efficient and reduces waste.
* **Monitor Storage Usage:** Regularly audit your contracts to track and optimize storage consumption.



