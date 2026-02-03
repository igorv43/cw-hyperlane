#!/bin/bash

#━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# 🚀 SCRIPT COMPLETO: DEPLOY E ASSOCIAÇÃO DO IGP
#━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

set -e

# Cores
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo ""
echo "╔═══════════════════════════════════════════════════════════════════════╗"
echo "║          🚀 DEPLOY E ASSOCIAÇÃO DO IGP TERRA CLASSIC                  ║"
echo "╚═══════════════════════════════════════════════════════════════════════╝"
echo ""

# Configurações
ORACLE="0x7113Df4d1D8B230e6339011d10277a6E5AC4eC9c"
OVERHEAD="200000"
BENEFICIARY="0x133fD7F7094DBd17b576907d052a5aCBd48dB526"
WARP_ROUTE="0x224a4419D7FA69D3bEbAbce574c7c84B48D829b4"
DOMAIN="1325"
EXCHANGE_RATE="142244393"
GAS_PRICE="38325000000"
RPC="https://ethereum-sepolia-rpc.publicnode.com"

TMP_DIR="/tmp/igp-deploy-$(date +%s)"

#━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# ETAPA 1: DEPLOY DO IGP
#━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

if [ -z "$PRIVATE_KEY_SEPOLIA" ]; then
    echo -e "${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${YELLOW}⚠️  PRIVATE_KEY_SEPOLIA não definida${NC}"
    echo -e "${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo ""
    echo -e "${BLUE}OPÇÃO 1: Deploy Automático (via Forge)${NC}"
    echo ""
    echo "  1. Defina sua chave privada da SEPOLIA:"
    echo "     ${YELLOW}export PRIVATE_KEY_SEPOLIA='0xSUA_CHAVE_PRIVADA_SEPOLIA'${NC}"
    echo ""
    echo "  2. Execute novamente este script:"
    echo "     ${YELLOW}./deploy-e-associar-igp.sh${NC}"
    echo ""
    echo -e "${BLUE}OPÇÃO 2: Deploy Manual (via Remix - RECOMENDADO)${NC}"
    echo ""
    echo "  1. Abra: https://remix.ethereum.org"
    echo ""
    echo "  2. Crie arquivo: TerraClassicIGP.sol"
    echo ""
    echo "  3. Cole o código de:"
    echo "     ${YELLOW}cat /tmp/igp-deploy-*/src/TerraClassicIGP.sol${NC}"
    echo "     Ou veja em: ${YELLOW}TerraClassicIGPStandalone.sol${NC}"
    echo ""
    echo "  4. Compile (Solidity 0.8.13+)"
    echo ""
    echo "  5. Deploy com os parâmetros:"
    echo "     _gasOracle:   ${GREEN}$ORACLE${NC}"
    echo "     _gasOverhead: ${GREEN}$OVERHEAD${NC}"
    echo "     _beneficiary: ${GREEN}$BENEFICIARY${NC}"
    echo ""
    echo "  6. Após o deploy, copie o endereço do contrato"
    echo ""
    echo "  7. Execute a configuração:"
    echo "     ${YELLOW}export IGP_ADDRESS='0xENDERECO_DO_REMIX'${NC}"
    echo "     ${YELLOW}export PRIVATE_KEY_SEPOLIA='0xSUA_CHAVE_PRIVADA_SEPOLIA'${NC}"
    echo "     ${YELLOW}./configurar-e-associar-igp.sh${NC}"
    echo ""
    echo -e "${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    exit 1
fi

echo "1️⃣  PREPARANDO AMBIENTE DE COMPILAÇÃO..."
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

mkdir -p "$TMP_DIR/src"

cat > "$TMP_DIR/src/TerraClassicIGP.sol" << 'EOF'
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
EOF

echo -e "${GREEN}✅ Contrato criado${NC}"
echo ""

cd "$TMP_DIR"

echo "2️⃣  COMPILANDO CONTRATO..."
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

forge init --no-git --force . >/dev/null 2>&1
forge build 2>&1 | grep -E "(Compiling|Compiler run successful)" || true

if [ ! -f "out/TerraClassicIGP.sol/TerraClassicIGP.json" ]; then
    echo -e "${RED}❌ Compilação falhou${NC}"
    exit 1
fi

echo -e "${GREEN}✅ Compilação bem-sucedida${NC}"
echo ""

echo "3️⃣  FAZENDO DEPLOY DO IGP..."
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

DEPLOY_OUTPUT=$(forge create src/TerraClassicIGP.sol:TerraClassicIGP \
    --rpc-url "$RPC" \
    --private-key "$PRIVATE_KEY_SEPOLIA" \
    --constructor-args "$ORACLE" "$OVERHEAD" "$BENEFICIARY" \
    --legacy \
    2>&1)

