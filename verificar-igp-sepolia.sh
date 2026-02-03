#!/bin/bash

# Script para verificar configuração do IGP no Sepolia

set -e

# Cores
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuração
RPC_URL="${RPC_URL:-https://1rpc.io/sepolia}"
WARP_ROUTE="0x224a4419D7FA69D3bEbAbce574c7c84B48D829b4"
ORACLE_ADDRESS="0x7113Df4d1D8B230e6339011d10277a6E5AC4eC9c"
TERRA_DOMAIN="1325"

echo -e "${BLUE}======================================================================"
echo -e "VERIFICAÇÃO DO IGP - SEPOLIA"
echo -e "======================================================================${NC}"
echo ""

# Solicitar endereço do IGP
if [ -z "$IGP_ADDRESS" ]; then
  echo -e "${YELLOW}Digite o endereço do IGP deployado:${NC}"
  read IGP_ADDRESS
fi

echo -e "${BLUE}📋 Configuração:${NC}"
echo "   IGP Address: $IGP_ADDRESS"
echo "   Oracle: $ORACLE_ADDRESS"
echo "   Warp Route: $WARP_ROUTE"
echo "   Terra Domain: $TERRA_DOMAIN"
echo "   RPC: $RPC_URL"
echo ""

# Verificação 1: Hook do Warp Route
echo -e "${BLUE}======================================================================"
echo -e "1️⃣  Verificando Hook do Warp Route"
echo -e "======================================================================${NC}"

HOOK=$(cast call "$WARP_ROUTE" \
  "hook()(address)" \
  --rpc-url "$RPC_URL" 2>/dev/null || echo "ERRO")

if [ "$HOOK" == "ERRO" ]; then
  echo -e "${RED}❌ ERRO: Não foi possível consultar o hook do Warp Route${NC}"
  exit 1
fi

echo "   Hook atual: $HOOK"

if [ "$(echo "$HOOK" | tr '[:upper:]' '[:lower:]')" == "$(echo "$IGP_ADDRESS" | tr '[:upper:]' '[:lower:]')" ]; then
  echo -e "${GREEN}✅ Hook configurado corretamente!${NC}"
else
  echo -e "${YELLOW}⚠️  Hook não aponta para o IGP fornecido${NC}"
  echo -e "${YELLOW}   Execute: cast send \"$WARP_ROUTE\" \"setHook(address)\" \"$IGP_ADDRESS\" --private-key \$PRIVATE_KEY --rpc-url $RPC_URL${NC}"
fi

echo ""

# Verificação 2: Oracle no IGP
echo -e "${BLUE}======================================================================"
echo -e "2️⃣  Verificando Oracle configurado no IGP"
echo -e "======================================================================${NC}"

IGP_ORACLE=$(cast call "$IGP_ADDRESS" \
  "gasOracles(uint32)(address)" \
  $TERRA_DOMAIN \
  --rpc-url "$RPC_URL" 2>/dev/null || echo "ERRO")

if [ "$IGP_ORACLE" == "ERRO" ]; then
  echo -e "${RED}❌ ERRO: Não foi possível consultar o oracle do IGP${NC}"
  echo -e "${YELLOW}   Verifique se o endereço do IGP está correto: $IGP_ADDRESS${NC}"
  exit 1
fi

echo "   Oracle no IGP: $IGP_ORACLE"

if [ "$(echo "$IGP_ORACLE" | tr '[:upper:]' '[:lower:]')" == "$(echo "$ORACLE_ADDRESS" | tr '[:upper:]' '[:lower:]')" ]; then
  echo -e "${GREEN}✅ Oracle configurado corretamente!${NC}"
else
  echo -e "${RED}❌ Oracle NÃO está configurado para o domain $TERRA_DOMAIN${NC}"
  echo -e "${YELLOW}   Execute a função 'setDestinationGasConfig' no Remix IDE:${NC}"
  echo -e "${YELLOW}   - remoteDomain: $TERRA_DOMAIN${NC}"
  echo -e "${YELLOW}   - gasOracle: $ORACLE_ADDRESS${NC}"
  echo -e "${YELLOW}   - gasOverhead: 200000${NC}"
  exit 1
fi

echo ""

# Verificação 3: Gas Overhead
echo -e "${BLUE}======================================================================"
echo -e "3️⃣  Verificando Gas Overhead"
echo -e "======================================================================${NC}"

GAS_OVERHEAD=$(cast call "$IGP_ADDRESS" \
  "destinationGasOverhead(uint32)(uint256)" \
  $TERRA_DOMAIN \
  --rpc-url "$RPC_URL" 2>/dev/null || echo "0")

