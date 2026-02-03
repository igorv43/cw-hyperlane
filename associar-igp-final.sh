#!/bin/bash

# ═══════════════════════════════════════════════════════════════════════════
#  🎯 Associação Final do IGP ao Warp Route Sepolia (ENDEREÇO CORRETO)
# ═══════════════════════════════════════════════════════════════════════════

set -e

# Cores
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Configurações CORRETAS
RPC_URL="https://1rpc.io/sepolia"
PRIVATE_KEY="0xe6802d288e10e94a9e7910793b6a58328f4011ab622d19ad2636ce28264812e5"
WARP_ADDRESS="0x224a4419D7FA69D3bEbAbce574c7c84B48D829b4"  # ✅ ENDEREÇO CORRETO!

DOMAIN_TERRA=1325
TOKEN_EXCHANGE_RATE=142244393
GAS_PRICE=38325000000

echo -e "${BLUE}"
cat << 'EOF'
╔════════════════════════════════════════════════════════════════════════╗
║                                                                        ║
║           🚀 ASSOCIAÇÃO E TESTE DO IGP - VERSÃO FINAL                 ║
║                                                                        ║
╚════════════════════════════════════════════════════════════════════════╝
EOF
echo -e "${NC}"

# Verificar se IGP_ADDRESS está definido
if [ -z "$IGP_ADDRESS" ]; then
    echo -e "${RED}❌ Erro: IGP_ADDRESS não está definido!${NC}"
    echo ""
    echo "Por favor, defina o endereço do IGP deployado no Remix:"
    echo ""
    echo "  export IGP_ADDRESS=\"<endereco_do_remix>\""
    echo ""
    exit 1
fi

echo ""
echo -e "${YELLOW}📊 Configuração:${NC}"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "  Warp Route:        $WARP_ADDRESS"
echo "  Novo IGP:          $IGP_ADDRESS"
echo "  Domain Terra:      $DOMAIN_TERRA"
echo "  Token Exch Rate:   $TOKEN_EXCHANGE_RATE"
echo "  Gas Price:         $GAS_PRICE"
echo ""

# Verificar se IGP existe
echo -e "${YELLOW}🔍 Verificando IGP deployado...${NC}"
CODE=$(cast code "$IGP_ADDRESS" --rpc-url "$RPC_URL" 2>&1)

if [ "$CODE" == "0x" ] || [ -z "$CODE" ]; then
    echo -e "${RED}❌ Erro: IGP não tem código deployado no endereço $IGP_ADDRESS${NC}"
    echo "   Verifique se o deploy no Remix foi bem-sucedido."
    exit 1
fi

echo -e "${GREEN}✅ IGP deployado confirmado!${NC}"
echo ""

# Verificar hookType
echo -e "${YELLOW}🔍 Verificando hookType do novo IGP...${NC}"
HOOK_TYPE=$(cast call "$IGP_ADDRESS" "hookType()(uint8)" --rpc-url "$RPC_URL" 2>&1)

echo "   hookType: $HOOK_TYPE"

if [ "$HOOK_TYPE" == "4" ]; then
    echo -e "${GREEN}   ✅ hookType correto (4 = INTERCHAIN_GAS_PAYMASTER)${NC}"
elif [ "$HOOK_TYPE" == "2" ]; then
    echo -e "${RED}   ❌ hookType incorreto (2 = AGGREGATION)${NC}"
    echo -e "${RED}   ⚠️  ATENÇÃO: Este IGP tem o mesmo problema!${NC}"
    echo ""
    read -p "Continuar mesmo assim? (s/N): " continuar
    if [[ ! "$continuar" =~ ^[Ss]$ ]]; then
        exit 1
    fi
else
    echo -e "${YELLOW}   ⚠️  hookType inesperado: $HOOK_TYPE${NC}"
fi

echo ""

# Configurar IGP
echo -e "${YELLOW}🔧 Configurando exchange rate e gas price para Terra Classic...${NC}"
echo ""

TX_HASH=$(cast send "$IGP_ADDRESS" \
    "setRemoteGasDataConfig(((uint32,uint128,uint128)[]))" \
    "([($DOMAIN_TERRA,$TOKEN_EXCHANGE_RATE,$GAS_PRICE)])" \
    --rpc-url "$RPC_URL" \
    --private-key "$PRIVATE_KEY" \
    --json 2>&1 | jq -r '.transactionHash' 2>/dev/null || echo "")

if [ -z "$TX_HASH" ] || [ "$TX_HASH" == "null" ]; then
    echo -e "${RED}❌ Erro ao configurar IGP${NC}"
    exit 1
fi

echo "   TX Hash: $TX_HASH"
echo "   Aguardando confirmação..."
sleep 3
echo -e "${GREEN}   ✅ IGP configurado!${NC}"
echo ""

# Verificar configuração
echo -e "${YELLOW}🔍 Verificando configuração Terra Classic...${NC}"
CONFIG=$(cast call "$IGP_ADDRESS" "getExchangeRateAndGasPrice(uint32)(uint128,uint128)" "$DOMAIN_TERRA" --rpc-url "$RPC_URL" 2>&1)

