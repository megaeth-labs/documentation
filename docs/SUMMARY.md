# Table of contents

* [Home](README.md)
* [Architecture](architecture.md)
* [Mini-Blocks](mini-block.md)

## User Guide

* [Get Started](user/get-started.md)
* [Connect to MegaETH](user/connect.md)
* [Get Funds on Mainnet](user/bridge.md)
* [Get ETH on Testnet](user/faucet.md)
* [Featured Apps](user/apps.md)
* [User FAQ](user/faq.md)

## Developer Docs

* [Overview](dev/overview.md)

### Send Transaction

* [Contracts & Tokens](dev/send-tx/contracts.md)
* [Gas Estimation](dev/send-tx/gas-estimation.md)
* [Debugging Transactions](dev/send-tx/debugging.md)

### Read from MegaETH

* [RPC](dev/read/rpc/overview.md)
  * [eth\_subscribe](dev/read/rpc/eth_subscribe.md)
  * [eth\_callAfter](dev/read/rpc/eth_callAfter.md)
  * [eth\_getLogsWithCursor](dev/read/rpc/eth_getLogsWithCursor.md)
  * [realtime\_sendRawTransaction](dev/read/rpc/realtime_sendRawTransaction.md)
  * [Error Codes](dev/read/rpc/error-codes.md)

### Low Latency

* [Realtime API](dev/low-latency/realtime-api.md)

### Transaction Execution

* [EVM Differences](dev/execution/evm-differences.md)
* [Gas Model](dev/execution/gas-model.md)
* [Resource Limits](dev/execution/resource-limits.md)
* [Volatile Data Access](dev/execution/volatile-data.md)
* [System Contracts](dev/execution/system-contracts.md)

### Resources

* [Developer FAQ](dev/faq.md)
* [Tooling & Infrastructure](dev/tooling.md)

## Specification

* [Overview](spec/overview.md)
* [Hardforks and Specs](spec/hardfork-spec.md)
* [MegaEVM](spec/evm/overview.md)
  * [Dual Gas Model](spec/evm/dual-gas-model.md)
  * [Resource Limits](spec/evm/resource-limits.md)
  * [Resource Accounting](spec/evm/resource-accounting.md)
  * [Gas Detention](spec/evm/gas-detention.md)
  * [Gas Forwarding](spec/evm/gas-forwarding.md)
  * [SELFDESTRUCT](spec/evm/selfdestruct.md)
  * [Contract Limits](spec/evm/contract-limits.md)
  * [Precompiles](spec/evm/precompiles.md)
* [System Contracts](spec/system-contracts/overview.md)
  * [Call Interception](spec/system-contracts/interception.md)
  * [Mega System Transactions](spec/system-contracts/system-tx.md)
  * [Oracle](spec/system-contracts/oracle.md)
  * [High-Precision Timestamp](spec/system-contracts/high-precision-timestamp.md)
  * [Keyless Deployment](spec/system-contracts/keyless-deploy.md)
* [Network Upgrades](spec/upgrades/overview.md)
  * [MiniRex](spec/upgrades/minirex.md)
  * [Rex](spec/upgrades/rex.md)
  * [Rex1](spec/upgrades/rex1.md)
  * [Rex2](spec/upgrades/rex2.md)
  * [Rex3](spec/upgrades/rex3.md)
  * [Rex4](spec/upgrades/rex4.md)
* [Glossary](spec/glossary.md)
