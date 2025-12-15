#!/bin/bash
# Script para Vincular Terra Classic → Solana (lunc-solana-v2)
# Este script vincula o warp route da Solana como remote router no Terra Classic

set -e

# Cores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Variáveis
TERRA_WARP="terra1zlm0h2xu6rhnjchn29hxnpvr74uxxqetar9y75zcehyx2mqezg9slj09ml"
SOLANA_DOMAIN="1399811150"
SOLANA_PROGRAM_ID="HNxN3ZSBtD5J2nNF4AATMhuvTWVeHQf18nTtzKtsnkyw"
SOLANA_WARP_HEX="f35ac96952cd5f87be0a99b173927e2fe0a814079ceb9ce8f5237f775fc940fa"
KEY_NAME="hypelane-val-testnet"
CHAIN_ID="rebel-2"
RPC_NODE="https://rpc.luncblaze.com:443"
FEES="12000000uluna"

echo -e "${BLUE}╔══════════════════════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║   VINCULAR TERRA CLASSIC → SOLANA                          ║${NC}"
echo -e "${BLUE}║   Warp Route: lunc-solana-v2                              ║${NC}"
echo -e "${BLUE}╚══════════════════════════════════════════════════════════════╝${NC}"
echo ""

# PASSO 1: Verificar informações
echo -e "${YELLOW}📋 [1/3] Verificando informações...${NC}"
echo ""
echo -e "   ${BLUE}Terra Classic Warp Route:${NC}"
echo "   $TERRA_WARP"
echo ""
echo -e "   ${BLUE}Solana Warp Route (lunc-solana-v2):${NC}"
echo "   Program ID (Base58): $SOLANA_PROGRAM_ID"
echo "   Program ID (Hex): $SOLANA_WARP_HEX"
echo "   Domain: $SOLANA_DOMAIN"
echo ""

# Verificar hex length
if [ ${#SOLANA_WARP_HEX} -ne 64 ]; then
    echo -e "${RED}❌ Erro: Hex do router Solana deve ter 64 caracteres (32 bytes)${NC}"
    echo "   Tamanho atual: ${#SOLANA_WARP_HEX}"
    exit 1
fi
echo -e "${GREEN}✅ Hex válido (64 caracteres)${NC}"
echo ""

# PASSO 2: Vincular Remote Router
echo -e "${YELLOW}🔗 [2/3] Vinculando Remote Router no Terra Classic...${NC}"
echo ""
echo -e "${BLUE}Comando que será executado:${NC}"
echo "   terrad tx wasm execute \"$TERRA_WARP\" \\"
echo "     \"{\\\"router\\\":{\\\"set_route\\\":{\\\"set\\\":{\\\"domain\\\":$SOLANA_DOMAIN,\\\"route\\\":\\\"$SOLANA_WARP_HEX\\\"}}}}\" \\"
echo "     --from $KEY_NAME \\"
echo "     --keyring-backend file \\"
echo "     --chain-id $CHAIN_ID \\"
echo "     --node $RPC_NODE \\"
echo "     --gas auto \\"
echo "     --gas-adjustment 1.5 \\"
echo "     --fees $FEES \\"
echo "     --yes"
echo ""

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

if [ $? -eq 0 ]; then
    echo ""
    echo -e "${GREEN}✅ Transação enviada com sucesso!${NC}"
else
    echo ""
    echo -e "${RED}❌ Erro ao enviar transação${NC}"
    echo -e "${YELLOW}⚠️  Verifique se você é o owner do warp route do Terra Classic${NC}"
    exit 1
fi
echo ""

# PASSO 3: Verificar vinculação
echo -e "${YELLOW}🔍 [3/3] Verificando vinculação do Remote Router...${NC}"
echo ""
echo -e "${BLUE}Consultando rota configurada...${NC}"
echo ""

terrad query wasm contract-state smart "$TERRA_WARP" \
  "{\"router\":{\"get_route\":{\"domain\":$SOLANA_DOMAIN}}}" \
  --node "$RPC_NODE"

echo ""
echo -e "${GREEN}╔══════════════════════════════════════════════════════════════╗${NC}"
echo -e "${GREEN}║   ✅ VINCULAÇÃO CONCLUÍDA COM SUCESSO!                      ║${NC}"
echo -e "${GREEN}╚══════════════════════════════════════════════════════════════╝${NC}"
echo ""
echo -e "${BLUE}📝 Informações:${NC}"
echo "   Terra Classic Warp Route: $TERRA_WARP"
echo "   Solana Warp Route: $SOLANA_PROGRAM_ID"
echo "   Solana Domain: $SOLANA_DOMAIN"
echo ""
echo -e "${BLUE}🔍 Verificar na saída acima:${NC}"
echo "   Procure por 'route' e confirme que contém:"
echo "   $SOLANA_WARP_HEX"
echo ""
echo -e "${BLUE}📋 Próximos passos:${NC}"
echo "   1. Verificar se Solana → Terra Classic também está vinculado"
echo "   2. Testar transferência cross-chain"
echo ""

