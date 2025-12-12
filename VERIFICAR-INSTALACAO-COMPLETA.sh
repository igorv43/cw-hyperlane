#!/bin/bash

echo "=== Verificação Completa da Instalação ==="
echo ""

echo "1. Versão do Solana CLI:"
solana --version
echo ""

echo "2. Versão do cargo-build-sbf:"
cargo-build-sbf --version
echo ""

echo "3. Rust do sistema (não importa):"
rustc --version
echo ""

echo "4. Rust 1.75.0 instalado:"
~/.rustup/toolchains/1.75.0-x86_64-unknown-linux-gnu/bin/rustc --version 2>/dev/null || echo "❌ Não encontrado"
echo ""

echo "5. RUSTC configurado:"
if [ -n "$RUSTC" ]; then
    echo "RUSTC=$RUSTC"
    $RUSTC --version 2>/dev/null || echo "❌ RUSTC não funciona"
else
    echo "❌ RUSTC não configurado"
fi
echo ""

echo "6. rustup override no diretório sealevel:"
cd ~/hyperlane-monorepo/rust/sealevel 2>/dev/null || echo "❌ Diretório não encontrado"
rustup show 2>&1 | grep -A 2 "directory override" || echo "Nenhum override configurado"
echo ""

echo "7. PATH do Solana:"
which solana
which cargo-build-sbf
echo ""

echo "=== Verificação Completa ==="
echo ""
echo "✅ Se todas as verificações passaram, você pode compilar:"
echo "   cd ~/hyperlane-monorepo/rust/sealevel"
echo "   cargo build-sbf --manifest-path programs/hyperlane-sealevel-token/Cargo.toml"

