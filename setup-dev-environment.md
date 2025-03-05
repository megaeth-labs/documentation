# Setup The Development Environment 

# Install Prerequisites
## Homebrew
<details>
  <summary>What is it?</summary>
  Homebrew is a package manager for macOS that makes it easy to install much of the software below.
</details>


Run the following command from your terminal: 
```
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
```

To verify installation, run: 
```
brew --version   # you should see a version number
```
If you get an error saying ```zsh: command not found: brew```, it means that Homebrew is not in your system's PATH, so your terminal does not recognize ```brew``` as a command. To add Homebrew to your PATH, run:
```
echo 'eval "$(/opt/homebrew/bin/brew shellenv)"' >> ~/.zprofile
eval "$(/opt/homebrew/bin/brew shellenv)"
```
Verify the fix by using the step above.


## Node.js and npm
<details>
    <summary>What are they?</summary>

  **Node.js**  is an open source JavaScript runtime enviornemnt that allows developers to run JavaScript code outside of a web browser. This is widely used in backend and blockchain development

**Node Package Manager (npm)** is a packafe manager for Node.js which delps developers install, manage and share JavaScript libraries and dependencies. This will be important for managing frameworks like Hardhat and ethers.js. 
</details>

Run: 
``` 
brew install node
```


To verify the installation, run:
``` 
node -v  # Should return the Node.js version
npm -v   # Should return the npm version
``` 

## Ethers.js
<details>
  <summary>What is it?</summary>
  Ethers.js is a lightweight JavaScript library for building dApps and deploying smart contracts. 
</details>

Run: 
```
npm install -g hardhat @nomicfoundation/hardhat-toolbox ethers dotenv
```
To verify the installation, run:
```
npm list -g ethers   # you should see a dependency tree with ethers@6.13.5 at the bottom (version number may differ)
```



# Set Up Solidity Development Framework
## Option 1: Hardhat
This is the most popular framework for EVM development. To install, run:
```
mkdir megaeth_hardhat_test && cd megaeth_hardhat_test
npm init -y
npm install --save-dev hardhat
npx hardhat
```

When prompted with the following:
```
? What do you want to do? … 
❯ Create a JavaScript project
  Create a TypeScript project
  Create a TypeScript project (with Viem)
  Create an empty hardhat.config.js
  Quit
```
select ```create a JavaScript project```. Hit ENTER when when asked to select a project root:
```
✔ Hardhat project root: · /Users/testnetdocs/megaeth-contract/megaeth-contract
```
And opt ```Y``` for the remaining two questions:
```
✔ Do you want to add a .gitignore? (Y/n) · y
✔ Do you want to install this sample project's dependencies with npm (hardhat @nomicfoundation/hardhat-toolbox)? (Y/n) · y
```

To verify installation, run:
```
npx hardhat --version # you should see a verion number
```
<details>
<summary>If you're getting an unsupported Node.js warning</summary>
It's possible that hardhat does not support the latest version of Node.js that you installed. if this is the case, you need to downgrade to a stable LTS version. To do this, run:
    
```
curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.4/install.sh | bash

```
    
    Then run:
``` 
    nvm install 20
nvm use 20
node -v  # Should return "v20.x.x"
```
    
    
    
</details>


To verify that it compiles correctly, run:
```
npx hardhat compile   # you should see a message stating that it compiled successfully
```



## **Option 2: Foundry**
Foundry is a Rust-based, high-performance optimized development toolchain for Ethereum. To install, run:
```
curl -L https://foundry.paradigm.xyz | bash
```

After installation, foundry may not be recognized immediately. Run:
```
source ~/.zshenv    # expect no response
foundryup           # expect no response
```
Create a new Foundry project:
```
 forge init megaeth_foundry_test && cd megaeth_foundry_test
```


To verify the installation, run:
```
forge --version # should return a version number, commit SHA, build timestamp and build profile.
```



