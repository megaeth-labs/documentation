#!/usr/bin/env bash
#
# Deploy DrandLotteryDemo to MegaETH.
#
# Env (or .env): RPC_URL, PRIVATE_KEY, ORACLE_ADDRESS
#
# We query the node's own eth_estimateGas because MegaETH's dual-gas model
# charges materially more for contract creation than local Foundry simulation.
# Trusting `forge create`'s default estimator leads to out-of-gas reverts on
# deploy. See docs/dev/send-tx/gas-estimation.md.

set -euo pipefail
cd "$(dirname "$0")/.."
[ -f .env ] && set -a && . ./.env && set +a

: "${RPC_URL:?}"
: "${PRIVATE_KEY:?}"
: "${ORACLE_ADDRESS:?}"

echo "building…"
forge build --silent

RAW=$(jq -r '.bytecode.object' out/DrandLotteryDemo.sol/DrandLotteryDemo.json)
CTOR=$(cast abi-encode 'constructor(address)' "$ORACLE_ADDRESS")
INIT="${RAW}${CTOR#0x}"

FROM=$(cast wallet address --private-key "$PRIVATE_KEY")
GAS_HEX=$(cast rpc eth_estimateGas \
  "{\"from\":\"$FROM\",\"data\":\"$INIT\"}" \
  --rpc-url "$RPC_URL" | tr -d '"')
GAS=$(printf '%d' "$GAS_HEX")
LIMIT=$(( GAS * 130 / 100 ))
echo "node eth_estimateGas = $GAS → --gas-limit $LIMIT (30% margin)"

RECEIPT=$(cast send --private-key "$PRIVATE_KEY" --rpc-url "$RPC_URL" \
  --gas-limit "$LIMIT" --create "$INIT" --json)
ADDR=$(echo "$RECEIPT" | jq -r '.contractAddress')
echo "DrandLotteryDemo deployed: $ADDR"

# Patch .env so open.sh / settle.sh can pick it up.
if [ -f .env ]; then
  if grep -q '^LOTTERY_ADDRESS=' .env; then
    sed -i.bak "s|^LOTTERY_ADDRESS=.*|LOTTERY_ADDRESS=$ADDR|" .env && rm -f .env.bak
  else
    echo "LOTTERY_ADDRESS=$ADDR" >> .env
  fi
  echo "wrote LOTTERY_ADDRESS to .env"
fi
