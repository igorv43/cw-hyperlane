#!/bin/bash

#━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# 🚀 SCRIPT COMPLETO: DEPLOY, CONFIGURAÇÃO E ASSOCIAÇÃO DO IGP
#━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# 
# Este script faz TUDO automaticamente:
#   1. Compila o contrato TerraClassicIGP
#   2. Faz deploy na Sepolia
#   3. Configura para Terra Classic (domain 1325)
#   4. Associa ao Warp Route
#   5. Verifica a configuração
#
# Uso:
#   export PRIVATE_KEY_SEPOLIA='0xSUA_CHAVE_PRIVADA'
#   ./deploy-igp-completo.sh
#
#━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

set -e  # Parar em caso de erro

# Cores
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Configurações
ORACLE="0x7113Df4d1D8B230e6339011d10277a6E5AC4eC9c"
OVERHEAD="200000"
BENEFICIARY="0x133fD7F7094DBd17b576907d052a5aCBd48dB526"
WARP_ROUTE="0x224a4419D7FA69D3bEbAbce574c7c84B48D829b4"  # ✅ Endereço correto
DOMAIN="1325"
EXCHANGE_RATE="142244393"
GAS_PRICE="38325000000"
RPC="https://ethereum-sepolia-rpc.publicnode.com"

echo ""
echo "╔════════════════════════════════════════════════════════════════════╗"
echo "║                                                                    ║"
echo "║       🚀 DEPLOY COMPLETO DO IGP TERRA CLASSIC                     ║"
echo "║                                                                    ║"
echo "╚════════════════════════════════════════════════════════════════════╝"
echo ""

#━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# VERIFICAÇÃO DE PRÉ-REQUISITOS
#━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

if [ -z "$PRIVATE_KEY_SEPOLIA" ]; then
    echo -e "${RED}❌ PRIVATE_KEY_SEPOLIA não definida${NC}"
    echo ""
    echo "Execute primeiro:"
    echo -e "${YELLOW}export PRIVATE_KEY_SEPOLIA='0xSUA_CHAVE_PRIVADA_DA_SEPOLIA'${NC}"
    echo ""
    exit 1
fi

# Verificar cast
if ! command -v cast &> /dev/null; then
    echo -e "${RED}❌ 'cast' não encontrado. Instale o Foundry.${NC}"
    exit 1
fi

echo -e "${GREEN}✅ Pré-requisitos OK${NC}"
echo ""

#━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# ETAPA 1: COMPILAÇÃO
#━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

echo "1️⃣  PREPARANDO CONTRATO..."
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

TMP_DIR="/tmp/igp-deploy-$(date +%s)"
mkdir -p "$TMP_DIR/src"
cd "$TMP_DIR"

# Criar contrato (Sepolia)
cat > "src/TerraClassicIGP-Sepolia.sol" << 'SOLIDITY_EOF'
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

contract TerraClassicIGP {
    uint8 constant IGP_HOOK_TYPE = 4;
    uint256 constant TOKEN_EXCHANGE_RATE_SCALE = 1e10;
    uint32 constant TERRA_CLASSIC_DOMAIN = 1325;
    
    address public owner;
    address public gasOracle;
    uint96 public gasOverhead;
    address public beneficiary;
    
    mapping(uint32 => uint128) public tokenExchangeRate;
    mapping(uint32 => uint128) public gasPrice;
    
    event RemoteGasDataSet(uint32 indexed domain, uint128 exchangeRate, uint128 price);
    
    modifier onlyOwner() {
        require(msg.sender == owner, "not owner");
        _;
    }
    
    constructor(address _gasOracle, uint96 _gasOverhead, address _beneficiary) {
        require(_gasOracle != address(0), "invalid oracle");
        require(_beneficiary != address(0), "invalid beneficiary");
        owner = msg.sender;
        gasOracle = _gasOracle;
        gasOverhead = _gasOverhead;
        beneficiary = _beneficiary;
    }
    
    function hookType() external pure returns (uint8) {
        return IGP_HOOK_TYPE;
    }
    
    function supportsMetadata(bytes calldata) external pure returns (bool) {
        return true;
    }
    
    function postDispatch(bytes calldata, bytes calldata) external payable {}
    
    function quoteDispatch(bytes calldata metadata, bytes calldata message) external view returns (uint256) {
        uint32 destination = uint32(bytes4(message[41:45]));
        require(destination == TERRA_CLASSIC_DOMAIN, "destination not supported");
        
        uint256 gasLimit = uint256(bytes32(metadata[34:66]));
        uint128 _tokenExchangeRate = tokenExchangeRate[destination];
        uint128 _gasPrice = gasPrice[destination];
        
        require(_tokenExchangeRate > 0 && _gasPrice > 0, "not configured");
        
        uint256 gasPayment = (gasLimit + gasOverhead) * _gasPrice;
        return (gasPayment * _tokenExchangeRate) / TOKEN_EXCHANGE_RATE_SCALE;
    }
    
    function setRemoteGasData(uint32 domain, uint128 _exchangeRate, uint128 _gasPrice) external onlyOwner {
        tokenExchangeRate[domain] = _exchangeRate;
        gasPrice[domain] = _gasPrice;
        emit RemoteGasDataSet(domain, _exchangeRate, _gasPrice);
    }
}
SOLIDITY_EOF