if [[ "$CONFIG" == *"error"* ]]; then
    echo -e "${YELLOW}   ⚠️  Não foi possível verificar: $CONFIG${NC}"
else
    echo -e "${GREEN}   ✅ Config: $CONFIG${NC}"
fi

echo ""

# Associar ao Warp Route
echo -e "${YELLOW}🔗 Associando IGP ao Warp Route...${NC}"
echo ""

TX_HASH=$(cast send "$WARP_ADDRESS" \
    "setHook(address)" \
    "$IGP_ADDRESS" \
    --rpc-url "$RPC_URL" \
    --private-key "$PRIVATE_KEY" \
    --json 2>&1 | jq -r '.transactionHash' 2>/dev/null || echo "")

if [ -z "$TX_HASH" ] || [ "$TX_HASH" == "null" ]; then
    echo -e "${RED}❌ Erro ao associar hook${NC}"
    exit 1
fi

echo "   TX Hash: $TX_HASH"
echo "   Aguardando confirmação..."
sleep 3
echo -e "${GREEN}   ✅ Hook associado!${NC}"
echo ""

# Verificar associação
echo -e "${YELLOW}🔍 Verificando associação...${NC}"
CURRENT_HOOK=$(cast call "$WARP_ADDRESS" "hook()(address)" --rpc-url "$RPC_URL" 2>&1)

if [ "$CURRENT_HOOK" == "$IGP_ADDRESS" ]; then
    echo -e "${GREEN}   ✅ Hook associado corretamente!${NC}"
else
    echo -e "${RED}   ❌ Hook atual: $CURRENT_HOOK${NC}"
    echo -e "${RED}   ❌ Esperado:   $IGP_ADDRESS${NC}"
fi

echo ""

# TESTE FINAL
echo ""
echo -e "${BLUE}"
cat << 'EOF'
╔════════════════════════════════════════════════════════════════════════╗
║                                                                        ║
║                       🧪 TESTE FINAL                                  ║
║                                                                        ║
╚════════════════════════════════════════════════════════════════════════╝
EOF
echo -e "${NC}"
echo ""

echo -e "${YELLOW}Testando quoteTransferRemote()...${NC}"
echo ""

RECIPIENT="0x000000000000000000000000133fD7F7094DBd17b576907d052a5aCBd48dB526"
AMOUNT="1000000000000000000"

QUOTE_RESULT=$(cast call "$WARP_ADDRESS" \
    "quoteTransferRemote(uint32,bytes32,uint256)(uint256)" \
    "$DOMAIN_TERRA" \
    "$RECIPIENT" \
    "$AMOUNT" \
    --rpc-url "$RPC_URL" 2>&1)

echo "Resultado:"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

if [[ "$QUOTE_RESULT" == *"destination not supported"* ]]; then
    echo -e "${RED}❌ ERRO: destination not supported${NC}"
    echo ""
    echo -e "${RED}⚠️  O ERRO AINDA PERSISTE!${NC}"
    echo ""
    echo "Possíveis causas:"
    echo "  1. hookType ainda é 2 (verifique acima)"
    echo "  2. Contrato deployado não é o TerraClassicIGPStandalone.sol correto"
    echo "  3. Há outra lógica no Warp Route bloqueando"
    echo ""
elif [[ "$QUOTE_RESULT" =~ ^[0-9]+$ ]]; then
    QUOTE_ETH=$(cast --to-unit "$QUOTE_RESULT" ether 2>&1 || echo "erro")
    
    echo -e "${GREEN}"
    cat << 'EOF'
╔════════════════════════════════════════════════════════════════════════╗
║                                                                        ║
║                  ✅✅✅ SUCESSO TOTAL! ✅✅✅                         ║
║                                                                        ║
║             O ERRO FOI CORRIGIDO COM SUCESSO!                         ║
║                                                                        ║
╚════════════════════════════════════════════════════════════════════════╝
EOF
    echo -e "${NC}"
    echo ""
    echo "💰 Custo estimado da transferência:"
    echo "   $QUOTE_RESULT wei"
    echo "   $QUOTE_ETH ETH"
    echo ""
    echo -e "${GREEN}✅ Você pode agora transferir tokens de Sepolia para Terra Classic!${NC}"
    echo ""
else
    echo -e "${YELLOW}⚠️  Resposta inesperada:${NC}"
    echo "   $QUOTE_RESULT"
    echo ""
fi

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

# Resumo final
echo ""
echo -e "${BLUE}📊 RESUMO FINAL:${NC}"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "Warp Route:  $WARP_ADDRESS"
echo "Novo IGP:    $IGP_ADDRESS"
echo "hookType:    $HOOK_TYPE"
echo ""

if [[ "$QUOTE_RESULT" =~ ^[0-9]+$ ]]; then
    echo -e "${GREEN}Status: ✅ FUNCIONANDO PERFEITAMENTE!${NC}"
else
    echo -e "${RED}Status: ❌ Ainda com problemas${NC}"
fi

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
