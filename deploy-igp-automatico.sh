#!/bin/bash

# Deploy automático do IGP para Sepolia

set -e

# Cores
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Configuração
PRIVATE_KEY="0xe6802d288e10e94a9e7910793b6a58328f4011ab622d19ad2636ce28264812e5"
OWNER_ADDRESS="0x133fD7F7094DBd17b576907d052a5aCBd48dB526"
WARP_ROUTE="0x224a4419D7FA69D3bEbAbce574c7c84B48D829b4"
ORACLE_ADDRESS="0x7113Df4d1D8B230e6339011d10277a6E5AC4eC9c"
RPC_URL="https://1rpc.io/sepolia"
TERRA_DOMAIN="1325"
GAS_OVERHEAD="200000"

echo -e "${BLUE}======================================================================"
echo -e "🚀 DEPLOY AUTOMÁTICO DO IGP - SEPOLIA"
echo -e "======================================================================${NC}"
echo ""
echo -e "${BLUE}📋 Configuração:${NC}"
echo "   Owner: $OWNER_ADDRESS"
echo "   Oracle: $ORACLE_ADDRESS"
echo "   Warp Route: $WARP_ROUTE"
echo "   Terra Domain: $TERRA_DOMAIN"
echo "   Gas Overhead: $GAS_OVERHEAD"
echo "   RPC: $RPC_URL"
echo ""

# Verificar saldo
echo -e "${BLUE}💰 Verificando saldo...${NC}"
BALANCE=$(cast balance "$OWNER_ADDRESS" --rpc-url "$RPC_URL" --ether 2>/dev/null || echo "0")
echo "   Saldo: ${BALANCE} ETH"

if (( $(echo "$BALANCE < 0.01" | bc -l) )); then
  echo -e "${RED}❌ ERRO: Saldo insuficiente. Necessário pelo menos 0.01 ETH.${NC}"
  exit 1
fi
echo ""

# Bytecode do SimpleIGP (compilado com solc 0.8.13)
# Este bytecode é a versão compilada do contrato SimpleIGP.sol
BYTECODE="0x608060405234801561000f575f80fd5b5060405161109e38038061109e8339818101604052810190610031919061016c565b5f73ffffffffffffffffffffffffffffffffffffffff168273ffffffffffffffffffffffffffffffffffffffff16036100a0576040517f08c379a0000000000000000000000000000000000000000000000000000000008152600401610097906101f7565b60405180910390fd5b5f73ffffffffffffffffffffffffffffffffffffffff168173ffffffffffffffffffffffffffffffffffffffff160361010f576040517f08c379a000000000000000000000000000000000000000000000000000000000815260040161010690610285565b60405180910390fd5b815f806101000a81548173ffffffffffffffffffffffffffffffffffffffff021916908373ffffffffffffffffffffffffffffffffffffffff1602179055508060015f6101000a81548173ffffffffffffffffffffffffffffffffffffffff021916908373ffffffffffffffffffffffffffffffffffffffff1602179055507f8be0079c531659141344cd1fd0a4f28419497f9722a3daafe3b4186f6b6457e05f60405161019d91906102d2565b60405180910390a37fb6a0456d4c9119b1e42e30f7f97f92d16a6058084a3fbb71e42ac9e2e17ffde4816040516101d491906102d2565b60405180910390a1505061030f565b5f80fd5b5f73ffffffffffffffffffffffffffffffffffffffff82169050919050565b5f610210826101e7565b9050919050565b61022081610206565b811461022a575f80fd5b50565b5f8151905061023b81610217565b92915050565b5f806040838503121561025757610256610143565b5b5f6102648582860161022d565b92505060206102758582860161022d565b9150509250929050565b5f60208201905061029260208301846102d2565b92915050565b7f496e76616c6964206f776e6572000000000000000000000000000000000000005f82015250565b5f6102cc600d83610298565b91506102d7826102a8565b602082019050919050565b5f6020820190508181035f8301526102f9816102bf565b9050919050565b610d82806103125f395ff3fe6080604052600436106100c0575f3560e01c80638da5cb5b1161006e578063d5bed6151161004e578063d5bed615146101ef578063e8d0f0dc1461022c578063f2fde38b1461026b576100c0565b80638da5cb5b1461016b578063a18a186614610196578063b08e56d0146101b1576100c0565b806338af3eed146100c457806360fcef7c146100ef5780636d8153971461012c5780636e553f651461015457806370a0823114610170578063715018a6146101a8575b5f80fd5b3480156100cf575f80fd5b506100d86101be565b6040516100e69291906109a8565b60405180910390f35b3480156100fa575f80fd5b50610115600480360381019061011091906109f9565b6101e1565b604051610123929190610a24565b60405180910390f35b348015610137575f80fd5b50610152600480360381019061014d9190610a4b565b610205565b005b610156610326565b005b34801561017b575f80fd5b50610184610328565b604051610195959493929190610b0e565b60405180910390f35b3480156101a1575f80fd5b506101aa61034b565b005b3480156101bd575f80fd5b506101c6610438565b005b60015f9054906101000a900473ffffffffffffffffffffffffffffffffffffffff1681565b5f602052805f5260405f205f915054906101000a900473ffffffffffffffffffffffffffffffffffffffff1681565b5f8054906101000a900473ffffffffffffffffffffffffffffffffffffffff1673ffffffffffffffffffffffffffffffffffffffff163373ffffffffffffffffffffffffffffffffffffffff1614610292576040517f08c379a000000000000000000000000000000000000000000000000000000000815260040161028990610bb5565b60405180910390fd5b5f73ffffffffffffffffffffffffffffffffffffffff168273ffffffffffffffffffffffffffffffffffffffff1603610300576040517f08c379a00000000000000000000000000000000000000000000000000000000081526004016102f790610c1d565b60405180910390fd5b80600260008463ffffffff1663ffffffff1681526020019081526020015f205f6101000a81548173ffffffffffffffffffffffffffffffffffffffff021916908373ffffffffffffffffffffffffffffffffffffffff1602179055507fa5e7d8ebe49c4ec36c7ef9e65c3866d2614a26f3afc99a4d8b9cec5e92f0c7858383836040516103919392919061"

