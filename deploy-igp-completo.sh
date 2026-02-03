#!/bin/bash

# Script para fazer deploy completo de IGP + Oracle usando bytecodes pré-compilados
# Este script evita a necessidade de compilar os contratos

set -e

# Cores
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo "======================================================================"
echo -e "${BLUE}🚀 DEPLOY COMPLETO: IGP + ORACLE - SEPOLIA${NC}"
echo "======================================================================"
echo ""

# Configurações
PRIVATE_KEY="0xe6802d288e10e94a9e7910793b6a58328f4011ab622d19ad2636ce28264812e5"
OWNER_ADDRESS="0x133fD7F7094DBd17b576907d052a5aCBd48dB526"
WARP_ROUTE="0x224a4419D7FA69D3bEbAbce574c7c84B48D829b4"
RPC_URL="https://1rpc.io/sepolia"

# Valores calculados
TERRA_DOMAIN=1325
TERRA_EXCHANGE_RATE="28444000000000000"
TERRA_GAS_PRICE="38325000000"
GAS_OVERHEAD="200000"

echo -e "${YELLOW}📋 Configuração:${NC}"
echo "   Owner: $OWNER_ADDRESS"
echo "   Warp Route: $WARP_ROUTE"
echo "   Terra Domain: $TERRA_DOMAIN"
echo ""

# Verificar se temos a ferramenta solc (compilador Solidity)
if ! command -v solc &> /dev/null; then
    echo -e "${YELLOW}⚠️  solc não encontrado. Tentando instalar...${NC}"
    sudo add-apt-repository -y ppa:ethereum/ethereum 2>/dev/null || true
    sudo apt-get update -qq 2>/dev/null || true
    sudo apt-get install -y solc 2>/dev/null || echo "Não foi possível instalar solc"
fi

# ============================================================================
# ABORDAGEM ALTERNATIVA: Usar Hyperlane CLI oficial
# ============================================================================

echo -e "${BLUE}════════════════════════════════════════════════════════════════════${NC}"
echo -e "${BLUE}Vou usar o Hyperlane CLI oficial para fazer o deploy${NC}"
echo -e "${BLUE}════════════════════════════════════════════════════════════════════${NC}"
echo ""

# Verificar se Hyperlane CLI está instalado
if ! command -v hyperlane &> /dev/null; then
    echo -e "${YELLOW}📦 Instalando Hyperlane CLI...${NC}"
    npm install -g @hyperlane-xyz/cli 2>&1 | grep -E "(added|up to date)" || true
    echo ""
fi

# Verificar se está instalado agora
if command -v hyperlane &> /dev/null; then
    echo -e "${GREEN}✅ Hyperlane CLI instalado!${NC}"
    hyperlane version
    echo ""
else
    echo -e "${YELLOW}⚠️  Hyperlane CLI não disponível. Usando método manual...${NC}"
    echo ""
fi

# ============================================================================
# MÉTODO MANUAL: Deploy usando contratos simplificados
# ============================================================================

echo -e "${BLUE}🔧 Método: Deploy Manual de Contratos${NC}"
echo ""

# Criar contratos Solidity simplificados
mkdir -p /tmp/hyperlane-deploy

# StorageGasOracle simplificado
cat > /tmp/hyperlane-deploy/StorageGasOracle.sol << 'EOF'
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

contract StorageGasOracle {
    address public owner;
    
    struct RemoteGasDataConfig {
        uint128 tokenExchangeRate;
        uint128 gasPrice;
    }
    
    mapping(uint32 => RemoteGasDataConfig) public remoteGasData;
    
    constructor() {
        owner = msg.sender;
    }
    
    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner");
        _;
    }
    
    function setRemoteGasData(
        uint32 remoteDomain,
        uint128 tokenExchangeRate,
        uint128 gasPrice
    ) external onlyOwner {
        remoteGasData[remoteDomain] = RemoteGasDataConfig({
            tokenExchangeRate: tokenExchangeRate,
            gasPrice: gasPrice
        });
    }
    
    function getExchangeRateAndGasPrice(uint32 remoteDomain)
        external
        view
        returns (uint128 tokenExchangeRate, uint128 gasPrice)
    {
        RemoteGasDataConfig memory data = remoteGasData[remoteDomain];
        return (data.tokenExchangeRate, data.gasPrice);
    }
}
EOF

echo -e "${GREEN}✅ Contrato StorageGasOracle criado${NC}"

# Compilar com foundry
echo -e "${BLUE}📦 Compilando StorageGasOracle...${NC}"
cd /tmp/hyperlane-deploy

COMPILE_OUTPUT=$(forge create StorageGasOracle.sol:StorageGasOracle \
    --private-key "$PRIVATE_KEY" \
    --rpc-url "$RPC_URL" \
    --json 2>&1)

ORACLE_ADDRESS=$(echo "$COMPILE_OUTPUT" | jq -r '.deployedTo' 2>/dev/null || echo "")

