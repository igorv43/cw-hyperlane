#!/bin/bash

# Script para criar proposta de governance para atualizar IGP Oracle para Solana Testnet
# Endereço do módulo de governance: terra10d07y265gmmuvt4z0w9aw880jnsr700juxf95n

set -e

# Cores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

IGP_ORACLE="terra18tyqe79yktac6p3alv3f49k06xqna2q52twyaflrz55qka9emhrs30k3hg"
GOV_MODULE="terra10d07y265gmmuvt4z0w9aw880jnsr700juxf95n"
SOLANA_DOMAIN="1399811150"

# Novo exchange_rate calculado para Solana Testnet
# Cálculo seguindo EXATAMENTE a lógica do IGP-COMPLETE-GUIDE.md (mesma do BSC):
# 1. Custo do gas no destino: 200,000 compute units × 1 lamport = 0.0002 SOL
# 2. Converter para USD: 0.0002 SOL × $138.93 = $0.027786
# 3. Converter para LUNC: $0.027786 / $0.00006069 = 457.83 LUNC
# 4. Adicionar margem (20%): 457.83 × 1.20 = 549.40 LUNC = 549,401,878 uluna
# 5. Exchange Rate: (549,401,878 × 10^10) / (200,000 × 1) = 27,470,093,900,000
# Fórmula: exchange_rate = (gas_needed × 10^10) / (gas_amount × gas_price)
# TOKEN_EXCHANGE_RATE_SCALE = 10^10 (não 10^18!)
NEW_EXCHANGE_RATE="${1:-27470093900000}"
GAS_PRICE="${2:-1}"

echo -e "${BLUE}╔══════════════════════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║   CRIAR PROPOSTA: Atualizar IGP Oracle para Solana          ║${NC}"
echo -e "${BLUE}╚══════════════════════════════════════════════════════════════╝${NC}"
echo ""

echo -e "${YELLOW}📋 Configuração:${NC}"
echo "   IGP Oracle: ${IGP_ORACLE}"
echo "   Governance Module: ${GOV_MODULE}"
echo "   Domain: ${SOLANA_DOMAIN} (Solana Testnet)"
echo ""
echo -e "${YELLOW}📊 Valores Atuais (INCORRETOS):${NC}"
echo "   token_exchange_rate: 57675000000000000"
echo "   gas_price: 1"
echo "   Custo resultante: ~576.75 LUNC (MUITO ALTO!)"
echo ""
echo -e "${YELLOW}✨ Valores Novos (CORRETOS - seguindo IGP-COMPLETE-GUIDE.md):${NC}"
echo "   token_exchange_rate: ${NEW_EXCHANGE_RATE}"
echo "   gas_price: ${GAS_PRICE}"
echo "   Custo esperado: ~549.40 LUNC (com 20% margem)"
echo "   Baseado em: SOL @ \$138.93, LUNC @ \$0.00006069, gas_limit 200k"
echo ""

# Verificar se jq está instalado
if ! command -v jq &> /dev/null; then
    echo -e "${RED}❌ Erro: jq não está instalado${NC}"
    echo "   Instale com: sudo apt-get install jq"
    exit 1
fi

# Criar arquivo JSON da proposta
PROPOSAL_FILE="proposal-igp-oracle-solana-update.json"

