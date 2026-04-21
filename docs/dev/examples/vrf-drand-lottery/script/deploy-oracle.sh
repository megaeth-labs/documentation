#!/usr/bin/env bash
#
# Deploy DrandOracleQuicknet from the in-tree source.
#
# MegaETH's dual-gas model charges materially more for contract creation than
# local Foundry simulation, so we query eth_estimateGas on the node and set
# --gas-limit above that. Using `forge create` with its default estimator
# reverts out-of-gas.
#
# Env (or .env): RPC_URL, PRIVATE_KEY

set -euo pipefail
cd "$(dirname "$0")/.."
[ -f .env ] && set -a && . ./.env && set +a

: "${RPC_URL:?}"
: "${PRIVATE_KEY:?}"

echo "building…"
forge build --silent

ARTIFACT=out/DrandOracleQuicknet.sol/DrandOracleQuicknet.json
BYTECODE=$(jq -r '.bytecode.object' "$ARTIFACT")

FROM=$(cast wallet address --private-key "$PRIVATE_KEY")
GAS_HEX=$(cast rpc eth_estimateGas \
  "{\"from\":\"$FROM\",\"data\":\"$BYTECODE\"}" \
  --rpc-url "$RPC_URL" | tr -d '"')
GAS=$(printf '%d' "$GAS_HEX")
LIMIT=$(( GAS * 130 / 100 ))
echo "node eth_estimateGas = $GAS → --gas-limit $LIMIT (30% margin)"

RECEIPT=$(cast send --private-key "$PRIVATE_KEY" --rpc-url "$RPC_URL" \
  --gas-limit "$LIMIT" --create "$BYTECODE" --json)
ADDR=$(echo "$RECEIPT" | jq -r '.contractAddress')
echo "DrandOracleQuicknet deployed: $ADDR"

# Sanity check — verify a known-good quicknet beacon (round 20791007).
# If this fails the target chain likely lacks EIP-2537 precompiles.
RESULT=$(cast call "$ADDR" "verify(uint64,bytes)(bool)" 20791007 \
  0x8d2c8bbc37170dbacc5e280a21d4e195cff5f32a19fd6a58633fa4e4670478b5fb39bc13dd8f8c4372c5a76191198ac5 \
  --rpc-url "$RPC_URL" || echo "false")
echo "sanity check — verify(known-good vector): $RESULT"
if [ "$RESULT" != "true" ]; then
  echo "WARNING: chain may be missing EIP-2537 BLS12-381 precompiles." >&2
fi

if [ -f .env ]; then
  if grep -q '^ORACLE_ADDRESS=' .env; then
    sed -i.bak "s|^ORACLE_ADDRESS=.*|ORACLE_ADDRESS=$ADDR|" .env && rm -f .env.bak
  else
    echo "ORACLE_ADDRESS=$ADDR" >> .env
  fi
  echo "wrote ORACLE_ADDRESS to .env"
fi
