#!/usr/bin/env bash
#
# Deploy DrandOracleQuicknet from the upstream DrandVerifier repo and write
# its address into .env. Optional — reuse the pre-deployed oracle listed in
# .env.example if you don't need your own instance.
#
# Env (or .env): RPC_URL, PRIVATE_KEY

set -euo pipefail
cd "$(dirname "$0")/.."
[ -f .env ] && set -a && . ./.env && set +a

: "${RPC_URL:?}"
: "${PRIVATE_KEY:?}"

REPO_URL="${DRAND_VERIFIER_REPO:-https://github.com/Zodomo/DrandVerifier.git}"
REPO_REF="${DRAND_VERIFIER_REF:-main}"
CACHE_DIR=".drandverifier"

if [ ! -d "$CACHE_DIR" ]; then
  echo "cloning $REPO_URL ($REPO_REF)…"
  git clone --recursive --branch "$REPO_REF" --depth 1 "$REPO_URL" "$CACHE_DIR"
else
  echo "reusing cached $CACHE_DIR (delete to refresh)"
fi

echo "building DrandVerifier…"
( cd "$CACHE_DIR" && forge build --silent )

ARTIFACT="$CACHE_DIR/out/DrandOracleQuicknet.sol/DrandOracleQuicknet.json"
if [ ! -f "$ARTIFACT" ]; then
  echo "artifact not found at $ARTIFACT" >&2
  exit 1
fi
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

# Patch .env so subsequent scripts pick up the new oracle.
if [ -f .env ]; then
  if grep -q '^ORACLE_ADDRESS=' .env; then
    sed -i.bak "s|^ORACLE_ADDRESS=.*|ORACLE_ADDRESS=$ADDR|" .env && rm -f .env.bak
  else
    echo "ORACLE_ADDRESS=$ADDR" >> .env
  fi
  echo "wrote ORACLE_ADDRESS to .env"
fi
