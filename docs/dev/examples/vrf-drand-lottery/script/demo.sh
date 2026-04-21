#!/usr/bin/env bash
# End-to-end demo of DrandLottery commit-reveal flow.
#
# Required env:
#   RPC_URL         - JSON-RPC URL (e.g. http://localhost:9545)
#   ORACLE_ADDRESS  - deployed DrandOracleQuicknet
#   LOTTERY_ADDRESS - deployed DrandLottery (points at oracle above)
# Optional:
#   STAKE_WEI       - amount each player enters with (default 100000000000000000 = 0.1 ETH)
#   GAS_LIMIT       - gas limit for settle() (default 100000000; real use 15-20M, we give headroom)
#
# Assumes standard hardhat dev accounts (0..3) exist with funds. Account 0 is the
# "opener/settler" and 1..3 are the three players.

set -euo pipefail
export FOUNDRY_DISABLE_NIGHTLY_WARNING=1

: "${RPC_URL:?set RPC_URL}"
: "${ORACLE_ADDRESS:?set ORACLE_ADDRESS}"
: "${LOTTERY_ADDRESS:?set LOTTERY_ADDRESS}"
: "${STAKE_WEI:=100000000000000000}"
: "${GAS_LIMIT:=100000000}"

OPENER_PK=0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80     # hardhat #0
P1_PK=0x59c6995e998f97a5a0044966f0945389dc9e86dae88c7a8412f4603b6b78690d         # hardhat #1
P2_PK=0x5de4111afa1a4b94908f83103eb1f1706367c2e68ca870fc3fb9a804cdab365a         # hardhat #2
P3_PK=0x7c852118294e51e653712a81e05800f419141751be58f605c371e15141b007a6         # hardhat #3

P1_ADDR=$(cast wallet address --private-key $P1_PK)
P2_ADDR=$(cast wallet address --private-key $P2_PK)
P3_ADDR=$(cast wallet address --private-key $P3_PK)

QUICKNET_CHAIN=52db9ba70e0cc0f6eaf7803dd07447a1f5477735fd3f661792ba94600c84e971

hr() { printf "\n\033[1;36m==== %s ====\033[0m\n" "$*"; }

hr "Environment"
echo "  RPC:       $RPC_URL"
echo "  Oracle:    $ORACLE_ADDRESS"
echo "  Lottery:   $LOTTERY_ADDRESS"
echo "  Players:   $P1_ADDR, $P2_ADDR, $P3_ADDR"
echo "  Stake:     $STAKE_WEI wei each"

hr "1. Open game"
OPEN_TX=$(cast send "$LOTTERY_ADDRESS" "open()" \
    --rpc-url "$RPC_URL" --private-key "$OPENER_PK" \
    --gas-limit "$GAS_LIMIT" --json | tee /dev/stderr | jq -r .transactionHash)
# nextGameId is incremented post-assignment, so the id of the game we just
# opened is the new counter minus 1.
NEXT_ID=$(cast call "$LOTTERY_ADDRESS" "nextGameId()(uint256)" --rpc-url "$RPC_URL")
GAME_ID=$((NEXT_ID - 1))
echo "  -> game id = $GAME_ID"

hr "2. Three players enter"
for PK in $P1_PK $P2_PK $P3_PK; do
    ADDR=$(cast wallet address --private-key "$PK")
    echo "  $ADDR enters with $STAKE_WEI wei..."
    cast send "$LOTTERY_ADDRESS" "enter(uint256)" "$GAME_ID" \
        --rpc-url "$RPC_URL" --private-key "$PK" \
        --value "$STAKE_WEI" --gas-limit "$GAS_LIMIT" >/dev/null
done
cast call "$LOTTERY_ADDRESS" "entrants(uint256)(address[])" "$GAME_ID" --rpc-url "$RPC_URL"

hr "3. Close game (commit to future drand round)"
cast send "$LOTTERY_ADDRESS" "close(uint256)" "$GAME_ID" \
    --rpc-url "$RPC_URL" --private-key "$OPENER_PK" \
    --gas-limit "$GAS_LIMIT" >/dev/null
# Read revealRound and publish time.
GAME_STATE=$(cast call "$LOTTERY_ADDRESS" "game(uint256)(uint64,bool,uint256,address,uint256)" "$GAME_ID" --rpc-url "$RPC_URL")
REVEAL_ROUND=$(echo "$GAME_STATE" | head -n1 | awk '{print $1}')
PUBLISH_TIME=$(cast call "$LOTTERY_ADDRESS" "publishTimeOf(uint64)(uint64)" "$REVEAL_ROUND" --rpc-url "$RPC_URL" | awk '{print $1}')
NOW=$(date -u +%s)
echo "  reveal round   = $REVEAL_ROUND"
echo "  publish time   = $PUBLISH_TIME (unix)"
echo "  wall clock now = $NOW"
WAIT=$((PUBLISH_TIME - NOW + 2))  # +2s slack for the drand API to serve it
if [ "$WAIT" -gt 0 ]; then
    echo "  sleeping ${WAIT}s until round is published..."
    sleep "$WAIT"
fi

hr "4. Fetch signature from drand"
RESP=$(curl -fsSL "https://api.drand.sh/v2/chains/${QUICKNET_CHAIN}/rounds/${REVEAL_ROUND}")
echo "  api response: $RESP"
SIG=0x$(echo "$RESP" | python3 -c "import sys,json; print(json.load(sys.stdin)['signature'])")
echo "  signature (compressed G1): $SIG"

hr "5. Settle -- verify sig on-chain, pick winner, pay out"
BAL_BEFORE_1=$(cast balance $P1_ADDR --rpc-url "$RPC_URL")
BAL_BEFORE_2=$(cast balance $P2_ADDR --rpc-url "$RPC_URL")
BAL_BEFORE_3=$(cast balance $P3_ADDR --rpc-url "$RPC_URL")

cast send "$LOTTERY_ADDRESS" "settle(uint256,bytes)" "$GAME_ID" "$SIG" \
    --rpc-url "$RPC_URL" --private-key "$OPENER_PK" \
    --gas-limit "$GAS_LIMIT" >/dev/null

GAME_STATE=$(cast call "$LOTTERY_ADDRESS" "game(uint256)(uint64,bool,uint256,address,uint256)" "$GAME_ID" --rpc-url "$RPC_URL")
WINNER=$(echo "$GAME_STATE" | sed -n '4p')
POT=$(echo "$GAME_STATE" | sed -n '3p' | awk '{print $1}')
echo "  winner = $WINNER"
echo "  pot    = $POT wei"

BAL_AFTER_1=$(cast balance $P1_ADDR --rpc-url "$RPC_URL")
BAL_AFTER_2=$(cast balance $P2_ADDR --rpc-url "$RPC_URL")
BAL_AFTER_3=$(cast balance $P3_ADDR --rpc-url "$RPC_URL")

hr "6. Balance deltas"
printf "  P1 %s : %s -> %s  (delta %s)\n" "$P1_ADDR" "$BAL_BEFORE_1" "$BAL_AFTER_1" "$((BAL_AFTER_1 - BAL_BEFORE_1))"
printf "  P2 %s : %s -> %s  (delta %s)\n" "$P2_ADDR" "$BAL_BEFORE_2" "$BAL_AFTER_2" "$((BAL_AFTER_2 - BAL_BEFORE_2))"
printf "  P3 %s : %s -> %s  (delta %s)\n" "$P3_ADDR" "$BAL_BEFORE_3" "$BAL_AFTER_3" "$((BAL_AFTER_3 - BAL_BEFORE_3))"

hr "Done"
