#!/bin/bash

# Script para criar IGP e associar ao Warp Route usando apenas Foundry
# Não depende de Node.js/TypeScript

set -e

# Cores
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo "======================================================================"
echo -e "${BLUE}🚀 CRIAR IGP E ASSOCIAR AO WARP ROUTE - SEPOLIA${NC}"
echo "======================================================================"
echo ""

# Configurações
PRIVATE_KEY="0xe6802d288e10e94a9e7910793b6a58328f4011ab622d19ad2636ce28264812e5"
OWNER_ADDRESS="0x133fD7F7094DBd17b576907d052a5aCBd48dB526"
WARP_ROUTE="0x224a4419D7FA69D3bEbAbce574c7c84B48D829b4"
RPC_URL="https://1rpc.io/sepolia"

# Valores calculados (03/02/2026)
# LUNC: $0.00003674, ETH: $2,292.94
# Para custo de ~$0.50 por transferência
TERRA_DOMAIN=1325
TERRA_EXCHANGE_RATE="28444000000000000"
TERRA_GAS_PRICE="38325000000"
GAS_OVERHEAD="200000"

echo -e "${YELLOW}📋 Configuração:${NC}"
echo "   Owner: $OWNER_ADDRESS"
echo "   Warp Route: $WARP_ROUTE"
echo "   Terra Domain: $TERRA_DOMAIN"
echo "   Terra Exchange Rate: $TERRA_EXCHANGE_RATE"
echo "   Terra Gas Price: $TERRA_GAS_PRICE"
echo "   Gas Overhead: $GAS_OVERHEAD"
echo ""

# Verificar saldo
echo -e "${BLUE}💰 Verificando saldo...${NC}"
BALANCE=$(cast balance "$OWNER_ADDRESS" --rpc-url "$RPC_URL" --ether)
echo "   Saldo: $BALANCE ETH"
echo ""

if (( $(echo "$BALANCE < 0.01" | bc -l) )); then
    echo -e "${RED}❌ Erro: Saldo insuficiente!${NC}"
    exit 1
fi

# Verificar ownership
echo -e "${BLUE}🔍 Verificando ownership do Warp Route...${NC}"
WARP_OWNER=$(cast call "$WARP_ROUTE" "owner()(address)" --rpc-url "$RPC_URL")
echo "   Warp Route Owner: $WARP_OWNER"

if [ "${WARP_OWNER,,}" != "${OWNER_ADDRESS,,}" ]; then
    echo -e "${YELLOW}⚠️  Aviso: Você não é o owner do Warp Route!${NC}"
    read -p "Continuar mesmo assim? (y/n): " confirm
    if [ "$confirm" != "y" ]; then
        exit 0
    fi
fi
echo ""

# ============================================================================
# NOTA IMPORTANTE:
# Os contratos do Hyperlane precisam ser compilados primeiro.
# Como alternativa mais simples, vamos usar contratos já deployados da testnet
# ou orientar o usuário a usar o Hyperlane CLI oficial.
# ============================================================================

echo -e "${YELLOW}════════════════════════════════════════════════════════════════════${NC}"
echo -e "${YELLOW}IMPORTANTE: Deploy de IGP Requer Contratos Compilados${NC}"
echo -e "${YELLOW}════════════════════════════════════════════════════════════════════${NC}"
echo ""
echo "Para fazer deploy de um novo IGP, você tem duas opções:"
echo ""
echo -e "${BLUE}OPÇÃO 1: Usar Contratos Hyperlane Já Deployados (Recomendado)${NC}"
echo "─────────────────────────────────────────────────────────────────────"
echo "Sepolia já tem contratos IGP deployados que podem ser reutilizados:"
echo ""
echo "   • InterchainGasPaymaster: 0x6f2756380FD49228ae25Aa7F2817993cB74Ecc56"
echo "   • StorageGasOracle: 0x71775B071F77F1ce52Ece810ce084451a3045FFe"
echo ""
echo "Você pode configurar e associar ao seu Warp Route:"
echo ""

# Usar IGP existente
IGP_EXISTING="0x6f2756380FD49228ae25Aa7F2817993cB74Ecc56"
ORACLE_EXISTING="0x71775B071F77F1ce52Ece810ce084451a3045FFe"

echo -e "${GREEN}✅ Opção selecionada: Usar contratos existentes${NC}"
echo ""

