#!/bin/bash

# Script simplificado para criar IGP usando Foundry (Forge)
# Este script usa Forge para compilar e deployar os contratos
# Usage: ./script/deploy-igp-sepolia-foundry.sh

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo "======================================================================"
echo -e "${BLUE}Deploy IGP usando Foundry - Sepolia${NC}"
echo "======================================================================"
echo ""

# ============================================================================
# CONFIGURAÇÃO
# ============================================================================

SEPOLIA_RPC="${SEPOLIA_RPC:-https://1rpc.io/sepolia}"
CONTRACTS_PATH="${CONTRACTS_PATH:-$HOME/hyperlane-monorepo/solidity}"

# Verificar se SEPOLIA_PRIVATE_KEY está definida
if [ -z "$SEPOLIA_PRIVATE_KEY" ]; then
    echo -e "${RED}❌ Erro: SEPOLIA_PRIVATE_KEY não definida${NC}"
    echo "Defina com: export SEPOLIA_PRIVATE_KEY=\"0x...\""
    exit 1
fi

# Configurações padrão
TERRA_DOMAIN="${TERRA_DOMAIN:-1325}"
TERRA_GAS_PRICE="${TERRA_GAS_PRICE:-28325000000}"
TERRA_EXCHANGE_RATE="${TERRA_EXCHANGE_RATE:-1805936462255558}"
GAS_OVERHEAD="${GAS_OVERHEAD:-200000}"
WARP_ROUTE="${WARP_ROUTE:-0x224a4419D7FA69D3bEbAbce574c7c84B48D829b4}"

# Derivar endereços
DEPLOYER=$(cast wallet address "$SEPOLIA_PRIVATE_KEY" 2>/dev/null)
OWNER="${OWNER_ADDRESS:-$DEPLOYER}"
BENEFICIARY="${BENEFICIARY_ADDRESS:-$OWNER}"

echo -e "${BLUE}📋 Configuração:${NC}"
echo "RPC: $SEPOLIA_RPC"
echo "Deployer: $DEPLOYER"
echo "Owner: $OWNER"
echo "Beneficiary: $BENEFICIARY"
echo "Warp Route: $WARP_ROUTE"
echo ""

# ============================================================================
# VERIFICAR FERRAMENTAS
# ============================================================================

echo -e "${BLUE}🔧 Verificando ferramentas...${NC}"

if ! command -v forge &> /dev/null; then
    echo -e "${RED}❌ Foundry (forge) não encontrado!${NC}"
    echo "Instale com: curl -L https://foundry.paradigm.xyz | bash && foundryup"
    exit 1
fi

if ! command -v cast &> /dev/null; then
    echo -e "${RED}❌ Foundry (cast) não encontrado!${NC}"
    exit 1
fi

echo -e "${GREEN}✅ Foundry encontrado${NC}"
echo ""

# ============================================================================
# COMPILAR CONTRATOS
# ============================================================================

echo -e "${BLUE}🔨 Compilando contratos...${NC}"

if [ ! -d "$CONTRACTS_PATH" ]; then
    echo -e "${RED}❌ Diretório de contratos não encontrado: $CONTRACTS_PATH${NC}"
    echo "Defina o caminho correto com: export CONTRACTS_PATH=\"/caminho/para/hyperlane-monorepo/solidity\""
    exit 1
fi

cd "$CONTRACTS_PATH"

# Compilar se necessário
if [ ! -d "out" ] || [ ! -f "out/StorageGasOracle.sol/StorageGasOracle.json" ]; then
    echo "Compilando contratos Hyperlane..."
    forge build
else
    echo "Contratos já compilados"
fi

echo -e "${GREEN}✅ Contratos compilados${NC}"
echo ""

# Voltar ao diretório anterior
cd - > /dev/null

# ============================================================================
# DEPLOY STORAGEGASORACLE
# ============================================================================

echo "======================================================================"
echo -e "${BLUE}🚀 Passo 1: Deploy StorageGasOracle${NC}"
echo "======================================================================"
echo ""

