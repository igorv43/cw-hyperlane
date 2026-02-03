#!/bin/bash

################################################################################
#
# Associa o IGP deployado ao Warp Route
#
################################################################################

set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# ============ Configuração ============
RPC_URL="${RPC_URL:-https://1rpc.io/sepolia}"
WARP_ROUTE="0x224a4419D7FA69D3bEbAbce574c7c84B48D829b4"
PRIVATE_KEY="${SEPOLIA_PRIVATE_KEY:-0xe6802d288e10e94a9e7910793b6a58328f4011ab622d19ad2636ce28264812e5}"

echo -e "${BLUE}"
cat << 'EOF'
╔════════════════════════════════════════════════════════════════════╗
║                                                                    ║
║            ASSOCIAR IGP AO WARP ROUTE - SEPOLIA                   ║
║                                                                    ║
╚════════════════════════════════════════════════════════════════════╝
EOF
echo -e "${NC}"

# Verificar se IGP_ADDRESS foi fornecido
if [ -z "$IGP_ADDRESS" ]; then
    echo -e "${RED}❌ ERRO: Variável IGP_ADDRESS não definida${NC}"
    echo ""
    echo "Execute:"
    echo "  export IGP_ADDRESS=\"<endereço_do_igp>\""
    echo "  $0"
    exit 1
fi

echo -e "${GREEN}📊 CONFIGURAÇÃO:${NC}"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "   RPC: $RPC_URL"
echo "   Warp Route: $WARP_ROUTE"
echo "   IGP: $IGP_ADDRESS"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

# ============ Verificar Hook Atual ============
echo -e "${YELLOW}🔍 Verificando hook atual...${NC}"
CURRENT_HOOK=$(cast call "$WARP_ROUTE" \
    "hook()(address)" \
    --rpc-url "$RPC_URL")

echo "   Hook atual: $CURRENT_HOOK"
echo ""

if [ "$CURRENT_HOOK" = "$IGP_ADDRESS" ]; then
    echo -e "${GREEN}✅ IGP já está associado ao Warp Route${NC}"
    exit 0
fi

# ============ Verificar IGP ============
echo -e "${YELLOW}🔍 Verificando IGP...${NC}"

# Verificar se é um contrato válido
CODE=$(cast code "$IGP_ADDRESS" --rpc-url "$RPC_URL")
if [ "$CODE" = "0x" ]; then
    echo -e "${RED}❌ ERRO: Endereço do IGP não é um contrato${NC}"
    exit 1
fi

# Verificar hookType
HOOK_TYPE=$(cast call "$IGP_ADDRESS" \
    "hookType()(uint8)" \
    --rpc-url "$RPC_URL" 2>/dev/null || echo "")

if [ -n "$HOOK_TYPE" ]; then
    echo "   Hook Type: $HOOK_TYPE"
    if [ "$HOOK_TYPE" != "4" ]; then
        echo -e "${YELLOW}   ⚠️  Hook type não é IGP (esperado: 4, recebido: $HOOK_TYPE)${NC}"
    else
        echo -e "${GREEN}   ✅ Hook type correto (IGP = 4)${NC}"
    fi
else
    echo -e "${YELLOW}   ⚠️  Não foi possível verificar hook type${NC}"
fi

# Verificar gasOracle
GAS_ORACLE=$(cast call "$IGP_ADDRESS" \
    "gasOracle()(address)" \
    --rpc-url "$RPC_URL" 2>/dev/null || echo "")

if [ -n "$GAS_ORACLE" ]; then
    echo "   Gas Oracle: $GAS_ORACLE"
else
    echo -e "${YELLOW}   ⚠️  Não foi possível ler gasOracle${NC}"
fi

echo ""

# ============ Associar IGP ============
echo -e "${YELLOW}🔗 Associando IGP ao Warp Route...${NC}"

TX_HASH=$(cast send "$WARP_ROUTE" \
    "setHook(address)" \
    "$IGP_ADDRESS" \
    --rpc-url "$RPC_URL" \
    --private-key "$PRIVATE_KEY" \
    --json 2>&1 | jq -r '.transactionHash // empty')

if [ -z "$TX_HASH" ]; then
    echo -e "${RED}❌ ERRO: Falha ao enviar transação${NC}"
    exit 1
fi

echo "   TX Hash: $TX_HASH"
echo "   Aguardando confirmação..."

cast receipt "$TX_HASH" --rpc-url "$RPC_URL" > /dev/null 2>&1

echo -e "${GREEN}✅ Transação confirmada${NC}"
echo ""

# ============ Verificar ============
echo -e "${YELLOW}🔍 Verificando associação...${NC}"

NEW_HOOK=$(cast call "$WARP_ROUTE" \
    "hook()(address)" \
    --rpc-url "$RPC_URL")

echo "   Novo hook: $NEW_HOOK"
echo ""

if [ "$NEW_HOOK" = "$IGP_ADDRESS" ]; then
    echo -e "${GREEN}"
    cat << EOF
╔════════════════════════════════════════════════════════════════════╗
║                                                                    ║
║                  ✅ ASSOCIAÇÃO CONCLUÍDA COM SUCESSO!             ║
║                                                                    ║
╚════════════════════════════════════════════════════════════════════╝

📋 RESUMO:
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
   Warp Route: $WARP_ROUTE
   IGP:        $IGP_ADDRESS
   TX Hash:    $TX_HASH
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

🎯 PRÓXIMO PASSO:
   Teste a transferência de Sepolia para Terra Classic!
   O erro "destination not supported" deve estar corrigido.

🔗 Verificar no Explorer:
   https://sepolia.etherscan.io/tx/$TX_HASH

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
EOF
    echo -e "${NC}"
else
    echo -e "${RED}❌ ERRO: Hook não foi atualizado corretamente${NC}"
    exit 1
fi

# Salvar informações
cat > /home/lunc/cw-hyperlane/deployed-igp-info.txt << EOF
WarpRoute=$WARP_ROUTE
IGP=$IGP_ADDRESS
TxHash=$TX_HASH
Timestamp=$(date -u +"%Y-%m-%d %H:%M:%S UTC")
ExchangeRate=142244393
GasPrice=38325000000
GasOverhead=200000
TerraDomain=1325
EOF

echo -e "${GREEN}💾 Informações salvas em: deployed-igp-info.txt${NC}"
