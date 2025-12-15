#!/bin/bash
# Script DIRETO para configurar ISM - SEM PAUSAS
# Copie e cole este script completo no terminal

set -e

# Variáveis
KEYPAIR="/home/lunc/keys/solana-keypair-EMAYGfEyhywUyEX6kfG5FZZMfznmKXM8PbWpkJhJ9Jjd.json"
CHAIN="solanatestnet"
CONTEXT="lunc-solana-v2-ism"
WARP_ROUTE_NAME="lunc-solana-v2"
DOMAIN="1325"
VALIDATOR="242d8a855a8c932dec51f7999ae7d1e48b10c95e"
THRESHOLD="1"

BASE_DIR="$HOME/hyperlane-monorepo/rust/sealevel"
CLIENT_DIR="$BASE_DIR/client"
WARP_ROUTE_DIR="$BASE_DIR/environments/testnet/warp-routes/$WARP_ROUTE_NAME"

echo "╔══════════════════════════════════════════════════════════════╗"
echo "║   CONFIGURAR ISM PARA WARP ROUTE: $WARP_ROUTE_NAME          ║"
echo "╚══════════════════════════════════════════════════════════════╝"
echo ""

# PASSO 1: Descobrir Program ID
echo "📋 [1/6] Descobrindo Program ID..."
WARP_ROUTE_PROGRAM_ID=""

if [ -f "$WARP_ROUTE_DIR/program-ids.json" ]; then
    WARP_ROUTE_PROGRAM_ID=$(jq -r ".${CHAIN}.base58" "$WARP_ROUTE_DIR/program-ids.json" 2>/dev/null || echo "")
fi

if [ -z "$WARP_ROUTE_PROGRAM_ID" ] || [ "$WARP_ROUTE_PROGRAM_ID" == "null" ]; then
    echo "⚠️  Program ID não encontrado. Por favor, informe:"
    read -p "Program ID do Warp Route: " WARP_ROUTE_PROGRAM_ID
    if [ -z "$WARP_ROUTE_PROGRAM_ID" ]; then
        echo "❌ Program ID é obrigatório!"
        exit 1
    fi
fi

echo "✅ Warp Route Program ID: $WARP_ROUTE_PROGRAM_ID"
echo ""

# PASSO 2: Verificar/Compilar ISM
echo "🔨 [2/6] Verificando compilação do programa ISM..."
cd "$BASE_DIR"

if [ ! -f "target/deploy/hyperlane_sealevel_multisig_ism_message_id.so" ]; then
    echo "Compilando programa ISM..."
    cargo build-sbf --manifest-path programs/ism/multisig-ism-message-id/Cargo.toml
fi
echo "✅ Programa ISM pronto"
echo ""

# PASSO 3: Deploy do ISM
echo "🚀 [3/6] Fazendo deploy do novo ISM..."
echo "⏳ Isso pode levar alguns minutos - aguarde..."
cd "$CLIENT_DIR"

TEMP_OUTPUT=$(mktemp)

# Executar deploy mostrando output em tempo real
cargo run -- \
  -k "$KEYPAIR" \
  -u https://api.testnet.solana.com \
  multisig-ism-message-id deploy \
  --environment testnet \
  --environments-dir ../environments \
  --built-so-dir ../target/deploy \
  --chain "$CHAIN" \
  --context "$CONTEXT" \
  --registry ~/.hyperlane/registry 2>&1 | tee "$TEMP_OUTPUT"

DEPLOY_OUTPUT=$(cat "$TEMP_OUTPUT")
rm -f "$TEMP_OUTPUT"

NEW_ISM_PROGRAM_ID=$(echo "$DEPLOY_OUTPUT" | grep -oP 'program ID \K[0-9A-Za-z]{32,44}' | head -1)

if [ -z "$NEW_ISM_PROGRAM_ID" ]; then
    NEW_ISM_PROGRAM_ID=$(echo "$DEPLOY_OUTPUT" | grep -i "program id" | grep -oP '[0-9A-Za-z]{32,44}' | head -1)
fi

if [ -z "$NEW_ISM_PROGRAM_ID" ]; then
    echo ""
    echo "⚠️  Não foi possível extrair o Program ID automaticamente"
    echo "Por favor, copie o Program ID do output acima"
    read -p "Cole o Program ID do ISM aqui: " NEW_ISM_PROGRAM_ID
    if [ -z "$NEW_ISM_PROGRAM_ID" ]; then
        echo "❌ Program ID é obrigatório!"
        exit 1
    fi
fi

echo ""
echo "✅ Novo ISM Program ID: $NEW_ISM_PROGRAM_ID"
echo ""

# PASSO 4: Verificar Owner
echo "🔍 [4/6] Verificando owner do ISM..."
cargo run -- \
  -k "$KEYPAIR" \
  -u https://api.testnet.solana.com \
  multisig-ism-message-id query \
  --program-id "$NEW_ISM_PROGRAM_ID"
echo ""

# PASSO 5: Configurar Validadores
echo "⚙️  [5/6] Configurando validadores..."
echo "   Domain: $DOMAIN (Terra Classic)"
echo "   Validator: $VALIDATOR"
echo "   Threshold: $THRESHOLD"
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
    echo "✅ Validadores configurados"
else
    echo "❌ Erro ao configurar validadores"
    exit 1
fi
echo ""

# PASSO 6: Associar ISM ao Warp Route
echo "🔗 [6/6] Associando ISM ao Warp Route..."
echo "   Warp Route: $WARP_ROUTE_PROGRAM_ID"
echo "   ISM: $NEW_ISM_PROGRAM_ID"
echo ""

cargo run -- \
  -k "$KEYPAIR" \
  -u https://api.testnet.solana.com \
  token set-interchain-security-module \
  --program-id "$WARP_ROUTE_PROGRAM_ID" \
  --ism "$NEW_ISM_PROGRAM_ID"

if [ $? -eq 0 ]; then
    echo ""
    echo "╔══════════════════════════════════════════════════════════════╗"
    echo "║   ✅ CONFIGURAÇÃO CONCLUÍDA COM SUCESSO!                     ║"
    echo "╚══════════════════════════════════════════════════════════════╝"
    echo ""
    echo "📝 Informações:"
    echo "   Warp Route Program ID: $WARP_ROUTE_PROGRAM_ID"
    echo "   ISM Program ID: $NEW_ISM_PROGRAM_ID"
    echo "   Domain: $DOMAIN (Terra Classic)"
    echo "   Validator: $VALIDATOR"
    echo "   Threshold: $THRESHOLD"
    echo ""
    echo "🔍 Verificar configuração:"
    echo "   cargo run -- -k \"$KEYPAIR\" -u https://api.testnet.solana.com \\"
    echo "     token query --program-id $WARP_ROUTE_PROGRAM_ID synthetic"
    echo ""
else
    echo ""
    echo "❌ Erro ao associar ISM ao Warp Route"
    echo "⚠️  Verifique se você é o owner do warp route"
    exit 1
fi

