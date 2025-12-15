#!/bin/bash
# Script SIMPLIFICADO para Vincular Remote Router na Solana (lunc-solana-v2)
# Copie e cole este script completo no terminal

set -e

# Variáveis
KEYPAIR="/home/lunc/keys/solana-keypair-EMAYGfEyhywUyEX6kfG5FZZMfznmKXM8PbWpkJhJ9Jjd.json"
WARP_ROUTE_PROGRAM_ID="HNxN3ZSBtD5J2nNF4AATMhuvTWVeHQf18nTtzKtsnkyw"
TERRA_DOMAIN="1325"
TERRA_WARP_HEX="0x17f6fba8dcd0ef3962f3516e698583f57863032be8ca4f5058cdc8656c19120b"

CLIENT_DIR="$HOME/hyperlane-monorepo/rust/sealevel/client"

echo "╔══════════════════════════════════════════════════════════════╗"
echo "║   VINCULAR REMOTE ROUTER: Solana → Terra Classic            ║"
echo "║   Warp Route: lunc-solana-v2                                ║"
echo "╚══════════════════════════════════════════════════════════════╝"
echo ""

echo "📋 Informações:"
echo "   Warp Route Solana: $WARP_ROUTE_PROGRAM_ID"
echo "   Terra Classic Domain: $TERRA_DOMAIN"
echo "   Terra Classic Router: $TERRA_WARP_HEX"
echo ""

echo "🔗 [1/2] Vinculando Remote Router..."
cd "$CLIENT_DIR"

cargo run -- \
  -k "$KEYPAIR" \
  -u https://api.testnet.solana.com \
  token enroll-remote-router \
  --program-id "$WARP_ROUTE_PROGRAM_ID" \
  "$TERRA_DOMAIN" \
  "$TERRA_WARP_HEX"

if [ $? -eq 0 ]; then
    echo ""
    echo "✅ Remote Router vinculado!"
else
    echo ""
    echo "❌ Erro ao vincular"
    exit 1
fi
echo ""

echo "🔍 [2/2] Verificando vinculação..."
cargo run -- \
  -k "$KEYPAIR" \
  -u https://api.testnet.solana.com \
  token query \
  --program-id "$WARP_ROUTE_PROGRAM_ID" \
  synthetic

echo ""
echo "╔══════════════════════════════════════════════════════════════╗"
echo "║   ✅ CONCLUÍDO!                                              ║"
echo "╚══════════════════════════════════════════════════════════════╝"
echo ""
echo "📝 Verifique na saída acima se 'remote_routers' contém:"
echo "   1325: $TERRA_WARP_HEX"
echo ""

