#!/bin/bash

# Script para configurar rota IGP para Sepolia
# Usage: ./script/set-igp-route-sepolia.sh
# 
# Suporta dois métodos de autenticação:
# 1. Chave privada (PRIVATE_KEY ou TERRA_PRIVATE_KEY): usa script TypeScript
# 2. Keyring (KEY_NAME): usa terrad diretamente

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Configuration
KEYRING_BACKEND="file"
CHAIN_ID="rebel-2"
NODE="https://rpc.luncblaze.com:443"
FEES="12000000uluna"
IGP="terra1mcaqgr7kqs9xr3q6w0e9f2ekrj6sehwcep9shtss6u8pdz2rsw5qzrew7r"
IGP_ORACLE="terra1yew4y2ekzhkwuuz07yt7qufqxxejxhmnr7apehkqk7e8jdw8ffqqs8zhds"
SEPOLIA_DOMAIN=11155111

echo "======================================================================"
echo "Configurar Rota IGP para Sepolia (Domain $SEPOLIA_DOMAIN)"
echo "======================================================================"
echo ""
echo "Este script configura o IGP Router para usar o IGP Oracle quando"
echo "calcular custos de gas para transferências para Sepolia."
echo ""
echo "Configuração:"
echo "  • IGP Router: $IGP"
echo "  • IGP Oracle: $IGP_ORACLE"
echo "  • Domain: $SEPOLIA_DOMAIN (Sepolia Testnet)"
echo ""

# Check authentication method
if [ -n "$PRIVATE_KEY" ] || [ -n "$TERRA_PRIVATE_KEY" ]; then
  # Use private key method (TypeScript script)
  AUTH_METHOD="private_key"
  PRIVATE_KEY_TO_USE="${PRIVATE_KEY:-$TERRA_PRIVATE_KEY}"
  echo "🔐 Método de autenticação: Chave Privada"
  echo ""
  
  if [ -z "$SKIP_CONFIRM" ]; then
    read -p "Deseja continuar? (s/N): " CONFIRM
    if [ "$CONFIRM" != "s" ] && [ "$CONFIRM" != "S" ]; then
      echo "Operação cancelada."
      exit 0
    fi
  fi
  
  echo ""
  echo "======================================================================"
  echo "Configurando rota IGP usando chave privada..."
  echo "======================================================================"
  echo ""
  
  # Execute using TypeScript script
  PRIVATE_KEY="$PRIVATE_KEY_TO_USE" npx tsx script/set-igp-route-sepolia.ts
  
  if [ $? -eq 0 ]; then
    echo ""
    echo "======================================================================"
    echo "✅ Configuração concluída!"
    echo "======================================================================"
    echo ""
    echo "Agora você pode tentar transferir LUNC → Sepolia novamente."
    echo ""
  else
    echo -e "${RED}❌ Erro ao configurar rota IGP${NC}"
    exit 1
  fi
  
else
  # Use keyring method (terrad)
  AUTH_METHOD="keyring"
  echo "🔐 Método de autenticação: Keyring"
  echo ""
  
  # Check if KEY_NAME is set
  if [ -z "$KEY_NAME" ]; then
    read -p "Terra Classic Key Name [hypelane-val-testnet]: " KEY_NAME
    KEY_NAME="${KEY_NAME:-hypelane-val-testnet}"
  fi
  
  # Confirm
  if [ -z "$SKIP_CONFIRM" ]; then
    echo ""
    read -p "Deseja continuar? (s/N): " CONFIRM
    if [ "$CONFIRM" != "s" ] && [ "$CONFIRM" != "S" ]; then
      echo "Operação cancelada."
      exit 0
    fi
  fi
  
  echo ""
  echo "======================================================================"
  echo "Configurando rota IGP usando keyring..."
  echo "======================================================================"
  echo ""
  
  # Execute transaction
  TX_HASH=$(terrad tx wasm execute "$IGP" \
    "{\"router\":{\"set_routes\":{\"set\":[{\"domain\":$SEPOLIA_DOMAIN,\"route\":\"$IGP_ORACLE\"}]}}}" \
    --from "$KEY_NAME" \
    --keyring-backend "$KEYRING_BACKEND" \
    --chain-id "$CHAIN_ID" \
    --node "$NODE" \
    --gas auto \
    --gas-adjustment 1.5 \
    --fees "$FEES" \
    --yes \
    --output json 2>&1 | jq -r '.txhash' 2>/dev/null || echo "")
  
  if [ -z "$TX_HASH" ] || [ "$TX_HASH" == "null" ]; then
    echo -e "${RED}❌ Erro ao configurar rota IGP${NC}"
    echo "Verifique:"
    echo "  • KEY_NAME está correto"
    echo "  • Conta tem LUNC suficiente para fees"
    echo "  • IGP Router address está correto"
    exit 1
  fi
  
  echo -e "${GREEN}✅ Rota IGP configurada com sucesso!${NC}"
  echo "  • TX Hash: $TX_HASH"
  echo ""
  
  # Verify
  echo "Verificando configuração..."
  sleep 3
  
  VERIFY_ROUTE=$(terrad query wasm contract-state smart "$IGP" \
    '{"router":{"get_route":{"domain":'$SEPOLIA_DOMAIN'}}}' \
    --chain-id "$CHAIN_ID" \
    --node "$NODE" \
    --output json 2>/dev/null | jq -r '.data.route.route' 2>/dev/null || echo "")
  
  if [ "$VERIFY_ROUTE" == "$IGP_ORACLE" ]; then
    echo -e "${GREEN}✅ Verificação: Rota configurada corretamente${NC}"
    echo "  • Route: $VERIFY_ROUTE"
  else
    echo -e "${YELLOW}⚠️  Verificação: Aguardando confirmação da transação...${NC}"
    echo "  Execute novamente o script de verificação após alguns segundos:"
    echo "  ./script/check-igp-sepolia.sh"
  fi
  
  echo ""
  echo "======================================================================"
  echo "✅ Configuração concluída!"
  echo "======================================================================"
  echo ""
  echo "Agora você pode tentar transferir LUNC → Sepolia novamente."
  echo ""
fi
