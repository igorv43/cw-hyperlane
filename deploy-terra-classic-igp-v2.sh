#!/bin/bash

################################################################################
#
# Deploy do TerraClassicIGP usando o StorageGasOracle existente
# com VALORES CORRETOS (escala 1e10)
#
################################################################################

set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}"
cat << 'EOF'
╔════════════════════════════════════════════════════════════════════╗
║                                                                    ║
║     DEPLOY TERRA CLASSIC IGP - Usando Oracle Existente           ║
║                                                                    ║
║        TOKEN_EXCHANGE_RATE_SCALE = 1e10 ✅                       ║
║                                                                    ║
╚════════════════════════════════════════════════════════════════════╝
EOF
echo -e "${NC}"

# Configuração
RPC_URL="${RPC_URL:-https://1rpc.io/sepolia}"
WARP_ROUTE="0x224a4419D7FA69D3bEbAbce574c7c84B48D829b4"
ORACLE_ADDRESS="0x7113Df4d1D8B230e6339011d10277a6E5AC4eC9c"  # Oracle existente

# Valores CORRETOS (escala 1e10)
TERRA_DOMAIN=1325
TERRA_EXCHANGE_RATE="142244393"      # Escala 1e10 ✅
TERRA_GAS_PRICE="38325000000"        # 38.325 Gwei
GAS_OVERHEAD="200000"

PRIVATE_KEY="${SEPOLIA_PRIVATE_KEY:-0xe6802d288e10e94a9e7910793b6a58328f4011ab622d19ad2636ce28264812e5}"
OWNER_ADDRESS=$(cast wallet address --private-key "$PRIVATE_KEY")

echo -e "${GREEN}📊 CONFIGURAÇÃO:${NC}"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "   Owner: $OWNER_ADDRESS"
echo "   Warp Route: $WARP_ROUTE"
echo "   Oracle (existente): $ORACLE_ADDRESS"
echo ""
echo "   Exchange Rate: $TERRA_EXCHANGE_RATE (escala 1e10 ✅)"
echo "   Gas Price: $TERRA_GAS_PRICE WEI"
echo "   Gas Overhead: $GAS_OVERHEAD"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

# ============ PASSO 1: Reconfigurar Oracle ============
echo -e "${YELLOW}⚙️  PASSO 1/3: Reconfigurar Oracle com valores corretos (escala 1e10)...${NC}"

CALLDATA=$(cast calldata "setRemoteGasDataConfigs((uint32,uint128,uint128)[])" \
    "[($TERRA_DOMAIN,$TERRA_EXCHANGE_RATE,$TERRA_GAS_PRICE)]")

echo "   Enviando transação..."
TX_HASH=$(cast send "$ORACLE_ADDRESS" \
    --rpc-url "$RPC_URL" \
    --private-key "$PRIVATE_KEY" \
    "$CALLDATA" \
    --json 2>&1 | jq -r '.transactionHash // empty')

if [ -z "$TX_HASH" ]; then
    echo -e "${YELLOW}⚠️  Não foi possível reconfigurar o Oracle (pode não ter permissão)${NC}"
    echo "   Continuando com a configuração atual..."
else
    echo "   TX Hash: $TX_HASH"
    cast receipt "$TX_HASH" --rpc-url "$RPC_URL" > /dev/null 2>&1
    echo -e "${GREEN}✅ Oracle reconfigurado${NC}"
fi
sleep 2
echo ""

# ============ PASSO 2: Deploy TerraClassicIGP via cast (bytecode) ============
echo -e "${YELLOW}📦 PASSO 2/3: Deploy TerraClassicIGP...${NC}"
echo "   (Usando Remix IDE manual ou cast send --create)"
echo ""

# Compilar o contrato localmente na pasta atual (sem dependências externas)
cd /home/lunc/cw-hyperlane

echo "   Compilando TerraClassicIGP.sol..."
COMPILE_OUTPUT=$(solc --bin --abi \
    --optimize --optimize-runs 200 \
    TerraClassicIGP.sol 2>&1)

if echo "$COMPILE_OUTPUT" | grep -q "Error"; then
    echo -e "${RED}❌ Erro na compilação. Precisa usar Remix IDE.${NC}"
    echo ""
    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${YELLOW}📋 INSTRUÇÕES PARA DEPLOY VIA REMIX IDE:${NC}"
    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo ""
    echo "1. Abra https://remix.ethereum.org"
    echo "2. Crie arquivo 'TerraClassicIGP.sol' e cole o conteúdo de:"
    echo "   /home/lunc/cw-hyperlane/TerraClassicIGP.sol"
    echo ""
    echo "3. Compile com Solidity 0.8.13+"
    echo ""
    echo "4. Deploy com os seguintes parâmetros:"
    echo "   _gasOracle: $ORACLE_ADDRESS"
    echo "   _gasOverhead: $GAS_OVERHEAD"
    echo "   _beneficiary: $OWNER_ADDRESS"
    echo ""
    echo "5. Após deploy, copie o endereço e execute:"
    echo "   export IGP_ADDRESS=\"<endereço_deployado>\""
    echo "   /home/lunc/cw-hyperlane/associar-igp-ao-warp.sh"
    echo ""
    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    exit 0
fi

echo -e "${GREEN}✅ Compilação OK${NC}"
echo "   Deploy manual via Remix recomendado."
echo ""

echo -e "${YELLOW}📝 Valores para o constructor:${NC}"
echo "   _gasOracle: $ORACLE_ADDRESS"
echo "   _gasOverhead: $GAS_OVERHEAD"
echo "   _beneficiary: $OWNER_ADDRESS"
echo ""
