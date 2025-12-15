#!/bin/bash

# ============================================================================
# Script: Configurar ISM para Warp Route lunc-solana-v2
# ============================================================================
# Este script configura o ISM (Interchain Security Module) para o novo
# Warp route lunc-solana-v2 na Solana Testnet.
# ============================================================================

set -e  # Parar em caso de erro

# Cores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Variáveis
KEYPAIR="/home/lunc/keys/solana-keypair-EMAYGfEyhywUyEX6kfG5FZZMfznmKXM8PbWpkJhJ9Jjd.json"
CHAIN="solanatestnet"
CONTEXT="lunc-solana-v2-ism"
BUILT_SO_DIR="../target/deploy"
REGISTRY_DIR="$HOME/.hyperlane/registry"
ENVIRONMENTS_DIR="../environments"
WARP_ROUTE_NAME="lunc-solana-v2"
DOMAIN="1325"  # Terra Classic domain
VALIDATOR="242d8a855a8c932dec51f7999ae7d1e48b10c95e"  # Terra Classic validator (hex)
THRESHOLD="1"

# Diretório base
BASE_DIR="$HOME/hyperlane-monorepo/rust/sealevel"
CLIENT_DIR="$BASE_DIR/client"
WARP_ROUTE_DIR="$BASE_DIR/environments/testnet/warp-routes/$WARP_ROUTE_NAME"

echo -e "${BLUE}============================================================================${NC}"
echo -e "${BLUE}  CONFIGURAR ISM PARA WARP ROUTE: ${WARP_ROUTE_NAME}${NC}"
echo -e "${BLUE}============================================================================${NC}"
echo ""

# ============================================================================
# PASSO 1: Descobrir Program ID do Warp Route
# ============================================================================
echo -e "${YELLOW}[PASSO 1/6] Descobrindo Program ID do Warp Route...${NC}"
echo ""

WARP_ROUTE_PROGRAM_ID=""

# Tentar ler do arquivo program-ids.json
if [ -f "$WARP_ROUTE_DIR/program-ids.json" ]; then
    echo -e "${CYAN}Tentando ler Program ID do arquivo program-ids.json...${NC}"
    WARP_ROUTE_PROGRAM_ID=$(jq -r ".${CHAIN}.base58" "$WARP_ROUTE_DIR/program-ids.json" 2>/dev/null || echo "")
    
    if [ -n "$WARP_ROUTE_PROGRAM_ID" ] && [ "$WARP_ROUTE_PROGRAM_ID" != "null" ]; then
        echo -e "${GREEN}✅ Program ID encontrado no arquivo: ${WARP_ROUTE_PROGRAM_ID}${NC}"
    else
        echo -e "${YELLOW}⚠️  Não foi possível ler do arquivo${NC}"
    fi
fi

# Se não encontrou, pedir ao usuário
if [ -z "$WARP_ROUTE_PROGRAM_ID" ] || [ "$WARP_ROUTE_PROGRAM_ID" == "null" ]; then
    echo -e "${YELLOW}⚠️  Program ID não encontrado automaticamente${NC}"
    echo -e "${CYAN}Por favor, informe o Program ID do Warp Route ${WARP_ROUTE_NAME}:${NC}"
    read -p "Program ID: " WARP_ROUTE_PROGRAM_ID
    
    if [ -z "$WARP_ROUTE_PROGRAM_ID" ]; then
        echo -e "${RED}❌ Program ID é obrigatório!${NC}"
        exit 1
    fi
fi

echo -e "${GREEN}✅ Warp Route Program ID: ${WARP_ROUTE_PROGRAM_ID}${NC}"
echo ""
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""

# ============================================================================
# PASSO 2: Verificar/Compilar Programa ISM
# ============================================================================
echo -e "${YELLOW}[PASSO 2/6] Verificando compilação do programa ISM...${NC}"
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
# PASSO 3: Deploy do Novo ISM
# ============================================================================
echo -e "${YELLOW}[PASSO 3/6] Fazendo deploy do novo ISM...${NC}"
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
echo -e "${CYAN}⏳ Executando deploy (isso pode levar alguns minutos)...${NC}"
echo ""

cd "$CLIENT_DIR"

# Criar arquivo temporário para capturar output
TEMP_OUTPUT=$(mktemp)

# Executar deploy mostrando output em tempo real E salvando em arquivo
cargo run -- \
  -k "$KEYPAIR" \
  -u https://api.testnet.solana.com \
  multisig-ism-message-id deploy \
  --environment testnet \
  --environments-dir "$ENVIRONMENTS_DIR" \
  --built-so-dir "$BUILT_SO_DIR" \
  --chain "$CHAIN" \
  --context "$CONTEXT" \
  --registry "$REGISTRY_DIR" 2>&1 | tee "$TEMP_OUTPUT"

