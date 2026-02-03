#!/bin/bash

# Script para criar um novo IGP na rede Sepolia e associar ao Warp Route
# Baseado no conceito do script Solana, mas adaptado para Ethereum/Sepolia
# Usage: ./script/criar-igp-e-associar-warp-sepolia.sh

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo "======================================================================"
echo -e "${BLUE}Criar IGP e Associar ao Warp Route - Sepolia${NC}"
echo "======================================================================"
echo ""

# ============================================================================
# CONFIGURAÇÃO
# ============================================================================

# Sepolia RPC
SEPOLIA_RPC="${SEPOLIA_RPC:-https://1rpc.io/sepolia}"
SEPOLIA_RPC_ALT1="https://sepolia.drpc.org"
SEPOLIA_RPC_ALT2="https://rpc.sepolia.org"

# Domain IDs
TERRA_DOMAIN=1325
SEPOLIA_DOMAIN=11155111

# Endereço do Warp Route (fornecido pelo usuário)
WARP_ROUTE="${WARP_ROUTE:-0x224a4419D7FA69D3bEbAbce574c7c84B48D829b4}"

# Contratos Hyperlane em Sepolia (já deployados)
# Estes são os endereços dos contratos base do Hyperlane
MAILBOX="${MAILBOX:-0xfFAEF09B3cd11D9b20d1a19bECca54EEC2884766}"

# ============================================================================
# STEP 1: Coletar Inputs
# ============================================================================

# Verificar se as variáveis foram configuradas via ambiente (modo não-interativo)
if [ -n "$SEPOLIA_PRIVATE_KEY" ] && [ -n "$OWNER_ADDRESS" ]; then
  echo -e "${BLUE}📝 Modo não-interativo: usando variáveis de ambiente${NC}"
else
  # Modo interativo
  echo -e "${BLUE}📝 Por favor, forneça as seguintes informações:${NC}"
  echo ""

  # Sepolia Private Key
  if [ -z "$SEPOLIA_PRIVATE_KEY" ]; then
    read -p "Sepolia Private Key (0x...): " SEPOLIA_PRIVATE_KEY
    if [ -z "$SEPOLIA_PRIVATE_KEY" ]; then
      echo -e "${RED}❌ Erro: Sepolia Private Key é obrigatório${NC}"
      exit 1
    fi
  fi

  # Owner Address (endereço que será owner dos contratos)
  if [ -z "$OWNER_ADDRESS" ]; then
    read -p "Owner Address (0x...) [usar endereço da private key]: " OWNER_ADDRESS
    if [ -z "$OWNER_ADDRESS" ]; then
      # Derivar endereço da private key
      OWNER_ADDRESS=$(cast wallet address "$SEPOLIA_PRIVATE_KEY" 2>/dev/null || echo "")
      if [ -z "$OWNER_ADDRESS" ]; then
        echo -e "${RED}❌ Erro: Não foi possível derivar o endereço da private key${NC}"
        exit 1
      fi
      echo "  → Usando endereço derivado: $OWNER_ADDRESS"
    fi
  fi

  # Beneficiary (endereço que receberá os fundos do IGP)
  if [ -z "$BENEFICIARY_ADDRESS" ]; then
    read -p "Beneficiary Address (0x...) [usar owner]: " BENEFICIARY_ADDRESS
    if [ -z "$BENEFICIARY_ADDRESS" ]; then
      BENEFICIARY_ADDRESS="$OWNER_ADDRESS"
      echo "  → Usando owner como beneficiary: $BENEFICIARY_ADDRESS"
    fi
  fi

  # Configurações de Gas para Terra Classic
  # Valores atualizados baseados em:
  # LUNC: $0.00003674, ETH: $2,292.94 (03/02/2026)
  if [ -z "$TERRA_GAS_PRICE" ]; then
    read -p "Terra Classic Gas Price [38325000000 (38.325 uluna)]: " TERRA_GAS_PRICE
    TERRA_GAS_PRICE="${TERRA_GAS_PRICE:-38325000000}"
  fi

  if [ -z "$TERRA_EXCHANGE_RATE" ]; then
    read -p "Terra Classic Exchange Rate (LUNC/ETH * 1e18) [16020660000000]: " TERRA_EXCHANGE_RATE
    TERRA_EXCHANGE_RATE="${TERRA_EXCHANGE_RATE:-16020660000000}"
  fi

  if [ -z "$GAS_OVERHEAD" ]; then
    read -p "Gas Overhead para Terra Classic [200000]: " GAS_OVERHEAD
    GAS_OVERHEAD="${GAS_OVERHEAD:-200000}"
  fi
