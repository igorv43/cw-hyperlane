#!/bin/bash

# Script para vincular Warp Routes Terra Classic ↔ Sepolia
# Usage: ./script/link-terra-sepolia.sh

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
# Sepolia RPC - try multiple endpoints in order
# Tested and working: 1rpc.io, sepolia.drpc.org
SEPOLIA_RPC="${SEPOLIA_RPC:-https://1rpc.io/sepolia}"
# Alternative RPCs to try in order
SEPOLIA_RPC_ALT1="https://sepolia.drpc.org"
SEPOLIA_RPC_ALT2="https://rpc.sepolia.org"
SEPOLIA_RPC_ALT3="https://rpc.ankr.com/eth_sepolia"
SEPOLIA_RPC_ALT4="https://eth-sepolia-public.unifra.io"
TERRA_DOMAIN=1325
SEPOLIA_DOMAIN=11155111

echo "======================================================================"
echo "Vincular Warp Routes: Terra Classic ↔ Sepolia"
echo "======================================================================"
echo ""

# ============================================================================
# STEP 1: Collect Inputs
# ============================================================================

# Check if variables are set via environment (non-interactive mode)
if [ -n "$TERRA_WARP" ] && [ -n "$SEPOLIA_WARP" ] && [ -n "$SEPOLIA_PRIVATE_KEY" ]; then
  echo "📝 Modo não-interativo: usando variáveis de ambiente"
  SEPOLIA_DOMAIN="${SEPOLIA_DOMAIN:-11155111}"
  # Check if TERRA_PRIVATE_KEY is set, otherwise use KEY_NAME
  if [ -n "$TERRA_PRIVATE_KEY" ]; then
    TERRA_AUTH_METHOD="p"
    KEY_NAME=""
    # Remove 0x prefix if present
    TERRA_PRIVATE_KEY=$(echo "$TERRA_PRIVATE_KEY" | sed 's/^0x//')
  else
    TERRA_AUTH_METHOD="k"
    KEY_NAME="${KEY_NAME:-hypelane-val-testnet}"
    TERRA_PRIVATE_KEY=""
  fi
else
  # Interactive mode
  echo "📝 Por favor, forneça as seguintes informações:"
  echo ""

  # Terra Classic Warp Route (bech32)
  read -p "Terra Classic Warp Route (bech32): " TERRA_WARP
  if [ -z "$TERRA_WARP" ]; then
    echo -e "${RED}❌ Erro: Terra Classic Warp Route é obrigatório${NC}"
    exit 1
  fi

  # Sepolia Domain (default: 11155111)
  read -p "Sepolia Domain [11155111]: " SEPOLIA_DOMAIN_INPUT
  SEPOLIA_DOMAIN="${SEPOLIA_DOMAIN_INPUT:-11155111}"

  # Sepolia Warp Route (0x...)
  read -p "Sepolia Warp Route (0x...): " SEPOLIA_WARP
  if [ -z "$SEPOLIA_WARP" ]; then
    echo -e "${RED}❌ Erro: Sepolia Warp Route é obrigatório${NC}"
    exit 1
  fi

  # Sepolia Private Key
  read -p "Sepolia Private Key (0x...): " SEPOLIA_PRIVATE_KEY
  if [ -z "$SEPOLIA_PRIVATE_KEY" ]; then
    echo -e "${RED}❌ Erro: Sepolia Private Key é obrigatório${NC}"
    exit 1
  fi

  # Terra Classic Private Key or Key Name
  echo "Terra Classic:"
  read -p "  Usar chave privada (p) ou keyring (k)? [p]: " TERRA_AUTH_METHOD
  TERRA_AUTH_METHOD="${TERRA_AUTH_METHOD:-p}"

  if [ "$TERRA_AUTH_METHOD" = "p" ]; then
    read -p "  Terra Classic Private Key (hex, sem 0x): " TERRA_PRIVATE_KEY
    if [ -z "$TERRA_PRIVATE_KEY" ]; then
      echo -e "${RED}❌ Erro: Terra Classic Private Key é obrigatório${NC}"
      exit 1
    fi
    # Remove 0x prefix if present
    TERRA_PRIVATE_KEY=$(echo "$TERRA_PRIVATE_KEY" | sed 's/^0x//')
    KEY_NAME=""
  else
    read -p "  Terra Classic Key Name [hypelane-val-testnet]: " KEY_NAME
    KEY_NAME="${KEY_NAME:-hypelane-val-testnet}"
    TERRA_PRIVATE_KEY=""
  fi
fi

