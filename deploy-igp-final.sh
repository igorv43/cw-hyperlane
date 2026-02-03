#!/bin/bash

# ============================================================================
# Deploy TerraClassicIGP e Associar ao Warp Route - Solução Final
# ============================================================================

set -e

# Cores
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuração
RPC_URL="https://1rpc.io/sepolia"
PRIVATE_KEY="0xe6802d288e10e94a9e7910793b6a58328f4011ab622d19ad2636ce28264812e5"
ORACLE="0x7113Df4d1D8B230e6339011d10277a6E5AC4eC9c"
OVERHEAD="200000"
WARP_ROUTE="0x224a4419D7FA69D3bEbAbce574c7c84B48D829b4"
OWNER=$(cast wallet address --private-key "$PRIVATE_KEY")

echo -e "${BLUE}╔════════════════════════════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║                                                                    ║${NC}"
echo -e "${BLUE}║         🚀 DEPLOY E CONFIGURAÇÃO COMPLETA DO IGP                  ║${NC}"
echo -e "${BLUE}║                                                                    ║${NC}"
echo -e "${BLUE}╚════════════════════════════════════════════════════════════════════╝${NC}"
echo ""
echo -e "${YELLOW}📊 Configuração:${NC}"
echo "   Owner/Beneficiary: $OWNER"
echo "   Oracle: $ORACLE"
echo "   Gas Overhead: $OVERHEAD"
echo "   Warp Route: $WARP_ROUTE"
echo ""

# ============================================================================
# PASSO 1: Deploy do IGP via Remix (Manual)
# ============================================================================

echo -e "${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${YELLOW}PASSO 1: Deploy do TerraClassicIGPStandalone via Remix${NC}"
echo -e "${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""
echo "Por favor, faça o deploy manualmente no Remix IDE:"
echo ""
echo "1. Abra: https://remix.ethereum.org"
echo "2. Crie arquivo: TerraClassicIGPStandalone.sol"
echo "3. Cole o código de: /home/lunc/cw-hyperlane/TerraClassicIGPStandalone.sol"
echo "4. Compile com Solidity 0.8.13+"
echo "5. Deploy com parâmetros:"
echo "   _gasOracle:    $ORACLE"
echo "   _gasOverhead:  $OVERHEAD"
echo "   _beneficiary:  $OWNER"
echo ""
echo -e "${GREEN}6. Copie o endereço do contrato deployado${NC}"
echo ""
read -p "Cole o endereço do IGP deployado: " IGP_ADDRESS

if [ -z "$IGP_ADDRESS" ]; then
    echo -e "${RED}❌ Endereço não fornecido. Abortando.${NC}"
    exit 1
fi

echo ""
echo -e "${GREEN}✅ IGP Address: $IGP_ADDRESS${NC}"
echo ""

# Salvar para uso posterior
echo "IGP_ADDRESS=$IGP_ADDRESS" > /home/lunc/cw-hyperlane/deployed-igp-address.env

# ============================================================================
# PASSO 2: Verificar hookType do IGP
# ============================================================================

echo -e "${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${YELLOW}PASSO 2: Verificando hookType do IGP${NC}"
echo -e "${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""

HOOK_TYPE=$(cast call "$IGP_ADDRESS" "hookType()(uint8)" --rpc-url "$RPC_URL" 2>/dev/null || echo "error")

if [ "$HOOK_TYPE" = "error" ]; then
    echo -e "${RED}❌ Erro ao verificar hookType. Verifique se o endereço está correto.${NC}"
    exit 1
fi

