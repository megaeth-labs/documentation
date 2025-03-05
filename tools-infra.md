# **Development Tools and Infra**

##  Testnet Notice  
Many tooling and infrastructure components are still being finalized. We will monitor testnet performance and developer needs before implementing infrastructure.

---

## **Account Abstraction**  

### **EIP-4337**  
[EIP-4337](https://eips.ethereum.org/EIPS/eip-4337) enables fully decentralized smart contract wallets with features like sponsored transactions, session keys, and flexible authentication. **MegaETH supports 4337-compatible bundlers and paymasters**, allowing developers to create gasless transactions and seamless onboarding experiences.

### **EIP-7702**  
[EIP-7702](https://eips.ethereum.org/EIPS/eip-7702) introduces a new model for AA that enables smart contract wallets to temporarily function as externally owned accounts (EOAs). **MegaETH supports EIP-7702**, allowing developers to leverage gas sponsorships, account recovery mechanisms, and signature aggregation for seamless UX.  

### **Dynamic.xyz**  

### ZeroDev

### Pimlico

### Privy





---

## **Block Explorers**  
MegaETH supports **two block explorers** for tracking transactions, contracts, and network activity.

###  OKX Block Explorer  
The **OKX Block Explorer** is a third-party solution for querying MegaETH’s testnet activity.  

 **[Explore MegaETH Testnet on OKX](https://www.okx.com/web3/explorer/megaeth-testnet)**  

###  Community-Run Block Explorer  
A **MegaETH community-maintained explorer** is also available, providing additional insights and customization.  

 **[Explore MegaETH (Community Explorer)](https://www.megaexplorer.xyz)**

---

## **Oracles**  
MegaETH integrates **[RedStone](https://redstone.finance/)** to provide **high-performance, low-latency on-chain data**.

---

## **Indexers**  
High-performance blockchain indexing is **especially challenging on MegaETH** due to its **high throughput and real-time execution model**.  

- **Currently:** We are collaborating with multiple indexer providers to develop **a semi in-house indexing solution**.
- **Recommendation:** Until an official indexer is live, teams are advised to **build their own custom indexing solutions** tailored to their needs.

---

## **RPC Provision**  
MegaETH’s **node architecture is highly specialized** _(see [Node Specialization](../node-specialization))_, requiring careful RPC infrastructure design.  

- **Current Status:** We are **self-hosting our own RPC** for the testnet.
- **Future Plans:** We expect to **partner with third-party RPC providers** a few weeks after public testnet launch.