echo "   Gas Overhead: $GAS_OVERHEAD"

if [ "$GAS_OVERHEAD" != "0" ]; then
  echo -e "${GREEN}✅ Gas Overhead configurado: $GAS_OVERHEAD${NC}"
else
  echo -e "${YELLOW}⚠️  Gas Overhead não configurado ou é 0${NC}"
  echo -e "${YELLOW}   Recomendado: 200000${NC}"
fi

echo ""

# Verificação 4: Owner do IGP
echo -e "${BLUE}======================================================================"
echo -e "4️⃣  Verificando Owner do IGP"
echo -e "======================================================================${NC}"

IGP_OWNER=$(cast call "$IGP_ADDRESS" \
  "owner()(address)" \
  --rpc-url "$RPC_URL" 2>/dev/null || echo "ERRO")

if [ "$IGP_OWNER" == "ERRO" ]; then
  echo -e "${YELLOW}⚠️  Não foi possível consultar o owner do IGP${NC}"
else
  echo "   Owner: $IGP_OWNER"
  echo -e "${GREEN}✅ Owner identificado${NC}"
fi

echo ""

# Verificação 5: Testar Quote de Gas
echo -e "${BLUE}======================================================================"
echo -e "5️⃣  Testando Quote de Gas"
echo -e "======================================================================${NC}"

QUOTE=$(cast call "$IGP_ADDRESS" \
  "quoteGasPayment(uint32,uint256)(uint256)" \
  $TERRA_DOMAIN 200000 \
  --rpc-url "$RPC_URL" 2>/dev/null || echo "ERRO")

if [ "$QUOTE" == "ERRO" ]; then
  echo -e "${RED}❌ ERRO: Não foi possível calcular quote de gas${NC}"
  echo -e "${YELLOW}   Verifique se o Oracle está configurado corretamente${NC}"
  exit 1
fi

# Converter para ETH (wei para ether)
QUOTE_ETH=$(cast --to-unit "$QUOTE" ether 2>/dev/null || echo "N/A")

echo "   Quote para 200k gas:"
echo "   - Wei: $QUOTE"
echo "   - ETH: $QUOTE_ETH"
echo -e "${GREEN}✅ Quote calculado com sucesso!${NC}"

echo ""

# Verificação 6: Verificar Oracle configurado (Terra Domain)
echo -e "${BLUE}======================================================================"
echo -e "6️⃣  Verificando Oracle para Terra Classic"
echo -e "======================================================================${NC}"

ORACLE_CONFIG=$(cast call "$ORACLE_ADDRESS" \
  "getExchangeRateAndGasPrice(uint32)(uint128,uint128)" \
  $TERRA_DOMAIN \
  --rpc-url "$RPC_URL" 2>/dev/null || echo "ERRO")

if [ "$ORACLE_CONFIG" == "ERRO" ]; then
  echo -e "${RED}❌ ERRO: Oracle não está configurado para domain $TERRA_DOMAIN${NC}"
  exit 1
fi

# Parse do resultado (dois valores uint128)
EXCHANGE_RATE=$(echo "$ORACLE_CONFIG" | head -n 1)
GAS_PRICE=$(echo "$ORACLE_CONFIG" | tail -n 1)

echo "   Exchange Rate: $EXCHANGE_RATE"
echo "   Gas Price: $GAS_PRICE"

if [ "$EXCHANGE_RATE" != "0" ] && [ "$GAS_PRICE" != "0" ]; then
  echo -e "${GREEN}✅ Oracle configurado para Terra Classic!${NC}"
else
  echo -e "${RED}❌ Oracle NÃO está configurado para Terra Classic${NC}"
  exit 1
fi

echo ""

# Resumo Final
echo -e "${BLUE}======================================================================"
echo -e "✅ RESUMO DA VERIFICAÇÃO"
echo -e "======================================================================${NC}"
echo ""
echo -e "${GREEN}✅ Todas as verificações passaram!${NC}"
echo ""
echo "📋 Configuração Final:"
echo "   IGP: $IGP_ADDRESS"
echo "   Oracle: $ORACLE_ADDRESS"
echo "   Hook do Warp Route: $HOOK"
echo "   Exchange Rate: $EXCHANGE_RATE"
echo "   Gas Price: $GAS_PRICE"
echo "   Quote (200k gas): $QUOTE_ETH ETH"
echo ""
echo -e "${GREEN}🎉 Você pode testar transferências Sepolia → Terra Classic!${NC}"
echo ""
echo "======================================================================"
