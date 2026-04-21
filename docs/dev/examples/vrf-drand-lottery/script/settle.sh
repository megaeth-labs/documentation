#!/usr/bin/env bash
#
# Poll drand until the committed round is available, then submit its signature.
#
# Env (or .env): RPC_URL, PRIVATE_KEY, LOTTERY_ADDRESS

set -euo pipefail
cd "$(dirname "$0")/.."
[ -f .env ] && set -a && . ./.env && set +a

: "${RPC_URL:?}"
: "${PRIVATE_KEY:?}"
: "${LOTTERY_ADDRESS:?}"

QUICKNET_HASH=52db9ba70e0cc0f6eaf7803dd07447a1f5477735fd3f661792ba94600c84e971

ROUND_OUT=$(cast call "$LOTTERY_ADDRESS" 'revealRound()(uint64)' --rpc-url "$RPC_URL")
ROUND=${ROUND_OUT%% *}
PUBLISH_OUT=$(cast call "$LOTTERY_ADDRESS" 'publishTime()(uint256)' --rpc-url "$RPC_URL")
PUBLISH=${PUBLISH_OUT%% *}

echo "revealRound: $ROUND"
echo "publishTime: $PUBLISH"
echo "now:         $(date +%s)"

# Wait for the target round to be producible.
while [ "$(date +%s)" -lt "$PUBLISH" ]; do sleep 1; done

URL="https://api.drand.sh/v2/chains/$QUICKNET_HASH/rounds/$ROUND"
echo "polling $URL"
for _ in $(seq 1 60); do
  RESP=$(curl -fsSL "$URL" 2>/dev/null || true)
  [ -n "${RESP:-}" ] && break
  sleep 1
done
if [ -z "${RESP:-}" ]; then
  echo "drand did not serve round $ROUND within 60s — aborting" >&2
  exit 1
fi

SIG=$(echo "$RESP" | jq -r '.signature')
echo "signature:   $SIG"

cast send --private-key "$PRIVATE_KEY" --rpc-url "$RPC_URL" \
  --gas-limit 30000000 \
  "$LOTTERY_ADDRESS" "settle(bytes)" "0x$SIG" \
  | grep -E 'status|gasUsed|transactionHash'

echo "---"
echo "winner:      $(cast call "$LOTTERY_ADDRESS" 'winner()(address)'     --rpc-url "$RPC_URL")"
echo "randomness:  $(cast call "$LOTTERY_ADDRESS" 'randomness()(bytes32)' --rpc-url "$RPC_URL")"
