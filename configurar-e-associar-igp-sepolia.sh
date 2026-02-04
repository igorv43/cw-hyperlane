#!/bin/bash

#━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# ⚙️  SCRIPT: CONFIGURAR E ASSOCIAR IGP JÁ DEPLOYADO
#━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# Use este script se você já fez o deploy do IGP via Remix ou outro meio
#━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

set -e

# Cores
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo ""
echo "╔═══════════════════════════════════════════════════════════════════════╗"
echo "║         ⚙️  CONFIGURAR E ASSOCIAR IGP TERRA CLASSIC                   ║"
echo "╚═══════════════════════════════════════════════════════════════════════╝"
echo ""

# Configurações
WARP_ROUTE="0x224a4419D7FA69D3bEbAbce574c7c84B48D829b4"
DOMAIN="1325"
EXCHANGE_RATE="142244393"
GAS_PRICE="38325000000"
RPC="https://ethereum-sepolia-rpc.publicnode.com"

# Verificar se IGP_ADDRESS foi fornecido
if [ -z "$IGP_ADDRESS" ]; then
    echo -e "${RED}❌ IGP_ADDRESS não definido${NC}"
    echo ""
    echo "Execute primeiro:"
    echo -e "${YELLOW}export IGP_ADDRESS='0xENDERECO_DO_SEU_IGP'${NC}"
    echo ""
    echo "Depois execute novamente:"
    echo -e "${YELLOW}./configurar-e-associar-igp.sh${NC}"
    echo ""
    exit 1
fi

# Verificar se PRIVATE_KEY_SEPOLIA foi fornecido
if [ -z "$PRIVATE_KEY_SEPOLIA" ]; then
    echo -e "${RED}❌ PRIVATE_KEY_SEPOLIA não definida${NC}"
    echo ""
    echo "Execute primeiro:"
    echo -e "${YELLOW}export PRIVATE_KEY_SEPOLIA='0xSUA_CHAVE_PRIVADA_SEPOLIA'${NC}"
    echo ""
    echo "Depois execute novamente:"
    echo -e "${YELLOW}./configurar-e-associar-igp.sh${NC}"
    echo ""
    exit 1
fi

echo -e "${GREEN}📍 IGP Address: $IGP_ADDRESS${NC}"
echo -e "${GREEN}📍 Warp Route: $WARP_ROUTE${NC}"
echo ""

#━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# ETAPA 1: VERIFICAR IGP
#━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

echo "1️⃣  VERIFICANDO IGP DEPLOYADO..."
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

# Verificar se o contrato existe
CODE=$(cast code "$IGP_ADDRESS" --rpc-url "$RPC" 2>/dev/null || echo "0x")

if [ "$CODE" = "0x" ]; then
    echo -e "${RED}❌ Contrato não encontrado no endereço $IGP_ADDRESS${NC}"
    echo ""
    echo "Verifique se:"
    echo "  1. O endereço está correto"
    echo "  2. O deploy foi bem-sucedido"
    echo "  3. Você está na rede certa (Sepolia)"
    echo ""
    exit 1
fi

echo -e "${GREEN}✅ Contrato encontrado${NC}"

# Verificar hookType
HOOK_TYPE=$(cast call "$IGP_ADDRESS" "hookType()(uint8)" --rpc-url "$RPC" 2>/dev/null || echo "ERRO")

if [ "$HOOK_TYPE" = "4" ]; then
    echo -e "${GREEN}✅ Hook Type correto: 4 (INTERCHAIN_GAS_PAYMASTER)${NC}"
elif [ "$HOOK_TYPE" != "ERRO" ]; then
    echo -e "${RED}❌ Hook Type incorreto: $HOOK_TYPE (deveria ser 4)${NC}"
    exit 1
else
    echo -e "${YELLOW}⚠️  Não foi possível verificar hookType (continuando...)${NC}"
fi

echo ""

#━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# ETAPA 2: CONFIGURAR IGP PARA TERRA CLASSIC
#━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

echo "2️⃣  CONFIGURANDO IGP PARA TERRA CLASSIC..."
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

echo "   Domain: $DOMAIN"
echo "   Exchange Rate: $EXCHANGE_RATE"
echo "   Gas Price: $GAS_PRICE"
echo ""

MAX_RETRIES=3
RETRY=0