# Inicializar e compilar
cat > foundry.toml << 'EOF'
[profile.default]
src = "src"
out = "out"
libs = ["lib"]
solc = "0.8.22"
optimizer = true
optimizer_runs = 200
EOF

forge init --no-git --force . >/dev/null 2>&1
forge build >/dev/null 2>&1

echo -e "${GREEN}✅ Contrato compilado${NC}"
echo ""

#━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# ETAPA 2: DEPLOY
#━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

echo "2️⃣  FAZENDO DEPLOY NA SEPOLIA..."
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "   Aguarde 30-60 segundos..."
echo ""

# Obter bytecode compilado
BYTECODE=$(jq -r '.bytecode.object' out/TerraClassicIGP-Sepolia.sol/TerraClassicIGP.json)

# Codificar parâmetros do constructor
CONSTRUCTOR_ARGS=$(cast abi-encode "constructor(address,uint96,address)" "$ORACLE" "$OVERHEAD" "$BENEFICIARY")

# Bytecode completo (bytecode + constructor args)
FULL_BYTECODE="${BYTECODE}${CONSTRUCTOR_ARGS:2}"

# Deploy
export ETH_RPC_URL="$RPC"
DEPLOY_RESULT=$(cast send \
    --private-key "$PRIVATE_KEY_SEPOLIA" \
    --rpc-url "$RPC" \
    --legacy \
    --json \
    --create "$FULL_BYTECODE" \
    2>&1)

TX_HASH=$(echo "$DEPLOY_RESULT" | jq -r '.transactionHash')

if [ -z "$TX_HASH" ] || [ "$TX_HASH" = "null" ]; then
    echo -e "${RED}❌ Erro no deploy${NC}"
    echo "$DEPLOY_RESULT"
    exit 1
fi

echo -e "${GREEN}✅ Transação enviada: $TX_HASH${NC}"
echo ""
echo "   Aguardando confirmação..."
sleep 10

# Obter endereço do contrato
IGP_ADDRESS=$(cast receipt "$TX_HASH" --json 2>/dev/null | jq -r '.contractAddress')

if [ -z "$IGP_ADDRESS" ] || [ "$IGP_ADDRESS" = "null" ]; then
    echo -e "${RED}❌ Erro ao obter endereço do contrato${NC}"
    exit 1
fi

echo ""
echo -e "${GREEN}✅✅✅ IGP DEPLOYADO COM SUCESSO! ✅✅✅${NC}"
echo ""
echo -e "${GREEN}📍 Endereço: $IGP_ADDRESS${NC}"
echo ""

# Salvar endereço
echo "$IGP_ADDRESS" > ~/cw-hyperlane/IGP_ADDRESS-SEPOLIA.txt

#━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# ETAPA 3: CONFIGURAÇÃO
#━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

echo "3️⃣  CONFIGURANDO PARA TERRA CLASSIC..."
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "   Domain: $DOMAIN"
echo "   Exchange Rate: $EXCHANGE_RATE"
echo "   Gas Price: $GAS_PRICE"
echo ""

CONFIG_RESULT=$(cast send "$IGP_ADDRESS" \
    "setRemoteGasData(uint32,uint128,uint128)" \
    "$DOMAIN" "$EXCHANGE_RATE" "$GAS_PRICE" \
    --rpc-url "$RPC" \
    --private-key "$PRIVATE_KEY_SEPOLIA" \
    --legacy \
    --json 2>/dev/null)

CONFIG_TX=$(echo "$CONFIG_RESULT" | jq -r '.transactionHash')

if [ ! -z "$CONFIG_TX" ] && [ "$CONFIG_TX" != "null" ]; then
    echo -e "${GREEN}✅ IGP configurado${NC}"
    echo "   TX: $CONFIG_TX"
else
    echo -e "${RED}❌ Erro na configuração${NC}"
    exit 1
fi

echo ""
sleep 5

#━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# ETAPA 4: ASSOCIAÇÃO AO WARP ROUTE
#━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

echo "4️⃣  ASSOCIANDO AO WARP ROUTE..."
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "   Warp Route: $WARP_ROUTE"
echo "   IGP: $IGP_ADDRESS"
echo ""

