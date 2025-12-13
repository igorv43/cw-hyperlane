#!/bin/bash

# ============================================================================
# Script: Mostrar Passo a Passo para Criar Novo ISM na Solana
# ============================================================================
# Este script apenas mostra os comandos, sem executá-los
# ============================================================================

# Cores
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

clear

echo -e "${BLUE}╔════════════════════════════════════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║                                                                        ║${NC}"
echo -e "${BLUE}║     PASSO A PASSO: CRIAR NOVO ISM NA SOLANA E ASSOCIAR AO WARP      ║${NC}"
echo -e "${BLUE}║                                                                        ║${NC}"
echo -e "${BLUE}╚════════════════════════════════════════════════════════════════════════════╝${NC}"
echo ""

# ============================================================================
# PASSO 1
# ============================================================================
echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${YELLOW}[PASSO 1/6] Verificar/Compilar Programa ISM${NC}"
echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""
echo -e "${GREEN}cd ~/hyperlane-monorepo/rust/sealevel${NC}"
echo ""
echo -e "${GREEN}# Verificar se já está compilado${NC}"
echo -e "${GREEN}ls -lh target/deploy/hyperlane_sealevel_multisig_ism_message_id.so${NC}"
echo ""
echo -e "${GREEN}# Se não existir, compilar:${NC}"
echo -e "${GREEN}cargo build-sbf --manifest-path programs/ism/multisig-ism-message-id/Cargo.toml${NC}"
echo ""
read -p "Pressione ENTER para ver o próximo passo..."

# ============================================================================
# PASSO 2
# ============================================================================
clear
echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${YELLOW}[PASSO 2/6] Deploy do Novo ISM${NC}"
echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""
echo -e "${GREEN}cd ~/hyperlane-monorepo/rust/sealevel/client${NC}"
echo ""
echo -e "${GREEN}cargo run -- \\${NC}"
echo -e "${GREEN}  -k /home/lunc/keys/solana-keypair-EMAYGfEyhywUyEX6kfG5FZZMfznmKXM8PbWpkJhJ9Jjd.json \\${NC}"
echo -e "${GREEN}  -u https://api.testnet.solana.com \\${NC}"
echo -e "${GREEN}  multisig-ism-message-id deploy \\${NC}"
echo -e "${GREEN}  --environment testnet \\${NC}"
echo -e "${GREEN}  --environments-dir ../environments \\${NC}"
echo -e "${GREEN}  --built-so-dir ../target/deploy \\${NC}"
echo -e "${GREEN}  --chain solanatestnet \\${NC}"
echo -e "${GREEN}  --context lunc-solana-ism \\${NC}"
echo -e "${GREEN}  --registry ~/.hyperlane/registry${NC}"
echo ""
echo -e "${YELLOW}⚠️  IMPORTANTE: Anote o Program ID retornado!${NC}"
echo ""
read -p "Pressione ENTER para ver o próximo passo..."

# ============================================================================
# PASSO 3
# ============================================================================
clear
echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${YELLOW}[PASSO 3/6] Verificar Owner do Novo ISM${NC}"
echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""
echo -e "${GREEN}# Substitua <NOVO_PROGRAM_ID> pelo Program ID do passo anterior${NC}"
echo -e "${GREEN}NOVO_ISM_PROGRAM_ID=\"<NOVO_PROGRAM_ID>\"${NC}"
echo ""
echo -e "${GREEN}cargo run -- \\${NC}"
echo -e "${GREEN}  -k /home/lunc/keys/solana-keypair-EMAYGfEyhywUyEX6kfG5FZZMfznmKXM8PbWpkJhJ9Jjd.json \\${NC}"
echo -e "${GREEN}  -u https://api.testnet.solana.com \\${NC}"
echo -e "${GREEN}  multisig-ism-message-id query \\${NC}"
echo -e "${GREEN}  --program-id \"\$NOVO_ISM_PROGRAM_ID\"${NC}"
echo ""
echo -e "${YELLOW}⚠️  Verifique se o owner é: EMAYGfEyhywUyEX6kfG5FZZMfznmKXM8PbWpkJhJ9Jjd${NC}"
echo ""
read -p "Pressione ENTER para ver o próximo passo..."

# ============================================================================
# PASSO 4
# ============================================================================
clear
echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${YELLOW}[PASSO 4/6] Configurar Validadores no Novo ISM${NC}"
echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""
echo -e "${GREEN}# Parâmetros:${NC}"
echo -e "${GREEN}#   Domain: 1325 (Terra Classic)${NC}"
echo -e "${GREEN}#   Validator: 242d8a855a8c932dec51f7999ae7d1e48b10c95e${NC}"
echo -e "${GREEN}#   Threshold: 1${NC}"
echo ""
echo -e "${GREEN}cargo run -- \\${NC}"
echo -e "${GREEN}  -k /home/lunc/keys/solana-keypair-EMAYGfEyhywUyEX6kfG5FZZMfznmKXM8PbWpkJhJ9Jjd.json \\${NC}"
echo -e "${GREEN}  -u https://api.testnet.solana.com \\${NC}"
echo -e "${GREEN}  multisig-ism-message-id set-validators-and-threshold \\${NC}"
echo -e "${GREEN}  --program-id \"\$NOVO_ISM_PROGRAM_ID\" \\${NC}"
echo -e "${GREEN}  --domain 1325 \\${NC}"
echo -e "${GREEN}  --validators 242d8a855a8c932dec51f7999ae7d1e48b10c95e \\${NC}"
echo -e "${GREEN}  --threshold 1${NC}"
echo ""
read -p "Pressione ENTER para ver o próximo passo..."

