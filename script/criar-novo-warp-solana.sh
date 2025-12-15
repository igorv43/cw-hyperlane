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
    "uri": "https://raw.githubusercontent.com/igorv43/cw-hyperlane/refs/heads/main/warp/solana/metadata.json"
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

# PASSO 5: Atualizar metadata.json no GitHub (se necessário)
echo "📝 PASSO 5: Verificando metadata.json..."
METADATA_FILE="$HOME/cw-hyperlane/warp/solana/metadata.json"
if [ -f "$METADATA_FILE" ]; then
  SYMBOL=$(jq -r '.symbol' "$METADATA_FILE")
  if [ "$SYMBOL" != "wwwwwLUNC" ]; then
    echo "⚠️  Símbolo no metadata.json é '$SYMBOL', atualizando para 'wwwwwLUNC'..."
    jq '.symbol = "wwwwwLUNC"' "$METADATA_FILE" > "$METADATA_FILE.tmp" && mv "$METADATA_FILE.tmp" "$METADATA_FILE"
    echo "✅ metadata.json atualizado"
    echo "   ⚠️  IMPORTANTE: Faça commit e push do metadata.json antes de continuar!"
    echo "   git -C $HOME/cw-hyperlane add warp/solana/metadata.json"
    echo "   git -C $HOME/cw-hyperlane commit -m 'Update symbol to wwwwwLUNC'"
    echo "   git -C $HOME/cw-hyperlane push"
    echo ""
    read -p "Pressione Enter após fazer push do metadata.json..."
  else
    echo "✅ metadata.json já está correto (symbol: wwwwwLUNC)"
  fi
else
  echo "⚠️  metadata.json não encontrado em $METADATA_FILE"
fi
echo ""

# PASSO 6: Deploy manual do programa (para evitar erro --use-rpc)
echo "🚀 PASSO 6: Fazendo deploy MANUAL do programa..."
echo "   (Isso evita o erro --use-rpc)"
echo ""

cd ~/hyperlane-monorepo/rust/sealevel

PROGRAM_KEYPAIR="../environments/testnet/warp-routes/$WARP_ROUTE_NAME/keys/hyperlane_sealevel_token-solanatestnet-keypair.json"
BUFFER_KEYPAIR="../environments/testnet/warp-routes/$WARP_ROUTE_NAME/keys/hyperlane_sealevel_token-solanatestnet-buffer.json"

# Verificar se os keypairs foram criados
if [ ! -f "$PROGRAM_KEYPAIR" ]; then
  echo "⚠️  Keypairs não encontrados. Executando cargo run para gerá-los..."
  cd client
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
    --ata-payer-funding-amount 5000000 2>&1 | head -50
  echo ""
  echo "⚠️  O comando acima deve ter gerado os keypairs. Agora faça o deploy manual:"
  echo ""
fi

cd ~/hyperlane-monorepo/rust/sealevel

echo "📤 Deploy manual do programa..."
solana program deploy target/deploy/hyperlane_sealevel_token.so \
  --url https://api.testnet.solana.com \
  --keypair "$KEYPAIR" \
  --program-id "$PROGRAM_KEYPAIR" \
  --buffer "$BUFFER_KEYPAIR" \
  --upgrade-authority "$KEYPAIR"

echo ""
echo "✅ Deploy manual concluído!"
echo ""

# PASSO 7: Continuar com inicialização do warp route
echo "🚀 PASSO 7: Inicializando warp route..."
echo ""

cd ~/hyperlane-monorepo/rust/sealevel/client

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
