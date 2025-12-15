#!/bin/bash
# Script para criar novo warp route Solana com símbolo wwwwwLUNC

set -e

echo "╔══════════════════════════════════════════════════════════════╗"
echo "║   CRIAR NOVO WARP ROUTE SOLANA (wwwwwLUNC)                  ║"
echo "╚══════════════════════════════════════════════════════════════╝"
echo ""

# PASSO 1: Criar novo diretório
echo "📁 PASSO 1: Criando novo diretório..."
cd ~/hyperlane-monorepo/rust/sealevel/environments/testnet/warp-routes
mkdir -p lunc-solana-v2
echo "✅ Diretório criado: lunc-solana-v2"
echo ""

# PASSO 2: Criar token-config.json
echo "📝 PASSO 2: Criando token-config.json..."
cat > lunc-solana-v2/token-config.json << 'JSONEOF'
{
  "solanatestnet": {
    "type": "synthetic",
    "name": "Luna Classic",
    "symbol": "wwwwwLUNC",
    "decimals": 6,
    "totalSupply": "0",
    "interchainGasPaymaster": "9SQVtTNsbipdMzumhzi6X8GwojiSMwBfqAhS7FgyTcqy",
    "uri": "https://raw.githubusercontent.com/igorv43/cw-hyperlane/main/warp/solana/metadata.json"
  }
}
JSONEOF
echo "✅ token-config.json criado com símbolo: wwwwwLUNC"
echo ""

# PASSO 3: Verificar que não existe program-ids.json
echo "🔍 PASSO 3: Verificando que não existe program-ids.json..."
if [ -f "lunc-solana-v2/program-ids.json" ]; then
  echo "⚠️  ATENÇÃO: program-ids.json existe! Removendo..."
  rm -f lunc-solana-v2/program-ids.json
  echo "✅ program-ids.json removido (novo será gerado)"
else
  echo "✅ Nenhum program-ids.json encontrado (correto)"
fi
echo ""

# PASSO 4: Preparar variáveis para deploy
echo "⚙️  PASSO 4: Preparando variáveis..."
cd ~/hyperlane-monorepo/rust/sealevel/client

KEYPAIR="/home/lunc/keys/solana-keypair-EMAYGfEyhywUyEX6kfG5FZZMfznmKXM8PbWpkJhJ9Jjd.json"
WARP_ROUTE_NAME="lunc-solana-v2"
ENVIRONMENTS_DIR="../environments"
TOKEN_CONFIG="../environments/testnet/warp-routes/lunc-solana-v2/token-config.json"
BUILT_SO_DIR="../target/deploy"
REGISTRY_DIR="$HOME/.hyperlane/registry"

echo "   KEYPAIR: $KEYPAIR"
echo "   WARP_ROUTE_NAME: $WARP_ROUTE_NAME"
echo "   TOKEN_CONFIG: $TOKEN_CONFIG"
echo ""

# PASSO 5: Deploy
echo "🚀 PASSO 5: Iniciando deploy do novo warp route..."
echo "   (Isso pode levar alguns minutos...)"
echo ""

cargo run -- \
  -k "$KEYPAIR" \
  -u https://api.testnet.solana.com \
  warp-route deploy \
  --warp-route-name "$WARP_ROUTE_NAME" \
  --environment testnet \
  --environments-dir "$ENVIRONMENTS_DIR" \
  --token-config-file "$TOKEN_CONFIG" \
  --built-so-dir "$BUILT_SO_DIR" \
  --registry "$REGISTRY_DIR" \
  --ata-payer-funding-amount 5000000

echo ""
echo "✅ Deploy concluído!"
echo ""
echo "📋 PRÓXIMOS PASSOS:"
echo "   1. Anote o novo Program ID gerado no output acima"
echo "   2. Anote o Mint Account (se foi criado)"
echo "   3. Verifique o novo warp route com:"
echo "      cargo run -- -k \"$KEYPAIR\" -u https://api.testnet.solana.com token query --program-id <NOVO_PROGRAM_ID> synthetic"
echo ""