# Configure Wallet and Get Testnet ETH
## [Wallet](https://https://hackmd.io/@r3LiMJ7TSGmd1Jsi9FMX1A/Byf7-Opt1l)
##  [Faucet](https://hackmd.io/@r3LiMJ7TSGmd1Jsi9FMX1A/rkIjbuat1e) 

# Configure Development Enviornment
## Set Up Envirnoment Variables 
For security, you should create an ```.env``` file to store private keys and sensitive data. Begin by navigating to the appropriate folder (```megaeth_hardhat_test``` or ```megaeth_foundry_test``` depending on your chosen framework). If you're using Hardhat, you will need to install ```dotenv``` ( a module to load ```.env``` files). 
```
npm install dotenv   #ignore this step if you're using Foundry
```

To create the file, run:
```
touch .env # creates the file
```
```
nano .env # allows you to edit the file
```
add the following information (for the must up to date RPC and WS URLs, refer to the [Network & RPC Configuration](https://hackmd.io/@r3LiMJ7TSGmd1Jsi9FMX1A/HyUno8ys1g) page):
```
PRIVATE_KEY="<your_private_key>"
MEGAETH_RPC="<desired_RPC_URL>"
MEGAETH_WS="<desired_WS_URL>"
```
Save and exit by pressing ```CTRL + X```, then ```Y```, then ```ENTER```.

If you're using Hardhat, you should be all set. Idf you're using Foundry, you will need to manually load the ```.env``` file:
```
export $(grep -v '^#' .env | xargs)
```
To verify that the ```.env``` file loaded correctly, run:
```
echo $MEGAETH_RPC  # Should output the RPC URL
```


## Configure Hardhat for MegaETH
We need to update the ```hardhat.config.js``` file with the network configuration info we put into the ```.env``` file. To do this, run:
```
nano hardhat.config.js
```
and replace all its contents with:
```
require("dotenv").config();
require("@nomicfoundation/hardhat-toolbox");

module.exports = {
  solidity: "0.8.28",
  networks: {
    megaeth: {
      url: process.env.MEGAETH_RPC,  // Uses RPC URL from .env
      accounts: [process.env.PRIVATE_KEY], // Loads private key from .env
    },
  },
};
```
Save and exit (```CTRL + X```, then ```Y``` then ```ENTER```). 



## Configure Foundry for MegaETH
We need to update the ```foundry.toml``` file with the network configuration info we put into the ```.env``` file. To do this, run:
```
nano foundry.toml
```
and replace all its contents with:
```
[profile.default]
src = 'src'
out = 'out'
libs = ['lib']

[rpc_endpoints]
megaeth = "${MEGAETH_RPC}"
```
Save and exit (```CTRL + X```, then ```Y``` then ```ENTER```). 

## Verify RPC Connection 
### Hardhat
Run: 
```
npx hardhat console --network megaeth
```

This will open an interactive JavaScript console connected to the MegaETH testnet. Lets start by verifying the network connection:
```
(await ethers.provider.getNetwork()).chainId.toString();  # You should see the Chain ID
```

Next, retrieve your wallet address:
```
const [deployer] = await ethers.getSigners();
deployer.address;                               # you should see your address
```
Lastly, check wallet balance:
```
ethers.formatEther(await ethers.provider.getBalance(deployer.address))   # you should see your balance
```

### Foundry
 
Let's start by verifying the network connection:
```
cast rpc eth_chainId --rpc-url $MEGAETH_RPC 
   # you should see the chainID
```
Next, retrieve your wallet address:
```
cast wallet address $PRIVATE_KEY                # you should see your address
```
Lastly, check your wallet balance: 
```
ADDRESS=$(cast wallet address $PRIVATE_KEY)
cast balance $ADDRESS --rpc-url $MEGAETH_RPC    # you should see your balance
```

<details>
    <summary>Why are my ChainID and balance a little different?</summary>
    
**ChainID:** Hardhat returns it as a decimal number whereas Foundry returns it as a hexadecimal number.  
    
**Balance:** Hardhat returns it in ETH whereas Foundry returns it im wei. 
</details>
