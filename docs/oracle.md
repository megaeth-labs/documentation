---
title: Enshrined Oracle Interface
---

Enshrined Oracle Interface grants on-chain transactions low-latency access to
off-chain data. This document explains the interface for end users and oracle
providers.

# Motivation

The fundamental task of oracles is to reliably transport data from off-chain
providers to on-chain consumers. Oracles traditionally fall into two categories
with respective pros and cons.

_Push-based oracles_ publish data points through on-chain smart contracts.
Providers preemptively push new data points to the smart contracts which are
then read by consumers asynchronously. Such oracles excel in simplicity since
reading them is as simple as calling the oracle smart contracts. But, because
providers cannot predict when consumers will want to read the oracles, they
have to rely on heuristics to decide when to push new data points. Any
resulting timing mismatches between pushing and reading add to latency or cause
redundant refreshes which waste chain capacity.

_Pull-based oracles_ publish data points over off-chain streams such as
WebSocket connections. Consumers then bring data points to the blockchain on a
need basis. This mechanism minimizes latency and redundancy since consumers
upload the most recent data points exactly when they want to use them. However,
integrating with pull-based oracles can be complicated because of the added
logic on the consumer side.

Enshrined Oracle Interface combines the best of both worlds. Like push-based
oracles, it provides the same on-chain API, so integration is equally simple
and requires minimal or no change to existing applications. Meanwhile, like
pull-based oracles, data points are refreshed just before they are read by
consumers, so there is no added latency or redundancy from mismatched refreshes
and reads.

# Design

For users, an oracle built with the Enshrined Oracle Interface functions just
like a push-based oracle. A _user transaction_ can read the oracle simply by
calling a smart contract, denoted as the _oracle contract_. Under the hood, the
following happens.

First, the oracle contract, which the oracle provider develops, calls a _system
contract_ to signal to the MegaETH sequencer that the current user transaction
attempts to read the oracle. The system contract is a regular EVM smart
contract. But, instead of actually executing the system contract, the sequencer
handles the call by running an _off-chain routine_ that is pre-arranged with
the oracle provider. The purpose of the routine is to fetch the latest data
point of the oracle. For example, for an oracle that provides the current
wall-clock time, this routine can be as simple as reading the hardware clock.
The sequencer passes the result of the off-chain routine to the oracle
contract. In other words, the call made by the oracle contract to the system
contract is silently replaced by the off-chain routine, with the result of the
latter being used as the return value. At this point, the oracle contract has
obtained the latest data point of the oracle, fetched just in time using the
off-chain routine, and can return it to the user transaction after optional
validation or postprocessing.

While intercepting the call to the system contract allows the sequencer to
pause the user transaction and fetch the latest oracle data by running the
off-chain routine, other nodes cannot re-execute or validate the user
transaction just yet. For them to agree with the sequencer on its outcome, they
must arrive at the same result as the sequencer when handling the call to the
system contract. However, they cannot simply run the same off-chain routine as
the sequencer does, because the result of the routine is specific to the
context in which the sequencer runs it, and other nodes cannot reproduce the
result unless they run the routine in identical context. In the aforementioned
example of a time oracle, a node re-executing the user transaction on a
different day is bound to get a different result if it reads its hardware
clock. The sequencer must convey to other nodes the unique result it gets when
running the off-chain routine, so that they can plug in the same result when
they re-execute the remainder of the user transaction.

There are many potential ways for the sequencer to pass the information to
other nodes, such as injecting it to the block header or a new section of the
block body. Unfortunately, the sequencer is not afforded the flexibility if it
wishes to stay compatible with standard EVMs. In MegaETH, the sequencer injects
the result of the off-chain routine in a separate _system transaction_ that
appears immediately before the user transaction in the assembled block. The job
of the system transaction is to update the state of system contract, such that
the call to the system contract, triggered by the subsequent user transaction,
returns the result injected by the sequencer. In the eyes of a re-executing
node, the system transaction appears as a just-in-time write to the system
contract that causes the subsequent read to the system contract to return the
latest oracle data point. For all nodes other than the sequencer, the system
transaction and the system contract are handled as normal EVM transactions and
contracts.

# Programming Interfaces for Oracle Providers

Use of the Enshrined Oracle Interface is permissioned. Each oracle has its own
system contract whose behavior can be customized by defining the following
methods.

- $\text{validate}(k, v) \rightarrow \{\text{true}, \text{false}\}$. The oracle
  provider should use it to define how the sequencer should verify the fetched
data. $k$ is a parameter that the oracle provider may use to identify the data
point, and $v$ should be used to pass in the fetched data.
- $\text{write}(k, v)$. The oracle provider should use it to define how the
  sequencer should update the state of the system contract with the fetched
data. $k$ is a parameter that the oracle provider may use to identify the data
point, and $v$ should be used to pass in the fetched data.
- $\text{read}(k) \rightarrow \{0, 1\}*$, a view function of the system
  contract. The oracle provider should use it to define how the sequencer
returns the value associated with key $k$ given the state of the system contract.

$\text{read}(k)$ is the only method that can be called in any transaction. The other methods
can only be called by system transactions and this is enforced by a special key pair.

In addition, the interface allows the oracle provider to specify the following
off-chain routine.

- $\text{fetch}(k)$. The oracle provider should use this routine to define how
  the sequencer should fetch data for the oracle from off-chain sources. $k$ is
a parameter that the oracle provider may use to identify the data point.

The Enshrined Oracle Interface augments the behavior of the sequencer as the
following when it executes any transaction $t$ that is not a system transaction
and encounters $\text{read}(k)$.

1. Run $\text{fetch}(k)$. Let the result be $v$.
2. Run $\text{validate}(k, v)$.
    a. If it attempts to read any storage slot that has so far been written by
$t$, or write any storage slot that has so far been read by $t$, return
$\text{read}(k)$ and ignore remaining steps.
    b. If the result is false, return $\text{read}(k)$ and ignore remaining steps.
3. Run $\text{write}(k, v)$.
    a. If it attempts to read any storage slot that has so far been written by
$t$, or write any storage slot that has so far been read by $t$, return
$\text{read}(k)$ and ignore remaining steps.
4. Generate a system transaction $s$ that has the following behavior and insert $s$ immediately before $t$ in the assembled block.
    a. Run $\text{validate}(k, v)$ and assert that the result is true.
    b. Run $\text{write}(k, v)$.

The system transaction does not consume gas.

TODO: formally verify (prove) that the interface, along with the dynamic checks, is safe