fi

echo ""
echo "======================================================================"
echo -e "${BLUE}📋 Resumo da Configuração:${NC}"
echo "======================================================================"
echo "Warp Route: $WARP_ROUTE"
echo "Owner: $OWNER_ADDRESS"
echo "Beneficiary: ${BENEFICIARY_ADDRESS:-$OWNER_ADDRESS}"
echo "Terra Domain: $TERRA_DOMAIN"
echo "Sepolia Domain: $SEPOLIA_DOMAIN"
echo "Terra Gas Price: ${TERRA_GAS_PRICE:-28325000000}"
echo "Terra Exchange Rate: ${TERRA_EXCHANGE_RATE:-1805936462255558}"
echo "Gas Overhead: ${GAS_OVERHEAD:-200000}"
echo ""

# Confirmar (skip em modo não-interativo)
if [ -z "$SKIP_CONFIRM" ]; then
  read -p "Deseja continuar? (y/n): " confirm
  if [ "$confirm" != "y" ]; then
    echo "Operação cancelada."
    exit 0
  fi
fi

# Garantir que o beneficiary está definido
BENEFICIARY_ADDRESS="${BENEFICIARY_ADDRESS:-$OWNER_ADDRESS}"
TERRA_GAS_PRICE="${TERRA_GAS_PRICE:-38325000000}"
TERRA_EXCHANGE_RATE="${TERRA_EXCHANGE_RATE:-16020660000000}"
GAS_OVERHEAD="${GAS_OVERHEAD:-200000}"

# ============================================================================
# STEP 2: Verificar ferramentas necessárias
# ============================================================================

echo ""
echo "======================================================================"
echo -e "${BLUE}🔧 Verificando ferramentas necessárias...${NC}"
echo "======================================================================"

if ! command -v cast &> /dev/null; then
    echo -e "${RED}❌ Foundry (cast) não encontrado!${NC}"
    echo "Instale com: curl -L https://foundry.paradigm.xyz | bash && foundryup"
    exit 1
fi

echo -e "${GREEN}✅ Foundry (cast) encontrado${NC}"

# ============================================================================
# STEP 3: Deploy StorageGasOracle
# ============================================================================

echo ""
echo "======================================================================"
echo -e "${BLUE}🚀 Passo 1: Deploy StorageGasOracle${NC}"
echo "======================================================================"
echo ""

# Tentar RPCs em ordem até encontrar um que funcione
STORAGE_GAS_ORACLE=""
RPC_USED=""

for RPC in "$SEPOLIA_RPC" "$SEPOLIA_RPC_ALT1" "$SEPOLIA_RPC_ALT2"; do
  echo "Tentando RPC: $RPC"
  
  # Deploy StorageGasOracle
  # O construtor é: constructor() Ownable(msg.sender)
  DEPLOY_OUTPUT=$(cast send --create \
    "$(cat ~/hyperlane-monorepo/solidity/contracts/hooks/igp/StorageGasOracle.sol | forge create --print-bytecode)" \
    --private-key "$SEPOLIA_PRIVATE_KEY" \
    --rpc-url "$RPC" \
    --json 2>&1 || echo "")
  
  # Verificar se o deploy foi bem-sucedido
  STORAGE_GAS_ORACLE=$(echo "$DEPLOY_OUTPUT" | jq -r '.contractAddress' 2>/dev/null)
  
  if [ -n "$STORAGE_GAS_ORACLE" ] && [ "$STORAGE_GAS_ORACLE" != "null" ]; then
    RPC_USED="$RPC"
    echo -e "${GREEN}✅ StorageGasOracle deployado com sucesso!${NC}"
    echo "Endereço: $STORAGE_GAS_ORACLE"
    break
  else
    echo -e "${YELLOW}⚠️  RPC falhou, tentando próximo...${NC}"
  fi