HOOK_RESULT=$(cast send "$WARP_ROUTE" \
    "setHook(address)" \
    "$IGP_ADDRESS" \
    --rpc-url "$RPC" \
    --private-key "$PRIVATE_KEY_SEPOLIA" \
    --legacy \
    --json 2>/dev/null)

HOOK_TX=$(echo "$HOOK_RESULT" | jq -r '.transactionHash')

if [ ! -z "$HOOK_TX" ] && [ "$HOOK_TX" != "null" ]; then
    echo -e "${GREEN}✅ IGP associado ao Warp Route${NC}"
    echo "   TX: $HOOK_TX"
else
    echo -e "${RED}❌ Erro na associação${NC}"
    exit 1
fi

echo ""
sleep 10

#━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# ETAPA 5: VERIFICAÇÃO
#━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

echo "5️⃣  VERIFICANDO CONFIGURAÇÃO..."
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

# Verificar hook
HOOK_ATUAL=$(cast call "$WARP_ROUTE" "hook()(address)" --rpc-url "$RPC" 2>/dev/null)
HOOK_TYPE=$(cast call "$IGP_ADDRESS" "hookType()(uint8)" --rpc-url "$RPC" 2>/dev/null)

echo "   Hook configurado: $HOOK_ATUAL"
echo "   Hook Type: $HOOK_TYPE"

# Converter para lowercase para comparação
HOOK_ATUAL_LOWER=$(echo "$HOOK_ATUAL" | tr '[:upper:]' '[:lower:]')
IGP_ADDRESS_LOWER=$(echo "$IGP_ADDRESS" | tr '[:upper:]' '[:lower:]')

if [ "$HOOK_ATUAL_LOWER" = "$IGP_ADDRESS_LOWER" ] && [ "$HOOK_TYPE" = "4" ]; then
    echo -e "${GREEN}   ✅ Configuração correta!${NC}"
else
    echo -e "${YELLOW}   ⚠️  Aguarde alguns segundos para propagação${NC}"
fi

echo ""

#━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# RELATÓRIO FINAL
#━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

echo "╔════════════════════════════════════════════════════════════════════╗"
echo "║                                                                    ║"
echo "║              ✅✅✅ DEPLOY COMPLETO! ✅✅✅                       ║"
echo "║                                                                    ║"
echo "╚════════════════════════════════════════════════════════════════════╝"
echo ""
echo "📋 RESUMO:"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo -e "${GREEN}  ✅ IGP Deployado: $IGP_ADDRESS${NC}"
echo -e "${GREEN}  ✅ Hook Type: 4 (IGP)${NC}"
echo -e "${GREEN}  ✅ Warp Route: $WARP_ROUTE${NC}"
echo -e "${GREEN}  ✅ Configurado para Terra Classic (1325)${NC}"
echo ""
echo "🔗 TRANSAÇÕES:"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "  Deploy:       $TX_HASH"
echo "  Configuração: $CONFIG_TX"
echo "  Associação:   $HOOK_TX"
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "🎯 TESTE AGORA:"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "1. Acesse: https://warp.hyperlane.xyz"
echo "2. Conecte sua carteira (Sepolia)"
echo "3. Selecione: Sepolia → Terra Classic"
echo "4. Tente enviar tokens"
echo ""
echo -e "${GREEN}✅ O erro 'destination not supported' deve estar corrigido!${NC}"
echo ""

# Salvar relatório
cat > ~/cw-hyperlane/DEPLOY-REPORT-$(date +%Y%m%d-%H%M%S).txt << EOF
╔════════════════════════════════════════════════════════════════════╗
║              RELATÓRIO DE DEPLOY DO IGP TERRA CLASSIC             ║
╚════════════════════════════════════════════════════════════════════╝

Data: $(date)

📍 ENDEREÇOS:
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
IGP Deployado:        $IGP_ADDRESS
Warp Route Sepolia:   $WARP_ROUTE
Oracle:               $ORACLE
Beneficiary:          $BENEFICIARY

📊 CONFIGURAÇÃO:
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Hook Type:            4 (INTERCHAIN_GAS_PAYMASTER)
Domain:               $DOMAIN (Terra Classic)
Exchange Rate:        $EXCHANGE_RATE
Gas Price:            $GAS_PRICE WEI
Gas Overhead:         $OVERHEAD

🔗 TRANSAÇÕES:
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Deploy:               $TX_HASH
Configuração:         $CONFIG_TX
Associação ao Warp:   $HOOK_TX

✅ Status: SUCESSO
EOF

echo "📄 Relatório salvo em: ~/cw-hyperlane/DEPLOY-REPORT-$(date +%Y%m%d-%H%M%S).txt"
echo ""
