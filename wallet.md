# Set Up and Connect a Wallet 
# Testnet Notice

MegaETH is currently in **testnet**, which means the following for wallets:

- Manual network configuration may be required.
- Wallet balances and transaction history may reset due to network upgrades or resets.
- Some wallets may not automatically detect testnet tokens.
- Certain wallet features may not be supported or may behave unpredictably.
- Testnet tokens have no real-world value and cannot be bridged to mainnet.

**To learn more about the implications of being on testnet and our rollout roadmap, see [Network Phases](https://hackmd.io/zTV7ghoXRqWLLT8W5UN9BQ#Network-Phases).**


# What is a Wallet?

A crypto wallet is a tool which allows a user to store, send and receive digital assets (think tokens and NFTs) securely. 

### Private Key

The core of every wallet is the private key (privkey)—a 256 bit string of alphanumeric characters which is unique to you and should never be shared. The public key:

- Allows you to sign transactions and authorize asset transfers.
- Uses elliptic curve cryptography to derive a corresponding public key (pubkey).

> While a privkey can generate a pubkey, it's mathematically impossible to discover a privkey from a pubkey.
> 

### Public Key and Wallets Address

A pubkey is mathematically linked to a privkey, but can be shared freely. However, due to pubkey’s long and complex nature, wallets use a shorter hashed version called a waller address. This is what is shared to receive funds. 

> The primary purpose of the pubkey is to allow others to verify that a digital signature was created by the corresponding privkey— without revealing the privkey itself.
> 

### Signing and Verifying Transactions

When a transaction is sent:

1. The wallet signs the transaction using a privkey, creating a digital signature. 
2. The network verifies the transaction using the corresponding pubkey.
3. If the signature is valid, the transaction is added to the blockchain. 

This flow ensures that, while anyone can verify the authenticity of a transactions without knowing the privkey, only the privkey holder can initiate said transactions. 

### A Wallet is Closer to a Crypto Keyring

The term ‘wallet’ is actually a bit of a misnomer, as all crypto assets live on blockchains, and the only thing a user holds is a set of keys which prove their ownership of the assets. When you receive tokens, nothing is actually deposited into you wallet, rather, the blockchain updates its records to reflect your ownership. 

> See FAQs section for more details on wallets.




# Manual Network Configuration

Before native wallet support is live, you must manually configure your wallet to connect to the MegaETH testnet. 

### Rabby 

1. Click on the **More** icon.
2. Go to **Settings** → **Networks.**
3. Click **Add Custom Network.**
4. Enter the following details.
    
    
    | Network Name: | MegaETH Testnet |
    | --- | --- |
    | RPC URL: | `https://burrow.megaeth.com:10547/07ie2L8FUzu97apwY7ZHy0hOeAarjHbK/` |
    | Chain ID: | 1338 |
    | Currency Symbol: | MGA |
    | Block Explorer: | `https://www.okx.com/web3/explorer/megaeth-testnet`  (Optional) |
5. Click **Save** and switch to the **MegaETH** network.

![Screenshot 2025-02-12 at 5.14.17 AM.png](attachment:7f39c668-6dcb-49a7-823f-b538d237d4d1:Screenshot_2025-02-12_at_5.14.17_AM.png)

![Screenshot 2025-02-12 at 5.16.07 AM.png](attachment:ea674246-7160-4fd1-9564-4ca17649a641:Screenshot_2025-02-12_at_5.16.07_AM.png)

![Screenshot 2025-02-12 at 5.16.20 AM.png](attachment:ffe1159a-dc6b-46f6-af5c-c6931d215488:Screenshot_2025-02-12_at_5.16.20_AM.png)

![Screenshot 2025-02-12 at 5.16.33 AM.png](attachment:bf5c9e22-491e-4a3b-b522-0d78b024ce33:Screenshot_2025-02-12_at_5.16.33_AM.png)

### Other Wallets

If you’re using a different EVM-compatible wallet, follow a similar process to manually configure the network

> Note: If your wallet requires an RPC URL with a username and password, use the following format instead: `https://megabunny:f13mi5h9iant@burrow.megaeth.com:10545`
> 

# Common Errors and Troubleshooting

# FAQs

**Is my wallet address anonymous?** 

**What’s an ENS?**

**Should I get a hard wallet?**

**What’s a secret phrase?**

**How can you be sure that no one can reverse engineer my privkey from my pubkey?**


<div style="display: flex; justify-content: space-between; margin-top: 40px;">
  <a href="https://hackmd.io/1so5MP3ZRJiVKuXHg4aaVQ#Network-Overview" 
     style="padding: 20px 40px; font-size: 16px; font-weight: bold; border: 1px solid #ddd; text-decoration: none; border-radius: 10px; display: inline-block; text-align: left; width: 350px; color: black;">
    <span style="font-size: 14px; color: #6c757d;">Previous</span><br>
    <span style="font-size: 18px; color: #5c3cff;">« Network Overview</span>
  </a>
  <a href="https://hackmd.io/ZMe52In5SfqIwfoNHpsl5g#Aquire-Tokens" 
     style="padding: 20px 40px; font-size: 16px; font-weight: bold; border: 1px solid #ddd; text-decoration: none; border-radius: 10px; display: inline-block; text-align: right; width: 350px; color: black;">
    <span style="font-size: 14px; color: #6c757d;">Next</span><br>
    <span style="font-size: 18px; color: #5c3cff;">Aquire Tokens  »</span>
  </a>
</div>