STORAGE_GAS_ORACLE=$(forge create \
    --rpc-url "$SEPOLIA_RPC" \
    --private-key "$SEPOLIA_PRIVATE_KEY" \
    --contracts "$CONTRACTS_PATH/contracts" \
    contracts/hooks/igp/StorageGasOracle.sol:StorageGasOracle \
    --json | jq -r '.deployedTo')

if [ -z "$STORAGE_GAS_ORACLE" ] || [ "$STORAGE_GAS_ORACLE" == "null" ]; then
    echo -e "${RED}❌ Erro ao deployar StorageGasOracle${NC}"
    exit 1
fi

echo -e "${GREEN}✅ StorageGasOracle deployado!${NC}"
echo "Endereço: $STORAGE_GAS_ORACLE"
echo ""

# Aguardar confirmação
sleep 3

# ============================================================================
# CONFIGURAR STORAGEGASORACLE
# ============================================================================

echo "======================================================================"
echo -e "${BLUE}⚙️  Passo 2: Configurar StorageGasOracle${NC}"
echo "======================================================================"
echo ""

echo "Configurando dados de gas para Terra Classic (domain $TERRA_DOMAIN)..."

TX_HASH=$(cast send "$STORAGE_GAS_ORACLE" \
    "setRemoteGasData((uint32,uint128,uint128))" \
    "($TERRA_DOMAIN,$TERRA_EXCHANGE_RATE,$TERRA_GAS_PRICE)" \
    --private-key "$SEPOLIA_PRIVATE_KEY" \
    --rpc-url "$SEPOLIA_RPC" \
    --json | jq -r '.transactionHash')

if [ -z "$TX_HASH" ] || [ "$TX_HASH" == "null" ]; then
    echo -e "${RED}❌ Erro ao configurar StorageGasOracle${NC}"
    exit 1
fi

echo -e "${GREEN}✅ StorageGasOracle configurado!${NC}"
echo "TX Hash: $TX_HASH"
echo ""

# Verificar
RESULT=$(cast call "$STORAGE_GAS_ORACLE" \
    "getExchangeRateAndGasPrice(uint32)(uint128,uint128)" \
    "$TERRA_DOMAIN" \
    --rpc-url "$SEPOLIA_RPC")

echo "Verificação:"
echo "$RESULT"
echo ""

sleep 3

# ============================================================================
# DEPLOY INTERCHAINGASPAYMASTER
# ============================================================================

echo "======================================================================"
echo -e "${BLUE}🚀 Passo 3: Deploy InterchainGasPaymaster${NC}"
echo "======================================================================"
echo ""

IGP_ADDRESS=$(forge create \
    --rpc-url "$SEPOLIA_RPC" \
    --private-key "$SEPOLIA_PRIVATE_KEY" \
    --contracts "$CONTRACTS_PATH/contracts" \
    contracts/hooks/igp/InterchainGasPaymaster.sol:InterchainGasPaymaster \
    --json | jq -r '.deployedTo')

if [ -z "$IGP_ADDRESS" ] || [ "$IGP_ADDRESS" == "null" ]; then
    echo -e "${RED}❌ Erro ao deployar InterchainGasPaymaster${NC}"
    exit 1
fi

echo -e "${GREEN}✅ InterchainGasPaymaster deployado!${NC}"
echo "Endereço: $IGP_ADDRESS"
echo ""

sleep 3

# ============================================================================
# INICIALIZAR IGP
# ============================================================================

echo "======================================================================"
echo -e "${BLUE}⚙️  Passo 4: Inicializar IGP${NC}"
echo "======================================================================"
echo ""

echo "Inicializando IGP com owner=$OWNER e beneficiary=$BENEFICIARY..."

TX_HASH=$(cast send "$IGP_ADDRESS" \
    "initialize(address,address)" \
    "$OWNER" \
    "$BENEFICIARY" \
    --private-key "$SEPOLIA_PRIVATE_KEY" \
    --rpc-url "$SEPOLIA_RPC" \
    --json | jq -r '.transactionHash')