done

if [ -z "$STORAGE_GAS_ORACLE" ] || [ "$STORAGE_GAS_ORACLE" == "null" ]; then
  echo -e "${RED}❌ Falha ao deployar StorageGasOracle${NC}"
  echo ""
  echo "ℹ️  SOLUÇÃO ALTERNATIVA:"
  echo "Você pode usar o script TypeScript que usa ethers.js:"
  echo "  npx tsx script/criar-igp-e-associar-warp-sepolia.ts"
  exit 1
fi

# ============================================================================
# STEP 4: Configurar Gas Oracle com dados da Terra Classic
# ============================================================================

echo ""
echo "======================================================================"
echo -e "${BLUE}⚙️  Passo 2: Configurar Gas Oracle${NC}"
echo "======================================================================"
echo ""

echo "Configurando dados de gas para Terra Classic (domain $TERRA_DOMAIN)..."

# Função: setRemoteGasDataConfigs((uint32,uint128,uint128)[])
# struct RemoteGasDataConfig {
#   uint32 remoteDomain;
#   uint128 tokenExchangeRate;
#   uint128 gasPrice;
# }

CALLDATA=$(cast calldata "setRemoteGasDataConfigs((uint32,uint128,uint128)[])" \
  "[($TERRA_DOMAIN,$TERRA_EXCHANGE_RATE,$TERRA_GAS_PRICE)]")

echo "Calldata: $CALLDATA"

TX_HASH=$(cast send "$STORAGE_GAS_ORACLE" \
  "setRemoteGasDataConfigs((uint32,uint128,uint128)[])" \
  "[($TERRA_DOMAIN,$TERRA_EXCHANGE_RATE,$TERRA_GAS_PRICE)]" \
  --private-key "$SEPOLIA_PRIVATE_KEY" \
  --rpc-url "$RPC_USED" \
  --json | jq -r '.transactionHash')

if [ -z "$TX_HASH" ] || [ "$TX_HASH" == "null" ]; then
  echo -e "${RED}❌ Erro ao configurar Gas Oracle${NC}"
  exit 1
fi

echo -e "${GREEN}✅ Gas Oracle configurado com sucesso!${NC}"
echo "TX Hash: $TX_HASH"

# ============================================================================
# STEP 5: Deploy InterchainGasPaymaster
# ============================================================================

echo ""
echo "======================================================================"
echo -e "${BLUE}🚀 Passo 3: Deploy InterchainGasPaymaster${NC}"
echo "======================================================================"
echo ""

# O InterchainGasPaymaster usa padrão Proxy (Upgradeable)
# Precisamos fazer deploy de um proxy e inicializar
# Por simplicidade, vamos fazer deploy direto e chamar initialize

echo "⚠️  Nota: Para produção, considere usar TransparentUpgradeableProxy"
echo ""

# Deploy InterchainGasPaymaster (implementação)
# Vamos usar o script TypeScript para isso, pois é mais complexo
echo "Executando deploy via script TypeScript..."

DEPLOY_RESULT=$(SEPOLIA_PRIVATE_KEY="$SEPOLIA_PRIVATE_KEY" \
  OWNER_ADDRESS="$OWNER_ADDRESS" \
  BENEFICIARY_ADDRESS="$BENEFICIARY_ADDRESS" \
  STORAGE_GAS_ORACLE="$STORAGE_GAS_ORACLE" \
  TERRA_DOMAIN="$TERRA_DOMAIN" \
  GAS_OVERHEAD="$GAS_OVERHEAD" \
  RPC_URL="$RPC_USED" \
  npx tsx script/deploy-igp-sepolia-helper.ts 2>&1)

echo "$DEPLOY_RESULT"

# Extrair endereço do IGP
IGP_ADDRESS=$(echo "$DEPLOY_RESULT" | grep -E "IGP Address:" | sed 's/.*IGP Address: //' | tr -d ' ')

