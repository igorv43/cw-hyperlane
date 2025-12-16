#!/bin/bash

# Script para atualizar IGP Oracle para Solana Testnet diretamente via terrad
# (sem passar por governança - requer que você seja o owner)

set -e

# Cores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuração
IGP_ORACLE="terra1yew4y2ekzhkwuuz07yt7qufqxxejxhmnr7apehkqk7e8jdw8ffqqs8zhds"
SOLANA_DOMAIN="1399811150"
KEY_NAME="${KEY_NAME:-hypelane-val-testnet}"
KEYRING_BACKEND="file"
CHAIN_ID="rebel-2"
NODE="https://rpc.luncblaze.com:443"
FEES="12000000uluna"

# Valores corretos (calculados seguindo IGP-COMPLETE-GUIDE.md)
# Cálculo: gas_limit 200k, SOL @ $138.93, LUNC @ $0.00006069, 20% margem
EXCHANGE_RATE="27470093900000"
GAS_PRICE="1"

echo -e "${BLUE}╔══════════════════════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║   ATUALIZAR IGP ORACLE: Solana Testnet (Direto)             ║${NC}"
echo -e "${BLUE}╚══════════════════════════════════════════════════════════════╝${NC}"
echo ""

# Verificar se a key existe
if ! terrad keys show ${KEY_NAME} --keyring-backend ${KEYRING_BACKEND} &>/dev/null; then
    echo -e "${RED}❌ Erro: Key '${KEY_NAME}' não encontrada no keyring.${NC}"
    echo "   Keys disponíveis:"
    terrad keys list --keyring-backend ${KEYRING_BACKEND} 2>/dev/null | grep -E "^[a-z]" || echo "   (nenhuma encontrada)"
    exit 1
fi

KEY_ADDRESS=$(terrad keys show ${KEY_NAME} --keyring-backend ${KEYRING_BACKEND} --address)
echo -e "${YELLOW}📋 Configuração:${NC}"
echo "   IGP Oracle: ${IGP_ORACLE}"
echo "   Domain: ${SOLANA_DOMAIN} (Solana Testnet)"
echo "   Key: ${KEY_NAME}"
echo "   Key Address: ${KEY_ADDRESS}"
echo ""

# Verificar se você é o owner
echo -e "${YELLOW}🔍 Verificando owner do IGP Oracle...${NC}"
OWNER=$(terrad query wasm contract-state smart ${IGP_ORACLE} \
  '{"ownable":{"get_owner":{}}}' \
  --chain-id ${CHAIN_ID} \
  --node ${NODE} \
  --output json 2>/dev/null | jq -r '.data.owner' || echo "")

if [ -z "$OWNER" ]; then
    echo -e "${RED}❌ Erro: Não foi possível consultar o owner do IGP Oracle${NC}"
    exit 1
fi

echo "   Owner atual: ${OWNER}"
echo ""

if [ "$OWNER" != "$KEY_ADDRESS" ]; then
    echo -e "${RED}❌ Erro: Você não é o owner do IGP Oracle!${NC}"
    echo "   Owner: ${OWNER}"
    echo "   Sua key: ${KEY_ADDRESS}"
    echo ""
    echo -e "${YELLOW}💡 Solução:${NC}"
    echo "   Se o owner for o módulo de governança, use:"
    echo "   bash script/update-igp-oracle-solana.sh"
    echo "   (cria proposta de governança)"
    exit 1
fi

echo -e "${GREEN}✅ Você é o owner do IGP Oracle!${NC}"
echo ""

# Mostrar valores atuais
echo -e "${YELLOW}📊 Valores Atuais:${NC}"
CURRENT_CONFIG=$(terrad query wasm contract-state smart ${IGP_ORACLE} \
  "{\"oracle\":{\"get_exchange_rate_and_gas_price\":{\"dest_domain\":${SOLANA_DOMAIN}}}}" \
  --chain-id ${CHAIN_ID} \
  --node ${NODE} \
  --output json 2>/dev/null | jq -r '.data // empty' || echo "")

