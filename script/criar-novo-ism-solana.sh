#!/bin/bash

# ============================================================================
# Script: Criar Novo ISM na Solana e Associar ao Warp Route
# ============================================================================
# Este script cria um novo ISM na Solana, configura validadores e associa
# ao warp route, resolvendo o problema de não ser owner do ISM existente.
# ============================================================================

set -e  # Parar em caso de erro

# Cores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Variáveis
KEYPAIR="/home/lunc/keys/solana-keypair-EMAYGfEyhywUyEX6kfG5FZZMfznmKXM8PbWpkJhJ9Jjd.json"
CHAIN="solanatestnet"
CONTEXT="lunc-solana-ism"
BUILT_SO_DIR="../target/deploy"
REGISTRY_DIR="$HOME/.hyperlane/registry"
ENVIRONMENTS_DIR="../environments"
WARP_ROUTE_PROGRAM_ID="5BuTS1oZhUKJgpgwXJyz5VRdTq99SMvHm7hrPMctJk6x"
DOMAIN="1325"  # Terra Classic domain
VALIDATOR="242d8a855a8c932dec51f7999ae7d1e48b10c95e"  # Terra Classic validator (hex)
THRESHOLD="1"

# Diretório base
BASE_DIR="$HOME/hyperlane-monorepo/rust/sealevel"
CLIENT_DIR="$BASE_DIR/client"

echo -e "${BLUE}============================================================================${NC}"
echo -e "${BLUE}  CRIAR NOVO ISM NA SOLANA E ASSOCIAR AO WARP ROUTE${NC}"
echo -e "${BLUE}============================================================================${NC}"
echo ""

# ============================================================================
# PASSO 1: Verificar Compilação do Programa ISM
# ============================================================================
echo -e "${YELLOW}[PASSO 1/6] Verificando compilação do programa ISM...${NC}"
echo ""

cd "$BASE_DIR"

if [ ! -f "target/deploy/hyperlane_sealevel_multisig_ism_message_id.so" ]; then
    echo -e "${YELLOW}⚠️  Programa ISM não encontrado. Compilando...${NC}"
    echo ""
    cargo build-sbf --manifest-path programs/ism/multisig-ism-message-id/Cargo.toml
    
    if [ $? -ne 0 ]; then
        echo -e "${RED}❌ Erro ao compilar o programa ISM${NC}"
        exit 1
    fi
    
    echo -e "${GREEN}✅ Programa ISM compilado com sucesso${NC}"
else
    echo -e "${GREEN}✅ Programa ISM já compilado${NC}"
    ls -lh target/deploy/hyperlane_sealevel_multisig_ism_message_id.so
fi

echo ""
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""

# ============================================================================
# PASSO 2: Deploy do Novo ISM
# ============================================================================
echo -e "${YELLOW}[PASSO 2/6] Fazendo deploy do novo ISM...${NC}"
echo ""
echo -e "${BLUE}Comando que será executado:${NC}"
echo "cd $CLIENT_DIR"
echo "cargo run -- \\"
echo "  -k \"$KEYPAIR\" \\"
echo "  -u https://api.testnet.solana.com \\"
echo "  multisig-ism-message-id deploy \\"
echo "  --environment testnet \\"
echo "  --environments-dir \"$ENVIRONMENTS_DIR\" \\"
echo "  --built-so-dir \"$BUILT_SO_DIR\" \\"
echo "  --chain \"$CHAIN\" \\"
echo "  --context \"$CONTEXT\" \\"
echo "  --registry \"$REGISTRY_DIR\""
echo ""
read -p "Pressione ENTER para continuar ou Ctrl+C para cancelar..."

cd "$CLIENT_DIR"

echo ""
echo -e "${YELLOW}Executando deploy...${NC}"
echo ""

# Executar deploy e capturar output
DEPLOY_OUTPUT=$(cargo run -- \
  -k "$KEYPAIR" \
  -u https://api.testnet.solana.com \
  multisig-ism-message-id deploy \
  --environment testnet \
  --environments-dir "$ENVIRONMENTS_DIR" \
  --built-so-dir "$BUILT_SO_DIR" \
  --chain "$CHAIN" \
  --context "$CONTEXT" \
  --registry "$REGISTRY_DIR" 2>&1)

echo "$DEPLOY_OUTPUT"

