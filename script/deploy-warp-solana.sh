#!/bin/bash

set -e

# Variáveis
PROGRAM_ID="5BuTS1oZhUKJgpgwXJyz5VRdTq99SMvHm7hrPMctJk6x"
KEYPAIR="/home/lunc/keys/solana-keypair-EMAYGfEyhywUyEX6kfG5FZZMfznmKXM8PbWpkJhJ9Jjd.json"
WARP_ROUTE_NAME="lunc-solana"

# Caminhos corretos a partir de client/
ENVIRONMENTS_DIR="../environments"
TOKEN_CONFIG="../environments/testnet/warp-routes/lunc-solana/token-config.json"
BUILT_SO_DIR="../target/deploy"
REGISTRY_DIR="$HOME/.hyperlane/registry"

echo "=== Verificando arquivos e diretórios ==="
cd ~/hyperlane-monorepo/rust/sealevel/client

# Verificar se estamos no diretório correto
if [ ! -d "../environments" ]; then
    echo "❌ Erro: Diretório ../environments não encontrado"
    echo "   Execute este script de: ~/hyperlane-monorepo/rust/sealevel/client"
    exit 1
fi

# Verificar token-config.json
if [ ! -f "$TOKEN_CONFIG" ]; then
    echo "❌ Erro: Arquivo $TOKEN_CONFIG não encontrado"
    exit 1
fi
echo "✅ token-config.json encontrado"

# Verificar built-so-dir
if [ ! -f "$BUILT_SO_DIR/hyperlane_sealevel_token.so" ]; then
    echo "❌ Erro: Arquivo $BUILT_SO_DIR/hyperlane_sealevel_token.so não encontrado"
    echo "   Execute primeiro: cargo build-sbf --manifest-path programs/hyperlane-sealevel-token/Cargo.toml"
    exit 1
fi
echo "✅ hyperlane_sealevel_token.so encontrado"

# Verificar/criar registry
if [ ! -f "$REGISTRY_DIR/chains/metadata.yaml" ]; then
    echo "⚠️  Criando registry/chains/metadata.yaml..."
    mkdir -p "$REGISTRY_DIR/chains"
    cat > "$REGISTRY_DIR/chains/metadata.yaml" << EOF
solanatestnet:
  chainId: 101
  domainId: 1399811150  # Solana Testnet (Mainnet uses 1399811149)
  name: solanatestnet
  nativeToken:
    decimals: 9
    name: SOL
    symbol: SOL
  protocol: sealevel
  rpcUrls:
    - http: https://api.testnet.solana.com
  blocks:
    confirmations: 1
    estimateBlockTime: 1
  isTestnet: true
EOF
    echo "✅ metadata.yaml criado"
else
    echo "✅ metadata.yaml já existe"
fi

# Verificar keypair
if [ ! -f "$KEYPAIR" ]; then
    echo "❌ Erro: Keypair $KEYPAIR não encontrado"
    exit 1
fi
echo "✅ Keypair encontrado"

echo ""
echo "=== Executando deploy do warp route ==="
echo ""

# Executar deploy
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
  --ata-payer-funding-amount 10000000

echo ""
echo "=== Deploy concluído! ==="