if [ -z "$TX_HASH" ] || [ "$TX_HASH" == "null" ]; then
    echo -e "${RED}❌ Erro ao inicializar IGP${NC}"
    exit 1
fi

echo -e "${GREEN}✅ IGP inicializado!${NC}"
echo "TX Hash: $TX_HASH"
echo ""

sleep 3

# ============================================================================
# CONFIGURAR DESTINATION GAS CONFIGS
# ============================================================================

echo "======================================================================"
echo -e "${BLUE}⚙️  Passo 5: Configurar Destination Gas Configs${NC}"
echo "======================================================================"
echo ""

echo "Configurando gas configs para Terra Classic..."

TX_HASH=$(cast send "$IGP_ADDRESS" \
    "setDestinationGasConfigs((uint32,address,uint96)[])" \
    "[($TERRA_DOMAIN,$STORAGE_GAS_ORACLE,$GAS_OVERHEAD)]" \
    --private-key "$SEPOLIA_PRIVATE_KEY" \
    --rpc-url "$SEPOLIA_RPC" \
    --json | jq -r '.transactionHash')

if [ -z "$TX_HASH" ] || [ "$TX_HASH" == "null" ]; then
    echo -e "${RED}❌ Erro ao configurar destination gas configs${NC}"
    exit 1
fi

echo -e "${GREEN}✅ Destination gas configs configurados!${NC}"
echo "TX Hash: $TX_HASH"
echo ""

sleep 3

# ============================================================================
# ASSOCIAR AO WARP ROUTE
# ============================================================================

echo "======================================================================"
echo -e "${BLUE}🔗 Passo 6: Associar IGP ao Warp Route${NC}"
echo "======================================================================"
echo ""

echo "Verificando owner do Warp Route..."
WARP_OWNER=$(cast call "$WARP_ROUTE" \
    "owner()(address)" \
    --rpc-url "$SEPOLIA_RPC" 2>/dev/null || echo "")

if [ -n "$WARP_OWNER" ]; then
    echo "Warp Route Owner: $WARP_OWNER"
    if [ "$WARP_OWNER" != "$DEPLOYER" ]; then
        echo -e "${YELLOW}⚠️  AVISO: Você não é o owner do Warp Route!${NC}"
        echo "  Owner: $WARP_OWNER"
        echo "  Você: $DEPLOYER"
        echo ""
        read -p "Deseja continuar mesmo assim? (y/n): " confirm
        if [ "$confirm" != "y" ]; then
            echo "Pulando associação ao Warp Route."
            echo "Para associar manualmente mais tarde, use:"
            echo "  cast send \"$WARP_ROUTE\" \"setHook(address)\" \"$IGP_ADDRESS\" --private-key \$WARP_OWNER_KEY --rpc-url $SEPOLIA_RPC"
            exit 0
        fi
    fi
fi

echo "Associando IGP ao Warp Route..."

TX_HASH=$(cast send "$WARP_ROUTE" \
    "setHook(address)" \
    "$IGP_ADDRESS" \
    --private-key "$SEPOLIA_PRIVATE_KEY" \
    --rpc-url "$SEPOLIA_RPC" \
    --json 2>&1 | jq -r '.transactionHash' 2>/dev/null || echo "")

if [ -n "$TX_HASH" ] && [ "$TX_HASH" != "null" ]; then
    echo -e "${GREEN}✅ IGP associado ao Warp Route!${NC}"
    echo "TX Hash: $TX_HASH"
    echo ""
    
    # Verificar
    sleep 3
    CURRENT_HOOK=$(cast call "$WARP_ROUTE" \
        "hook()(address)" \
        --rpc-url "$SEPOLIA_RPC" 2>/dev/null || echo "")
    
    if [ "$CURRENT_HOOK" == "$IGP_ADDRESS" ]; then
        echo -e "${GREEN}✅ Hook verificado com sucesso!${NC}"
    else
        echo -e "${YELLOW}⚠️  Hook atual: $CURRENT_HOOK${NC}"
        echo "  Esperado: $IGP_ADDRESS"
    fi