HOOK_TYPE_DEC=$((16#${HOOK_TYPE#0x}))

echo "Hook Type: $HOOK_TYPE_DEC"

if [ "$HOOK_TYPE_DEC" = "4" ]; then
    echo -e "${GREEN}✅ Hook Type correto! (4 = INTERCHAIN_GAS_PAYMASTER)${NC}"
else
    echo -e "${RED}❌ Hook Type ERRADO! Esperado: 4, Obtido: $HOOK_TYPE_DEC${NC}"
    echo -e "${RED}   Por favor, deploy novamente o TerraClassicIGPStandalone.sol${NC}"
    exit 1
fi

echo ""

# ============================================================================
# PASSO 3: Associar IGP ao Warp Route
# ============================================================================

echo -e "${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${YELLOW}PASSO 3: Associando IGP ao Warp Route${NC}"
echo -e "${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""

echo "Enviando transação setHook()..."
echo ""

TX_HASH=$(cast send "$WARP_ROUTE" \
    "setHook(address)" "$IGP_ADDRESS" \
    --rpc-url "$RPC_URL" \
    --private-key "$PRIVATE_KEY" \
    --json 2>/dev/null | jq -r '.transactionHash // empty')

if [ -z "$TX_HASH" ]; then
    echo -e "${RED}❌ Erro ao enviar transação setHook${NC}"
    exit 1
fi

echo -e "${GREEN}✅ Transação enviada: $TX_HASH${NC}"
echo ""
echo "Aguardando confirmação (30 segundos)..."
sleep 30

# Verificar se foi associado
CURRENT_HOOK=$(cast call "$WARP_ROUTE" "hook()(address)" --rpc-url "$RPC_URL" 2>/dev/null || echo "error")

if [ "$CURRENT_HOOK" = "error" ]; then
    echo -e "${YELLOW}⚠️  Não foi possível verificar o hook. Continuando...${NC}"
elif [ "${CURRENT_HOOK,,}" = "${IGP_ADDRESS,,}" ]; then
    echo -e "${GREEN}✅ Hook associado corretamente ao Warp Route!${NC}"
else
    echo -e "${RED}❌ Hook não foi associado corretamente.${NC}"
    echo "   Esperado: $IGP_ADDRESS"
    echo "   Obtido: $CURRENT_HOOK"
    exit 1
fi

echo ""

# ============================================================================
# PASSO 4: Testar quoteDispatch
# ============================================================================

echo -e "${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${YELLOW}PASSO 4: Testando quoteDispatch do IGP${NC}"
echo -e "${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""

# Criar metadados e mensagem de teste
METADATA="0x0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000c350" # gasLimit = 50000
# Mensagem de teste para Terra Classic (domain 1325 = 0x052d)
MESSAGE="0x00000000000000000000000000000000000000000000000000000000000000010000000000000000000000000000000000000000000000000000000000000000052d0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000"

echo "Chamando quoteDispatch()..."

QUOTE=$(cast call "$IGP_ADDRESS" \
    "quoteDispatch(bytes,bytes)(uint256)" \
    "$METADATA" "$MESSAGE" \
    --rpc-url "$RPC_URL" 2>&1)

if echo "$QUOTE" | grep -q "destination not supported"; then
    echo -e "${RED}❌ ERRO: 'destination not supported'${NC}"
    echo "   O IGP não está reconhecendo o domínio 1325 (Terra Classic)"
    echo "   Verifique se o Oracle está configurado corretamente."
    exit 1
elif echo "$QUOTE" | grep -q "Error"; then
    echo -e "${RED}❌ ERRO ao chamar quoteDispatch:${NC}"
    echo "$QUOTE"
    exit 1
else
    QUOTE_DEC=$((16#${QUOTE#0x}))
    QUOTE_ETH=$(cast --to-unit "$QUOTE" ether)
    echo -e "${GREEN}✅ Quote obtido com sucesso!${NC}"
    echo "   Custo em Wei: $QUOTE_DEC"
    echo "   Custo em ETH: $QUOTE_ETH"
fi

echo ""

# ============================================================================
# PASSO 5: Testar quoteTransferRemote no Warp Route
# ============================================================================

echo -e "${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${YELLOW}PASSO 5: Testando quoteTransferRemote no Warp Route${NC}"
echo -e "${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""

# Testar com endereço de teste
TERRA_RECIPIENT="0000000000000000000000000000000000000000000000000000000000000001"
TERRA_RECIPIENT_BYTES32="0x0000000000000000000000000000000000000000000000000000000000000001"
AMOUNT="1000000000000000000" # 1 token

echo "Chamando quoteTransferRemote()..."
echo "   Domain: 1325 (Terra Classic)"
echo "   Recipient: $TERRA_RECIPIENT_BYTES32"
echo "   Amount: $AMOUNT"
echo ""

WARP_QUOTE=$(cast call "$WARP_ROUTE" \
    "quoteTransferRemote(uint32,bytes32,uint256)(uint256)" \
    "1325" "$TERRA_RECIPIENT_BYTES32" "$AMOUNT" \
    --rpc-url "$RPC_URL" 2>&1)

if echo "$WARP_QUOTE" | grep -q "destination not supported"; then
    echo -e "${RED}❌ ERRO: 'destination not supported'${NC}"
    echo ""
    echo "   Este erro indica que o Warp Route ainda não reconhece o IGP."
    echo "   Possíveis causas:"
    echo "   1. A transação setHook() ainda não foi confirmada (aguarde mais)"
    echo "   2. O hookType do IGP está errado (deveria ser 4)"
    echo "   3. O IGP não suporta o domínio 1325"
    echo ""
    echo "   Aguardando mais 30 segundos e tentando novamente..."
    sleep 30
    
    WARP_QUOTE=$(cast call "$WARP_ROUTE" \
        "quoteTransferRemote(uint32,bytes32,uint256)(uint256)" \
        "1325" "$TERRA_RECIPIENT_BYTES32" "$AMOUNT" \
        --rpc-url "$RPC_URL" 2>&1)
    
    if echo "$WARP_QUOTE" | grep -q "destination not supported"; then
        echo -e "${RED}❌ ERRO PERSISTE: 'destination not supported'${NC}"
        echo "   Por favor, verifique manualmente no Etherscan:"
        echo "   1. Transação setHook: https://sepolia.etherscan.io/tx/$TX_HASH"
        echo "   2. Hook atual: https://sepolia.etherscan.io/address/$WARP_ROUTE#readContract"
        exit 1
    fi
elif echo "$WARP_QUOTE" | grep -q "Configured IGP doesn't support domain"; then
    echo -e "${RED}❌ ERRO: 'Configured IGP doesn't support domain 1325'${NC}"
    echo "   O Oracle não está configurado para Terra Classic."
    echo "   Verifique: https://sepolia.etherscan.io/address/$ORACLE#readContract"
    exit 1
elif echo "$WARP_QUOTE" | grep -q "Error"; then
    echo -e "${RED}❌ ERRO ao chamar quoteTransferRemote:${NC}"
    echo "$WARP_QUOTE"
    exit 1
else
    WARP_QUOTE_DEC=$((16#${WARP_QUOTE#0x}))
    WARP_QUOTE_ETH=$(cast --to-unit "$WARP_QUOTE" ether)
    echo -e "${GREEN}✅✅✅ SUCESSO! quoteTransferRemote funcionou!${NC}"
    echo ""
    echo "   Custo para transferir 1 token:"
    echo "   - Wei: $WARP_QUOTE_DEC"
    echo "   - ETH: $WARP_QUOTE_ETH"
    echo ""
    echo -e "${GREEN}🎉 O erro 'destination not supported' foi CORRIGIDO!${NC}"
fi

echo ""

# ============================================================================
# RESUMO FINAL
# ============================================================================

echo -e "${BLUE}╔════════════════════════════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║                                                                    ║${NC}"
echo -e "${BLUE}║                    ✅ CONFIGURAÇÃO COMPLETA!                       ║${NC}"
echo -e "${BLUE}║                                                                    ║${NC}"
echo -e "${BLUE}╚════════════════════════════════════════════════════════════════════╝${NC}"
echo ""
echo -e "${GREEN}📋 Resumo da Configuração:${NC}"
echo ""
echo "   🔹 IGP Address:        $IGP_ADDRESS"
echo "   🔹 Hook Type:          4 (INTERCHAIN_GAS_PAYMASTER) ✅"
echo "   🔹 Warp Route:         $WARP_ROUTE"
echo "   🔹 Oracle:             $ORACLE"
echo "   🔹 Gas Overhead:       $OVERHEAD"
echo "   🔹 setHook TX:         $TX_HASH"
echo ""
echo -e "${GREEN}🎯 Próximos Passos:${NC}"
echo ""
echo "   1. Teste a transferência Sepolia → Terra Classic no front-end"
echo "   2. O erro 'destination not supported' NÃO deve mais aparecer"
echo "   3. O custo estimado será ~$WARP_QUOTE_ETH ETH por transferência"
echo ""
echo -e "${YELLOW}📚 Documentação:${NC}"
echo "   - Configuração salva em: deployed-igp-address.env"
echo "   - Guia completo: CONFIGURAR-WARP-LUNC-SEPOLIA.md"
echo ""
echo -e "${GREEN}✅ Tudo pronto para transferências!${NC}"
echo ""
