#!/bin/bash

# Script to link uluna warp route: Terra Classic → BSC Testnet
# Usage: ./script/link-uluna-warp-terrad.sh

# Configuration
TERRA_WARP_ADDRESS="terra1whrvf9u47c23lxa8wxc6vp4jy2l9p5x2gh3gqnpqy2snv7akxanqjcrlu8"
BSC_WARP_ADDRESS="0x63B2f9C469F422De8069Ef6FE382672F16a367d3"
TARGET_DOMAIN=97  # BSC Testnet
CHAIN_ID="rebel-2"
NODE="https://rpc.luncblaze.com:443"
KEY_NAME="${KEY_NAME:-hypelane-val-testnet}"
KEYRING_BACKEND="file"

# Convert BSC address to hex format (64 characters, padded)
BSC_HEX=$(echo "${BSC_WARP_ADDRESS}" | sed 's/0x//' | tr '[:upper:]' '[:lower:]')
BSC_ROUTE=$(printf "%064s" "${BSC_HEX}" | tr ' ' '0')

echo "Linking uluna warp route: Terra Classic → BSC Testnet"
echo "Terra Warp Address: ${TERRA_WARP_ADDRESS}"
echo "BSC Warp Address: ${BSC_WARP_ADDRESS}"
echo "Target Domain: ${TARGET_DOMAIN} (BSC Testnet)"
echo "Route (hex, 64 chars): ${BSC_ROUTE}"
echo ""

# Check if key exists
if ! terrad keys show ${KEY_NAME} --keyring-backend ${KEYRING_BACKEND} &>/dev/null; then
  echo "⚠️  Error: Key '${KEY_NAME}' not found in keyring."
  echo "Available keys:"
  terrad keys list --keyring-backend ${KEYRING_BACKEND} 2>/dev/null | grep -E "^[a-z]" || echo "  (none found)"
  exit 1
fi

echo "Using key: ${KEY_NAME}"
echo "Key address: $(terrad keys show ${KEY_NAME} --keyring-backend ${KEYRING_BACKEND} --address)"
echo ""

# Create execution message
EXECUTE_MSG=$(cat <<EOF
{
  "router": {
    "set_route": {
      "set": {
        "domain": ${TARGET_DOMAIN},
        "route": "${BSC_ROUTE}"
      }
    }
  }
}
EOF
)

echo "Execution message:"
echo "${EXECUTE_MSG}" | jq .
echo ""

# Execute
terrad tx wasm execute ${TERRA_WARP_ADDRESS} "${EXECUTE_MSG}" \
  --from ${KEY_NAME} \
  --keyring-backend ${KEYRING_BACKEND} \
  --chain-id ${CHAIN_ID} \
  --node ${NODE} \
  --gas auto \
  --gas-adjustment 1.5 \
  --fees 12000000uluna \
  --yes

echo ""
echo "✅ Transaction submitted!"
echo ""
echo "To verify the route was set:"
echo "  terrad query wasm contract-state smart ${TERRA_WARP_ADDRESS} '{\"router\":{\"route\":{\"domain\":${TARGET_DOMAIN}}}}' --chain-id ${CHAIN_ID} --node ${NODE}"

