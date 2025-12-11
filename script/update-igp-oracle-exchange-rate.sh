#!/bin/bash

# Script para atualizar o exchange_rate do IGP Oracle para domain 97 (BSC Testnet)
# Usage: ./script/update-igp-oracle-exchange-rate.sh

# Configuration
IGP_ORACLE="terra18tyqe79yktac6p3alv3f49k06xqna2q52twyaflrz55qka9emhrs30k3hg"
KEY_NAME="${KEY_NAME:-hypelane-val-testnet}"
KEYRING_BACKEND="file"
CHAIN_ID="rebel-2"
NODE="https://rpc.luncblaze.com:443"
FEES="12000000uluna"

# New exchange rate (recomendado: 14798000000000)
# Valor atual: 1805936462255558 (muito alto, resulta em $1512.01)
# Novo valor: 14798000000000 (calculado para resultar em 74 LUNC = $0.0044894)
# Cálculo: (73,990,000 × 10^18) / (100000 × 50000000) = 14798000000000
# Baseado em: BNB @ $897.88, LUNC @ $0.00006069
NEW_EXCHANGE_RATE="${1:-14798000000000}"
GAS_PRICE="50000000"

echo "Atualizando IGP Oracle - Exchange Rate para BSC Testnet (domain 97)"
echo "======================================================================"
echo "IGP Oracle: ${IGP_ORACLE}"
echo "Domain: 97 (BSC Testnet)"
echo "Exchange Rate atual: 1805936462255558 (resulta em ~\$1512.01 - ERRADO!)"
echo "Exchange Rate novo: ${NEW_EXCHANGE_RATE}"
echo "Custo esperado de gas IGP: 73,990,000 uluna (~74 LUNC = \$0.0044894)"
echo "Baseado em: BNB @ \$897.88, LUNC @ \$0.00006069"
echo "Gas Price: ${GAS_PRICE}"
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
        "remote_domain": 97,
        "token_exchange_rate": "${NEW_EXCHANGE_RATE}",
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
echo "  terrad query wasm contract-state smart ${IGP_ORACLE} '{\"oracle\":{\"get_exchange_rate_and_gas_price\":{\"dest_domain\":97}}}' --chain-id ${CHAIN_ID} --node ${NODE}"
echo ""
echo "To verify IGP calculation:"
echo "  IGP=\"terra1n70g3vg7xge6q8m44rudm4y6fm6elpspwsgfmfphs3teezpak6cs6wxlk9\""
echo "  terrad query wasm contract-state smart \${IGP} '{\"igp\":{\"quote_gas_payment\":{\"dest_domain\":97,\"gas_amount\":\"100000\"}}}' --chain-id ${CHAIN_ID} --node ${NODE}"

