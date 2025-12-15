#!/bin/bash
# Script para configurar ISM com deploy MANUAL (evita erro --use-rpc)
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
ISM_KEYPAIR_DIR="$BASE_DIR/environments/testnet/multisig-ism-message-id/$CHAIN/$CONTEXT/keys"

echo "╔══════════════════════════════════════════════════════════════╗"
echo "║   CONFIGURAR ISM PARA WARP ROUTE: $WARP_ROUTE_NAME          ║"
echo "║   (Deploy Manual - Evita erro --use-rpc)                    ║"
echo "╚══════════════════════════════════════════════════════════════╝"
echo ""

# PASSO 1: Descobrir Program ID do Warp Route
echo "📋 [1/8] Descobrindo Program ID do Warp Route..."
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
echo "🔨 [2/8] Verificando compilação do programa ISM..."
cd "$BASE_DIR"

if [ ! -f "target/deploy/hyperlane_sealevel_multisig_ism_message_id.so" ]; then
    echo "Compilando programa ISM..."
    cargo build-sbf --manifest-path programs/ism/multisig-ism-message-id/Cargo.toml
fi
echo "✅ Programa ISM pronto"
echo ""

# PASSO 3: Gerar keypairs do ISM (se necessário)
echo "🔑 [3/8] Verificando keypairs do ISM..."
cd "$CLIENT_DIR"

# Executar comando para gerar keypairs (mesmo que falhe no deploy)
echo "Gerando keypairs do ISM..."
cargo run -- \
  -k "$KEYPAIR" \
  -u https://api.testnet.solana.com \
  multisig-ism-message-id deploy \
  --environment testnet \
  --environments-dir ../environments \
  --built-so-dir ../target/deploy \
  --chain "$CHAIN" \
  --context "$CONTEXT" \
  --registry ~/.hyperlane/registry 2>&1 | head -20 || true

# Verificar se os keypairs foram criados
PROGRAM_KEYPAIR="$ISM_KEYPAIR_DIR/hyperlane_sealevel_multisig_ism_message_id-keypair.json"
BUFFER_KEYPAIR="$ISM_KEYPAIR_DIR/hyperlane_sealevel_multisig_ism_message_id-buffer.json"

if [ ! -f "$PROGRAM_KEYPAIR" ] || [ ! -f "$BUFFER_KEYPAIR" ]; then
    echo "❌ Keypairs não encontrados em:"
    echo "   $PROGRAM_KEYPAIR"
    echo "   $BUFFER_KEYPAIR"
    echo "   Execute o comando deploy novamente para gerá-los"
    exit 1
fi

# Extrair Program ID do keypair
NEW_ISM_PROGRAM_ID=$(solana address -k "$PROGRAM_KEYPAIR" 2>/dev/null || echo "")

if [ -z "$NEW_ISM_PROGRAM_ID" ]; then
    echo "⚠️  Não foi possível extrair o Program ID do keypair"
    read -p "Informe o Program ID do ISM: " NEW_ISM_PROGRAM_ID
    if [ -z "$NEW_ISM_PROGRAM_ID" ]; then
        echo "❌ Program ID é obrigatório!"
        exit 1
    fi
fi

echo "✅ ISM Program ID: $NEW_ISM_PROGRAM_ID"
echo ""

# PASSO 4: Deploy MANUAL do ISM (sem --use-rpc)
echo "🚀 [4/8] Fazendo deploy MANUAL do programa ISM..."
echo "   (Isso evita o erro --use-rpc)"
echo ""

cd "$BASE_DIR"

solana program deploy target/deploy/hyperlane_sealevel_multisig_ism_message_id.so \
  --url https://api.testnet.solana.com \
  --keypair "$KEYPAIR" \
  --program-id "$PROGRAM_KEYPAIR" \
  --buffer "$BUFFER_KEYPAIR" \
  --upgrade-authority "$KEYPAIR"

if [ $? -eq 0 ]; then
    echo "✅ Deploy manual concluído!"
else
    echo "❌ Erro no deploy manual"
    exit 1
fi
echo ""

# PASSO 5: Inicializar o ISM
echo "🔧 [5/7] Inicializando o ISM..."
cd "$CLIENT_DIR"

cargo run -- \
  -k "$KEYPAIR" \
  -u https://api.testnet.solana.com \
  multisig-ism-message-id init \
  --program-id "$NEW_ISM_PROGRAM_ID"

if [ $? -eq 0 ]; then
    echo "✅ ISM inicializado"
else
    echo "⚠️  Erro na inicialização (pode já estar inicializado)"
fi
echo ""

# PASSO 6: Verificar Owner (opcional, pode pular se der erro)
echo "🔍 [6/7] Verificando owner do ISM..."
cargo run -- \
  -k "$KEYPAIR" \
  -u https://api.testnet.solana.com \
  multisig-ism-message-id query \
  --program-id "$NEW_ISM_PROGRAM_ID" 2>&1 || echo "⚠️  Query falhou (normal se ainda não configurado)"
echo ""

# PASSO 7: Configurar Validadores
echo "⚙️  [7/8] Configurando validadores..."
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

# PASSO 8: Associar ISM ao Warp Route
echo "🔗 [8/8] Associando ISM ao Warp Route..."
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

