---
description: Verifiable onchain randomness on MegaETH via DrandOracleQuicknet — a preinstalled, stateless BLS12-381 verifier for the public drand quicknet beacon.
---

# Verifiable Randomness (VRF)

MegaETH ships with a preinstalled verifiable random function (VRF) service: [DrandOracleQuicknet](https://github.com/Zodomo/DrandVerifier), a stateless BLS12-381 signature verifier deployed at a fixed address on each MegaETH network.
Any contract can consume it.
The randomness itself comes from [drand](https://drand.love), a public randomness beacon independently produced by a global network of participants and freely downloadable over HTTP.

At the highest level:

1. Your app commits to a specific future drand round.
2. Anyone — user, relayer, keeper, bot — fetches that round's signature from the public `api.drand.sh` once it's published.
3. They submit it in a transaction; `DrandOracleQuicknet.verifyNormalized(round, sig)` checks the BLS pairing onchain and returns a canonical 32-byte random value.

{% hint style="info" %}
For a complete worked example — contract, tests, and an end-to-end shell demo — see the [Drand VRF Lottery](https://github.com/megaeth-labs/documentation/blob/main/docs/dev/examples/vrf-drand-quicknet-lottery/README.md).
{% endhint %}

## What is VRF?

A verifiable random function produces a random value together with a **proof** of its validity.
Given the proof and a public verification key, anyone can independently check three properties:

- **Correctness.** The value was produced according to the VRF's public rules — no one can forge it.
- **Uniqueness.** For any given input, there is exactly one valid output. The producer cannot choose among alternatives to bias the result.
- **Unpredictability.** Before the proof is published, the value is indistinguishable from random.

For onchain use, the property that matters most is _public verifiability_: the proof is small enough that a smart contract can check it directly, without trusting the producer.

## The VRF service on MegaETH

`DrandOracleQuicknet` is pre-deployed at a known address on each MegaETH network.
Treat it the way you'd treat `ecrecover` — a stateless verification function your contract can call without owning or operating anything.

Source and full ABI: [Zodomo/DrandVerifier](https://github.com/Zodomo/DrandVerifier).

### Addresses

| Network         | Chain ID | `DrandOracleQuicknet`                        |
| --------------- | -------- | -------------------------------------------- |
| MegaETH Mainnet | 4326     | `0x7a53a6eFA81c426838fcf4824E6e207923969b36` |
| MegaETH Testnet | 6343     | `0x4e1673dcAA38136b5032F27ef93423162aF977Cc` |

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

Source, full ABI, and test vectors live at [Zodomo/DrandVerifier](https://github.com/Zodomo/DrandVerifier) — start there if you need anything beyond the summary below.

### API surface

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
It returns a canonical random value independent of whether the submitter handed you compressed or uncompressed signature bytes.
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

        // We take the 3rd return (chainScopedHash): chain- and contract-bound,
        // so the same beacon can't be replayed across chains or contracts.
        (bool ok,, bytes32 r) = VRF.verifyNormalized(revealRound, sig);
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

### Worked example

The [Drand VRF Lottery](https://github.com/megaeth-labs/documentation/blob/main/docs/dev/examples/vrf-drand-quicknet-lottery/README.md) is a complete Foundry project — `src/DrandLottery.sol`, test suite, deploy scripts, and an `./script/demo.sh` that drives the full lifecycle end-to-end against a real MegaETH network.
Clone it if you want something you can run immediately.

## Security caveats

`DrandOracleQuicknet` answers exactly one question: "is this a valid drand beacon for this round?".
Everything else — when to consume it, which round to use, how to lock application inputs — is your contract's responsibility.
Get these three things right and you're safe; get any one wrong and the cryptography cannot save you.

The caveats below cover **integration-level** concerns — what your consuming contract must do to make drand randomness safe to use.
For **protocol-level** concerns that sit below our layer — drand's threshold-honesty assumption, front-running by malicious drand nodes, DoS and liveness bounds, DKG assumptions — see drand's own [Security Model](https://docs.drand.love/docs/security-model/).
Your contract inherits those assumptions by consuming drand; they are not things `DrandOracleQuicknet` can enforce.

### 1. Commit to a future round and lock every outcome-relevant input at commit time

{% hint style="danger" %}
The round you consume must be one drand has **not yet signed** at commit time, and the entrant set, stakes, tier choices, or anything else that affects the outcome must all be pinned in the same transaction.
{% endhint %}

drand beacons are public.
If you pick the current round, or leave any outcome-relevant input mutable after commit, the submitter can read the beacon offchain and only proceed when the result favors them.
Derive `revealRound` from `block.timestamp + delay` with `publish_time(revealRound) > block.timestamp`, reject any signature whose round doesn't match the committed one exactly, and freeze application state in the same commit transaction.

### 2. Own the state the verifier doesn't

{% hint style="danger" %}
`DrandOracleQuicknet` is stateless by design.
Replay prevention, freshness checks, and encoding canonicalization are all on your consuming contract.
{% endhint %}

Three things your contract must do that the verifier will not:

- **Freshness:** require `block.timestamp >= publish_time(revealRound)` in `reveal` so a premature submission cannot succeed by accident.
- **Replay:** flip a `settled` / `consumed` storage flag before the external verify call (checks-effects-interactions), so the same beacon cannot be consumed twice.
- **Encoding:** use `verifyNormalized`. The same valid G1 point can be encoded as 48 bytes (compressed) or 96 bytes (uncompressed); if you hash raw signature bytes yourself, the submitter gets to choose between two different random values. `verifyNormalized` hashes the canonical uncompressed point so both encodings produce the same output.

### 3. Handle drand stalls explicitly

{% hint style="warning" %}
drand can miss a round — network outages and DKG incidents happen.
A contract that waits forever for a stalled round is a bricked contract.
{% endhint %}

Add an expiry or fallback path so the game can resolve if the beacon never arrives.
For example, a cancel-and-refund function gated by `block.timestamp >= publishTime + STALL_WINDOW`, or retry against a later round.
See the [DoS scenarios](https://docs.drand.love/docs/security-model/#dos-the-drand-network) in drand's security model for how long such stalls can plausibly last.

## References

- [Drand VRF Lottery example](https://github.com/megaeth-labs/documentation/blob/main/docs/dev/examples/vrf-drand-quicknet-lottery/README.md) — runnable consumer contract with deploy scripts and an end-to-end shell demo
- [Zodomo/DrandVerifier](https://github.com/Zodomo/DrandVerifier) — source of `DrandOracleQuicknet`, full test suite, gas snapshot
- [drand developer docs](https://docs.drand.love/developer/)
- [drand protocol specification](https://docs.drand.love/docs/specification/) — including beacon timing
- [drand security model](https://docs.drand.love/docs/security-model/)
- [EIP-2537 — BLS12-381 curve operations](https://eips.ethereum.org/EIPS/eip-2537)
