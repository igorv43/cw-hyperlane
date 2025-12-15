#!/bin/bash
# Script: get-mint-account-solana.sh
# Descrição: Extrai o mint account do warp route Solana

set -e

# Cores
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# Variáveis
KEYPAIR="${KEYPAIR:-/home/lunc/keys/solana-keypair-EMAYGfEyhywUyEX6kfG5FZZMfznmKXM8PbWpkJhJ9Jjd.json}"
PROGRAM_ID="${PROGRAM_ID:-5BuTS1oZhUKJgpgwXJyz5VRdTq99SMvHm7hrPMctJk6x}"
RPC_URL="${RPC_URL:-https://api.testnet.solana.com}"
CLIENT_DIR="${CLIENT_DIR:-$HOME/hyperlane-monorepo/rust/sealevel/client}"

echo -e "${BLUE}╔══════════════════════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║     LOCALIZAR MINT ACCOUNT DO WARP ROUTE SOLANA             ║${NC}"
echo -e "${BLUE}╚══════════════════════════════════════════════════════════════╝${NC}"
echo ""

# Verificar se o diretório do client existe
if [ ! -d "$CLIENT_DIR" ]; then
  echo -e "${RED}❌ Erro: Diretório do client não encontrado: $CLIENT_DIR${NC}"
  echo -e "${YELLOW}   Defina CLIENT_DIR ou ajuste o caminho${NC}"
  exit 1
fi

# Verificar se o keypair existe
if [ ! -f "$KEYPAIR" ]; then
  echo -e "${RED}❌ Erro: Keypair não encontrado: $KEYPAIR${NC}"
  echo -e "${YELLOW}   Defina KEYPAIR ou ajuste o caminho${NC}"
  exit 1
fi

echo -e "${BLUE}📋 Configuração:${NC}"
echo -e "   Program ID: ${GREEN}$PROGRAM_ID${NC}"
echo -e "   RPC URL: ${GREEN}$RPC_URL${NC}"
echo -e "   Keypair: ${GREEN}$KEYPAIR${NC}"
echo ""

cd "$CLIENT_DIR"

echo -e "${BLUE}🔍 Buscando mint account...${NC}"
echo ""

# Query do token sintético
MINT_ACCOUNT=$(cargo run -- \
  -k "$KEYPAIR" \
  -u "$RPC_URL" \
  token query \
  --program-id "$PROGRAM_ID" \
  synthetic 2>/dev/null | jq -r '.mint // empty')

if [ -z "$MINT_ACCOUNT" ] || [ "$MINT_ACCOUNT" = "null" ]; then
  echo -e "${RED}❌ Erro: Não foi possível encontrar o mint account${NC}"
  echo ""
  echo -e "${YELLOW}Possíveis causas:${NC}"
  echo "  1. O warp route não foi inicializado"
  echo "  2. O Program ID está incorreto"
  echo "  3. Problema de conexão com a RPC"
  echo ""
  echo -e "${YELLOW}Verifique:${NC}"
  echo "  solana program show $PROGRAM_ID --url $RPC_URL"
  exit 1
fi

echo -e "${GREEN}✅ Mint Account encontrado!${NC}"
echo ""
echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${GREEN}   Mint Address:${NC} $MINT_ACCOUNT"
echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""

# Obter informações completas
echo -e "${BLUE}📋 Informações completas do token:${NC}"
echo ""

TOKEN_INFO=$(cargo run -- \
  -k "$KEYPAIR" \
  -u "$RPC_URL" \
  token query \
  --program-id "$PROGRAM_ID" \
  synthetic 2>/dev/null)

echo "$TOKEN_INFO" | jq '{
  mint,
  name,
  symbol,
  decimals,
  total_supply
}'

echo ""
echo -e "${BLUE}🔗 Links úteis:${NC}"
echo -e "   Explorer: ${GREEN}https://explorer.solana.com/address/$MINT_ACCOUNT?cluster=testnet${NC}"
echo ""

# Verificar supply usando spl-token (se disponível)
if command -v spl-token &> /dev/null; then
  echo -e "${BLUE}📊 Verificando supply...${NC}"
  SUPPLY=$(spl-token supply "$MINT_ACCOUNT" --url "$RPC_URL" 2>/dev/null | head -n 1 || echo "N/A")
  echo -e "   Supply: ${GREEN}$SUPPLY${NC}"
  echo ""
fi

# Exportar variável para uso em outros scripts
export SOLANA_MINT_ACCOUNT="$MINT_ACCOUNT"
echo -e "${YELLOW}💡 Dica: A variável SOLANA_MINT_ACCOUNT foi exportada${NC}"
echo -e "   Use: ${GREEN}\$SOLANA_MINT_ACCOUNT${NC} em outros scripts"
echo ""

