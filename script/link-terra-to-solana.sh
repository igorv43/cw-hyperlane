#!/bin/bash

# Link Terra Classic → Solana Warp Route
# This script enrolls the Solana warp route as a remote router on Terra Classic

set -e

# Variables
TERRA_WARP="terra1zlm0h2xu6rhnjchn29hxnpvr74uxxqetar9y75zcehyx2mqezg9slj09ml"
SOLANA_DOMAIN="1399811150"
SOLANA_WARP_HEX="3e39de1edbc0495cee651b3e046f63d01ff9436932bb520e8c0cb4ba5c5c7f1d"
KEY_NAME="hypelane-val-testnet"
CHAIN_ID="rebel-2"
RPC_NODE="https://rpc.luncblaze.com:443"
FEES="12000000uluna"

echo "🔗 Linking Terra Classic → Solana Warp Route"
echo ""
echo "Terra Classic Warp Route: $TERRA_WARP"
echo "Solana Domain: $SOLANA_DOMAIN"
echo "Solana Router (hex): $SOLANA_WARP_HEX"
echo ""

# Verify hex length
if [ ${#SOLANA_WARP_HEX} -ne 64 ]; then
    echo "❌ Error: Solana router hex must be 64 characters (32 bytes)"
    echo "   Current length: ${#SOLANA_WARP_HEX}"
    exit 1
fi

echo "📝 Executing enroll_remote_router transaction..."
echo ""

# Execute
terrad tx wasm execute "$TERRA_WARP" \
  "{\"router\":{\"set_route\":{\"set\":{\"domain\":$SOLANA_DOMAIN,\"route\":\"$SOLANA_WARP_HEX\"}}}}" \
  --from "$KEY_NAME" \
  --keyring-backend file \
  --chain-id "$CHAIN_ID" \
  --node "$RPC_NODE" \
  --gas auto \
  --gas-adjustment 1.5 \
  --fees "$FEES" \
  --yes

echo ""
echo "✅ Transaction submitted!"
echo ""
echo "📋 To verify the enrollment, run:"
echo "   terrad query wasm contract-state smart $TERRA_WARP \\"
echo "     '{\"router\":{\"get_route\":{\"domain\":1399811150}}}' \\"
echo "     --node $RPC_NODE"

