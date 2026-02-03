#!/bin/bash

# ============================================================================
# Deploy Direto do IGP usando Bytecode Pré-compilado
# ============================================================================

set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}╔════════════════════════════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║                                                                    ║${NC}"
echo -e "${BLUE}║         🚀 DEPLOY DIRETO DO IGP (SEM REMIX)                       ║${NC}"
echo -e "${BLUE}║                                                                    ║${NC}"
echo -e "${BLUE}╚════════════════════════════════════════════════════════════════════╝${NC}"
echo ""

# Configuração
RPC_URL="https://1rpc.io/sepolia"
PRIVATE_KEY="0xe6802d288e10e94a9e7910793b6a58328f4011ab622d19ad2636ce28264812e5"
ORACLE="0x7113Df4d1D8B230e6339011d10277a6E5AC4eC9c"
OVERHEAD="200000"
WARP_ROUTE="0x224a4419D7FA69D3bEbAbce574c7c84B48D829b4"
OWNER=$(cast wallet address --private-key "$PRIVATE_KEY" 2>/dev/null)

if [ -z "$OWNER" ]; then
    echo -e "${RED}❌ Erro: cast não está disponível${NC}"
    echo "Instale Foundry: curl -L https://foundry.paradigm.xyz | bash"
    exit 1
fi

echo -e "${YELLOW}📊 Configuração:${NC}"
echo "   Owner/Beneficiary: $OWNER"
echo "   Oracle: $ORACLE"
echo "   Gas Overhead: $OVERHEAD"
echo "   Warp Route: $WARP_ROUTE"
echo ""

# Bytecode do contrato compilado (será atualizado com o bytecode real)
echo -e "${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${YELLOW}ATENÇÃO: Deploy via bytecode${NC}"
echo -e "${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""
echo "Este método requer o bytecode compilado do contrato."
echo "Como não conseguimos compilar automaticamente no sistema atual,"
echo "você tem 2 opções:"
echo ""
echo "OPÇÃO 1 (Recomendada): Deploy via Remix IDE"
echo "   $ cat DEPLOY-AGORA.md"
echo "   https://remix.ethereum.org"
echo ""
echo "OPÇÃO 2: Fornecer bytecode manualmente"
echo "   1. Compile o contrato localmente"
echo "   2. Forneça o bytecode"
echo "   3. Este script fará o deploy"
echo ""

read -p "Você tem o bytecode compilado? (s/n): " HAS_BYTECODE

if [ "$HAS_BYTECODE" != "s" ] && [ "$HAS_BYTECODE" != "S" ]; then
    echo ""
    echo -e "${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${GREEN}✅ Use o Remix IDE para fazer o deploy:${NC}"
    echo ""
    echo "   1. Leia o guia:"
    echo "      $ cat DEPLOY-AGORA.md"
    echo ""
    echo "   2. Abra: https://remix.ethereum.org"
    echo ""
    echo "   3. Deploy o contrato TerraClassicIGPStandalone.sol"
    echo ""
    echo "   4. Depois execute:"
    echo "      $ export IGP_ADDRESS=\"<endereço_copiado>\""
    echo "      $ ./deploy-igp-final.sh"
    echo ""
    echo -e "${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    exit 0
fi

# Se usuário tem bytecode, solicitar
echo ""
read -p "Cole o bytecode (começando com 0x): " BYTECODE

if [ -z "$BYTECODE" ]; then
    echo -e "${RED}❌ Bytecode não fornecido${NC}"
    exit 1
fi

# Preparar constructor args
echo ""
echo -e "${YELLOW}🔧 Preparando constructor args...${NC}"

# Encode constructor arguments
# constructor(address _gasOracle, uint96 _gasOverhead, address _beneficiary)
CONSTRUCTOR_ARGS=$(cast abi-encode "constructor(address,uint96,address)" "$ORACLE" "$OVERHEAD" "$OWNER")

echo "   Constructor Args: $CONSTRUCTOR_ARGS"
echo ""

# Combinar bytecode + constructor args
DEPLOY_DATA="${BYTECODE}${CONSTRUCTOR_ARGS:2}"

echo -e "${YELLOW}🚀 Fazendo deploy...${NC}"
echo ""

# Deploy
TX_HASH=$(cast send --create "$DEPLOY_DATA" \
    --rpc-url "$RPC_URL" \
    --private-key "$PRIVATE_KEY" \
    --json 2>/dev/null | jq -r '.transactionHash // empty')

if [ -z "$TX_HASH" ]; then
    echo -e "${RED}❌ Erro ao fazer deploy${NC}"
    exit 1
fi

echo -e "${GREEN}✅ Transação enviada: $TX_HASH${NC}"
echo ""
echo "Aguardando confirmação..."
sleep 30

