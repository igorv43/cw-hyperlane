#!/bin/bash

################################################################################
#
# Deploy completo do IGP para Terra Classic - VERSÃO CORRETA
#
# Usa TOKEN_EXCHANGE_RATE_SCALE = 1e10 (escala oficial do Hyperlane V3)
#
################################################################################

set -e

# Cores
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}"
cat << 'EOF'
╔════════════════════════════════════════════════════════════════════╗
║                                                                    ║
║          DEPLOY IGP TERRA CLASSIC - HYPERLANE V3                  ║
║                                                                    ║
║       Token Exchange Rate Scale: 1e10 (NÃO 1e18!)                ║
║                                                                    ║
╚════════════════════════════════════════════════════════════════════╝
EOF
echo -e "${NC}"

# ============ Configuração ============
RPC_URL="${RPC_URL:-https://1rpc.io/sepolia}"
CHAIN_ID=11155111
WARP_ROUTE="0x224a4419D7FA69D3bEbAbce574c7c84B48D829b4"

# Valores CORRETOS calculados com escala 1e10
TERRA_DOMAIN=1325
TERRA_EXCHANGE_RATE="142244393"      # Escala 1e10
TERRA_GAS_PRICE="38325000000"        # 38.325 Gwei
GAS_OVERHEAD="200000"

# Chave privada (usuário forneceu)
PRIVATE_KEY="${SEPOLIA_PRIVATE_KEY:-0xe6802d288e10e94a9e7910793b6a58328f4011ab622d19ad2636ce28264812e5}"

# Derivar endereço do owner
OWNER_ADDRESS=$(cast wallet address --private-key "$PRIVATE_KEY")

echo -e "${GREEN}📊 CONFIGURAÇÃO:${NC}"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "   RPC: $RPC_URL"
echo "   Chain ID: $CHAIN_ID"
echo "   Owner: $OWNER_ADDRESS"
echo "   Warp Route: $WARP_ROUTE"
echo ""
echo "   Terra Classic Domain: $TERRA_DOMAIN"
echo "   Exchange Rate: $TERRA_EXCHANGE_RATE (escala 1e10)"
echo "   Gas Price: $TERRA_GAS_PRICE WEI (38.325 Gwei)"
echo "   Gas Overhead: $GAS_OVERHEAD"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

# Verificar saldo
echo -e "${YELLOW}💰 Verificando saldo...${NC}"
BALANCE=$(cast balance "$OWNER_ADDRESS" --rpc-url "$RPC_URL")
BALANCE_ETH=$(cast --to-unit "$BALANCE" ether)
echo "   Saldo: $BALANCE_ETH ETH"
echo ""

if (( $(echo "$BALANCE_ETH < 0.01" | bc -l) )); then
    echo -e "${RED}❌ ERRO: Saldo insuficiente. Necessário pelo menos 0.01 ETH${NC}"
    exit 1
fi

# ============ PASSO 1: Deploy StorageGasOracle ============
echo -e "${YELLOW}📦 PASSO 1/4: Deploy StorageGasOracle...${NC}"

ORACLE_ADDRESS=$(forge create \
    --rpc-url "$RPC_URL" \
    --private-key "$PRIVATE_KEY" \
    --constructor-args "$OWNER_ADDRESS" \
    ~/hyperlane-monorepo/solidity/contracts/hooks/igp/StorageGasOracle.sol:StorageGasOracle \
    --json 2>/dev/null | jq -r '.deployedTo')

if [ -z "$ORACLE_ADDRESS" ] || [ "$ORACLE_ADDRESS" = "null" ]; then
    echo -e "${RED}❌ ERRO: Falha ao deployar StorageGasOracle${NC}"
    exit 1
fi

echo -e "${GREEN}✅ StorageGasOracle deployado: $ORACLE_ADDRESS${NC}"
sleep 3
echo ""

# ============ PASSO 2: Configurar Oracle ============
echo -e "${YELLOW}⚙️  PASSO 2/4: Configurar StorageGasOracle para Terra Classic...${NC}"

# Criar struct para setRemoteGasDataConfigs
# Formato: [(uint32 remoteDomain, uint128 tokenExchangeRate, uint128 gasPrice)]
CALLDATA=$(cast calldata "setRemoteGasDataConfigs((uint32,uint128,uint128)[])" \
    "[($TERRA_DOMAIN,$TERRA_EXCHANGE_RATE,$TERRA_GAS_PRICE)]")

TX_HASH=$(cast send "$ORACLE_ADDRESS" \
    --rpc-url "$RPC_URL" \
    --private-key "$PRIVATE_KEY" \
    "$CALLDATA" \
    --json 2>/dev/null | jq -r '.transactionHash')

if [ -z "$TX_HASH" ] || [ "$TX_HASH" = "null" ]; then
    echo -e "${RED}❌ ERRO: Falha ao configurar Oracle${NC}"
    exit 1
fi

echo "   TX Hash: $TX_HASH"
echo "   Aguardando confirmação..."
cast receipt "$TX_HASH" --rpc-url "$RPC_URL" > /dev/null 2>&1
echo -e "${GREEN}✅ Oracle configurado${NC}"
sleep 2
echo ""