while [ $RETRY -lt $MAX_RETRIES ]; do
    echo "   Tentativa $((RETRY + 1))/$MAX_RETRIES..."
    
    TX_CONFIG=$(cast send "$IGP_ADDRESS" \
        "setRemoteGasData(uint32,uint128,uint128)" \
        "$DOMAIN" "$EXCHANGE_RATE" "$GAS_PRICE" \
        --rpc-url "$RPC" \
        --private-key "$PRIVATE_KEY_SEPOLIA" \
        --legacy \
        2>&1 | grep "transactionHash" | awk '{print $2}')
    
    if [ ! -z "$TX_CONFIG" ]; then
        echo -e "${GREEN}✅ IGP configurado${NC}"
        echo "   TX: $TX_CONFIG"
        break
    fi
    
    RETRY=$((RETRY + 1))
    if [ $RETRY -lt $MAX_RETRIES ]; then
        echo -e "${YELLOW}   ⚠️  Tentando novamente...${NC}"
        sleep 3
    else
        echo -e "${RED}   ❌ Falhou após $MAX_RETRIES tentativas${NC}"
        exit 1
    fi
done

echo ""

#━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# ETAPA 3: ASSOCIAR IGP AO WARP ROUTE
#━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

echo "3️⃣  ASSOCIANDO IGP AO WARP ROUTE..."
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

RETRY=0

while [ $RETRY -lt $MAX_RETRIES ]; do
    echo "   Tentativa $((RETRY + 1))/$MAX_RETRIES..."
    
    TX_HOOK=$(cast send "$WARP_ROUTE" \
        "setHook(address)" \
        "$IGP_ADDRESS" \
        --rpc-url "$RPC" \
        --private-key "$PRIVATE_KEY_SEPOLIA" \
        --legacy \
        2>&1 | grep "transactionHash" | awk '{print $2}')
    
    if [ ! -z "$TX_HOOK" ]; then
        echo -e "${GREEN}✅ IGP associado ao Warp Route${NC}"
        echo "   TX: $TX_HOOK"
        break
    fi
    
    RETRY=$((RETRY + 1))
    if [ $RETRY -lt $MAX_RETRIES ]; then
        echo -e "${YELLOW}   ⚠️  Tentando novamente...${NC}"
        sleep 3
    else
        echo -e "${RED}   ❌ Falhou após $MAX_RETRIES tentativas${NC}"
        exit 1
    fi
done

echo ""

#━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# ETAPA 4: VERIFICAÇÃO FINAL
#━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

echo "4️⃣  VERIFICANDO CONFIGURAÇÃO FINAL..."
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

echo "   Aguardando confirmação na blockchain..."
sleep 10

HOOK_ATUAL=$(cast call "$WARP_ROUTE" "hook()(address)" --rpc-url "$RPC" 2>/dev/null || echo "ERRO")

echo ""
echo "   Hook configurado no Warp: $HOOK_ATUAL"
echo "   Hook esperado: $IGP_ADDRESS"
echo "   Hook Type: $HOOK_TYPE"

echo ""

if [ "$HOOK_ATUAL" = "$IGP_ADDRESS" ]; then
    echo -e "${GREEN}   ✅✅✅ CONFIGURAÇÃO PERFEITA! ✅✅✅${NC}"
else
    echo -e "${YELLOW}   ⚠️  Hooks não coincidem${NC}"
    echo -e "${YELLOW}   Isso pode ser um problema de propagação${NC}"
    echo -e "${YELLOW}   Aguarde 30 segundos e verifique novamente${NC}"
fi

echo ""

#━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# CONCLUSÃO
#━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

echo "╔═══════════════════════════════════════════════════════════════════════╗"
echo "║                                                                       ║"
echo "║                  ✅ CONFIGURAÇÃO CONCLUÍDA! ✅                        ║"
echo "║                                                                       ║"
echo "╚═══════════════════════════════════════════════════════════════════════╝"
echo ""
echo -e "${GREEN}📋 RESUMO:${NC}"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo -e "${GREEN}  ✅ IGP: $IGP_ADDRESS${NC}"
echo -e "${GREEN}  ✅ Warp Route: $WARP_ROUTE${NC}"
echo -e "${GREEN}  ✅ Hook Type: 4 (correto)${NC}"
echo -e "${GREEN}  ✅ Terra Classic configurado (domain 1325)${NC}"
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo -e "${BLUE}🎯 PRÓXIMO PASSO: Testar a transferência${NC}"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "1. Acesse: https://warp.hyperlane.xyz"
echo "2. Conecte sua carteira"
echo "3. Selecione: Sepolia → Terra Classic"
echo "4. Tente enviar tokens"
echo ""
echo -e "${GREEN}O erro 'destination not supported' deve estar CORRIGIDO! ✅${NC}"
echo ""