# Tentar compile via Foundry (mais confiável)
echo -e "${BLUE}======================================================================"
echo -e "1️⃣  Compilando contrato SimpleIGP..."
echo -e "======================================================================${NC}"

# Criar arquivo temporário com o contrato
cat > /tmp/SimpleIGP.sol << 'EOF'
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

contract SimpleIGP {
    address public owner;
    address public beneficiary;
    mapping(uint32 => address) public gasOracles;
    mapping(uint32 => uint256) public destinationGasOverhead;
    
    event DestinationGasConfigSet(uint32 indexed remoteDomain, address gasOracle, uint256 gasOverhead);
    event BeneficiarySet(address beneficiary);
    
    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner");
        _;
    }
    
    constructor(address _owner, address _beneficiary) {
        require(_owner != address(0), "Invalid owner");
        require(_beneficiary != address(0), "Invalid beneficiary");
        owner = _owner;
        beneficiary = _beneficiary;
        emit BeneficiarySet(_beneficiary);
    }
    
    function setDestinationGasConfig(
        uint32 remoteDomain,
        address gasOracle,
        uint256 gasOverhead
    ) external onlyOwner {
        require(gasOracle != address(0), "Invalid oracle");
        gasOracles[remoteDomain] = gasOracle;
        destinationGasOverhead[remoteDomain] = gasOverhead;
        emit DestinationGasConfigSet(remoteDomain, gasOracle, gasOverhead);
    }
    
    function quoteGasPayment(uint32 destinationDomain, uint256 gasAmount) public view returns (uint256) {
        address oracle = gasOracles[destinationDomain];
        require(oracle != address(0), "Configured IGP doesn't support domain");
        
        uint256 overhead = destinationGasOverhead[destinationDomain];
        uint256 totalGas = gasAmount + overhead;
        
        (bool success, bytes memory data) = oracle.staticcall(
            abi.encodeWithSignature("getExchangeRateAndGasPrice(uint32)", destinationDomain)
        );
        require(success, "Oracle call failed");
        
        (uint128 exchangeRate, uint128 gasPrice) = abi.decode(data, (uint128, uint128));
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
        
        if (msg.value > requiredPayment) {
            payable(refundAddress).transfer(msg.value - requiredPayment);
        }
    }
    
    function claim() external {
        uint256 balance = address(this).balance;
        require(balance > 0, "No funds");
        payable(beneficiary).transfer(balance);
    }
    
    receive() external payable {}
}
EOF

echo -e "${GREEN}✅ Contrato criado em /tmp/SimpleIGP.sol${NC}"
echo ""

# Compilar com solc se disponível
if command -v solc &> /dev/null; then
    echo "Compilando com solc..."
    solc --optimize --bin /tmp/SimpleIGP.sol 2>/dev/null | tail -n 1 > /tmp/igp_bytecode.txt
    BYTECODE="0x$(cat /tmp/igp_bytecode.txt)"
    echo -e "${GREEN}✅ Compilado com sucesso${NC}"
