#!/bin/bash
# Script para Vincular Remote Router na Solana (lunc-solana-v2) ao Terra Classic
# Copie e cole este script completo no terminal

set -e

# Variáveis
KEYPAIR="/home/lunc/keys/solana-keypair-EMAYGfEyhywUyEX6kfG5FZZMfznmKXM8PbWpkJhJ9Jjd.json"
WARP_ROUTE_PROGRAM_ID="HNxN3ZSBtD5J2nNF4AATMhuvTWVeHQf18nTtzKtsnkyw"
TERRA_DOMAIN="1325"
TERRA_WARP_BECH32="terra1zlm0h2xu6rhnjchn29hxnpvr74uxxqetar9y75zcehyx2mqezg9slj09ml"
TERRA_WARP_HEX="0x17f6fba8dcd0ef3962f3516e698583f57863032be8ca4f5058cdc8656c19120b"

BASE_DIR="$HOME/hyperlane-monorepo/rust/sealevel"
CLIENT_DIR="$BASE_DIR/client"

echo "╔══════════════════════════════════════════════════════════════╗"
echo "║   VINCULAR REMOTE ROUTER: Solana → Terra Classic            ║"
echo "║   Warp Route: lunc-solana-v2                                ║"
echo "╚══════════════════════════════════════════════════════════════╝"
echo ""

# PASSO 1: Verificar informações
echo "📋 [1/3] Verificando informações..."
echo ""
echo "   Warp Route Solana (lunc-solana-v2):"
echo "   Program ID: $WARP_ROUTE_PROGRAM_ID"
echo ""
echo "   Warp Route Terra Classic:"
echo "   Bech32: $TERRA_WARP_BECH32"
echo "   Hex: $TERRA_WARP_HEX"
echo "   Domain: $TERRA_DOMAIN"
echo ""

# PASSO 2: Vincular Remote Router
echo "🔗 [2/3] Vinculando Remote Router na Solana..."
echo ""
echo "   Comando que será executado:"
echo "   cargo run -- \\"
echo "     -k \"$KEYPAIR\" \\"
echo "     -u https://api.testnet.solana.com \\"
echo "     token enroll-remote-router \\"
echo "     --program-id $WARP_ROUTE_PROGRAM_ID \\"
echo "     $TERRA_DOMAIN \\"
echo "     $TERRA_WARP_HEX"
echo ""

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
    echo "✅ Remote Router vinculado com sucesso!"
else
    echo ""
    echo "❌ Erro ao vincular Remote Router"
    echo "⚠️  Verifique se você é o owner do warp route"
    exit 1
fi
echo ""

# PASSO 3: Verificar vinculação
echo "🔍 [3/3] Verificando vinculação do Remote Router..."
echo ""

cargo run -- \
  -k "$KEYPAIR" \
  -u https://api.testnet.solana.com \
  token query \
  --program-id "$WARP_ROUTE_PROGRAM_ID" \
  synthetic

echo ""
echo "╔══════════════════════════════════════════════════════════════╗"
echo "║   ✅ VINCULAÇÃO CONCLUÍDA COM SUCESSO!                      ║"
echo "╚══════════════════════════════════════════════════════════════╝"
echo ""
echo "📝 Informações:"
echo "   Warp Route Solana: $WARP_ROUTE_PROGRAM_ID"
echo "   Warp Route Terra Classic: $TERRA_WARP_BECH32"
echo "   Domain: $TERRA_DOMAIN"
echo ""
echo "🔍 Verificar na saída acima:"
echo "   Procure por 'remote_routers' e confirme que contém:"
echo "   1325: $TERRA_WARP_HEX"
echo ""
echo "📋 Próximos passos:"
echo "   1. Verificar se Terra Classic → Solana também está vinculado"
echo "   2. Testar transferência cross-chain"
echo ""