# Ler output do arquivo
DEPLOY_OUTPUT=$(cat "$TEMP_OUTPUT")
rm -f "$TEMP_OUTPUT"

# Extrair Program ID do output
NEW_ISM_PROGRAM_ID=$(echo "$DEPLOY_OUTPUT" | grep -oP 'program ID \K[0-9A-Za-z]{32,44}' | head -1)

if [ -z "$NEW_ISM_PROGRAM_ID" ]; then
    # Tentar extrair de outra forma
    NEW_ISM_PROGRAM_ID=$(echo "$DEPLOY_OUTPUT" | grep -i "program id" | grep -oP '[0-9A-Za-z]{32,44}' | head -1)
fi

if [ -z "$NEW_ISM_PROGRAM_ID" ]; then
    echo ""
    echo -e "${RED}❌ Não foi possível extrair o Program ID do output${NC}"
    echo -e "${YELLOW}Por favor, copie manualmente o Program ID do output acima${NC}"
    read -p "Cole o Program ID aqui: " NEW_ISM_PROGRAM_ID
    
    if [ -z "$NEW_ISM_PROGRAM_ID" ]; then
        echo -e "${RED}❌ Program ID é obrigatório!${NC}"
        exit 1
    fi
fi

echo ""
echo -e "${GREEN}✅ Deploy concluído!${NC}"
echo -e "${GREEN}📝 Novo ISM Program ID: ${NEW_ISM_PROGRAM_ID}${NC}"

# Salvar em arquivo para referência
echo "$NEW_ISM_PROGRAM_ID" > /tmp/new_ism_program_id_lunc_solana_v2.txt
echo "$NEW_ISM_PROGRAM_ID" > "$HOME/new_ism_program_id_lunc_solana_v2.txt"

echo ""
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""

# ============================================================================
# PASSO 4: Verificar Owner do Novo ISM
# ============================================================================
echo -e "${YELLOW}[PASSO 4/6] Verificando owner do novo ISM...${NC}"
echo ""
echo -e "${CYAN}Executando query...${NC}"
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
# PASSO 5: Configurar Validadores no Novo ISM
# ============================================================================
echo -e "${YELLOW}[PASSO 5/6] Configurando validadores no novo ISM...${NC}"
echo ""
echo -e "${BLUE}Parâmetros:${NC}"
echo "  - Domain: $DOMAIN (Terra Classic)"
echo "  - Validator: $VALIDATOR"
echo "  - Threshold: $THRESHOLD"
echo ""
echo -e "${CYAN}Executando configuração de validadores...${NC}"
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
# PASSO 6: Associar Novo ISM ao Warp Route
# ============================================================================
echo -e "${YELLOW}[PASSO 6/6] Associando novo ISM ao warp route...${NC}"
echo ""
echo -e "${BLUE}Parâmetros:${NC}"
echo "  - Warp Route Program ID: $WARP_ROUTE_PROGRAM_ID"
echo "  - Novo ISM Program ID: $NEW_ISM_PROGRAM_ID"
echo ""
echo -e "${CYAN}Executando associação...${NC}"
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
echo -e "  ${YELLOW}Warp Route Name:${NC} $WARP_ROUTE_NAME"
echo -e "  ${YELLOW}Warp Route Program ID:${NC} $WARP_ROUTE_PROGRAM_ID"
echo -e "  ${YELLOW}Novo ISM Program ID:${NC} $NEW_ISM_PROGRAM_ID"
echo -e "  ${YELLOW}Domain configurado:${NC} $DOMAIN (Terra Classic)"
echo -e "  ${YELLOW}Validator:${NC} $VALIDATOR"
echo -e "  ${YELLOW}Threshold:${NC} $THRESHOLD"
echo ""
echo -e "${BLUE}📁 Arquivos salvos:${NC}"
echo "  - /tmp/new_ism_program_id_lunc_solana_v2.txt"
echo "  - $HOME/new_ism_program_id_lunc_solana_v2.txt"
echo ""
echo -e "${BLUE}🔍 Próximos passos:${NC}"
echo "  1. Verificar se o ISM está configurado no warp route:"
echo "     cargo run -- -k \"$KEYPAIR\" -u https://api.testnet.solana.com \\"
echo "       token query --program-id $WARP_ROUTE_PROGRAM_ID synthetic"
echo ""
echo "  2. Testar transferência cross-chain Terra Classic → Solana"
echo ""
echo -e "${GREEN}============================================================================${NC}"