# ============================================================================
# PASSO 5
# ============================================================================
clear
echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${YELLOW}[PASSO 5/6] Verificar Configuração dos Validadores${NC}"
echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""
echo -e "${GREEN}cargo run -- \\${NC}"
echo -e "${GREEN}  -k /home/lunc/keys/solana-keypair-EMAYGfEyhywUyEX6kfG5FZZMfznmKXM8PbWpkJhJ9Jjd.json \\${NC}"
echo -e "${GREEN}  -u https://api.testnet.solana.com \\${NC}"
echo -e "${GREEN}  multisig-ism-message-id query \\${NC}"
echo -e "${GREEN}  --program-id \"\$NOVO_ISM_PROGRAM_ID\" \\${NC}"
echo -e "${GREEN}  --domains 1325${NC}"
echo ""
echo -e "${YELLOW}⚠️  Verifique se os validadores estão corretos na saída${NC}"
echo ""
read -p "Pressione ENTER para ver o próximo passo..."

# ============================================================================
# PASSO 6
# ============================================================================
clear
echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${YELLOW}[PASSO 6/6] Associar Novo ISM ao Warp Route${NC}"
echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""
echo -e "${GREEN}# Warp Route Program ID: 5BuTS1oZhUKJgpgwXJyz5VRdTq99SMvHm7hrPMctJk6x${NC}"
echo ""
echo -e "${GREEN}cargo run -- \\${NC}"
echo -e "${GREEN}  -k /home/lunc/keys/solana-keypair-EMAYGfEyhywUyEX6kfG5FZZMfznmKXM8PbWpkJhJ9Jjd.json \\${NC}"
echo -e "${GREEN}  -u https://api.testnet.solana.com \\${NC}"
echo -e "${GREEN}  token set-interchain-security-module \\${NC}"
echo -e "${GREEN}  --program-id 5BuTS1oZhUKJgpgwXJyz5VRdTq99SMvHm7hrPMctJk6x \\${NC}"
echo -e "${GREEN}  --ism \"\$NOVO_ISM_PROGRAM_ID\"${NC}"
echo ""
read -p "Pressione ENTER para ver o resumo final..."

# ============================================================================
# RESUMO
# ============================================================================
clear
echo -e "${GREEN}╔════════════════════════════════════════════════════════════════════════════╗${NC}"
echo -e "${GREEN}║                                                                        ║${NC}"
echo -e "${GREEN}║                         ✅ RESUMO FINAL                                 ║${NC}"
echo -e "${GREEN}║                                                                        ║${NC}"
echo -e "${GREEN}╚════════════════════════════════════════════════════════════════════════════╝${NC}"
echo ""
echo -e "${YELLOW}📝 Informações importantes:${NC}"
echo ""
echo -e "  ${CYAN}Novo ISM Program ID:${NC} (anotado no Passo 2)"
echo -e "  ${CYAN}Warp Route Program ID:${NC} 5BuTS1oZhUKJgpgwXJyz5VRdTq99SMvHm7hrPMctJk6x"
echo -e "  ${CYAN}Domain configurado:${NC} 1325 (Terra Classic)"
echo -e "  ${CYAN}Validator:${NC} 242d8a855a8c932dec51f7999ae7d1e48b10c95e"
echo -e "  ${CYAN}Threshold:${NC} 1"
echo ""
echo -e "${YELLOW}🔍 Próximos passos:${NC}"
echo ""
echo -e "  1. Verificar se o ISM está configurado no warp route:"
echo -e "     ${GREEN}cargo run -- -k \"\$KEYPAIR\" -u https://api.testnet.solana.com \\${NC}"
echo -e "     ${GREEN}  token query --program-id 5BuTS1oZhUKJgpgwXJyz5VRdTq99SMvHm7hrPMctJk6x synthetic${NC}"
echo ""
echo -e "  2. Testar transferência cross-chain Terra Classic → Solana"
echo ""
echo -e "${GREEN}╔════════════════════════════════════════════════════════════════════════════╗${NC}"
echo -e "${GREEN}║                                                                        ║${NC}"
echo -e "${GREEN}║  Para executar automaticamente, use:                                    ║${NC}"
echo -e "${GREEN}║  ${CYAN}./script/criar-novo-ism-solana.sh${NC}${GREEN}                                    ║${NC}"
echo -e "${GREEN}║                                                                        ║${NC}"
echo -e "${GREEN}╚════════════════════════════════════════════════════════════════════════════╝${NC}"
echo ""

