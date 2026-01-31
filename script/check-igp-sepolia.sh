#!/bin/bash

# Script para verificar configuração IGP para Sepolia
# Usage: ./script/check-igp-sepolia.sh

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Configuration
CHAIN_ID="rebel-2"
NODE="https://rpc.luncblaze.com:443"
IGP="terra1mcaqgr7kqs9xr3q6w0e9f2ekrj6sehwcep9shtss6u8pdz2rsw5qzrew7r"
IGP_ORACLE="terra1yew4y2ekzhkwuuz07yt7qufqxxejxhmnr7apehkqk7e8jdw8ffqqs8zhds"
SEPOLIA_DOMAIN=11155111

echo "======================================================================"
echo "Verificar Configuração IGP para Sepolia (Domain $SEPOLIA_DOMAIN)"
echo "======================================================================"
echo ""

# ============================================================================
# STEP 1: Verificar IGP Router Route
# ============================================================================
echo "1. Verificando rota IGP Router para Sepolia..."
echo "──────────────────────────────────────────────────────────────────────"

IGP_ROUTE_RAW=$(terrad query wasm contract-state smart "$IGP" \
  '{"router":{"get_route":{"domain":'$SEPOLIA_DOMAIN'}}}' \
  --chain-id "$CHAIN_ID" \
  --node "$NODE" \
  --output json 2>/dev/null || echo "")

# Extract route from response
# Response format: {"data":{"route":{"domain":11155111,"route":null}}}
IGP_ROUTE=$(echo "$IGP_ROUTE_RAW" | jq -r '.data.route.route // empty' 2>/dev/null)
if [ -z "$IGP_ROUTE" ] || [ "$IGP_ROUTE" == "null" ]; then
  IGP_ROUTE=""
fi

if [ -z "$IGP_ROUTE" ] || [ "$IGP_ROUTE" == "null" ] || [ "$IGP_ROUTE" == "" ]; then
  echo -e "${RED}❌ Rota IGP NÃO configurada para Sepolia${NC}"
  echo "   O IGP Router não tem uma rota configurada para domain $SEPOLIA_DOMAIN"
  echo "   Isso causa o erro: 'gas oracle not found for 11155111'"
  echo ""
  echo -e "${YELLOW}⚠️  AÇÃO NECESSÁRIA:${NC}"
  echo "   Configure a rota IGP usando o script:"
  echo "   ./script/set-igp-route-sepolia.sh"
  IGP_ROUTE_OK=false
else
  echo -e "${GREEN}✅ Rota IGP configurada: $IGP_ROUTE${NC}"
  if [ "$IGP_ROUTE" == "$IGP_ORACLE" ]; then
    echo -e "${GREEN}   ✓ Rota aponta para o IGP Oracle correto${NC}"
    IGP_ROUTE_OK=true
  else
    echo -e "${YELLOW}   ⚠️  Rota aponta para: $IGP_ROUTE (esperado: $IGP_ORACLE)${NC}"
    IGP_ROUTE_OK=false
  fi
fi

echo ""

# ============================================================================
# STEP 2: Verificar IGP Oracle Configuration
# ============================================================================
echo "2. Verificando configuração IGP Oracle para Sepolia..."
echo "──────────────────────────────────────────────────────────────────────"

ORACLE_CONFIG=$(terrad query wasm contract-state smart "$IGP_ORACLE" \
  '{"oracle":{"get_exchange_rate_and_gas_price":{"dest_domain":'$SEPOLIA_DOMAIN'}}}' \
  --chain-id "$CHAIN_ID" \
  --node "$NODE" \
  --output json 2>/dev/null || echo "")

if [ -z "$ORACLE_CONFIG" ] || echo "$ORACLE_CONFIG" | jq -e '.data == null' >/dev/null 2>&1; then
  echo -e "${RED}❌ IGP Oracle NÃO configurado para Sepolia${NC}"
  echo "   O IGP Oracle não tem dados de gas configurados para domain $SEPOLIA_DOMAIN"
  ORACLE_OK=false
else
  EXCHANGE_RATE=$(echo "$ORACLE_CONFIG" | jq -r '.data.exchange_rate // .data.token_exchange_rate // empty' 2>/dev/null || echo "")
  GAS_PRICE=$(echo "$ORACLE_CONFIG" | jq -r '.data.gas_price' 2>/dev/null || echo "")
  
  if [ -n "$EXCHANGE_RATE" ] && [ -n "$GAS_PRICE" ]; then
    echo -e "${GREEN}✅ IGP Oracle configurado:${NC}"
    echo "   • Exchange Rate: $EXCHANGE_RATE"
    echo "   • Gas Price: $GAS_PRICE"
    ORACLE_OK=true
  else
    echo -e "${RED}❌ IGP Oracle configurado mas dados incompletos${NC}"
    ORACLE_OK=false
  fi
fi

echo ""

# ============================================================================
# SUMMARY
# ============================================================================
echo "======================================================================"
echo "Resumo da Verificação"
echo "======================================================================"
echo ""

if [ "$IGP_ROUTE_OK" = true ] && [ "$ORACLE_OK" = true ]; then
  echo -e "${GREEN}✅ Tudo configurado corretamente!${NC}"
  echo ""
  echo "A configuração IGP está pronta para transferências Terra Classic → Sepolia."
  exit 0
else
  echo -e "${RED}❌ Configuração incompleta${NC}"
  echo ""
  echo "Problemas encontrados:"
  [ "$IGP_ROUTE_OK" = false ] && echo "  • Rota IGP Router não configurada para Sepolia"
  [ "$ORACLE_OK" = false ] && echo "  • IGP Oracle não configurado para Sepolia"
  echo ""
  echo "Para corrigir, execute:"
  echo "  ./script/set-igp-route-sepolia.sh"
  exit 1
fi