if [ -z "$IGP_ADDRESS" ] || [ "$IGP_ADDRESS" == "null" ]; then
  echo -e "${RED}❌ Erro ao deployar InterchainGasPaymaster${NC}"
  exit 1
fi

echo -e "${GREEN}✅ InterchainGasPaymaster deployado com sucesso!${NC}"
echo "Endereço: $IGP_ADDRESS"

# ============================================================================
# STEP 6: Associar IGP ao Warp Route
# ============================================================================

echo ""
echo "======================================================================"
echo -e "${BLUE}🔗 Passo 4: Associar IGP ao Warp Route${NC}"
echo "======================================================================"
echo ""

echo "Associando IGP $IGP_ADDRESS ao Warp Route $WARP_ROUTE..."

# A função no Warp Route para configurar o hook é:
# setHook(address _hook) external onlyOwner

TX_HASH=$(cast send "$WARP_ROUTE" \
  "setHook(address)" \
  "$IGP_ADDRESS" \
  --private-key "$SEPOLIA_PRIVATE_KEY" \
  --rpc-url "$RPC_USED" \
  --json 2>&1 | jq -r '.transactionHash' 2>/dev/null || echo "")

if [ -n "$TX_HASH" ] && [ "$TX_HASH" != "null" ]; then
  echo -e "${GREEN}✅ IGP associado ao Warp Route com sucesso!${NC}"
  echo "TX Hash: $TX_HASH"
else
  echo -e "${YELLOW}⚠️  Possível erro ao associar IGP ao Warp Route${NC}"
  echo ""
  echo "Isso pode acontecer se:"
  echo "  • Você não é o owner do Warp Route"
  echo "  • O Warp Route não possui a função setHook"
  echo "  • O Warp Route usa um padrão diferente (ex: HookConfig)"
  echo ""
  echo "Tente manualmente:"
  echo "  cast send \"$WARP_ROUTE\" \\"
  echo "    \"setHook(address)\" \\"
  echo "    \"$IGP_ADDRESS\" \\"
  echo "    --private-key \$SEPOLIA_PRIVATE_KEY \\"
  echo "    --rpc-url \"$RPC_USED\""
fi

# ============================================================================
# STEP 7: Resumo Final
# ============================================================================

echo ""
echo "======================================================================"
echo -e "${GREEN}✅ Processo Concluído!${NC}"
echo "======================================================================"
echo ""
echo -e "${BLUE}📋 Endereços dos Contratos:${NC}"
echo "─────────────────────────────────────────────────────────────────────"
echo "StorageGasOracle:         $STORAGE_GAS_ORACLE"
echo "InterchainGasPaymaster:   $IGP_ADDRESS"
echo "Warp Route:               $WARP_ROUTE"
echo ""
echo -e "${BLUE}📋 Configurações:${NC}"
echo "─────────────────────────────────────────────────────────────────────"
echo "Owner:                    $OWNER_ADDRESS"
echo "Beneficiary:              $BENEFICIARY_ADDRESS"
echo "Terra Domain:             $TERRA_DOMAIN"
echo "Terra Gas Price:          $TERRA_GAS_PRICE"
echo "Terra Exchange Rate:      $TERRA_EXCHANGE_RATE"
echo "Gas Overhead:             $GAS_OVERHEAD"
echo ""
echo -e "${BLUE}🔍 Verificação:${NC}"
echo "─────────────────────────────────────────────────────────────────────"
echo ""
echo "# Verificar configuração do Gas Oracle:"
echo "cast call \"$STORAGE_GAS_ORACLE\" \\"
echo "  \"getExchangeRateAndGasPrice(uint32)(uint128,uint128)\" \\"
echo "  $TERRA_DOMAIN \\"
echo "  --rpc-url \"$RPC_USED\""
echo ""
echo "# Verificar owner do IGP:"
echo "cast call \"$IGP_ADDRESS\" \\"
echo "  \"owner()(address)\" \\"
echo "  --rpc-url \"$RPC_USED\""
echo ""
echo "# Verificar hook do Warp Route:"
echo "cast call \"$WARP_ROUTE\" \\"
echo "  \"hook()(address)\" \\"
echo "  --rpc-url \"$RPC_USED\""
echo ""
echo "======================================================================"