# Extrair Program ID do output
NEW_ISM_PROGRAM_ID=$(echo "$DEPLOY_OUTPUT" | grep -oP 'program ID \K[0-9A-Za-z]{32,44}' | head -1)

if [ -z "$NEW_ISM_PROGRAM_ID" ]; then
    # Tentar extrair de outra forma
    NEW_ISM_PROGRAM_ID=$(echo "$DEPLOY_OUTPUT" | grep -i "program id" | grep -oP '[0-9A-Za-z]{32,44}' | head -1)
fi

if [ -z "$NEW_ISM_PROGRAM_ID" ]; then
    echo -e "${RED}❌ Não foi possível extrair o Program ID do output${NC}"
    echo -e "${YELLOW}Por favor, copie manualmente o Program ID do output acima${NC}"
    read -p "Cole o Program ID aqui: " NEW_ISM_PROGRAM_ID
fi

echo ""
echo -e "${GREEN}✅ Deploy concluído!${NC}"
echo -e "${GREEN}📝 Novo ISM Program ID: ${NEW_ISM_PROGRAM_ID}${NC}"

# Salvar em arquivo para referência
echo "$NEW_ISM_PROGRAM_ID" > /tmp/new_ism_program_id.txt
echo "$NEW_ISM_PROGRAM_ID" > "$HOME/new_ism_program_id.txt"

echo ""
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""

# ============================================================================
# PASSO 3: Verificar Owner do Novo ISM
# ============================================================================
echo -e "${YELLOW}[PASSO 3/6] Verificando owner do novo ISM...${NC}"
echo ""
echo -e "${BLUE}Comando que será executado:${NC}"
echo "cargo run -- \\"
echo "  -k \"$KEYPAIR\" \\"
echo "  -u https://api.testnet.solana.com \\"
echo "  multisig-ism-message-id query \\"
echo "  --program-id \"$NEW_ISM_PROGRAM_ID\""
echo ""
read -p "Pressione ENTER para continuar..."

echo ""
echo -e "${YELLOW}Executando query...${NC}"
echo ""

cargo run -- \
  -k "$KEYPAIR" \
  -u https://api.testnet.solana.com \
  multisig-ism-message-id query \
  --program-id "$NEW_ISM_PROGRAM_ID"

echo ""
echo -e "${GREEN}✅ Verificação concluída${NC}"
echo -e "${YELLOW}⚠️  Verifique se o owner é: EMAYGfEyhywUyEX6kfG5FZZMfznmKXM8PbWpkJhJ9Jjd${NC}"

echo ""
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""

# ============================================================================
# PASSO 4: Configurar Validadores no Novo ISM
# ============================================================================
echo -e "${YELLOW}[PASSO 4/6] Configurando validadores no novo ISM...${NC}"
echo ""
echo -e "${BLUE}Parâmetros:${NC}"
echo "  - Domain: $DOMAIN (Terra Classic)"
echo "  - Validator: $VALIDATOR"
echo "  - Threshold: $THRESHOLD"
echo ""
echo -e "${BLUE}Comando que será executado:${NC}"
echo "cargo run -- \\"
echo "  -k \"$KEYPAIR\" \\"
echo "  -u https://api.testnet.solana.com \\"
echo "  multisig-ism-message-id set-validators-and-threshold \\"
echo "  --program-id \"$NEW_ISM_PROGRAM_ID\" \\"
echo "  --domain \"$DOMAIN\" \\"
echo "  --validators \"$VALIDATOR\" \\"
echo "  --threshold \"$THRESHOLD\""
echo ""
read -p "Pressione ENTER para continuar..."

echo ""
echo -e "${YELLOW}Executando configuração de validadores...${NC}"
echo ""

cargo run -- \
  -k "$KEYPAIR" \
  -u https://api.testnet.solana.com \
  multisig-ism-message-id set-validators-and-threshold \
  --program-id "$NEW_ISM_PROGRAM_ID" \
  --domain "$DOMAIN" \
  --validators "$VALIDATOR" \
  --threshold "$THRESHOLD"

if [ $? -eq 0 ]; then
    echo ""
    echo -e "${GREEN}✅ Validadores configurados com sucesso!${NC}"
else
    echo ""
    echo -e "${RED}❌ Erro ao configurar validadores${NC}"
    exit 1
fi

echo ""
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""

