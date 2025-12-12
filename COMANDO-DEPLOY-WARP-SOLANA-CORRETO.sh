#!/bin/bash

# ⚠️ IMPORTANTE: Execute este script de ~/hyperlane-monorepo/rust/sealevel/client

cd ~/hyperlane-monorepo/rust/sealevel/client

# Variáveis
KEYPAIR="/home/lunc/keys/solana-keypair-EMAYGfEyhywUyEX6kfG5FZZMfznmKXM8PbWpkJhJ9Jjd.json"
WARP_ROUTE_NAME="lunc-solana"

# ⚠️ Caminhos corretos: Use ../ (um nível acima de client/), não ../../
ENVIRONMENTS_DIR="../environments"
TOKEN_CONFIG="../environments/testnet/warp-routes/lunc-solana/token-config.json"
BUILT_SO_DIR="../target/deploy"
REGISTRY_DIR="$HOME/.hyperlane/registry"

echo "=== Deploy Warp Route Solana ==="
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