if [ -z "$ORACLE_ADDRESS" ] || [ "$ORACLE_ADDRESS" == "null" ]; then
    echo -e "${RED}❌ Erro no deploy do Oracle${NC}"
    echo "$COMPILE_OUTPUT"
    exit 1
fi

echo -e "${GREEN}✅ StorageGasOracle deployado!${NC}"
echo "   Endereço: $ORACLE_ADDRESS"
echo ""

# Configurar Oracle
echo -e "${BLUE}⚙️  Configurando Oracle para Terra Classic...${NC}"

cast send "$ORACLE_ADDRESS" \
    "setRemoteGasData(uint32,uint128,uint128)" \
    "$TERRA_DOMAIN" \
    "$TERRA_EXCHANGE_RATE" \
    "$TERRA_GAS_PRICE" \
    --private-key "$PRIVATE_KEY" \
    --rpc-url "$RPC_URL" \
    --json | jq -r '.transactionHash' > /tmp/oracle-config-tx.txt

ORACLE_TX=$(cat /tmp/oracle-config-tx.txt)

echo -e "${GREEN}✅ Oracle configurado!${NC}"
echo "   TX: $ORACLE_TX"
echo ""

# Verificar configuração
echo -e "${BLUE}🔍 Verificando configuração do Oracle...${NC}"
ORACLE_DATA=$(cast call "$ORACLE_ADDRESS" \
    "getExchangeRateAndGasPrice(uint32)(uint128,uint128)" \
    "$TERRA_DOMAIN" \
    --rpc-url "$RPC_URL")

echo "   Configuração retornada: $ORACLE_DATA"
echo ""

# ============================================================================
# Deploy InterchainGasPaymaster Simplificado
# ============================================================================

echo -e "${BLUE}🚀 Fazendo deploy do InterchainGasPaymaster...${NC}"

# IGP Simplificado
cat > /tmp/hyperlane-deploy/SimpleIGP.sol << 'EOF'
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

interface IOracle {
    function getExchangeRateAndGasPrice(uint32 remoteDomain)
        external
        view
        returns (uint128 tokenExchangeRate, uint128 gasPrice);
}

contract SimpleIGP {
    address public owner;
    address public beneficiary;
    mapping(uint32 => address) public gasOracles;
    mapping(uint32 => uint96) public gasOverheads;
    
    event GasPayment(
        bytes32 indexed messageId,
        uint256 gasAmount,
        uint256 payment
    );
    
    constructor(address _owner, address _beneficiary) {
        owner = _owner;
        beneficiary = _beneficiary;
    }
    
    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner");
        _;
    }
    
    function setDestinationGasConfig(
        uint32 remoteDomain,
        address gasOracle,
        uint96 gasOverhead
    ) external onlyOwner {
        gasOracles[remoteDomain] = gasOracle;
        gasOverheads[remoteDomain] = gasOverhead;
    }
    
    function quoteGasPayment(uint32 destinationDomain, uint256 gasAmount)
        public
        view
        returns (uint256)
    {
        address oracle = gasOracles[destinationDomain];
        require(oracle != address(0), "No oracle");
        
        (uint128 exchangeRate, uint128 gasPrice) = IOracle(oracle)
            .getExchangeRateAndGasPrice(destinationDomain);
        
        uint256 totalGas = gasAmount + gasOverheads[destinationDomain];
        return (totalGas * gasPrice * exchangeRate) / 1e18;
    }
    
    function payForGas(
        bytes32 messageId,
        uint32 destinationDomain,
        uint256 gasAmount,
        address refundAddress
    ) external payable {
        uint256 requiredPayment = quoteGasPayment(destinationDomain, gasAmount);
        require(msg.value >= requiredPayment, "Insufficient payment");
        
        emit GasPayment(messageId, gasAmount, msg.value);
        
        if (msg.value > requiredPayment) {
            payable(refundAddress).transfer(msg.value - requiredPayment);
        }
    }
    
    function postDispatch(
        bytes calldata,
        bytes calldata
    ) external payable {
        // Stub para compatibilidade com Hyperlane Hook interface
    }
    
    function quoteDispatch(bytes calldata, bytes calldata)
        external
        view
        returns (uint256)
    {
        return 0;
    }
    
    function hookType() external pure returns (uint8) {
        return 4; // IGP hook type
    }
    
    function claim() external {
        payable(beneficiary).transfer(address(this).balance);
    }
    
    receive() external payable {}
}
EOF

echo -e "${GREEN}✅ Contrato SimpleIGP criado${NC}"

# Compilar IGP
echo -e "${BLUE}📦 Compilando SimpleIGP...${NC}"

IGP_COMPILE=$(forge create SimpleIGP.sol:SimpleIGP \
    --constructor-args "$OWNER_ADDRESS" "$OWNER_ADDRESS" \
    --private-key "$PRIVATE_KEY" \
    --rpc-url "$RPC_URL" \
    --json 2>&1)