echo ""
echo "======================================================================"
echo "📋 Resumo da Configuração:"
echo "======================================================================"
echo "Terra Classic Warp Route: $TERRA_WARP"
echo "Terra Classic Domain: $TERRA_DOMAIN"
echo "Sepolia Warp Route: $SEPOLIA_WARP"
echo "Sepolia Domain: $SEPOLIA_DOMAIN"
if [ -n "$TERRA_PRIVATE_KEY" ]; then
  echo "Terra Classic Auth: Private Key (${#TERRA_PRIVATE_KEY} chars)"
else
  echo "Terra Classic Auth: Keyring ($KEY_NAME)"
fi
echo ""

# Confirm (skip in non-interactive mode)
if [ -z "$SKIP_CONFIRM" ]; then
  read -p "Deseja continuar? (y/n): " confirm
  if [ "$confirm" != "y" ]; then
    echo "Operação cancelada."
    exit 0
  fi
fi

# ============================================================================
# STEP 2: Convert Addresses to Hex Format
# ============================================================================

echo ""
echo "======================================================================"
echo "🔄 Convertendo endereços para formato hex..."
echo "======================================================================"

# Convert Sepolia address (0x...) to 32-byte hex
# EVM addresses are 20 bytes (40 hex chars), but contract expects 32 bytes (64 hex chars)
# So we need to pad with zeros on the left
SEPOLIA_WARP_CLEAN=$(echo "$SEPOLIA_WARP" | sed 's/^0x//' | tr '[:upper:]' '[:lower:]')
# Validate it's a valid hex address (40 chars)
if [ ${#SEPOLIA_WARP_CLEAN} -ne 40 ]; then
  echo -e "${RED}❌ Erro: Endereço Sepolia inválido (deve ter 40 caracteres hex após 0x)${NC}"
  exit 1
fi
# Pad to 64 characters (32 bytes) with zeros on the left
SEPOLIA_WARP_HEX=$(printf "%064s" "$SEPOLIA_WARP_CLEAN" | sed 's/ /0/g')
SEPOLIA_WARP_HEX="0x$SEPOLIA_WARP_HEX"

echo "✅ Sepolia Warp Route (hex 32 bytes): $SEPOLIA_WARP_HEX"

# Convert Terra Classic address (bech32) to 32-byte hex
echo "Convertendo Terra Classic address para hex..."
TERRA_WARP_HEX=$(node -e "
const { fromBech32 } = require('@cosmjs/encoding');
try {
  const addr = '$TERRA_WARP';
  const { data } = fromBech32(addr);
  const hexed = Buffer.from(data).toString('hex');
  const padded = hexed.padStart(64, '0');
  console.log('0x' + padded);
} catch (e) {
  console.error('Erro:', e.message);
  process.exit(1);
}
")

if [ -z "$TERRA_WARP_HEX" ]; then
  echo -e "${RED}❌ Erro ao converter Terra Classic address${NC}"
  exit 1
fi

echo "✅ Terra Classic Warp Route (hex 32 bytes): $TERRA_WARP_HEX"
echo ""

# ============================================================================
# STEP 3: Link Terra Classic → Sepolia
# ============================================================================

echo "======================================================================"
echo "🔗 Passo 1: Vincular Terra Classic → Sepolia"
echo "======================================================================"
echo ""

if [ -n "$TERRA_PRIVATE_KEY" ]; then
  # Use private key (TypeScript script)
  echo "Executando transação no Terra Classic usando chave privada..."
  echo ""
  
  # Execute and capture output
  TERRA_OUTPUT=$(TERRA_PRIVATE_KEY="$TERRA_PRIVATE_KEY" \
    TERRA_WARP="$TERRA_WARP" \
    SEPOLIA_DOMAIN="$SEPOLIA_DOMAIN" \
    SEPOLIA_WARP_HEX="$SEPOLIA_WARP_HEX" \
    npx tsx script/enroll-remote-router-terra.ts 2>&1)
  
  # Display output
  echo "$TERRA_OUTPUT"
  
  # Extract TX hash
  TERRA_TX_HASH=$(echo "$TERRA_OUTPUT" | grep -E "TX Hash:" | sed 's/.*TX Hash: //' | head -1 | tr -d ' ')
  
  if [ -z "$TERRA_TX_HASH" ] || [ "$TERRA_TX_HASH" == "null" ]; then
    echo -e "${RED}❌ Erro ao executar transação no Terra Classic${NC}"
    echo "Verifique a saída acima para mais detalhes."
    exit 1
  fi
  
  echo ""
  echo -e "${GREEN}✅ Transação Terra Classic executada com sucesso!${NC}"
  echo "TX Hash: $TERRA_TX_HASH"
else
  # Use keyring (terrad)
  # Check if key exists
  if ! terrad keys show ${KEY_NAME} --keyring-backend ${KEYRING_BACKEND} &>/dev/null; then
    echo -e "${RED}⚠️  Erro: Key '${KEY_NAME}' não encontrada no keyring.${NC}"
    echo "Chaves disponíveis:"
    terrad keys list --keyring-backend ${KEYRING_BACKEND} 2>/dev/null | grep -E "^[a-z]" || echo "  (nenhuma encontrada)"
    exit 1
  fi

  echo "Executando transação no Terra Classic usando keyring..."
  echo ""

  # Remove 0x prefix for terrad (contract expects hex without prefix)
  SEPOLIA_WARP_HEX_NO_PREFIX=$(echo "$SEPOLIA_WARP_HEX" | sed 's/^0x//')
  
  TERRA_TX_HASH=$(terrad tx wasm execute "$TERRA_WARP" \
    "{\"router\":{\"set_route\":{\"set\":{\"domain\":$SEPOLIA_DOMAIN,\"route\":\"$SEPOLIA_WARP_HEX_NO_PREFIX\"}}}}" \
    --from ${KEY_NAME} \
    --keyring-backend ${KEYRING_BACKEND} \
    --chain-id ${CHAIN_ID} \
    --node ${NODE} \
    --gas auto \
    --gas-adjustment 1.5 \
    --fees ${FEES} \
    --yes \
    --output json | jq -r '.txhash')

  if [ -z "$TERRA_TX_HASH" ] || [ "$TERRA_TX_HASH" == "null" ]; then
    echo -e "${RED}❌ Erro ao executar transação no Terra Classic${NC}"
    exit 1
  fi

  echo -e "${GREEN}✅ Transação Terra Classic executada com sucesso!${NC}"
  echo "TX Hash: $TERRA_TX_HASH"
fi

echo ""

# Wait a bit for transaction to be included
echo "Aguardando confirmação..."
sleep 5

# ============================================================================
# STEP 4: Link Sepolia → Terra Classic
# ============================================================================

echo "======================================================================"
echo "🔗 Passo 2: Vincular Sepolia → Terra Classic"
echo "======================================================================"
echo ""

# Generate calldata
echo "Gerando calldata..."
CALLDATA=$(cast calldata "enrollRemoteRouter(uint32,bytes32)" \
  $TERRA_DOMAIN \
  $TERRA_WARP_HEX)

echo "Calldata: $CALLDATA"
echo ""

# Execute transaction on Sepolia
echo "Executando transação no Sepolia..."
echo ""

# Try RPCs in order until one works
SEPOLIA_TX_HASH=""
RPC_USED=""

for RPC in "$SEPOLIA_RPC" "$SEPOLIA_RPC_ALT1" "$SEPOLIA_RPC_ALT2" "$SEPOLIA_RPC_ALT3" "$SEPOLIA_RPC_ALT4"; do
  echo "Tentando RPC: $RPC"
  
  RPC_OUTPUT=$(cast send "$SEPOLIA_WARP" \
    "enrollRemoteRouter(uint32,bytes32)" \
    $TERRA_DOMAIN \
    $TERRA_WARP_HEX \
    --private-key "$SEPOLIA_PRIVATE_KEY" \
    --rpc-url "$RPC" \
    --legacy \
    --gas-price 1000000000 \
    --json 2>&1)
  
  SEPOLIA_TX_HASH=$(echo "$RPC_OUTPUT" | jq -r '.transactionHash' 2>/dev/null)
  
  if [ -n "$SEPOLIA_TX_HASH" ] && [ "$SEPOLIA_TX_HASH" != "null" ] && [ "$SEPOLIA_TX_HASH" != "" ]; then
    RPC_USED="$RPC"
    echo -e "${GREEN}✅ Sucesso com RPC: $RPC${NC}"
    break
  else
    echo -e "${YELLOW}⚠️  RPC falhou, tentando próximo...${NC}"
  fi
done

if [ -z "$SEPOLIA_TX_HASH" ] || [ "$SEPOLIA_TX_HASH" == "null" ] || [ "$SEPOLIA_TX_HASH" == "" ]; then
  echo -e "${RED}❌ Erro ao executar transação no Sepolia com todos os RPCs${NC}"
  echo "Verifique:"
  echo "  • RPCs estão acessíveis"
  echo "  • Chave privada está correta"
  echo "  • Conta tem ETH suficiente para gas"
  echo "  • Warp Route address está correto"
  exit 1
fi

echo ""
echo "RPC usado: $RPC_USED"

echo -e "${GREEN}✅ Transação Sepolia executada com sucesso!${NC}"
echo "TX Hash: $SEPOLIA_TX_HASH"
echo ""

# Wait a bit for transaction to be included
echo "Aguardando confirmação..."
sleep 5

# ============================================================================
# STEP 5: Verify Links
# ============================================================================

echo ""
echo "======================================================================"
echo "✅ Verificando vínculos..."
echo "======================================================================"
echo ""

# Verify Terra Classic → Sepolia
echo "1. Verificando Terra Classic → Sepolia..."
TERRA_ROUTE=$(terrad query wasm contract-state smart "$TERRA_WARP" \
  "{\"router\":{\"get_route\":{\"domain\":$SEPOLIA_DOMAIN}}}" \
  --node "$NODE" \
  --output json 2>/dev/null | jq -r '.data.route' || echo "")

if [ -n "$TERRA_ROUTE" ] && [ "$TERRA_ROUTE" != "null" ]; then
  echo -e "${GREEN}✅ Rota encontrada no Terra Classic: $TERRA_ROUTE${NC}"
  if [ "$TERRA_ROUTE" == "$SEPOLIA_WARP_HEX" ]; then
    echo -e "${GREEN}   ✓ Endereço corresponde ao Sepolia Warp Route${NC}"
  else
    echo -e "${YELLOW}   ⚠️  Endereço não corresponde exatamente${NC}"
  fi
else
  echo -e "${YELLOW}⚠️  Rota não encontrada (pode levar alguns segundos para aparecer)${NC}"
fi

echo ""

# Verify Sepolia → Terra Classic
echo "2. Verificando Sepolia → Terra Classic..."
SEPOLIA_ROUTE=""
for RPC in "$SEPOLIA_RPC" "$SEPOLIA_RPC_ALT1" "$SEPOLIA_RPC_ALT2" "$SEPOLIA_RPC_ALT3" "$SEPOLIA_RPC_ALT4"; do
  if SEPOLIA_ROUTE=$(cast call "$SEPOLIA_WARP" \
    "routers(uint32)(bytes32)" \
    $TERRA_DOMAIN \
    --rpc-url "$RPC" 2>/dev/null); then
    break
  fi
done

if [ -n "$SEPOLIA_ROUTE" ] && [ "$SEPOLIA_ROUTE" != "0x0000000000000000000000000000000000000000000000000000000000000000" ]; then
  echo -e "${GREEN}✅ Rota encontrada no Sepolia: $SEPOLIA_ROUTE${NC}"
  if [ "$SEPOLIA_ROUTE" == "$TERRA_WARP_HEX" ]; then
    echo -e "${GREEN}   ✓ Endereço corresponde ao Terra Classic Warp Route${NC}"
  else
    echo -e "${YELLOW}   ⚠️  Endereço não corresponde exatamente${NC}"
  fi
else
  echo -e "${YELLOW}⚠️  Rota não encontrada (pode levar alguns segundos para aparecer)${NC}"
fi

echo ""

# List all routes on Terra Classic
echo "3. Listando todas as rotas no Terra Classic..."
terrad query wasm contract-state smart "$TERRA_WARP" \
  '{"router":{"list_routes":{}}}' \
  --node "$NODE" \
  --output json | jq '.data.routes' || echo "Erro ao listar rotas"

echo ""
echo "======================================================================"
echo -e "${GREEN}✅ Processo concluído!${NC}"
echo "======================================================================"
echo ""
echo "📋 Resumo das Transações:"
echo "  • Terra Classic → Sepolia: $TERRA_TX_HASH"
echo "  • Sepolia → Terra Classic: $SEPOLIA_TX_HASH"
echo ""
echo "🔍 Para verificar novamente mais tarde:"
echo ""
echo "  # Terra Classic → Sepolia"
echo "  terrad query wasm contract-state smart \"$TERRA_WARP\" \\"
echo "    '{\"router\":{\"get_route\":{\"domain\":$SEPOLIA_DOMAIN}}}' \\"
echo "    --node \"$NODE\""
echo ""
echo "  # Sepolia → Terra Classic"
echo "  cast call \"$SEPOLIA_WARP\" \\"
echo "    \"routers(uint32)(bytes32)\" \\"
echo "    $TERRA_DOMAIN \\"
echo "    --rpc-url \"$SEPOLIA_RPC\""
echo ""
