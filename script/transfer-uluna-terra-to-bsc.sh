#!/bin/bash

# Script to transfer uluna from Terra Classic to BSC Testnet
# Usage: ./script/transfer-uluna-terra-to-bsc.sh [AMOUNT] [BSC_RECIPIENT]

# Configuration
TERRA_WARP="terra1whrvf9u47c23lxa8wxc6vp4jy2l9p5x2gh3gqnpqy2snv7akxanqjcrlu8"
DEST_DOMAIN=97  # BSC Testnet
KEY_NAME="${KEY_NAME:-hypelane-val-testnet}"
KEYRING_BACKEND="file"
CHAIN_ID="rebel-2"
NODE="https://rpc.luncblaze.com:443"
FEES="12000000uluna"

# Parameters
AMOUNT="${1:-1000000}"  # Default: 1 LUNA (1,000,000 uluna)
BSC_ADDRESS="${2:-0x63B2f9C469F422De8069Ef6FE382672F16a367d3}"  # Default: BSC warp route address
HOOK_FEE="283215"  # Required hook fee for cross-chain gas payment

# Convert BSC address to Hyperlane format (64 hex characters, padded)
BSC_RECIPIENT=$(node -e "
const addr = '${BSC_ADDRESS}';
const hex = addr.replace('0x', '').toLowerCase();
const padded = hex.padStart(64, '0');
console.log(padded);
" 2>/dev/null)

if [ -z "${BSC_RECIPIENT}" ]; then
  echo "❌ Error: Failed to convert BSC address. Make sure Node.js is installed."
  echo "   You can manually convert: remove '0x', lowercase, pad to 64 chars"
  exit 1
fi

echo "Transferring uluna: Terra Classic → BSC Testnet"
echo "================================================"
echo "Terra Warp Contract: ${TERRA_WARP}"
echo "Destination Domain: ${DEST_DOMAIN} (BSC Testnet)"
echo "BSC Recipient: ${BSC_ADDRESS}"
echo "Recipient (formatted): ${BSC_RECIPIENT}"
echo "Transfer Amount: ${AMOUNT} uluna ($(echo "scale=6; ${AMOUNT}/1000000" | bc) LUNA)"
echo "Hook Fee: ${HOOK_FEE} uluna (required for cross-chain gas)"
echo "Transaction Fees: ${FEES}"
TOTAL_AMOUNT=$((AMOUNT + HOOK_FEE))
echo "Total Amount: ${TOTAL_AMOUNT} uluna ($(echo "scale=6; ${TOTAL_AMOUNT}/1000000" | bc) LUNA)"
echo ""

# Check if key exists
if ! terrad keys show ${KEY_NAME} --keyring-backend ${KEYRING_BACKEND} &>/dev/null; then
  echo "⚠️  Error: Key '${KEY_NAME}' not found in keyring."
  echo "Available keys:"
  terrad keys list --keyring-backend ${KEYRING_BACKEND} 2>/dev/null | grep -E "^[a-z]" || echo "  (none found)"
  echo ""
  echo "Please add your key:"
  echo "  terrad keys add ${KEY_NAME} --recover --keyring-backend ${KEYRING_BACKEND}"
  exit 1
fi

echo "Using key: ${KEY_NAME}"
echo "Key address: $(terrad keys show ${KEY_NAME} --keyring-backend ${KEYRING_BACKEND} --address)"
echo ""

# Create execution message
EXECUTE_MSG=$(cat <<EOF
{
  "transfer_remote": {
    "dest_domain": ${DEST_DOMAIN},
    "recipient": "${BSC_RECIPIENT}",
    "amount": "${AMOUNT}"
  }
}
EOF
)

echo "Execution message:"
echo "${EXECUTE_MSG}" | jq .
echo ""

# Confirm before executing
read -p "Do you want to proceed with this transfer? (y/n): " confirm
if [ "$confirm" != "y" ]; then
  echo "Transfer cancelled."
  exit 0
fi

echo ""
echo "Executing transfer..."

# Calculate total: transfer amount + hook fee
TOTAL_AMOUNT=$((AMOUNT + HOOK_FEE))

# Execute
# Include both transfer amount and hook fee (summed into single value)
# Note: terrad does not accept comma-separated values of the same denomination
terrad tx wasm execute ${TERRA_WARP} "${EXECUTE_MSG}" \
  --from ${KEY_NAME} \
  --keyring-backend ${KEYRING_BACKEND} \
  --chain-id ${CHAIN_ID} \
  --node ${NODE} \
  --gas auto \
  --gas-adjustment 1.5 \
  --fees ${FEES} \
  --amount ${TOTAL_AMOUNT}uluna \
  --yes

echo ""
echo "✅ Transaction submitted!"
echo ""
echo "To check transaction status:"
echo "  terrad query tx <TX_HASH> --chain-id ${CHAIN_ID} --node ${NODE}"
echo ""
echo "Note: The transfer will be processed by Hyperlane relayers."
echo "      It may take a few minutes for tokens to arrive on BSC."