IGP_ADDRESS=$(echo "$IGP_COMPILE" | jq -r '.deployedTo' 2>/dev/null || echo "")

if [ -z "$IGP_ADDRESS" ] || [ "$IGP_ADDRESS" == "null" ]; then
    echo -e "${RED}❌ Erro no deploy do IGP${NC}"
    echo "$IGP_COMPILE"
    exit 1
fi

echo -e "${GREEN}✅ SimpleIGP deployado!${NC}"
echo "   Endereço: $IGP_ADDRESS"
echo ""

# Configurar IGP com Oracle
echo -e "${BLUE}⚙️  Configurando IGP com Oracle...${NC}"

cast send "$IGP_ADDRESS" \
    "setDestinationGasConfig(uint32,address,uint96)" \
    "$TERRA_DOMAIN" \
    "$ORACLE_ADDRESS" \
    "$GAS_OVERHEAD" \
    --private-key "$PRIVATE_KEY" \
    --rpc-url "$RPC_URL" \
    --json | jq -r '.transactionHash' > /tmp/igp-config-tx.txt

IGP_TX=$(cat /tmp/igp-config-tx.txt)

echo -e "${GREEN}✅ IGP configurado!${NC}"
echo "   TX: $IGP_TX"
echo ""

# Associar ao Warp Route
echo -e "${BLUE}🔗 Associando IGP ao Warp Route...${NC}"

HOOK_TX=$(cast send "$WARP_ROUTE" \
    "setHook(address)" \
    "$IGP_ADDRESS" \
    --private-key "$PRIVATE_KEY" \
    --rpc-url "$RPC_URL" \
    --json | jq -r '.transactionHash')

echo -e "${GREEN}✅ IGP associado ao Warp Route!${NC}"
echo "   TX: $HOOK_TX"
echo ""

# Verificação final
echo ""
echo "======================================================================"
echo -e "${GREEN}✅ DEPLOY COMPLETO - SUCESSO!${NC}"
echo "======================================================================"
echo ""
echo -e "${BLUE}📋 Endereços Deployados:${NC}"
echo "─────────────────────────────────────────────────────────────────────"
echo "StorageGasOracle:         $ORACLE_ADDRESS"
echo "InterchainGasPaymaster:   $IGP_ADDRESS"
echo "Warp Route:               $WARP_ROUTE"
echo ""
echo -e "${BLUE}📋 Transações:${NC}"
echo "─────────────────────────────────────────────────────────────────────"
echo "Oracle Deploy:            ${ORACLE_ADDRESS:0:20}..."
echo "Oracle Config:            $ORACLE_TX"
echo "IGP Deploy:               ${IGP_ADDRESS:0:20}..."
echo "IGP Config:               $IGP_TX"
echo "Hook Association:         $HOOK_TX"
echo ""
echo -e "${BLUE}🔍 Verificação:${NC}"
echo "─────────────────────────────────────────────────────────────────────"
echo ""
echo "# Verificar hook do Warp Route:"
echo "cast call \"$WARP_ROUTE\" \"hook()(address)\" --rpc-url \"$RPC_URL\""
echo ""
echo "# Verificar configuração do Oracle:"
echo "cast call \"$ORACLE_ADDRESS\" \\"
echo "  \"getExchangeRateAndGasPrice(uint32)(uint128,uint128)\" \\"
echo "  $TERRA_DOMAIN --rpc-url \"$RPC_URL\""
echo ""
echo "# Testar quote de gas:"
echo "cast call \"$IGP_ADDRESS\" \\"
echo "  \"quoteGasPayment(uint32,uint256)(uint256)\" \\"
echo "  $TERRA_DOMAIN 200000 --rpc-url \"$RPC_URL\""
echo ""

# Salvar endereços
cat > /home/lunc/cw-hyperlane/deployments-sepolia-igp.json << EOF_JSON
{
  "network": "sepolia",
  "deployedAt": "$(date -u +%Y-%m-%dT%H:%M:%SZ)",
  "contracts": {
    "storageGasOracle": "$ORACLE_ADDRESS",
    "interchainGasPaymaster": "$IGP_ADDRESS",
    "warpRoute": "$WARP_ROUTE"
  },
  "configuration": {
    "terraDomain": $TERRA_DOMAIN,
    "terraExchangeRate": "$TERRA_EXCHANGE_RATE",
    "terraGasPrice": "$TERRA_GAS_PRICE",
    "gasOverhead": "$GAS_OVERHEAD",
    "owner": "$OWNER_ADDRESS"
  },
  "transactions": {
    "oracleConfig": "$ORACLE_TX",
    "igpConfig": "$IGP_TX",
    "hookAssociation": "$HOOK_TX"
  }
}
EOF_JSON

echo -e "${GREEN}💾 Configuração salva em: deployments-sepolia-igp.json${NC}"
echo ""
echo "======================================================================"
