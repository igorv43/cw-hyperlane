#!/bin/bash

# Script to instantiate uluna native warp route on Terra Classic Testnet
# Usage: ./script/instantiate-uluna-warp.sh

# Configuration
CODE_ID=2000
LABEL="cw-hpl: hpl_warp_native"
ADMIN="terra12awgqgwm2evj05ndtgs0xa35uunlpc76d85pze"
OWNER="terra12awgqgwm2evj05ndtgs0xa35uunlpc76d85pze"
MAILBOX="terra1rqg3qfkfg5upad9xu6zj5jhl626qy053s7rn08829rgqzv2wu39s5la8yf"
CHAIN_ID="rebel-2"
NODE="https://rpc.luncblaze.com:443"

# Create instantiation message
INSTANTIATE_MSG=$(cat <<EOF
{
  "token": {
    "collateral": {
      "denom": "uluna"
    }
  },
  "hrp": "terra",
  "owner": "${OWNER}",
  "mailbox": "${MAILBOX}"
}
EOF
)

echo "Instantiating uluna native warp route..."
echo "Code ID: ${CODE_ID}"
echo "Label: ${LABEL}"
echo "Admin: ${ADMIN}"
echo ""
echo "Instantiation message:"
echo "${INSTANTIATE_MSG}" | jq .
echo ""

# Key configuration
# Change KEY_NAME to match your keyring key name (e.g., "hypelane-val-testnet" or "uluna-warp")
KEY_NAME="${KEY_NAME:-hypelane-val-testnet}"  # Default to hypelane-val-testnet, can be overridden
KEYRING_BACKEND="file"

# Check if key exists
if ! terrad keys show ${KEY_NAME} --keyring-backend ${KEYRING_BACKEND} &>/dev/null; then
  echo "⚠️  Warning: Key '${KEY_NAME}' not found in keyring."
  echo "Available keys:"
  terrad keys list --keyring-backend ${KEYRING_BACKEND} 2>/dev/null | grep -E "^[a-z]" || echo "  (none found)"
  echo ""
  echo "Please either:"
  echo "  1. Add your key: terrad keys add ${KEY_NAME} --recover --keyring-backend ${KEYRING_BACKEND}"
  echo "  2. Or set KEY_NAME environment variable: KEY_NAME=your-key-name ./script/instantiate-uluna-warp.sh"
  echo ""
  read -p "Do you want to add a key now? (y/n): " add_key
  if [ "$add_key" = "y" ]; then
    terrad keys add ${KEY_NAME} --recover --keyring-backend ${KEYRING_BACKEND}
  else
    echo "Exiting. Please add your key and try again."
    exit 1
  fi
fi

echo "Using key: ${KEY_NAME}"
echo "Key address: $(terrad keys show ${KEY_NAME} --keyring-backend ${KEYRING_BACKEND} --address)"
echo ""

# Execute terrad command
# Use key name instead of address if key is in keyring
terrad tx wasm instantiate ${CODE_ID} "${INSTANTIATE_MSG}" \
  --label "${LABEL}" \
  --admin "${ADMIN}" \
  --from "${KEY_NAME}" \
  --keyring-backend "${KEYRING_BACKEND}" \
  --chain-id "${CHAIN_ID}" \
  --node "${NODE}" \
  --gas auto \
  --gas-adjustment 1.5 \
  --fees 12000000uluna \
  --yes

echo ""
echo "✅ Transaction submitted!"
echo ""
echo "To check transaction status:"
echo "  terrad query tx <TX_HASH> --chain-id ${CHAIN_ID} --node ${NODE}"
echo ""
echo "To get contract address:"
echo "  terrad query tx <TX_HASH> --chain-id ${CHAIN_ID} --node ${NODE} --output json | jq -r '.logs[0].events[] | select(.type == \"instantiate\") | .attributes[] | select(.key == \"_contract_address\") | .value'"
echo ""
echo "Or check on block explorer:"
echo "  https://testnet.luncblaze.com"

