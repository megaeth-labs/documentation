---
description: End-to-end onchain randomness example using drand quicknet verified with BLS12-381 precompiles on MegaETH.
---

# Drand VRF Lottery

A runnable demo of publicly verifiable onchain randomness on MegaETH, built on top of the stateless [DrandVerifier](https://github.com/Zodomo/DrandVerifier) contracts.

drand is a public threshold-BLS randomness beacon.
Every three seconds, the drand network produces and publishes a signed random value that anyone can fetch and verify.
No oracle service, no subscription, no callback.
For background on the protocol, see the [drand developer docs](https://docs.drand.love/developer/).

This example deploys a stateless verifier (`DrandOracleQuicknet`) and a single-slot lottery that consumes it via commit-reveal.

## What this example shows

- Calling a stateless BLS12-381 signature verifier from a user contract.
- A correct commit-reveal flow: committing a target round **before** its signature exists, then revealing once drand publishes it.
- Adversarial-path testing: the same contract correctly rejects early settlement and wrong-round signatures.

## Prerequisites

- [Foundry](https://getfoundry.sh/) installed (`forge`, `cast`)
- A MegaETH Testnet wallet with testnet ETH — see [Get ETH on Testnet](../../../user/faucet.md)
- `curl` and `jq` for fetching drand beacons

{% hint style="info" %}
drand verification uses the BLS12-381 precompiles activated in Pectra (EIP-2537).
MegaETH Testnet has these enabled.
The `DrandVerifier` libraries will not work on chains without EIP-2537.
{% endhint %}

## Deployed addresses (MegaETH Testnet, chain id 6343)

| Contract            | Address                                      |
| ------------------- | -------------------------------------------- |
| DrandOracleQuicknet | `0x4e1673dcAA38136b5032F27ef93423162aF977Cc` |
| DrandLotteryDemo    | `0x0Eed2baF5a317D8C20a20dc51E6a6BBb8390f4e5` |

You can interact with these directly, or deploy your own copy using the steps below.

## How it works

drand quicknet publishes one threshold-BLS signature per round, every three seconds, under a fixed group public key.
Anyone with the public key can verify any round's signature onchain.
A contract that wants randomness picks a future round, waits for it to be produced, then accepts `(round, signature)` from any submitter and checks the signature onchain.

Randomness is "fair" only if the app commits to a round **before** that round's signature exists.
Otherwise, an attacker can read the public beacon offchain and choose whether to reveal based on the result.

```
 t0: open()   → pins revealRound (future, not yet signed by drand)
                pins entrants, locks further changes
 t1: drand network produces round N (independent of our chain)
     signature becomes publicly available at api.drand.sh
 t2: anyone   → settle(sig) → oracle.verifyNormalized(round, sig)
                BLS pairing check onchain → r is the canonical random
                winner = entrants[uint256(r) % entrants.length]
```

## The contract

The full source is in [`DrandLotteryDemo.sol`](DrandLotteryDemo.sol).
Key invariants:

- `open` computes `revealRound` from the future publish window and requires `publishTime > block.timestamp`.
- `settle` requires `block.timestamp >= publishTime` so an early submission cannot succeed by accident.
- `settle` requires the oracle's pairing check to pass — only one signature per round is valid, so the wrong signature reverts.
- Entrants are frozen at `open` time; no input used in winner selection can be changed after the commit.

```solidity
function settle(bytes calldata sig) external {
    require(revealRound != 0 && !settled, "not settlable");
    uint256 publishTime_ = GENESIS + uint256(revealRound - 1) * PERIOD;
    require(block.timestamp >= publishTime_, "round not yet published");

    (bool ok, bytes32 r,) = oracle.verifyNormalized(revealRound, sig);
    require(ok, "bad signature");

    uint256 idx = uint256(r) % entrants.length;
    settled = true;
    randomness = r;
    winner = entrants[idx];
    emit LotterySettled(revealRound, winner, idx, r);
}
```

## Walkthrough

The testnet oracle and lottery addresses above are already deployed.
The steps below use them directly; skip to "Deploy your own copy" if you want fresh instances.

{% stepper %}
{% step %}

### Open a round

Commit an entrant set and a reveal round that is at least a few seconds in the future.

```bash
export RPC_URL="https://carrot.megaeth.com/rpc"
export PRIVATE_KEY=0x...

LOT=0x0Eed2baF5a317D8C20a20dc51E6a6BBb8390f4e5
ENTRANTS='[0x1111111111111111111111111111111111111111,0x2222222222222222222222222222222222222222,0x3333333333333333333333333333333333333333,0x4444444444444444444444444444444444444444]'

cast send --private-key $PRIVATE_KEY --rpc-url $RPC_URL \
  --gas-limit 30000000 \
  $LOT "open(address[],uint64)" $ENTRANTS 24
```

Read the committed round:

```bash
cast call $LOT "revealRound()(uint64)" --rpc-url $RPC_URL
# 27985651
cast call $LOT "publishTime()(uint256)" --rpc-url $RPC_URL
# 1776760317
```

{% endstep %}
{% step %}

### Wait for drand to produce that round

Quicknet publishes every three seconds, so the wait is bounded by `publishTime - now` plus a few seconds of API propagation.
Poll until the round is available:

```bash
ROUND=27985651
URL=https://api.drand.sh/v2/chains/52db9ba70e0cc0f6eaf7803dd07447a1f5477735fd3f661792ba94600c84e971/rounds/$ROUND

until RESP=$(curl -fsSL "$URL" 2>/dev/null) && [ -n "$RESP" ]; do sleep 1; done
SIG=$(echo "$RESP" | jq -r '.signature')
echo "$SIG"
# b3548e49211c5285c23420d01f4be07ef60d55680f1d609191524aa3e4089360ad869393f6a7b28451617e3acbf0c58f
```

The signature is a 48-byte compressed G1 point.
Nothing about fetching it is privileged — anyone can pull the beacon from `api.drand.sh`.

{% endstep %}
{% step %}

### Settle

Submit the signature back to the lottery.
The oracle runs the BLS pairing check and the contract selects a winner deterministically from the canonical random value:

```bash
cast send --private-key $PRIVATE_KEY --rpc-url $RPC_URL \
  --gas-limit 30000000 \
  $LOT "settle(bytes)" "0x$SIG"
```

Read the result:

```bash
cast call $LOT "winner()(address)"     --rpc-url $RPC_URL
# 0x2222222222222222222222222222222222222222
cast call $LOT "randomness()(bytes32)" --rpc-url $RPC_URL
# 0xd743530bc80936fe28d1f6a79556cfc67a97796eb1e61d853d4dbdde089c93f1
```

Verify offchain that the winner matches the committed selection rule:

```bash
python3 -c "r=0xd743530bc80936fe28d1f6a79556cfc67a97796eb1e61d853d4dbdde089c93f1; print(r % 4)"
# 1  → entrants[1] = 0x2222…
```

{% endstep %}
{% endstepper %}

## Adversarial paths

The contract rejects both of the obvious attacks.

Settling before the target round has been produced:

```bash
cast call $LOT "settle(bytes)" "0x<any_sig>" --rpc-url $RPC_URL
# execution reverted: round not yet published
```

Submitting a valid signature for a different round:

```bash
# Known-good signature for round 20791007, submitted against a different revealRound
cast call $LOT "settle(bytes)" "0x8d2c8bbc37…198ac5" --rpc-url $RPC_URL
# execution reverted: bad signature
```

The oracle's pairing check binds signature validity to the specific round hash, so a signature from any other round fails verification.

## Deploy your own copy

{% stepper %}
{% step %}

### Clone the verifier repo

```bash
git clone https://github.com/Zodomo/DrandVerifier.git
cd DrandVerifier
git submodule update --init --recursive
forge build
```

{% endstep %}
{% step %}

### Deploy `DrandOracleQuicknet`

The contract has no constructor arguments.
MegaETH's dual-gas model returns a larger `eth_estimateGas` than local Foundry simulation, so ask the node directly and set `--gas-limit` above its estimate:

```bash
BYTECODE=$(jq -r '.bytecode.object' out/DrandOracleQuicknet.sol/DrandOracleQuicknet.json)

cast rpc eth_estimateGas \
  "{\"from\":\"$(cast wallet address --private-key $PRIVATE_KEY)\",\"data\":\"$BYTECODE\"}" \
  --rpc-url $RPC_URL
# "0x929b16e"  → 153,534,830 gas

cast send --private-key $PRIVATE_KEY --rpc-url $RPC_URL \
  --gas-limit 200000000 \
  --create "$BYTECODE"
```

Record the returned `contractAddress`.
Sanity-check the deployment by verifying a known-good vector:

```bash
ORACLE=0x...
cast call $ORACLE "verify(uint64,bytes)(bool)" 20791007 \
  0x8d2c8bbc37170dbacc5e280a21d4e195cff5f32a19fd6a58633fa4e4670478b5fb39bc13dd8f8c4372c5a76191198ac5 \
  --rpc-url $RPC_URL
# true  → BLS12-381 precompiles working, contract wired up correctly
```

{% endstep %}
{% step %}

### Deploy `DrandLotteryDemo`

Copy [`DrandLotteryDemo.sol`](DrandLotteryDemo.sol) into your Foundry project and build.
Then deploy with the oracle address as the constructor argument:

```bash
BYTECODE=$(jq -r '.bytecode.object' out/DrandLotteryDemo.sol/DrandLotteryDemo.json)
CTOR=$(cast abi-encode 'constructor(address)' $ORACLE)

cast send --private-key $PRIVATE_KEY --rpc-url $RPC_URL \
  --gas-limit 80000000 \
  --create "${BYTECODE}${CTOR#0x}"
```

{% endstep %}
{% endstepper %}

## Gas profile

Observed on MegaETH Testnet at the time of deployment.

| Operation                             | Gas used    |
| ------------------------------------- | ----------- |
| Deploy `DrandOracleQuicknet` (14.6KB) | 151,323,053 |
| Deploy `DrandLotteryDemo` (6.2KB)     | 56,047,921  |
| `open(entrants, delay)` first call    | 236,106     |
| `open(entrants, delay)` subsequent    | 113,069     |
| `settle(sig)`                         | 442,690     |

{% hint style="warning" %}
Deployments are dominated by MegaETH's storage gas.
`forge script`'s local simulation understates the cost by ~50×; always query `eth_estimateGas` on a MegaETH RPC endpoint before setting `--gas-limit` for non-trivial deploys.
See [Gas Estimation](../../send-tx/gas-estimation.md) for details.
{% endhint %}

`settle` is the only hot-path cost at runtime; everything inside `verifyNormalized` is a fixed-cost pairing check plus hash-to-G1, independent of entrant count.

## Security considerations

{% hint style="danger" %}
The verifier contract is stateless.
It does not track freshness, replay, or commitment.
Every consumer must enforce those policies itself.
{% endhint %}

Checklist for a production integration:

- **Commit before the signature exists.** The target round must satisfy `publishTime > block.timestamp` at the commit transaction.
- **Freeze every input that can bias the outcome** at commit time.
  Entrant set, bet amounts, tier selection, anything downstream of `r` must be fixed in the commit transaction.
- **Pin an exact round.** Never accept "any round >= committedRound"; the submitter would pick the most favorable one.
- **Prevent replay.** Mark the commitment settled before any external calls, including the oracle call.
- **Handle drand stalls.** The network can miss rounds. Define fallback behavior (secondary round, expiry, refund path) rather than deadlocking the contract.
- **Pick one signature encoding.** Compressed (48 bytes) and uncompressed (96 bytes) G1 points hash to different values if you derive randomness from raw bytes. Use `verifyNormalized` — it returns the canonical point bytes and avoids this footgun.

## References

- [DrandVerifier repository](https://github.com/Zodomo/DrandVerifier) — source, tests, gas snapshot
- [drand developer docs](https://docs.drand.love/developer/) — protocol spec, beacon format, security model
- [EIP-2537: BLS12-381 curve operations](https://eips.ethereum.org/EIPS/eip-2537) — precompile reference
- [`DrandLotteryDemo.sol`](DrandLotteryDemo.sol) — full source of the contract used in this walkthrough