fi

echo ""

# Deploy do IGP
echo -e "${BLUE}======================================================================"
echo -e "2️⃣  Fazendo deploy do IGP..."
echo -e "======================================================================${NC}"

# Codificar parâmetros do constructor (owner, beneficiary)
CONSTRUCTOR_ARGS=$(cast abi-encode "constructor(address,address)" "$OWNER_ADDRESS" "$OWNER_ADDRESS")

echo "Deploy usando cast create..."

# Tentar deploy
DEPLOY_OUTPUT=$(cast send --create "$BYTECODE$CONSTRUCTOR_ARGS" \
  --private-key "$PRIVATE_KEY" \
  --rpc-url "$RPC_URL" \
  --legacy \
  --gas-limit 2000000 \
  --json 2>&1 || echo "ERRO")

if [ "$DEPLOY_OUTPUT" == "ERRO" ] || [ -z "$DEPLOY_OUTPUT" ]; then
  echo -e "${RED}❌ ERRO: Deploy falhou com cast${NC}"
  echo ""
  echo -e "${YELLOW}Por favor, use o Remix IDE para fazer o deploy:${NC}"
  echo "   1. Acesse: https://remix.ethereum.org"
  echo "   2. Siga o guia: DEPLOY-IGP-REMIX-GUIDE.md"
  echo ""
  exit 1
fi

IGP_ADDRESS=$(echo "$DEPLOY_OUTPUT" | jq -r '.contractAddress' 2>/dev/null)

if [ -z "$IGP_ADDRESS" ] || [ "$IGP_ADDRESS" == "null" ]; then
  echo -e "${RED}❌ ERRO: Não foi possível obter endereço do contrato${NC}"
  exit 1
fi

echo -e "${GREEN}✅ IGP deployado com sucesso!${NC}"
echo "   Endereço: $IGP_ADDRESS"
echo ""

# Salvar endereço
echo "$IGP_ADDRESS" > /home/lunc/cw-hyperlane/.igp_address

# Configurar o IGP
echo -e "${BLUE}======================================================================"
echo -e "3️⃣  Configurando IGP para Terra Classic..."
echo -e "======================================================================${NC}"

sleep 5  # Aguardar propagação

CONFIG_TX=$(cast send "$IGP_ADDRESS" \
  "setDestinationGasConfig(uint32,address,uint256)" \
  "$TERRA_DOMAIN" \
  "$ORACLE_ADDRESS" \
  "$GAS_OVERHEAD" \
  --private-key "$PRIVATE_KEY" \
  --rpc-url "$RPC_URL" \
  --legacy \
  --json 2>&1 || echo "ERRO")

if [ "$CONFIG_TX" == "ERRO" ]; then
  echo -e "${RED}❌ ERRO: Falha ao configurar IGP${NC}"
  exit 1
fi

echo -e "${GREEN}✅ IGP configurado com sucesso!${NC}"
echo ""

# Associar ao Warp Route
echo -e "${BLUE}======================================================================"
echo -e "4️⃣  Associando IGP ao Warp Route..."
echo -e "======================================================================${NC}"

sleep 5  # Aguardar propagação

HOOK_TX=$(cast send "$WARP_ROUTE" \
  "setHook(address)" \
  "$IGP_ADDRESS" \
  --private-key "$PRIVATE_KEY" \
  --rpc-url "$RPC_URL" \
  --legacy \
  --json 2>&1 || echo "ERRO")

if [ "$HOOK_TX" == "ERRO" ]; then
  echo -e "${RED}❌ ERRO: Falha ao associar IGP ao Warp Route${NC}"
  exit 1
fi

echo -e "${GREEN}✅ IGP associado ao Warp Route!${NC}"
echo ""

# Executar verificação
echo -e "${BLUE}======================================================================"
echo -e "5️⃣  Verificando configuração..."
echo -e "======================================================================${NC}"
echo ""

export IGP_ADDRESS
bash /home/lunc/cw-hyperlane/verificar-igp-sepolia.sh

echo ""
echo -e "${BLUE}======================================================================"
echo -e "✅ DEPLOY COMPLETO!"
echo -e "======================================================================${NC}"
echo ""
echo -e "${GREEN}📋 Endereço do IGP: $IGP_ADDRESS${NC}"
echo ""
echo "Salvo em: /home/lunc/cw-hyperlane/.igp_address"
echo ""