# Obter endereço do contrato
IGP_ADDRESS=$(cast receipt "$TX_HASH" --rpc-url "$RPC_URL" --json 2>/dev/null | jq -r '.contractAddress // empty')

if [ -z "$IGP_ADDRESS" ]; then
    echo -e "${RED}❌ Não foi possível obter o endereço do contrato${NC}"
    exit 1
fi

echo ""
echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${GREEN}✅ Deploy bem-sucedido!${NC}"
echo -e "${GREEN}   IGP Address: $IGP_ADDRESS${NC}"
echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""

# Salvar endereço
export IGP_ADDRESS
echo "IGP_ADDRESS=$IGP_ADDRESS" > deployed-igp-address.env

# Verificar hookType
echo -e "${YELLOW}🔍 Verificando hookType...${NC}"
HOOK_TYPE=$(cast call "$IGP_ADDRESS" "hookType()(uint8)" --rpc-url "$RPC_URL" 2>/dev/null)
HOOK_TYPE_DEC=$((16#${HOOK_TYPE#0x}))

echo "   Hook Type: $HOOK_TYPE_DEC"

if [ "$HOOK_TYPE_DEC" = "4" ]; then
    echo -e "${GREEN}   ✅ Hook Type CORRETO (4)${NC}"
else
    echo -e "${RED}   ❌ Hook Type ERRADO (esperado: 4, obtido: $HOOK_TYPE_DEC)${NC}"
    exit 1
fi

echo ""

# Associar ao Warp Route
echo -e "${YELLOW}🔗 Associando IGP ao Warp Route...${NC}"
echo ""

TX_HASH=$(cast send "$WARP_ROUTE" \
    "setHook(address)" "$IGP_ADDRESS" \
    --rpc-url "$RPC_URL" \
    --private-key "$PRIVATE_KEY" \
    --json 2>/dev/null | jq -r '.transactionHash // empty')

if [ -z "$TX_HASH" ]; then
    echo -e "${RED}❌ Erro ao associar IGP${NC}"
    exit 1
fi

echo -e "${GREEN}✅ Transação enviada: $TX_HASH${NC}"
echo ""
echo "Aguardando confirmação..."
sleep 30

# Verificar associação
CURRENT_HOOK=$(cast call "$WARP_ROUTE" "hook()(address)" --rpc-url "$RPC_URL" 2>/dev/null)
HOOK_ADDR="0x${CURRENT_HOOK:26:40}"

if [ "${HOOK_ADDR,,}" = "${IGP_ADDRESS,,}" ]; then
    echo -e "${GREEN}✅ IGP associado corretamente!${NC}"
else
    echo -e "${YELLOW}⚠️  Verificação: Hook atual: $HOOK_ADDR${NC}"
fi

echo ""

# Teste final
echo -e "${YELLOW}🧪 Testando quoteTransferRemote...${NC}"
echo ""

RECIPIENT="0x0000000000000000000000000000000000000000000000000000000000000001"
AMOUNT="1000000000000000000"

RESULT=$(cast call "$WARP_ROUTE" \
    "quoteTransferRemote(uint32,bytes32,uint256)(uint256)" \
    "1325" "$RECIPIENT" "$AMOUNT" \
    --rpc-url "$RPC_URL" 2>&1)

if echo "$RESULT" | grep -q "destination not supported"; then
    echo -e "${RED}❌ Erro ainda persiste: destination not supported${NC}"
    exit 1
elif echo "$RESULT" | grep -q "Error"; then
    echo -e "${RED}❌ Erro: $RESULT${NC}"
    exit 1
else
    QUOTE_DEC=$((16#${RESULT#0x}))
    QUOTE_ETH=$(cast --to-unit "$RESULT" ether)
    echo -e "${GREEN}✅✅✅ SUCESSO!${NC}"
    echo ""
    echo "   Custo estimado: $QUOTE_ETH ETH"
    echo ""
    echo -e "${GREEN}🎉 O erro foi CORRIGIDO!${NC}"
fi

echo ""
echo -e "${BLUE}╔════════════════════════════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║                                                                    ║${NC}"
echo -e "${BLUE}║                    ✅ DEPLOY COMPLETO!                            ║${NC}"
echo -e "${BLUE}║                                                                    ║${NC}"
echo -e "${BLUE}╚════════════════════════════════════════════════════════════════════╝${NC}"
echo ""
echo "📋 Resumo:"
echo "   IGP Address: $IGP_ADDRESS"
echo "   Hook Type: 4 ✅"
echo "   Warp Route: $WARP_ROUTE"
echo "   Status: Funcionando ✅"
echo ""