else
    echo -e "${YELLOW}⚠️  Não foi possível associar IGP ao Warp Route${NC}"
    echo "Isso pode acontecer se você não for o owner ou se o contrato usar uma interface diferente."
    echo ""
    echo "Para associar manualmente:"
    echo "  cast send \"$WARP_ROUTE\" \"setHook(address)\" \"$IGP_ADDRESS\" --private-key \$OWNER_KEY --rpc-url $SEPOLIA_RPC"
fi

echo ""

# ============================================================================
# RESUMO FINAL
# ============================================================================

echo "======================================================================"
echo -e "${GREEN}✅ DEPLOY CONCLUÍDO!${NC}"
echo "======================================================================"
echo ""
echo -e "${BLUE}📋 Endereços dos Contratos:${NC}"
echo "──────────────────────────────────────────────────────────────────"
echo "StorageGasOracle:         $STORAGE_GAS_ORACLE"
echo "InterchainGasPaymaster:   $IGP_ADDRESS"
echo "Warp Route:               $WARP_ROUTE"
echo ""
echo -e "${BLUE}📋 Configuração:${NC}"
echo "──────────────────────────────────────────────────────────────────"
echo "Owner:                    $OWNER"
echo "Beneficiary:              $BENEFICIARY"
echo "Terra Domain:             $TERRA_DOMAIN"
echo "Terra Gas Price:          $TERRA_GAS_PRICE"
echo "Terra Exchange Rate:      $TERRA_EXCHANGE_RATE"
echo "Gas Overhead:             $GAS_OVERHEAD"
echo ""
echo -e "${BLUE}🔍 Comandos de Verificação:${NC}"
echo "──────────────────────────────────────────────────────────────────"
echo ""
echo "# Verificar configuração do Gas Oracle:"
echo "cast call \"$STORAGE_GAS_ORACLE\" \\"
echo "  \"getExchangeRateAndGasPrice(uint32)(uint128,uint128)\" \\"
echo "  $TERRA_DOMAIN \\"
echo "  --rpc-url \"$SEPOLIA_RPC\""
echo ""
echo "# Verificar owner do IGP:"
echo "cast call \"$IGP_ADDRESS\" \\"
echo "  \"owner()(address)\" \\"
echo "  --rpc-url \"$SEPOLIA_RPC\""
echo ""
echo "# Verificar beneficiary do IGP:"
echo "cast call \"$IGP_ADDRESS\" \\"
echo "  \"beneficiary()(address)\" \\"
echo "  --rpc-url \"$SEPOLIA_RPC\""
echo ""
echo "# Verificar hook do Warp Route:"
echo "cast call \"$WARP_ROUTE\" \\"
echo "  \"hook()(address)\" \\"
echo "  --rpc-url \"$SEPOLIA_RPC\""
echo ""
echo "======================================================================"

# Salvar endereços
OUTPUT_FILE="deployments/sepolia-igp-$(date +%Y%m%d-%H%M%S).json"
mkdir -p deployments

cat > "$OUTPUT_FILE" <<EOF
{
  "storageGasOracle": "$STORAGE_GAS_ORACLE",
  "interchainGasPaymaster": "$IGP_ADDRESS",
  "warpRoute": "$WARP_ROUTE",
  "owner": "$OWNER",
  "beneficiary": "$BENEFICIARY",
  "configuration": {
    "terraDomain": $TERRA_DOMAIN,
    "terraGasPrice": "$TERRA_GAS_PRICE",
    "terraExchangeRate": "$TERRA_EXCHANGE_RATE",
    "gasOverhead": "$GAS_OVERHEAD"
  },
  "deployedAt": "$(date -Iseconds)",
  "network": "sepolia",
  "deployer": "$DEPLOYER"
}
EOF

echo -e "${GREEN}💾 Endereços salvos em: $OUTPUT_FILE${NC}"
echo ""