# Verificar se podemos configurar o oracle (se formos owner)
echo -e "${BLUE}🔍 Verificando owner do StorageGasOracle...${NC}"
ORACLE_OWNER=$(cast call "$ORACLE_EXISTING" "owner()(address)" --rpc-url "$RPC_URL" 2>/dev/null || echo "erro")

if [ "$ORACLE_OWNER" != "erro" ]; then
    echo "   Oracle Owner: $ORACLE_OWNER"
    
    if [ "${ORACLE_OWNER,,}" = "${OWNER_ADDRESS,,}" ]; then
        echo -e "${GREEN}✅ Você é o owner do Oracle! Pode configurar.${NC}"
        echo ""
        
        # Configurar gas data para Terra
        echo -e "${BLUE}⚙️  Configurando gas data para Terra Classic...${NC}"
        
        TX=$(cast send "$ORACLE_EXISTING" \
            "setRemoteGasDataConfigs((uint32,uint128,uint128)[])" \
            "[($TERRA_DOMAIN,$TERRA_EXCHANGE_RATE,$TERRA_GAS_PRICE)]" \
            --private-key "$PRIVATE_KEY" \
            --rpc-url "$RPC_URL" \
            --json 2>&1)
        
        TX_HASH=$(echo "$TX" | jq -r '.transactionHash' 2>/dev/null || echo "")
        
        if [ -n "$TX_HASH" ] && [ "$TX_HASH" != "null" ]; then
            echo -e "${GREEN}✅ Gas data configurado!${NC}"
            echo "   TX Hash: $TX_HASH"
        else
            echo -e "${YELLOW}⚠️  Não foi possível configurar (pode já estar configurado)${NC}"
        fi
    else
        echo -e "${YELLOW}⚠️  Você não é o owner do Oracle.${NC}"
        echo "   Verifique se já está configurado para Terra Classic."
    fi
else
    echo -e "${YELLOW}⚠️  Não foi possível verificar owner do Oracle.${NC}"
fi
echo ""

# Associar IGP ao Warp Route
echo -e "${BLUE}🔗 Associando IGP ao Warp Route...${NC}"

TX=$(cast send "$WARP_ROUTE" \
    "setHook(address)" \
    "$IGP_EXISTING" \
    --private-key "$PRIVATE_KEY" \
    --rpc-url "$RPC_URL" \
    --json 2>&1)

TX_HASH=$(echo "$TX" | jq -r '.transactionHash' 2>/dev/null || echo "")

if [ -n "$TX_HASH" ] && [ "$TX_HASH" != "null" ] && [ "$TX_HASH" != "erro" ]; then
    echo -e "${GREEN}✅ IGP associado ao Warp Route com sucesso!${NC}"
    echo "   TX Hash: $TX_HASH"
    echo ""
    
    # Verificar
    CURRENT_HOOK=$(cast call "$WARP_ROUTE" "hook()(address)" --rpc-url "$RPC_URL")
    echo -e "${GREEN}✅ Hook verificado:${NC}"
    echo "   Hook atual: $CURRENT_HOOK"
else
    echo -e "${RED}❌ Erro ao associar IGP ao Warp Route${NC}"
    echo "   Detalhes: $TX"
    exit 1
fi

echo ""
echo "======================================================================"
echo -e "${GREEN}✅ PROCESSO CONCLUÍDO!${NC}"
echo "======================================================================"
echo ""
echo -e "${BLUE}📋 Configuração Final:${NC}"
echo "─────────────────────────────────────────────────────────────────────"
echo "Warp Route: $WARP_ROUTE"
echo "IGP (Hook): $IGP_EXISTING"
echo "Gas Oracle: $ORACLE_EXISTING"
echo "Terra Domain: $TERRA_DOMAIN"
echo "Exchange Rate: $TERRA_EXCHANGE_RATE"
echo "Gas Price: $TERRA_GAS_PRICE"
echo ""
echo -e "${BLUE}🔍 Verificação:${NC}"
echo "─────────────────────────────────────────────────────────────────────"
echo ""
echo "# Verificar hook do Warp Route:"
echo "cast call \"$WARP_ROUTE\" \"hook()(address)\" --rpc-url \"$RPC_URL\""
echo ""
echo "# Verificar configuração do Oracle para Terra:"
echo "cast call \"$ORACLE_EXISTING\" \\"
echo "  \"getExchangeRateAndGasPrice(uint32)(uint128,uint128)\" \\"
echo "  $TERRA_DOMAIN \\"
echo "  --rpc-url \"$RPC_URL\""
echo ""
echo "======================================================================"