cat > ${PROPOSAL_FILE} <<EOF
{
  "messages": [
    {
      "@type": "/cosmwasm.wasm.v1.MsgExecuteContract",
      "sender": "${GOV_MODULE}",
      "contract": "${IGP_ORACLE}",
      "msg": {
        "set_remote_gas_data_configs": {
          "configs": [
            {
              "remote_domain": ${SOLANA_DOMAIN},
              "token_exchange_rate": "${NEW_EXCHANGE_RATE}",
              "gas_price": "${GAS_PRICE}"
            }
          ]
        }
      },
      "funds": []
    }
  ],
  "metadata": "Update IGP Oracle gas data configuration for Solana Testnet (domain 1399811150). Fixes gas cost calculation using correct formula from IGP-COMPLETE-GUIDE.md. New cost: ~549.40 LUNC per transfer (with 20% margin).",
  "deposit": "1000000uluna",
  "title": "Update IGP Oracle Configuration for Solana Testnet",
  "summary": "Update token_exchange_rate from 57675000000000000 to ${NEW_EXCHANGE_RATE} for Solana Testnet (domain ${SOLANA_DOMAIN}). Calculation follows IGP-COMPLETE-GUIDE.md logic: gas_limit 200k, SOL @ \$138.93, LUNC @ \$0.00006069, 20% margin. New cost: ~549.40 LUNC per transfer.",
  "expedited": false
}
EOF

echo -e "${GREEN}✅ Arquivo de proposta criado: ${PROPOSAL_FILE}${NC}"
echo ""

echo -e "${BLUE}=== Conteúdo da Proposta ===${NC}"
cat ${PROPOSAL_FILE} | jq .
echo ""

echo -e "${BLUE}=== Comando para Enviar a Proposta ===${NC}"
echo ""
echo -e "${YELLOW}terrad tx gov submit-proposal ${PROPOSAL_FILE} \\${NC}"
echo "  --from hypelane-val-testnet \\"
echo "  --keyring-backend file \\"
echo "  --chain-id rebel-2 \\"
echo "  --node https://rpc.luncblaze.com:443 \\"
echo "  --gas auto \\"
echo "  --gas-adjustment 1.5 \\"
echo "  --gas-prices 28.5uluna \\"
echo "  --yes"
echo ""

echo -e "${BLUE}=== Após Enviar a Proposta ===${NC}"
echo ""
echo -e "${YELLOW}1.${NC} Anote o PROPOSAL_ID retornado"
echo -e "${YELLOW}2.${NC} A proposta entrará em PERÍODO DE DEPÓSITO"
echo -e "${YELLOW}3.${NC} Depósito inicial: 1,000,000 uluna (1 LUNC) - atinge o mínimo"
echo -e "${YELLOW}4.${NC} Após atingir o depósito mínimo, a proposta entrará em PERÍODO DE VOTAÇÃO"
echo -e "${YELLOW}5.${NC} Vote na proposta:"
echo ""
echo "   terrad tx gov vote <PROPOSAL_ID> yes \\"
echo "     --from hypelane-val-testnet \\"
echo "     --keyring-backend file \\"
echo "     --chain-id rebel-2 \\"
echo "     --node https://rpc.luncblaze.com:443 \\"
echo "     --gas-prices 28.5uluna \\"
echo "     --yes"
echo ""
echo -e "${YELLOW}6.${NC} Aguarde o período de votação terminar"
echo -e "${YELLOW}7.${NC} Verifique a execução consultando o IGP Oracle:"
echo ""
echo "   terrad query wasm contract-state smart ${IGP_ORACLE} \\"
echo "     '{\"oracle\":{\"get_exchange_rate_and_gas_price\":{\"dest_domain\":${SOLANA_DOMAIN}}}}' \\"
echo "     --chain-id rebel-2 \\"
echo "     --node https://rpc.luncblaze.com:443"
echo ""

echo -e "${BLUE}=== Verificar Cálculo do IGP ===${NC}"
echo ""
echo "   IGP=\"terra1n70g3vg7xge6q8m44rudm4y6fm6elpspwsgfmfphs3teezpak6cs6wxlk9\""
echo "   terrad query wasm contract-state smart \${IGP} \\"
echo "     '{\"igp\":{\"quote_gas_payment\":{\"dest_domain\":${SOLANA_DOMAIN},\"gas_amount\":\"200000\"}}}' \\"
echo "     --chain-id rebel-2 \\"
echo "     --node https://rpc.luncblaze.com:443"
echo ""
echo -e "${GREEN}   Resultado esperado: ~549,401,878 uluna (~549.40 LUNC)${NC}"
echo ""

