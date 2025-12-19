#!/bin/bash

# Script para transferir tokens de Terra Classic para Solana
# Uso: ./script/transfer-terra-to-solana.sh <SOLANA_ADDRESS> <AMOUNT_ULUNA>

set -e

# Verificar argumentos
if [ $# -lt 2 ]; then
    echo "Uso: $0 <SOLANA_ADDRESS> <AMOUNT_ULUNA>"
    echo "Exemplo: $0 EMAYGfEyhywUyEX6kfG5FZZMfznmKXM8PbWpkJhJ9Jjd 10000000"
    exit 1
fi

SOLANA_RECIPIENT="$1"
TRANSFER_AMOUNT="$2"

# Configuration
TERRA_WARP="terra1zlm0h2xu6rhnjchn29hxnpvr74uxxqetar9y75zcehyx2mqezg9slj09ml"
SOLANA_DOMAIN="1399811150"
HOOK_FEE="283215"  # Required hook fee for cross-chain gas
KEY_NAME="hypelane-val-testnet"
CHAIN_ID="rebel-2"
NODE="https://rpc.luncblaze.com:443"
IGP="terra1mcaqgr7kqs9xr3q6w0e9f2ekrj6sehwcep9shtss6u8pdz2rsw5qzrew7r"
GAS_AMOUNT="200000"  # Estimated gas for Solana

echo "=== Transferência Terra Classic → Solana ==="
echo "Solana Recipient: ${SOLANA_RECIPIENT}"
echo "Amount: ${TRANSFER_AMOUNT} uluna ($(echo "scale=6; ${TRANSFER_AMOUNT}/1000000" | bc) LUNC)"
echo ""

# Step 1: Convert Solana address to hex
echo "=== Convertendo endereço Solana para hex ==="
SOLANA_RECIPIENT_HEX=$(python3 << EOF
import base58
import binascii

solana_address = "${SOLANA_RECIPIENT}"
decoded = base58.b58decode(solana_address)
hex_address = binascii.hexlify(decoded).decode('utf-8')
hex_padded = hex_address.zfill(64)
print(hex_padded)  # 64 hex characters, no 0x
EOF
)

echo "Solana recipient hex: ${SOLANA_RECIPIENT_HEX}"
echo ""

# Step 2: Query IGP for gas payment
echo "=== Consultando IGP para calcular gas necessário ==="
IGP_GAS=$(terrad query wasm contract-state smart ${IGP} \
  '{"igp":{"quote_gas_payment":{"dest_domain":'${SOLANA_DOMAIN}',"gas_amount":"'${GAS_AMOUNT}'"}}}' \
  --chain-id ${CHAIN_ID} \
  --node ${NODE} \
  --output json | jq -r '.data.gas_needed')

if [ -z "$IGP_GAS" ] || [ "$IGP_GAS" == "null" ]; then
    echo "❌ Erro: Não foi possível obter o IGP gas. Verifique a configuração do IGP Oracle."
    exit 1
fi

IGP_GAS_LUNC=$(echo "scale=2; ${IGP_GAS}/1000000" | bc)
echo "IGP Gas necessário: ${IGP_GAS} uluna (${IGP_GAS_LUNC} LUNC)"
echo ""

# Step 3: Calculate total amount
echo "=== Calculando valor total ==="
TOTAL_AMOUNT=$((TRANSFER_AMOUNT + HOOK_FEE + IGP_GAS))
TOTAL_AMOUNT_LUNC=$(echo "scale=2; ${TOTAL_AMOUNT}/1000000" | bc)

echo "Transfer Amount: ${TRANSFER_AMOUNT} uluna ($(echo "scale=6; ${TRANSFER_AMOUNT}/1000000" | bc) LUNC)"
echo "Hook Fee: ${HOOK_FEE} uluna"
echo "IGP Gas: ${IGP_GAS} uluna (${IGP_GAS_LUNC} LUNC)"
echo "TOTAL: ${TOTAL_AMOUNT} uluna (${TOTAL_AMOUNT_LUNC} LUNC)"
echo ""

# Step 4: Check balance (optional)
echo "=== Verificando saldo ==="
BALANCE=$(terrad query bank balances $(terrad keys show ${KEY_NAME} --keyring-backend file --address) \
  --chain-id ${CHAIN_ID} \
  --node ${NODE} \
  --output json | jq -r '.balances[] | select(.denom=="uluna") | .amount' || echo "0")

if [ -z "$BALANCE" ]; then
    BALANCE="0"
fi

BALANCE_LUNC=$(echo "scale=2; ${BALANCE}/1000000" | bc)
echo "Saldo disponível: ${BALANCE} uluna (${BALANCE_LUNC} LUNC)"

# Verificar se tem saldo suficiente (incluindo fees de transação ~70 LUNC)
REQUIRED_WITH_FEES=$((TOTAL_AMOUNT + 70000000))
REQUIRED_WITH_FEES_LUNC=$(echo "scale=2; ${REQUIRED_WITH_FEES}/1000000" | bc)

if [ "$BALANCE" -lt "$REQUIRED_WITH_FEES" ]; then
    echo "⚠️  AVISO: Saldo insuficiente!"
    echo "   Necessário: ${REQUIRED_WITH_FEES} uluna (${REQUIRED_WITH_FEES_LUNC} LUNC)"
    echo "   Disponível: ${BALANCE} uluna (${BALANCE_LUNC} LUNC)"
    echo "   Faltam: $((REQUIRED_WITH_FEES - BALANCE)) uluna ($(echo "scale=2; ($REQUIRED_WITH_FEES - $BALANCE)/1000000" | bc) LUNC)"
    echo ""
    read -p "Deseja continuar mesmo assim? (y/N): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        exit 1
    fi
else
    echo "✅ Saldo suficiente"
fi
echo ""

# Step 5: Execute transfer
echo "=== Executando transferência ==="
echo "Comando:"
echo "terrad tx wasm execute ${TERRA_WARP} \\"
echo "  '{\"transfer_remote\":{\"dest_domain\":${SOLANA_DOMAIN},\"recipient\":\"${SOLANA_RECIPIENT_HEX}\",\"amount\":\"${TRANSFER_AMOUNT}\"}}' \\"
echo "  --from ${KEY_NAME} \\"
echo "  --keyring-backend file \\"
echo "  --chain-id ${CHAIN_ID} \\"
echo "  --node ${NODE} \\"
echo "  --gas auto \\"
echo "  --gas-adjustment 1.5 \\"
echo "  --fees 70000000uluna \\"
echo "  --amount ${TOTAL_AMOUNT}uluna \\"
echo "  --yes"
echo ""

terrad tx wasm execute ${TERRA_WARP} \
  "{\"transfer_remote\":{\"dest_domain\":${SOLANA_DOMAIN},\"recipient\":\"${SOLANA_RECIPIENT_HEX}\",\"amount\":\"${TRANSFER_AMOUNT}\"}}" \
  --from ${KEY_NAME} \
  --keyring-backend file \
  --chain-id ${CHAIN_ID} \
  --node ${NODE} \
  --gas auto \
  --gas-adjustment 1.5 \
  --fees 70000000uluna \
  --amount ${TOTAL_AMOUNT}uluna \
  --yes

echo ""
echo "✅ Transferência enviada com sucesso!"
echo "Aguarde a confirmação na blockchain."

