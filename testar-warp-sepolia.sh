#!/bin/bash

# ============================================================================
# Teste Rápido: Verificar se o erro "destination not supported" existe
# ============================================================================

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

RPC_URL="https://1rpc.io/sepolia"
WARP_ROUTE="0x224a4419D7FA69D3bEbAbce574c7c84B48D829b4"

echo -e "${BLUE}╔════════════════════════════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║                                                                    ║${NC}"
echo -e "${BLUE}║         🧪 TESTE: Verificar Erro 'destination not supported'      ║${NC}"
echo -e "${BLUE}║                                                                    ║${NC}"
echo -e "${BLUE}╚════════════════════════════════════════════════════════════════════╝${NC}"
echo ""

# 1. Verificar Hook atual
echo -e "${YELLOW}1. Verificando Hook atual do Warp Route...${NC}"
CURRENT_HOOK=$(cast call "$WARP_ROUTE" "hook()(address)" --rpc-url "$RPC_URL" 2>/dev/null)
CURRENT_HOOK_ADDR="0x${CURRENT_HOOK:26:40}"

echo "   Hook Address: $CURRENT_HOOK_ADDR"
echo ""

# 2. Verificar Hook Type
echo -e "${YELLOW}2. Verificando Hook Type...${NC}"
HOOK_TYPE=$(cast call "$CURRENT_HOOK_ADDR" "hookType()(uint8)" --rpc-url "$RPC_URL" 2>/dev/null || echo "error")

if [ "$HOOK_TYPE" = "error" ]; then
    echo -e "   ${RED}❌ Erro ao verificar hookType${NC}"
else
    HOOK_TYPE_DEC=$((16#${HOOK_TYPE#0x}))
    echo "   Hook Type: $HOOK_TYPE_DEC"
    
    if [ "$HOOK_TYPE_DEC" = "4" ]; then
        echo -e "   ${GREEN}✅ Hook Type CORRETO (4 = IGP)${NC}"
    else
        echo -e "   ${RED}❌ Hook Type ERRADO (esperado: 4, obtido: $HOOK_TYPE_DEC)${NC}"
    fi
fi
echo ""

# 3. Testar quoteTransferRemote
echo -e "${YELLOW}3. Testando quoteTransferRemote()...${NC}"
RECIPIENT="0x0000000000000000000000000000000000000000000000000000000000000001"
AMOUNT="1000000000000000000"

echo "   Domain: 1325 (Terra Classic)"
echo "   Recipient: $RECIPIENT"
echo "   Amount: 1 token"
echo ""

RESULT=$(cast call "$WARP_ROUTE" \
    "quoteTransferRemote(uint32,bytes32,uint256)(uint256)" \
    "1325" "$RECIPIENT" "$AMOUNT" \
    --rpc-url "$RPC_URL" 2>&1)

echo -e "${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"

if echo "$RESULT" | grep -q "destination not supported"; then
    echo -e "${RED}❌ ERRO DETECTADO: 'destination not supported'${NC}"
    echo ""
    echo "📋 Diagnóstico:"
    echo "   - O Hook Type está errado (não é 4)"
    echo "   - O Warp Route não reconhece o IGP como válido"
    echo ""
    echo "🔧 Solução:"
    echo "   Execute: ./deploy-igp-final.sh"
    echo "   Ou leia: SOLUCAO-FINAL-IGP.md"
    echo ""
    exit 1
    
elif echo "$RESULT" | grep -q "Configured IGP doesn't support domain"; then
    echo -e "${RED}❌ ERRO: Oracle não configurado para Terra Classic${NC}"
    echo ""
    echo "📋 Diagnóstico:"
    echo "   - O IGP está correto (hookType = 4)"
    echo "   - Mas o Oracle não tem configuração para domain 1325"
    echo ""
    echo "🔧 Solução:"
    echo "   Configure o Oracle com:"
    echo "   - Domain: 1325"
    echo "   - Gas Price: 38325000000"
    echo "   - Exchange Rate: 142244393 (com scale 1e10)"
    echo ""
    exit 1
    
elif echo "$RESULT" | grep -q "Error"; then
    echo -e "${RED}❌ ERRO:${NC}"
    echo "$RESULT"
    echo ""
    exit 1
    
else
    QUOTE_DEC=$((16#${RESULT#0x}))
    QUOTE_ETH=$(cast --to-unit "$RESULT" ether)
    
    echo -e "${GREEN}✅✅✅ SUCESSO! Sem erros!${NC}"
    echo ""
    echo "💰 Custo estimado para transferir 1 token:"
    echo "   - Wei: $QUOTE_DEC"
    echo "   - ETH: $QUOTE_ETH"
    echo ""
    echo -e "${GREEN}🎉 O sistema está funcionando corretamente!${NC}"
    echo ""
    echo "✅ Você pode fazer transferências Sepolia → Terra Classic"
    echo ""
    exit 0
fi
