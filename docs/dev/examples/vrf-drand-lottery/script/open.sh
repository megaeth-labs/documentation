#!/usr/bin/env bash
#
# Open a lottery round: commit the entrant set and a future drand quicknet round.
#
# Env (or .env): RPC_URL, PRIVATE_KEY, LOTTERY_ADDRESS, ENTRANTS, DELAY_SECONDS

set -euo pipefail
cd "$(dirname "$0")/.."
[ -f .env ] && set -a && . ./.env && set +a

: "${RPC_URL:?}"
: "${PRIVATE_KEY:?}"
: "${LOTTERY_ADDRESS:?run script/deploy-lottery.sh first, or set LOTTERY_ADDRESS}"
: "${ENTRANTS:?}"
: "${DELAY_SECONDS:=24}"

echo "opening lottery on $LOTTERY_ADDRESS"
echo "entrants:    $ENTRANTS"
echo "delay:       ${DELAY_SECONDS}s"

cast send --private-key "$PRIVATE_KEY" --rpc-url "$RPC_URL" \
  --gas-limit 30000000 \
  "$LOTTERY_ADDRESS" "open(address[],uint64)" "$ENTRANTS" "$DELAY_SECONDS" \
  | grep -E 'status|gasUsed|transactionHash'

echo "---"
echo "revealRound: $(cast call "$LOTTERY_ADDRESS" 'revealRound()(uint64)' --rpc-url "$RPC_URL")"
echo "publishTime: $(cast call "$LOTTERY_ADDRESS" 'publishTime()(uint256)' --rpc-url "$RPC_URL")"
echo
echo "next: run script/settle.sh once publishTime has passed."
