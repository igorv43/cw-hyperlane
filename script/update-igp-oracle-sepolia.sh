#!/bin/bash

# Script para atualizar o IGP Oracle para Sepolia Testnet (Domain 11155111)
# Usage: ./script/update-igp-oracle-sepolia.sh

# Configuration
IGP_ORACLE="terra1yew4y2ekzhkwuuz07yt7qufqxxejxhmnr7apehkqk7e8jdw8ffqqs8zhds"
KEY_NAME="${KEY_NAME:-hypelane-val-testnet}"
KEYRING_BACKEND="file"
CHAIN_ID="rebel-2"
NODE="https://rpc.luncblaze.com:443"
FEES="12000000uluna"

# Gas data configuration for Sepolia
# Taxa de Câmbio: 177534
# Gas Price: 1000000000 (1 Gwei)
DOMAIN_SEPOLIA=11155111
TOKEN_EXCHANGE_RATE="${1:-177534}"
GAS_PRICE="${2:-1000000000}"

echo "Atualizando IGP Oracle - Sepolia Testnet (Domain ${DOMAIN_SEPOLIA})"
echo "======================================================================"
echo "IGP Oracle: ${IGP_ORACLE}"
echo "Domain: ${DOMAIN_SEPOLIA} (Sepolia Testnet)"
echo "Exchange Rate: ${TOKEN_EXCHANGE_RATE}"
echo "Gas Price: ${GAS_PRICE} (1 Gwei)"
echo ""
echo "⚠️  IMPORTANTE: A chave usada deve ser o OWNER do IGP Oracle."
echo "   Owner padrão: terra10d07y265gmmuvt4z0w9aw880jnsr700juxf95n (governance)"
echo "   Se você transferiu o ownership, use a chave da conta que é owner."
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
  "set_remote_gas_data_configs": {
    "configs": [
      {
        "remote_domain": ${DOMAIN_SEPOLIA},
        "token_exchange_rate": "${TOKEN_EXCHANGE_RATE}",
        "gas_price": "${GAS_PRICE}"
      }
    ]
  }
}
EOF
)

echo "Execution message:"
echo "${EXECUTE_MSG}" | jq .
echo ""

# Confirm before executing
read -p "Do you want to proceed with this update? (y/n): " confirm
if [ "$confirm" != "y" ]; then
  echo "Update cancelled."
  exit 0
fi

echo ""
echo "Executing update..."

# Execute
terrad tx wasm execute ${IGP_ORACLE} "${EXECUTE_MSG}" \
  --from ${KEY_NAME} \
  --keyring-backend ${KEYRING_BACKEND} \
  --chain-id ${CHAIN_ID} \
  --node ${NODE} \
  --gas auto \
  --gas-adjustment 1.5 \
  --fees ${FEES} \
  --yes

echo ""
echo "✅ Transaction submitted!"
echo ""
echo "To verify the update:"
echo "  terrad query wasm contract-state smart ${IGP_ORACLE} '{\"oracle\":{\"get_exchange_rate_and_gas_price\":{\"dest_domain\":${DOMAIN_SEPOLIA}}}}' --chain-id ${CHAIN_ID} --node ${NODE}"
echo ""
echo "To verify IGP calculation:"
echo "  IGP=\"terra1n70g3vg7xge6q8m44rudm4y6fm6elpspwsgfmfphs3teezpak6cs6wxlk9\""
echo "  terrad query wasm contract-state smart \${IGP} '{\"igp\":{\"quote_gas_payment\":{\"dest_domain\":${DOMAIN_SEPOLIA},\"gas_amount\":\"100000\"}}}' --chain-id ${CHAIN_ID} --node ${NODE}"