# ============================================================================
# PASSO 5: Verificar Configuração dos Validadores
# ============================================================================
echo -e "${YELLOW}[PASSO 5/6] Verificando configuração dos validadores...${NC}"
echo ""
echo -e "${BLUE}Comando que será executado:${NC}"
echo "cargo run -- \\"
echo "  -k \"$KEYPAIR\" \\"
echo "  -u https://api.testnet.solana.com \\"
echo "  multisig-ism-message-id query \\"
echo "  --program-id \"$NEW_ISM_PROGRAM_ID\" \\"
echo "  --domains \"$DOMAIN\""
echo ""
read -p "Pressione ENTER para continuar..."

echo ""
echo -e "${YELLOW}Executando verificação...${NC}"
echo ""

cargo run -- \
  -k "$KEYPAIR" \
  -u https://api.testnet.solana.com \
  multisig-ism-message-id query \
  --program-id "$NEW_ISM_PROGRAM_ID" \
  --domains "$DOMAIN"

echo ""
echo -e "${GREEN}✅ Verificação concluída${NC}"
echo -e "${YELLOW}⚠️  Verifique se os validadores estão corretos na saída acima${NC}"

echo ""
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""

# ============================================================================
# PASSO 6: Associar Novo ISM ao Warp Route
# ============================================================================
echo -e "${YELLOW}[PASSO 6/6] Associando novo ISM ao warp route...${NC}"
echo ""
echo -e "${BLUE}Parâmetros:${NC}"
echo "  - Warp Route Program ID: $WARP_ROUTE_PROGRAM_ID"
echo "  - Novo ISM Program ID: $NEW_ISM_PROGRAM_ID"
echo ""
echo -e "${BLUE}Comando que será executado:${NC}"
echo "cargo run -- \\"
echo "  -k \"$KEYPAIR\" \\"
echo "  -u https://api.testnet.solana.com \\"
echo "  token set-interchain-security-module \\"
echo "  --program-id \"$WARP_ROUTE_PROGRAM_ID\" \\"
echo "  --ism \"$NEW_ISM_PROGRAM_ID\""
echo ""
read -p "Pressione ENTER para continuar..."

echo ""
echo -e "${YELLOW}Executando associação...${NC}"
echo ""

cargo run -- \
  -k "$KEYPAIR" \
  -u https://api.testnet.solana.com \
  token set-interchain-security-module \
  --program-id "$WARP_ROUTE_PROGRAM_ID" \
  --ism "$NEW_ISM_PROGRAM_ID"

if [ $? -eq 0 ]; then
    echo ""
    echo -e "${GREEN}✅ ISM associado ao warp route com sucesso!${NC}"
else
    echo ""
    echo -e "${RED}❌ Erro ao associar ISM ao warp route${NC}"
    echo -e "${YELLOW}⚠️  Verifique se você é o owner do warp route${NC}"
    exit 1
fi

echo ""
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""

# ============================================================================
# RESUMO FINAL
# ============================================================================
echo -e "${GREEN}============================================================================${NC}"
echo -e "${GREEN}  ✅ PROCESSO CONCLUÍDO COM SUCESSO!${NC}"
echo -e "${GREEN}============================================================================${NC}"
echo ""
echo -e "${BLUE}📝 Informações importantes:${NC}"
echo ""
echo -e "  ${YELLOW}Novo ISM Program ID:${NC} $NEW_ISM_PROGRAM_ID"
echo -e "  ${YELLOW}Warp Route Program ID:${NC} $WARP_ROUTE_PROGRAM_ID"
echo -e "  ${YELLOW}Domain configurado:${NC} $DOMAIN (Terra Classic)"
echo -e "  ${YELLOW}Validator:${NC} $VALIDATOR"
echo -e "  ${YELLOW}Threshold:${NC} $THRESHOLD"
echo ""
echo -e "${BLUE}📁 Arquivos salvos:${NC}"
echo "  - /tmp/new_ism_program_id.txt"
echo "  - $HOME/new_ism_program_id.txt"
echo ""
echo -e "${BLUE}🔍 Próximos passos:${NC}"
echo "  1. Verificar se o ISM está configurado no warp route:"
echo "     cargo run -- -k \"$KEYPAIR\" -u https://api.testnet.solana.com \\"
echo "       token query --program-id $WARP_ROUTE_PROGRAM_ID synthetic"
echo ""
echo "  2. Testar transferência cross-chain Terra Classic → Solana"
echo ""
echo -e "${GREEN}============================================================================${NC}"

