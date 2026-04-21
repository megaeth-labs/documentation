# drand-lottery-demo

A minimal commit-reveal lottery that consumes
[DrandOracleQuicknet](https://github.com/Zodomo/DrandVerifier) to draw a fair
winner using drand quicknet randomness.

The whole point of this demo is to show what a _consumer_ contract has to add
around the stateless drand verifier to make randomness safely usable. The
verifier answers one question — "is this a valid drand beacon?" — and nothing
else. Everything about **when** to consume it, **which round** to use, and
**how to lock inputs** is the application's responsibility. This contract
shows the minimum correct discipline.

## Contracts

| File                                                                        | Role                                                                                                                  |
| --------------------------------------------------------------------------- | --------------------------------------------------------------------------------------------------------------------- |
| `src/DrandLottery.sol`                                                      | State-changing consumer contract: holds a pot, commits to a future drand round, verifies the beacon, pays the winner. |
| (external) `dependencies/DrandVerifier/src/oracles/DrandOracleQuicknet.sol` | Pre-deployed, stateless BLS12-381 verifier.                                                                           |

## Flow

```
 open() ─▶ enter()×N ─▶ close() ─▶ (wait until revealRound published) ─▶ settle(sig)
                           │                                                  │
                           │                                                  ├─ verify BLS sig via DrandOracleQuicknet
                           │                                                  ├─ derive canonical randomness
                           │                                                  └─ pay winner = entrants[r % n]
                           │
                           └─ at close-time, the drand network has NOT YET signed revealRound.
                              No one, including the best-connected attacker, can know the winner yet.
```

### What `DrandLottery` enforces (that the verifier doesn't)

- **Future-round commitment** — `close()` picks `revealRound = currentRound + 2`, a round whose signature does not yet exist anywhere. Prevents "wait until the beacon is published, then only enter if I like the result."
- **Input lock** — `enter()` is rejected once `revealRound != 0`. The entrant set and pot are frozen at close.
- **Freshness** — `settle()` requires `block.timestamp >= publish_time(revealRound)`, so you can't pre-submit a reveal.
- **Replay** — `settled` flag set before the external call, rolled back only on verify failure so a malformed first submission doesn't brick the game. `AlreadySettled` on the second legit call.
- **Encoding footgun** — uses `verifyNormalized`, whose randomness is computed over the canonical uncompressed signature point. A relayer can't choose compressed-vs-uncompressed to change the winner.

See the DrandVerifier README (§ "Integration caveats") for the reasoning behind each of these.

## Requirements

- [Foundry](https://book.getfoundry.sh/) (tested with `forge 1.5.0-nightly`)
- A chain that supports EIP-2537 BLS12-381 precompiles (Pectra / Isthmus). Ethereum mainnet, most major Pectra-enabled L2s, and MegaETH devnet all qualify.
- A deployed `DrandOracleQuicknet` on the target chain. See upstream [DrandVerifier](https://github.com/Zodomo/DrandVerifier), or deploy it with `script/DeployOracle.s.sol` in this repo.
- For `script/demo.sh` only: `bash`, `curl`, `jq`, and `python3` on PATH. Internet access to reach `api.drand.sh`.

### Dev-account cheat sheet

All examples below assume standard hardhat test accounts (mnemonic
`test test test test test test test test test test test junk`), which most
devnets (including the MegaETH op-stack devnet) pre-fund at genesis. The
first four:

| #   | Address                                      | Private key                                                          |
| --- | -------------------------------------------- | -------------------------------------------------------------------- |
| 0   | `0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266` | `0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80` |
| 1   | `0x70997970C51812dc3A010C7d01b50e0d17dc79C8` | `0x59c6995e998f97a5a0044966f0945389dc9e86dae88c7a8412f4603b6b78690d` |
| 2   | `0x3C44CdDdB6a900fa2b585dd299e03d12FA4293BC` | `0x5de4111afa1a4b94908f83103eb1f1706367c2e68ca870fc3fb9a804cdab365a` |
| 3   | `0x90F79bf6EB2c4f870365E785982E1f101E93b906` | `0x7c852118294e51e653712a81e05800f419141751be58f605c371e15141b007a6` |

`script/demo.sh` hard-codes #0–#3, so if you're running against a chain that
doesn't fund those, edit the script. On real networks, supply your own
`PRIVATE_KEY` via env.

## Layout

```
drand-lottery-demo/
├── src/DrandLottery.sol              # consumer contract
├── script/
│   ├── DeployOracle.s.sol            # forge script: deploy DrandOracleQuicknet
│   ├── DeployLottery.s.sol           # forge script: deploy DrandLottery, wires DrandOracleQuicknet by env var
│   └── demo.sh                       # end-to-end shell demo against live drand
├── test/DrandLottery.t.sol           # 5 unit tests, uses canonical vector
├── foundry.toml                      # remappings + [dependencies] block
├── foundry.lock, soldeer.lock        # Foundry / Soldeer lockfiles
├── .gitmodules                       # single submodule: DrandVerifier
└── dependencies/                     # everything lives here, by Foundry default
    ├── forge-std-1.15.0/             # installed via Soldeer
    └── DrandVerifier/                # git submodule, pinned to a commit
        └── lib/{bls-solidity,solady,forge-std}/    # DrandVerifier's own nested submodules
```

Why two mechanisms? `forge-std` is on Soldeer so we install it there — no git
churn. DrandVerifier isn't on Soldeer (and `randa-mu/bls-solidity`, which it
depends on, is also not there), so that one is a git submodule. Both land in
`dependencies/` (Foundry's default now that this project has a `[dependencies]`
table). DrandVerifier's own source imports `../../lib/bls-solidity/...` and
`../../lib/solady/...` as relative paths, so its _nested_ submodules are what
resolve those — we don't need to install bls-solidity or solady at our level.

## Setup (first clone)

```bash
# if you're cloning the repo, pull submodules too
git clone --recurse-submodules <url>
cd drand-lottery-demo

# or if you already cloned without --recurse-submodules:
git submodule update --init --recursive

# install the Soldeer dep
forge soldeer install
```

## Build & test

```bash
forge build
forge test -vv
```

Tests use `vm.warp` to jump chain time to the quicknet genesis + round math so
the canonical vector (round 20791007) becomes the "future" round picked by
`close()`. No network required.

## Deploy

Two steps: `DrandOracleQuicknet` first, then the lottery pointed at it. Skip
step 1 if you already have a `DrandOracleQuicknet` on the target chain — just
set `ORACLE_ADDRESS` directly.

### 1. Deploy DrandOracleQuicknet (once per chain)

```bash
export RPC_URL=http://localhost:9545                                              # your chain's RPC
export PRIVATE_KEY=0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80   # hardhat #0; replace on real networks

forge create dependencies/DrandVerifier/src/oracles/DrandOracleQuicknet.sol:DrandOracleQuicknet \
  --rpc-url "$RPC_URL" --private-key "$PRIVATE_KEY" \
  --broadcast --legacy --gas-limit 500000000                                      # MegaETH note below
```

Or, equivalently, via `forge script` — note you need `--gas-estimate-multiplier`,
not `--gas-limit`, because `forge script` ignores `--gas-limit` in broadcast
mode and drives gas from the estimate:

```bash
forge script script/DeployOracle.s.sol \
  --rpc-url "$RPC_URL" --broadcast --legacy --gas-estimate-multiplier 5000
```

Grab the address from the output and export it:

```bash
export ORACLE_ADDRESS=0x...
```

### 2. Deploy the lottery wired to DrandOracleQuicknet

```bash
forge create src/DrandLottery.sol:DrandLottery \
  --rpc-url "$RPC_URL" --private-key "$PRIVATE_KEY" \
  --broadcast --legacy --gas-limit 200000000 \
  --constructor-args "$ORACLE_ADDRESS"
```

Or via `forge script` (same caveat about estimator):

```bash
forge script script/DeployLottery.s.sol \
  --rpc-url "$RPC_URL" --broadcast --legacy --gas-estimate-multiplier 5000
```

### MegaETH gas note

MegaETH's multi-dimensional gas model meters contract creation more
expensively than stock EVM. `DrandOracleQuicknet` costs ~150 M gas to deploy;
`DrandLottery` costs ~25 M. Two footguns to know about:

- `forge create --gas-limit <N>` is honored verbatim — set it high (500 M for
  `DrandOracleQuicknet`, 200 M for the lottery). This is the reliable path on
  MegaETH.
- `forge script --gas-limit <N>` is **silently ignored** in broadcast mode.
  The effective gas is `estimate × multiplier`, and the default multiplier of
  1.3 drastically undershoots MegaETH's real cost. Use
  `--gas-estimate-multiplier 5000` (or similar) instead.

On Ethereum mainnet and other Pectra chains, normal estimation is fine and
you can drop the gas overrides entirely.

## End-to-end demo

Once both contracts are deployed, run the full commit-reveal flow against live
drand:

```bash
export RPC_URL=http://localhost:9545
export ORACLE_ADDRESS=0x...                         # DrandOracleQuicknet
export LOTTERY_ADDRESS=0x...                        # from the deploy step
./script/demo.sh
```

The script:

1. Calls `open()` from hardhat account #0, captures the game id.
2. Has hardhat accounts #1, #2, #3 each `enter()` with a 0.1 ETH stake.
3. Calls `close()` — contract commits to `revealRound = currentRound + 2`.
4. Sleeps until `publish_time(revealRound)` has passed.
5. Curls `api.drand.sh` for that round, extracts the 48-byte compressed G1 signature.
6. Calls `settle(id, sig)`.
7. Prints the winner and the three players' balance deltas.

Expected output:

```
==== 5. Settle -- verify sig on-chain, pick winner, pay out ====
  winner = 0x3C44CdDdB6a900fa2b585dd299e03d12FA4293BC
  pot    = 300000000000000000 wei

==== 6. Balance deltas ====
  P1 0x7099...79C8 : delta -100000000000000000   # lost stake
  P2 0x3C44...93BC : delta +200000000000000000   # won pot minus own stake
  P3 0x90F7...b906 : delta -100000000000000000
```

(Which player wins depends on the beacon of the specific round that lands.)

## Known limitations

- Minimum round gap (`MIN_FUTURE_ROUNDS = 2`) is conservative; real deployments might want larger margins to tolerate reorgs and latency.
- `close()` can be called by anyone. For a real app you'd add a trusted closer, timelock, or minimum-entrants threshold.
- No drand-stall fallback. If round N never gets signed (network outage), `settle()` will wait forever. Add an expiry + cancel path in production.
- `settle()`'s randomness is used directly for entrant selection. For a lottery that's fine; for anything that derives multiple secrets, hash more than once.

## License

MIT.