# ============ PASSO 3: Deploy TerraClassicIGP ============
echo -e "${YELLOW}📦 PASSO 3/4: Deploy TerraClassicIGP...${NC}"

IGP_ADDRESS=$(forge create \
    --rpc-url "$RPC_URL" \
    --private-key "$PRIVATE_KEY" \
    --constructor-args "$ORACLE_ADDRESS" "$GAS_OVERHEAD" "$OWNER_ADDRESS" \
    /home/lunc/cw-hyperlane/TerraClassicIGP.sol:TerraClassicIGP \
    --json 2>/dev/null | jq -r '.deployedTo')

if [ -z "$IGP_ADDRESS" ] || [ "$IGP_ADDRESS" = "null" ]; then
    echo -e "${RED}❌ ERRO: Falha ao deployar TerraClassicIGP${NC}"
    exit 1
fi

echo -e "${GREEN}✅ TerraClassicIGP deployado: $IGP_ADDRESS${NC}"
sleep 3
echo ""

# ============ PASSO 4: Associar IGP ao Warp Route ============
echo -e "${YELLOW}🔗 PASSO 4/4: Associar IGP ao Warp Route...${NC}"

TX_HASH=$(cast send "$WARP_ROUTE" \
    "setHook(address)" \
    "$IGP_ADDRESS" \
    --rpc-url "$RPC_URL" \
    --private-key "$PRIVATE_KEY" \
    --json 2>/dev/null | jq -r '.transactionHash')

if [ -z "$TX_HASH" ] || [ "$TX_HASH" = "null" ]; then
    echo -e "${RED}❌ ERRO: Falha ao associar IGP ao Warp Route${NC}"
    exit 1
fi

echo "   TX Hash: $TX_HASH"
echo "   Aguardando confirmação..."
cast receipt "$TX_HASH" --rpc-url "$RPC_URL" > /dev/null 2>&1
echo -e "${GREEN}✅ IGP associado ao Warp Route${NC}"
echo ""

# ============ Verificação ============
echo -e "${BLUE}🔍 VERIFICAÇÃO:${NC}"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

# Verificar hook do Warp Route
CURRENT_HOOK=$(cast call "$WARP_ROUTE" "hook()(address)" --rpc-url "$RPC_URL")
echo "   Warp Route Hook: $CURRENT_HOOK"

if [ "$CURRENT_HOOK" = "$IGP_ADDRESS" ]; then
    echo -e "   ${GREEN}✅ Hook configurado corretamente${NC}"
else
    echo -e "   ${RED}❌ Hook NÃO corresponde ao IGP deployado${NC}"
fi

# Verificar configuração do Oracle
ORACLE_DATA=$(cast call "$ORACLE_ADDRESS" \
    "remoteGasData(uint32)((uint128,uint128))" \
    "$TERRA_DOMAIN" \
    --rpc-url "$RPC_URL")

echo "   Oracle Data para Terra Classic:"
echo "   $ORACLE_DATA"

# Verificar IGP
IGP_ORACLE=$(cast call "$IGP_ADDRESS" "gasOracle()(address)" --rpc-url "$RPC_URL")
IGP_OVERHEAD=$(cast call "$IGP_ADDRESS" "gasOverhead()(uint96)" --rpc-url "$RPC_URL")
echo "   IGP Oracle: $IGP_ORACLE"
echo "   IGP Gas Overhead: $IGP_OVERHEAD"

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

# ============ Resumo ============
echo -e "${GREEN}"
cat << EOF
╔════════════════════════════════════════════════════════════════════╗
║                                                                    ║
║                    ✅ DEPLOY CONCLUÍDO COM SUCESSO!               ║
║                                                                    ║
╚════════════════════════════════════════════════════════════════════╝

📋 ENDEREÇOS DEPLOYADOS:
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
   StorageGasOracle: $ORACLE_ADDRESS
   TerraClassicIGP:  $IGP_ADDRESS
   Warp Route:       $WARP_ROUTE
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

🎯 PRÓXIMO PASSO:
   Teste a transferência de Sepolia para Terra Classic!
   O erro "destination not supported" deve estar corrigido.

💡 ATENÇÃO:
   - Exchange Rate usa escala 1e10 (oficial do Hyperlane V3)
   - Custo estimado: ~\$0.50 USD por transferência (400k gas)
   - Gas Price: 38.325 Gwei

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
EOF
echo -e "${NC}"

# Salvar endereços em arquivo
cat > /home/lunc/cw-hyperlane/deployed-addresses.txt << EOF
StorageGasOracle=$ORACLE_ADDRESS
TerraClassicIGP=$IGP_ADDRESS
WarpRoute=$WARP_ROUTE
TerraDomain=$TERRA_DOMAIN
ExchangeRate=$TERRA_EXCHANGE_RATE
GasPrice=$TERRA_GAS_PRICE
GasOverhead=$GAS_OVERHEAD
DeployedAt=$(date -u +"%Y-%m-%d %H:%M:%S UTC")
EOF

echo -e "${GREEN}💾 Endereços salvos em: deployed-addresses.txt${NC}"
