---
description: Verifiable onchain randomness on MegaETH via DrandOracleQuicknet — a preinstalled, stateless BLS12-381 verifier for the public drand quicknet beacon. No subscription, no oracle callback, no trusted operator.
---

# Verifiable Randomness (VRF)

MegaETH ships with a preinstalled verifiable random function (VRF) service: `DrandOracleQuicknet`, a stateless BLS12-381 signature verifier deployed at a fixed address on each MegaETH network.
Any contract can consume it.
Randomness comes from the [drand](https://drand.love) public randomness beacon — independently produced by a global network of participants and freely downloadable over HTTP — so there is no trusted oracle operator, no subscription, and no callback flow.

At the highest level:

1. Your app commits to a specific future drand round.
2. Anyone (user, relayer, keeper, bot) fetches that round's signature from the public `api.drand.sh` once it's published.
3. They submit it in a transaction; `DrandOracleQuicknet.verifyNormalized(round, sig)` checks the BLS pairing onchain and returns a canonical 32-byte random value.

You pay normal transaction gas. You don't pay a VRF premium. You don't wait for a callback.

{% hint style="info" %}
This page is a developer reference.
For a complete worked example — contract, tests, and end-to-end shell demo — see the [Drand VRF Lottery](examples/vrf-drand-quicknet-lottery/README.md) example.
{% endhint %}

## What is VRF?

A verifiable random function is a primitive for producing a random value together with a **proof** that lets anyone independently check:

- The value was produced by the intended key holder.
- The value is the **unique** random output for the given input.
- No party — including the key holder — could have biased the output.

For onchain use the property that matters is _public verifiability_: given a public input and a proof, any verifier (including a smart contract) can confirm the value without trusting the producer.
This is strictly stronger than "a trusted oracle sends you a random number".

Three families of onchain randomness show up in practice:

| Source                       | Trust model                                          | Delivery                        | Cost                        |
| ---------------------------- | ---------------------------------------------------- | ------------------------------- | --------------------------- |
| `block.prevrandao`           | Block proposer; bounded validator influence per slot | Native block field              | Minimal                     |
| Oracle VRF (e.g. Chainlink)  | Single oracle network + subscription + callback      | Push — oracle fulfills request  | Gas + VRF premium           |
| **drand beacon** (this page) | Threshold of independent orgs (drand consortium)     | Pull — anyone submits the proof | Gas + onchain pairing check |

The drand model fits MegaETH's ethos well: no centralized service has to be kept alive for your dapp to function, because drand already publishes beacons for the whole world at a fixed cadence regardless of any single consumer.

## The VRF service on MegaETH

MegaETH networks come with `DrandOracleQuicknet` pre-deployed at a known address.
Treat it the way you'd treat `ecrecover` — a stateless verification function your contract can call without owning or operating anything.

### Addresses

| Network         | Chain ID | `DrandOracleQuicknet`                        |
| --------------- | -------- | -------------------------------------------- |
| MegaETH Testnet | 6343     | `0x4e1673dcAA38136b5032F27ef93423162aF977Cc` |
| MegaETH Mainnet | 4326     | _Deployment pending_                         |

{% hint style="info" %}
The Mainnet deployment will be published at the official MegaETH address registry once live.
Use the Testnet address above for development and integration testing.
{% endhint %}

### What it is (and isn't)

- A regular Solidity contract at the address above — not an EVM precompile.
  You interact with it like any other contract via normal `CALL` / `STATICCALL`.
- Completely stateless.
  Every call is a pure verification against hardcoded drand parameters (group public key, period, genesis, scheme).
  It has no owner, no upgrade path, no pause, and no storage that tracks anything per-caller.
- Identical on every MegaETH network.
  Same source, same configuration (drand quicknet: 3-second period, G1 signatures).
  Only the deployed address changes per network.

### Underlying protocol

The verifier speaks drand quicknet (`bls-unchained-g1-rfc9380`), a drand subnet that signs a new round every **three seconds**.
Each beacon is a 48-byte compressed G1 BLS12-381 signature over `sha256(uint64 round, big-endian)` under a fixed threshold-BLS group public key.
The verifier checks each signature with a pairing check through EIP-2537 BLS12-381 precompiles — which MegaETH supports natively.

For the protocol spec and security model, see the [drand developer docs](https://docs.drand.love/developer/).

## What is drand?

**drand** is a public randomness beacon produced by the "League of Entropy" — a coalition of independent organizations (Cloudflare, Protocol Labs, EPFL, universities, and more).

Every few seconds, drand participants each sign a predetermined message (derived from the round number) with their BLS key share.
Once enough shares arrive, anyone can combine them into a single valid BLS signature under the group public key.
That signature **is** the beacon.
Hashing it yields a 32-byte random value.

This gives three properties that matter for onchain randomness:

- **Publicly verifiable.** Anyone with the group public key can check any beacon.
- **Unpredictable.** The output is unknown until enough honest participants sign — no single party can predict it.
- **Unbiasable.** BLS signatures are deterministic; even a threshold majority cannot cherry-pick among outputs, only decide whether to produce one.

drand has multiple networks.
MegaETH's `DrandOracleQuicknet` targets the **quicknet** scheme specifically — the 3-second unchained subnet with G1 signatures.
Details on protocol variants are in the [drand protocol specification](https://docs.drand.love/docs/specification/).

## How to use `DrandOracleQuicknet`

### API surface

A short list — everything you need to consume randomness.

| Function                                                               | Purpose                                                                                                                                                                |
| ---------------------------------------------------------------------- | ---------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `PERIOD_SECONDS() → uint64`                                            | Returns `3` — the drand quicknet period.                                                                                                                               |
| `GENESIS_TIMESTAMP() → uint64`                                         | Returns `1692803367` — the Unix timestamp of round 1.                                                                                                                  |
| `roundMessageHash(uint64 round) → bytes32`                             | The 32-byte digest drand signs for a given round. Useful for offchain proof construction.                                                                              |
| `verify(uint64 round, bytes sig) → bool`                               | Runs the pairing check. Reverts on malformed signature bytes.                                                                                                          |
| `safeVerify(uint64 round, bytes sig) → bool`                           | Same, but returns `false` instead of reverting on malformed input.                                                                                                     |
| `verifyAPI(string json) → bool`                                        | Accepts a raw `api.drand.sh` JSON payload and verifies it. Convenient, costs extra gas for JSON parsing.                                                               |
| `verifyNormalized(uint64 round, bytes sig) → (bool, bytes32, bytes32)` | Verifies and, if valid, returns `(true, normalizedRoundHash, chainScopedHash)`. Encoding-invariant — the correct choice when you derive randomness from the signature. |

{% hint style="success" %}
For randomness consumption, use `verifyNormalized`.
It returns a canonical random value independent of whether the submitter handed you compressed or uncompressed signature bytes, which sidesteps a common integration footgun.
{% endhint %}

### Minimal pattern

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.34;

interface IDrandOracleQuicknet {
    function PERIOD_SECONDS() external pure returns (uint64);
    function GENESIS_TIMESTAMP() external pure returns (uint64);
    function verifyNormalized(uint64 round, bytes calldata sig)
        external view returns (bool, bytes32, bytes32);
}

contract RandomizedApp {
    IDrandOracleQuicknet constant VRF =
        IDrandOracleQuicknet(0x4e1673dcAA38136b5032F27ef93423162aF977Cc); // MegaETH Testnet

    uint64 public revealRound; // 0 = open / not yet committed
    bool public settled;
    bytes32 public randomness;

    uint64 constant MIN_DELAY_SECONDS = 30;

    /// Step 1: commit to a drand round that has NOT YET been signed.
    function commit() external {
        require(revealRound == 0 || settled, "in flight");
        uint64 period = VRF.PERIOD_SECONDS();
        uint64 genesis = VRF.GENESIS_TIMESTAMP();
        revealRound = uint64((block.timestamp + MIN_DELAY_SECONDS - genesis) / period + 1);
        settled = false;

        // Any app input that influences the outcome MUST be locked here too.
    }

    /// Step 2: after publishTime, anyone submits the beacon signature.
    function reveal(bytes calldata sig) external {
        require(revealRound != 0 && !settled, "not settlable");
        uint64 period = VRF.PERIOD_SECONDS();
        uint64 genesis = VRF.GENESIS_TIMESTAMP();
        uint256 publishTime = genesis + uint256(revealRound - 1) * period;
        require(block.timestamp >= publishTime, "round not published yet");

        settled = true; // checks-effects-interactions: flip before external call.

        (bool ok, bytes32 r,) = VRF.verifyNormalized(revealRound, sig);
        require(ok, "bad signature");

        randomness = r;
        // ... consume r (e.g. choose a winner, derive a secret, mint an NFT trait, ...)
    }
}
```

Under 50 lines, and the only external dependency is the address constant.

### Fetching the beacon offchain

The drand API is public, unauthenticated, and served by multiple independent relays.
Any of the paths below work — the JSON shape is identical.

{% tabs %}
{% tab title="curl" %}

```bash
# Get the round you committed to (replace 27985651 with yours).
curl -fsSL "https://api.drand.sh/v2/chains/52db9ba70e0cc0f6eaf7803dd07447a1f5477735fd3f661792ba94600c84e971/rounds/27985651"

# {"round":27985651,"signature":"b3548e49211c5285c23420d01f4be07ef60d55680f1d609191524aa3e4089360ad869393f6a7b28451617e3acbf0c58f"}
```

{% endtab %}
{% tab title="cast" %}

```bash
# Call reveal on your contract with the fetched signature.
SIG=$(curl -fsSL "https://api.drand.sh/v2/chains/52db9ba70e0cc0f6eaf7803dd07447a1f5477735fd3f661792ba94600c84e971/rounds/$ROUND" \
  | jq -r '.signature')

cast send $MY_CONTRACT "reveal(bytes)" "0x$SIG" \
  --rpc-url $MEGAETH_RPC --private-key $PRIVATE_KEY
```

{% endtab %}
{% tab title="viem" %}

```typescript
import { createWalletClient, http } from "viem";

const response = await fetch(
  `https://api.drand.sh/v2/chains/52db9ba70e0cc0f6eaf7803dd07447a1f5477735fd3f661792ba94600c84e971/rounds/${round}`,
);
const { signature } = await response.json();

await walletClient.writeContract({
  address: MY_CONTRACT,
  abi: MY_ABI,
  functionName: "reveal",
  args: [`0x${signature}` as `0x${string}`],
});
```

{% endtab %}
{% endtabs %}

The drand quicknet chain hash `52db9ba7…0c84e971` is fixed — don't change it.

### Round-time math

Given a Unix timestamp `t`, the in-flight round is:

```
round = ((t - GENESIS_TIMESTAMP) / PERIOD_SECONDS) + 1
```

Conversely, the publish time of round N is:

```
publish_time(N) = GENESIS_TIMESTAMP + (N - 1) * PERIOD_SECONDS
```

For Testnet / Mainnet the constants match drand quicknet: `GENESIS_TIMESTAMP = 1692803367`, `PERIOD_SECONDS = 3`.

### Worked example

The [Drand VRF Lottery](examples/vrf-drand-quicknet-lottery/README.md) example is a complete Foundry project — `src/DrandLottery.sol`, test suite, deploy scripts, and an `./script/demo.sh` that drives the full lifecycle end-to-end against a real MegaETH network.
Clone it if you want something you can run immediately.

## Pitfalls and security caveats

`DrandOracleQuicknet` answers exactly one question: "is this a valid drand beacon for this round?".
Everything else — when to consume it, which round to use, how to lock application inputs — is your contract's responsibility.
Getting that discipline wrong is how integrations get drained even when the cryptography is perfect.

### Commit before the signature exists

{% hint style="danger" %}
The round you consume must be **one that drand has not yet signed** at commit time.
If you pick the current round, an attacker can read the public beacon offchain and only submit when the result favors them.
{% endhint %}

Always derive `revealRound` from `block.timestamp + delay` with a delay large enough that the round's publish time is in the future:

```solidity
revealRound = uint64((block.timestamp + DELAY - GENESIS) / PERIOD + 1);
require(GENESIS + uint256(revealRound - 1) * PERIOD > block.timestamp, "round already known");
```

### Freeze every outcome-relevant input at commit

If `commit()` only pins the round but leaves entrant selection, bet amounts, or tier choice mutable, the adversary can wait until the beacon publishes and then adjust those inputs.
Lock _everything_ that affects the outcome at commit time, not just the round.

### Pin an exact round — don't accept "a later one"

A submitter-chosen round is equivalent to a submitter-chosen outcome.
Reject any signature whose round doesn't match the committed one exactly.

### Enforce freshness on reveal

Check `block.timestamp >= publish_time(revealRound)` in `reveal()`.
Without it, a delayed reveal could be confused with a premature one.

### Prevent replay

Flip a `settled` / `consumed` flag in storage before the external verify call.
This both plays nicely with checks-effects-interactions and prevents a second reveal from redoing winner selection with stale state.

### Handle drand stalls gracefully

drand can miss a round (network outage, DKG incident).
If round N never publishes, a naive contract deadlocks because `settle()` cannot proceed.
Define an expiry or secondary-round fallback in production contracts:

```solidity
function cancel() external {
    require(block.timestamp >= publishTime + STALL_WINDOW, "not stalled");
    // refund stakes, reset state
}
```

### Use `verifyNormalized` for randomness outputs

The same valid G1 point can be encoded as 48 bytes (compressed) or 96 bytes (uncompressed).
If you hash the raw signature bytes, those two encodings produce different random values — giving the submitter a choice of outcome.
`verifyNormalized` derives randomness over the canonical uncompressed point bytes, which removes that knob.

### Verify chain compatibility

`DrandOracleQuicknet` relies on the BLS12-381 precompiles introduced in EIP-2537 (Pectra).
MegaETH Mainnet and Testnet support them.
If you port consumer code to another chain, confirm EIP-2537 availability first, or `verify` will revert on every call.

### The verifier is stateless, on purpose

Don't rely on `DrandOracleQuicknet` for:

- Commitment tracking.
- Replay prevention.
- Freshness windows.
- Round scheduling.

None of these exist in the verifier; every one of them has to live in your consuming contract.

## References

- [Drand VRF Lottery example](examples/vrf-drand-quicknet-lottery/README.md) — runnable consumer contract with deploy scripts and an end-to-end shell demo
- [DrandVerifier repository](https://github.com/Zodomo/DrandVerifier) — source of `DrandOracleQuicknet`, full test suite, gas snapshot
- [drand developer docs](https://docs.drand.love/developer/)
- [drand security model](https://docs.drand.love/docs/security-model/)
- [drand protocol specification](https://docs.drand.love/docs/specification/)
- [EIP-2537 — BLS12-381 curve operations](https://eips.ethereum.org/EIPS/eip-2537)
- [EIP-4399 — `PREVRANDAO`](https://eips.ethereum.org/EIPS/eip-4399) for contrast with the block-level randomness source
