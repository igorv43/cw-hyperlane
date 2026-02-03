#!/bin/bash

# Script para executar a criação do IGP e associação ao Warp Route em Sepolia
# Endereço do Warp Route: 0x224a4419D7FA69D3bEbAbce574c7c84B48D829b4

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

# Valores atualizados (03/02/2026)
# LUNC: $0.00003674, ETH: $2,292.94
# Para custo de ~$0.50 por transferência
TERRA_EXCHANGE_RATE="28444000000000000"
TERRA_GAS_PRICE="38325000000"
GAS_OVERHEAD="200000"

echo -e "${YELLOW}📋 Configuração:${NC}"
echo "   Private Key: ${PRIVATE_KEY:0:10}...${PRIVATE_KEY: -10}"
echo "   Owner: $OWNER_ADDRESS"
echo "   Warp Route: $WARP_ROUTE"
echo "   Terra Exchange Rate: $TERRA_EXCHANGE_RATE"
echo "   Terra Gas Price: $TERRA_GAS_PRICE uluna"
echo "   Gas Overhead: $GAS_OVERHEAD"
echo ""

# Verificar saldo
echo -e "${BLUE}💰 Verificando saldo...${NC}"
BALANCE=$(cast balance "$OWNER_ADDRESS" --rpc-url https://1rpc.io/sepolia)
BALANCE_ETH=$(echo "scale=6; $BALANCE / 1000000000000000000" | bc)

echo "   Saldo: $BALANCE_ETH ETH"
echo ""

if [ "$BALANCE" = "0" ]; then
    echo -e "${RED}❌ Erro: Conta sem saldo!${NC}"
    echo ""
    echo "Obtenha ETH de Sepolia em um destes faucets:"
    echo "  • https://www.alchemy.com/faucets/ethereum-sepolia"
    echo "  • https://faucet.quicknode.com/ethereum/sepolia"
    echo "  • https://sepolia-faucet.pk910.de/"
    echo ""
    exit 1
fi

if (( $(echo "$BALANCE_ETH < 0.01" | bc -l) )); then
    echo -e "${YELLOW}⚠️  Aviso: Saldo baixo! Recomendado: pelo menos 0.1 ETH${NC}"
    echo ""
fi

# Verificar ownership do Warp Route
echo -e "${BLUE}🔍 Verificando ownership do Warp Route...${NC}"
WARP_OWNER=$(cast call "$WARP_ROUTE" "owner()(address)" --rpc-url https://1rpc.io/sepolia 2>/dev/null || echo "erro")

if [ "$WARP_OWNER" = "erro" ]; then
    echo -e "${YELLOW}⚠️  Aviso: Não foi possível verificar o owner do Warp Route${NC}"
    echo "   Isso pode acontecer se o contrato não possui a função owner()"
    echo ""
else
    echo "   Warp Route Owner: $WARP_OWNER"
    
    if [ "${WARP_OWNER,,}" != "${OWNER_ADDRESS,,}" ]; then
        echo -e "${YELLOW}⚠️  Aviso: Você NÃO é o owner do Warp Route!${NC}"
        echo "   Owner atual: $WARP_OWNER"
        echo "   Seu endereço: $OWNER_ADDRESS"
        echo ""
        echo "   A associação do IGP ao Warp Route pode falhar."
        echo "   Continue apenas se tiver certeza."
        echo ""
        read -p "Deseja continuar mesmo assim? (y/n): " confirm
        if [ "$confirm" != "y" ]; then
            echo "Operação cancelada."
            exit 0
        fi
    else
        echo -e "${GREEN}✅ Você é o owner do Warp Route!${NC}"
    fi
fi
echo ""

# Executar script TypeScript
echo -e "${BLUE}🚀 Executando deploy do IGP...${NC}"
echo "======================================================================"
echo ""

export SEPOLIA_PRIVATE_KEY="$PRIVATE_KEY"
export OWNER_ADDRESS="$OWNER_ADDRESS"
export BENEFICIARY_ADDRESS="$OWNER_ADDRESS"
export WARP_ROUTE="$WARP_ROUTE"
export TERRA_EXCHANGE_RATE="$TERRA_EXCHANGE_RATE"
export TERRA_GAS_PRICE="$TERRA_GAS_PRICE"
export GAS_OVERHEAD="$GAS_OVERHEAD"
export RPC_URL="https://1rpc.io/sepolia"

npx tsx script/criar-igp-e-associar-warp-sepolia.ts

echo ""
echo "======================================================================"
echo -e "${GREEN}✅ Script executado!${NC}"
echo "======================================================================"
