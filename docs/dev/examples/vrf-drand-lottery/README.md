---
description: End-to-end onchain randomness example using drand quicknet verified with BLS12-381 precompiles on MegaETH.
---

# Drand VRF Lottery

A self-contained, runnable demo of publicly verifiable onchain randomness on MegaETH, built on top of the stateless [DrandVerifier](https://github.com/Zodomo/DrandVerifier) contracts.

drand is a public threshold-BLS randomness beacon.
Every three seconds, the drand network produces and publishes a signed random value that anyone can fetch and verify.
No oracle service, no subscription, no callback.
For background on the protocol, see the [drand developer docs](https://docs.drand.love/developer/).

This example ships a complete Foundry project that deploys a single-slot lottery and drives it end-to-end via three shell scripts.

## What this example shows

- Calling a stateless BLS12-381 signature verifier from a user contract.
- A correct commit-reveal flow: committing a target round **before** its signature exists, then revealing once drand publishes it.
- Unit-testing a drand consumer with a mock oracle.
- Working around MegaETH's dual-gas model when deploying via scripts.

## Project layout

```
vrf-drand-lottery/
├── foundry.toml
├── .env.example                          # copy to .env and fill in
├── src/
│   └── DrandLotteryDemo.sol              # the contract
├── test/
│   └── DrandLotteryDemo.t.sol            # unit tests with a mock oracle
└── script/
    ├── deploy-lottery.sh                 # forge build + deploy with correct gas
    ├── open.sh                           # commit entrants + future round
    └── settle.sh                         # poll drand, fetch sig, submit
```

## Prerequisites

- [Foundry](https://getfoundry.sh/) (`forge`, `cast`)
- `jq`, `curl`, `bash`
- A MegaETH Testnet wallet with testnet ETH — see [Get ETH on Testnet](../../../user/faucet.md)

{% hint style="info" %}
drand verification uses the BLS12-381 precompiles activated in Pectra (EIP-2537).
MegaETH Testnet has these enabled.
The `DrandVerifier` libraries will not work on chains without EIP-2537.
{% endhint %}

## Already-deployed addresses (MegaETH Testnet, chain id 6343)

You can either reuse these or run `script/deploy-lottery.sh` to deploy your own copy.

| Contract            | Address                                      |
| ------------------- | -------------------------------------------- |
| DrandOracleQuicknet | `0x4e1673dcAA38136b5032F27ef93423162aF977Cc` |
| DrandLotteryDemo    | `0x0Eed2baF5a317D8C20a20dc51E6a6BBb8390f4e5` |

## Quick start

{% stepper %}
{% step %}

### Clone and configure

```bash
# From the documentation repo checkout:
cd docs/dev/examples/vrf-drand-lottery

cp .env.example .env
# then edit .env — at minimum set PRIVATE_KEY
```

`.env` contains:

- `RPC_URL` — MegaETH Testnet endpoint (default is fine).
- `PRIVATE_KEY` — funded testnet account.
- `ORACLE_ADDRESS` — pre-filled with the already-deployed oracle.
- `LOTTERY_ADDRESS` — auto-populated by `deploy-lottery.sh`.
- `ENTRANTS`, `DELAY_SECONDS` — defaults for `open.sh`.

{% endstep %}
{% step %}

### Install dependencies and build

The test suite uses `forge-std`.
Clone it into `lib/` (it is git-ignored so it won't be committed):

```bash
git clone --depth 1 https://github.com/foundry-rs/forge-std.git lib/forge-std
forge build
forge test -vv
```

You should see 8 tests pass.

{% endstep %}
{% step %}

### Deploy

```bash
./script/deploy-lottery.sh
# DrandLotteryDemo deployed: 0x…
# wrote LOTTERY_ADDRESS to .env
```

The script queries `eth_estimateGas` on the node and sets `--gas-limit` with a 30% margin.
This is necessary because MegaETH's dual-gas model charges materially more for contract creation than local Foundry simulation — deployments with the default estimator will revert out-of-gas.
See [Gas Estimation](../../send-tx/gas-estimation.md).

{% endstep %}
{% step %}

### Open a round

```bash
./script/open.sh
# opening lottery on 0x…
# entrants:    [0x1111…,0x2222…,0x3333…,0x4444…]
# delay:       24s
# revealRound: 27985651
# publishTime: 1776760317
```

{% endstep %}
{% step %}

### Settle

```bash
./script/settle.sh
# revealRound: 27985651
# publishTime: 1776760317
# now:         1776760300
# polling https://api.drand.sh/…/rounds/27985651
# signature:   b3548e49…
# winner:      0x2222222222222222222222222222222222222222
# randomness:  0xd743530bc80936fe28d1f6a79556cfc67a97796eb1e61d853d4dbdde089c93f1
```

`settle.sh` waits until `publishTime` is reached, polls `api.drand.sh` until the round is available, and then submits the signature.

{% endstep %}
{% endstepper %}

To run another round, just call `open.sh` and `settle.sh` again — the contract resets on each `open` after settlement.

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

Full source in `src/DrandLotteryDemo.sol`.
Key invariants:

- `open` computes `revealRound` from the future publish window and requires `publishTime > block.timestamp`.
- `settle` requires `block.timestamp >= publishTime` so an early submission cannot succeed by accident.
- `settle` requires the oracle's pairing check to pass — only one signature per round is valid, so the wrong signature reverts.
- Entrants are frozen at `open` time; no input used in winner selection can be changed after the commit.
- `settle` flips `settled = true` before the external oracle call (checks-effects-interactions).

```solidity
function settle(bytes calldata sig) external {
    require(revealRound != 0 && !settled, "not settlable");
    uint256 publishTime_ = GENESIS + uint256(revealRound - 1) * PERIOD;
    require(block.timestamp >= publishTime_, "round not yet published");

    settled = true; // checks-effects-interactions: flip state before the external call

    (bool ok, bytes32 r,) = oracle.verifyNormalized(revealRound, sig);
    require(ok, "bad signature");

    uint256 idx = uint256(r) % entrants.length;
    randomness = r;
    winner = entrants[idx];
    emit LotterySettled(revealRound, winner, idx, r);
}
```

## Testing with a mock oracle

`test/DrandLotteryDemo.t.sol` exercises the commit-reveal flow against a `MockOracleQuicknet` that returns caller-chosen results.
This decouples the lottery logic from the real BLS verifier so unit tests stay fast and deterministic.

```bash
forge test -vv
```

The suite covers:

- `open` commits a future round, rejects empty entrants, rejects re-open while in flight.
- `settle` reverts before `publishTime`, reverts on bad signature, reverts on replay.
- Winner selection is deterministic given the oracle's normalized hash.
- After `settle`, `open` can start a fresh round.

For integration-style testing against the real verifier on a forked MegaETH Testnet, use `forge test --fork-url $RPC_URL` with the already-deployed oracle address.

## Adversarial paths

The contract rejects both of the obvious attacks.
These are also covered by `DrandLotteryDemoTest`.

Settling before the target round has been produced:

```bash
cast call $LOTTERY_ADDRESS "settle(bytes)" "0x<any_sig>" --rpc-url $RPC_URL
# execution reverted: round not yet published
```

Submitting a valid signature for a different round:

```bash
# Known-good signature for round 20791007, submitted against a different revealRound
cast call $LOTTERY_ADDRESS "settle(bytes)" "0x8d2c8bbc37…198ac5" --rpc-url $RPC_URL
# execution reverted: bad signature
```

The oracle's pairing check binds signature validity to the specific round hash, so a signature from any other round fails verification.

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
`script/deploy-lottery.sh` does this for you.
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

## Deploying your own oracle

The steps above reuse the already-deployed `DrandOracleQuicknet`.
If you want your own instance, clone the source and deploy it:

```bash
git clone https://github.com/Zodomo/DrandVerifier.git
cd DrandVerifier
git submodule update --init --recursive
forge build

BYTECODE=$(jq -r '.bytecode.object' out/DrandOracleQuicknet.sol/DrandOracleQuicknet.json)
FROM=$(cast wallet address --private-key $PRIVATE_KEY)
GAS_HEX=$(cast rpc eth_estimateGas \
  "{\"from\":\"$FROM\",\"data\":\"$BYTECODE\"}" \
  --rpc-url $RPC_URL | tr -d '"')
LIMIT=$(( $(printf '%d' "$GAS_HEX") * 130 / 100 ))

cast send --private-key $PRIVATE_KEY --rpc-url $RPC_URL \
  --gas-limit $LIMIT --create "$BYTECODE"
```

Point `ORACLE_ADDRESS` in `.env` at the returned address and re-run `script/deploy-lottery.sh`.

## References

- [DrandVerifier repository](https://github.com/Zodomo/DrandVerifier) — source, tests, gas snapshot for the underlying verifier
- [drand developer docs](https://docs.drand.love/developer/) — protocol spec, beacon format, security model
- [EIP-2537: BLS12-381 curve operations](https://eips.ethereum.org/EIPS/eip-2537) — precompile reference
- `src/DrandLotteryDemo.sol` — the demo contract
- `test/DrandLotteryDemo.t.sol` — mock-oracle unit tests