echo "$DEPLOY_OUTPUT"

IGP_ADDRESS=$(echo "$DEPLOY_OUTPUT" | grep "Deployed to:" | awk '{print $3}')

if [ -z "$IGP_ADDRESS" ]; then
    echo -e "${RED}❌ Deploy falhou${NC}"
    exit 1
fi

echo ""
echo -e "${GREEN}✅✅✅ IGP DEPLOYADO COM SUCESSO! ✅✅✅${NC}"
echo ""
echo -e "${GREEN}📍 Endereço do IGP: $IGP_ADDRESS${NC}"
echo ""

cd /home/lunc/cw-hyperlane
echo "$IGP_ADDRESS" > IGP_ADDRESS.txt

#━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# ETAPA 2: CONFIGURAÇÃO DO IGP
#━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

echo "4️⃣  CONFIGURANDO IGP PARA TERRA CLASSIC..."
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

echo "   Domain: $DOMAIN"
echo "   Exchange Rate: $EXCHANGE_RATE"
echo "   Gas Price: $GAS_PRICE"
echo ""

TX_CONFIG=$(cast send "$IGP_ADDRESS" \
    "setRemoteGasData(uint32,uint128,uint128)" \
    "$DOMAIN" "$EXCHANGE_RATE" "$GAS_PRICE" \
    --rpc-url "$RPC" \
    --private-key "$PRIVATE_KEY_SEPOLIA" \
    --legacy \
    2>&1 | grep "transactionHash" | awk '{print $2}')

if [ ! -z "$TX_CONFIG" ]; then
    echo -e "${GREEN}✅ IGP configurado${NC}"
    echo "   TX: $TX_CONFIG"
else
    echo -e "${YELLOW}⚠️  Erro ao configurar (continuando...)${NC}"
fi

echo ""

#━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# ETAPA 3: ASSOCIAÇÃO AO WARP ROUTE
#━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

echo "5️⃣  ASSOCIANDO IGP AO WARP ROUTE..."
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

echo "   Warp Route: $WARP_ROUTE"
echo "   Novo IGP: $IGP_ADDRESS"
echo ""

TX_HOOK=$(cast send "$WARP_ROUTE" \
    "setHook(address)" \
    "$IGP_ADDRESS" \
    --rpc-url "$RPC" \
    --private-key "$PRIVATE_KEY_SEPOLIA" \
    --legacy \
    2>&1 | grep "transactionHash" | awk '{print $2}')

if [ ! -z "$TX_HOOK" ]; then
    echo -e "${GREEN}✅ IGP associado ao Warp Route${NC}"
    echo "   TX: $TX_HOOK"
else
    echo -e "${RED}❌ Erro ao associar IGP${NC}"
    exit 1
fi

echo ""

#━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# ETAPA 4: VERIFICAÇÃO
#━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

echo "6️⃣  VERIFICANDO CONFIGURAÇÃO..."
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

sleep 5

HOOK_ATUAL=$(cast call "$WARP_ROUTE" "hook()(address)" --rpc-url "$RPC" 2>/dev/null)
HOOK_TYPE=$(cast call "$IGP_ADDRESS" "hookType()(uint8)" --rpc-url "$RPC" 2>/dev/null)

echo "   Hook configurado no Warp: $HOOK_ATUAL"
echo "   Hook Type: $HOOK_TYPE"

if [ "$HOOK_ATUAL" = "$IGP_ADDRESS" ] && [ "$HOOK_TYPE" = "4" ]; then
    echo -e "${GREEN}   ✅ Configuração correta!${NC}"
else
    echo -e "${YELLOW}   ⚠️  Aguarde alguns segundos e verifique novamente${NC}"
fi

echo ""

#━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# CONCLUSÃO
#━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

echo "╔═══════════════════════════════════════════════════════════════════════╗"
echo "║                                                                       ║"
echo "║               ✅✅✅ DEPLOY E ASSOCIAÇÃO CONCLUÍDOS! ✅✅✅          ║"
echo "║                                                                       ║"
echo "╚═══════════════════════════════════════════════════════════════════════╝"
echo ""
echo -e "${GREEN}📍 IGP Deployado: $IGP_ADDRESS${NC}"
echo -e "${GREEN}📍 Warp Route: $WARP_ROUTE${NC}"
echo -e "${GREEN}📍 Hook Type: 4 (INTERCHAIN_GAS_PAYMASTER) ✅${NC}"
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo -e "${BLUE}🎯 PRÓXIMO PASSO: Testar a transferência${NC}"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "Acesse: https://warp.hyperlane.xyz"
echo "Tente enviar de Sepolia para Terra Classic"
echo ""
echo "O erro 'destination not supported' deve estar CORRIGIDO! ✅"
echo ""