if [ -n "$CURRENT_CONFIG" ]; then
    CURRENT_EXCHANGE_RATE=$(echo "$CURRENT_CONFIG" | jq -r '.token_exchange_rate // "N/A"')
    CURRENT_GAS_PRICE=$(echo "$CURRENT_CONFIG" | jq -r '.gas_price // "N/A"')
    echo "   token_exchange_rate: ${CURRENT_EXCHANGE_RATE}"
    echo "   gas_price: ${CURRENT_GAS_PRICE}"
else
    echo "   (não configurado)"
fi
echo ""

# Mostrar valores novos
echo -e "${YELLOW}✨ Valores Novos:${NC}"
echo "   token_exchange_rate: ${EXCHANGE_RATE}"
echo "   gas_price: ${GAS_PRICE}"
echo "   Custo esperado: ~549.40 LUNC (com 20% margem)"
echo "   Baseado em: SOL @ \$138.93, LUNC @ \$0.00006069, gas_limit 200k"
echo ""

# Criar mensagem de execução
EXECUTE_MSG=$(cat <<EOF
{
  "set_remote_gas_data_configs": {
    "configs": [
      {
        "remote_domain": ${SOLANA_DOMAIN},
        "token_exchange_rate": "${EXCHANGE_RATE}",
        "gas_price": "${GAS_PRICE}"
      }
    ]
  }
}
EOF
)

echo -e "${BLUE}=== Mensagem de Execução ===${NC}"
echo "${EXECUTE_MSG}" | jq .
echo ""

# Confirmar antes de executar
read -p "$(echo -e ${YELLOW}Deseja prosseguir com a atualização? [y/N]: ${NC})" confirm
if [ "$confirm" != "y" ] && [ "$confirm" != "Y" ]; then
    echo "Atualização cancelada."
    exit 0
fi

echo ""
echo -e "${YELLOW}🚀 Executando atualização...${NC}"
echo ""

# Executar atualização
terrad tx wasm execute ${IGP_ORACLE} "${EXECUTE_MSG}" \
  --from ${KEY_NAME} \
  --keyring-backend ${KEYRING_BACKEND} \
  --chain-id ${CHAIN_ID} \
  --node ${NODE} \
  --gas auto \
  --gas-adjustment 1.5 \
  --fees ${FEES} \
  --yes

if [ $? -eq 0 ]; then
    echo ""
    echo -e "${GREEN}✅ Transação enviada com sucesso!${NC}"
    echo ""
    echo -e "${BLUE}=== Verificar Atualização ===${NC}"
    echo ""
    echo "Aguarde alguns segundos e execute:"
    echo ""
    echo "terrad query wasm contract-state smart ${IGP_ORACLE} \\"
    echo "  '{\"oracle\":{\"get_exchange_rate_and_gas_price\":{\"dest_domain\":${SOLANA_DOMAIN}}}}' \\"
    echo "  --chain-id ${CHAIN_ID} \\"
    echo "  --node ${NODE}"
    echo ""
    echo -e "${BLUE}=== Verificar Cálculo do IGP ===${NC}"
    echo ""
    echo "IGP=\"terra1n70g3vg7xge6q8m44rudm4y6fm6elpspwsgfmfphs3teezpak6cs6wxlk9\""
    echo "terrad query wasm contract-state smart \${IGP} \\"
    echo "  '{\"igp\":{\"quote_gas_payment\":{\"dest_domain\":${SOLANA_DOMAIN},\"gas_amount\":\"200000\"}}}' \\"
    echo "  --chain-id ${CHAIN_ID} \\"
    echo "  --node ${NODE}"
    echo ""
    echo -e "${GREEN}Resultado esperado: ~549,401,878 uluna (~549.40 LUNC)${NC}"
else
    echo ""
    echo -e "${RED}❌ Erro ao enviar transação${NC}"
    exit 1
fi

