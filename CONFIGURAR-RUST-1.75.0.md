# Configurar Rust 1.75.0 para Solana 1.14.20

## Problema

O Solana 1.14.20 não inclui o Rust. O `cargo-build-sbf` está usando o Rust do sistema (1.84.0), que é incompatível e causa:
- Erro de compilação do `protobuf` (trait `Stdin: Read` não satisfeito)
- Stack overflow (funções usando Rust 1.84.x são maiores)

## Solução: Instalar Rust 1.75.0

### Passo 1: Instalar Rust 1.75.0 via rustup

```bash
# Instalar Rust 1.75.0
rustup toolchain install 1.75.0

# Verificar instalação
rustup toolchain list
# Deve mostrar: 1.75.0-x86_64-unknown-linux-gnu

# Verificar versão
~/.rustup/toolchains/1.75.0-x86_64-unknown-linux-gnu/bin/rustc --version
# Deve mostrar: rustc 1.75.0
```

### Passo 2: Configurar cargo-build-sbf para Usar Rust 1.75.0

```bash
# Criar script wrapper para cargo-build-sbf
cat > ~/.local/share/solana/install/active_release/bin/cargo-build-sbf-wrapper << 'EOF'
#!/bin/bash
export RUSTC="$HOME/.rustup/toolchains/1.75.0-x86_64-unknown-linux-gnu/bin/rustc"
export CARGO="$HOME/.rustup/toolchains/1.75.0-x86_64-unknown-linux-gnu/bin/cargo"
exec "$HOME/.local/share/solana/install/active_release/bin/cargo-build-sbf" "$@"
EOF

chmod +x ~/.local/share/solana/install/active_release/bin/cargo-build-sbf-wrapper

# OU configurar via variável de ambiente global
echo 'export RUSTC="$HOME/.rustup/toolchains/1.75.0-x86_64-unknown-linux-gnu/bin/rustc"' >> ~/.bashrc
echo 'export CARGO="$HOME/.rustup/toolchains/1.75.0-x86_64-unknown-linux-gnu/bin/cargo"' >> ~/.bashrc
source ~/.bashrc
```

### Passo 3: Verificar Configuração

```bash
# Verificar que RUSTC aponta para 1.75.0
echo $RUSTC
# Deve mostrar: /home/lunc/.rustup/toolchains/1.75.0-x86_64-unknown-linux-gnu/bin/rustc

# Verificar versão
$RUSTC --version
# Deve mostrar: rustc 1.75.0

# Verificar cargo-build-sbf (deve usar Rust 1.75.0)
cd ~/hyperlane-monorepo/rust/sealevel
RUSTC="$HOME/.rustup/toolchains/1.75.0-x86_64-unknown-linux-gnu/bin/rustc" \
  cargo-build-sbf --version 2>&1 | grep -i rust || echo "Verificar manualmente"
```

### Passo 4: Testar Compilação

```bash
cd ~/hyperlane-monorepo/rust/sealevel

# Limpar builds anteriores
cargo clean
rm -rf target/

# Compilar com Rust 1.75.0
export RUSTC="$HOME/.rustup/toolchains/1.75.0-x86_64-unknown-linux-gnu/bin/rustc"
export CARGO="$HOME/.rustup/toolchains/1.75.0-x86_64-unknown-linux-gnu/bin/cargo"

cargo build-sbf --manifest-path programs/hyperlane-sealevel-token/Cargo.toml
```

## Alternativa: Usar rustup override

```bash
cd ~/hyperlane-monorepo/rust/sealevel

# Configurar Rust 1.75.0 para este diretório
rustup override set 1.75.0

# Verificar
rustup show
# Deve mostrar: 1.75.0-x86_64-unknown-linux-gnu (directory override)

# Compilar
cargo build-sbf --manifest-path programs/hyperlane-sealevel-token/Cargo.toml
```

## Verificação Completa

```bash
#!/bin/bash
echo "=== Verificação Rust 1.75.0 ==="
echo ""

echo "1. Rust do sistema:"
rustc --version
echo ""

echo "2. Rust 1.75.0 instalado:"
~/.rustup/toolchains/1.75.0-x86_64-unknown-linux-gnu/bin/rustc --version 2>/dev/null || echo "❌ Não encontrado"
echo ""

echo "3. RUSTC configurado:"
echo $RUSTC
if [ -n "$RUSTC" ]; then
    $RUSTC --version
else
    echo "❌ RUSTC não configurado"
fi
echo ""

echo "4. Solana CLI:"
solana --version
echo ""

echo "5. cargo-build-sbf:"
cargo-build-sbf --version
echo ""

echo "6. rustup override (se configurado):"
cd ~/hyperlane-monorepo/rust/sealevel
rustup show 2>&1 | grep -A 2 "directory override" || echo "Nenhum override configurado"
echo ""

echo "=== Verificação Completa ==="
```

## Resultado Esperado

Após configuração correta:

```
=== Verificação Rust 1.75.0 ===

1. Rust do sistema:
rustc 1.84.0 (não importa)

2. Rust 1.75.0 instalado:
rustc 1.75.0 ✅

3. RUSTC configurado:
/home/lunc/.rustup/toolchains/1.75.0-x86_64-unknown-linux-gnu/bin/rustc
rustc 1.75.0 ✅

4. Solana CLI:
solana-cli 1.14.20 ✅

5. cargo-build-sbf:
solana-cargo-build-sbf 1.14.20 ✅

6. rustup override (se configurado):
1.75.0-x86_64-unknown-linux-gnu (directory override) ✅
```

## Troubleshooting

### Se rustup não estiver instalado

```bash
# Instalar rustup
curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh
source ~/.cargo/env
```

### Se Rust 1.75.0 não instalar

```bash
# Tentar instalar versão específica
rustup toolchain install 1.75.0-x86_64-unknown-linux-gnu

# Ou usar componente específico
rustup component add rustc --toolchain 1.75.0
```

### Se cargo-build-sbf ainda usar Rust errado

```bash
# Forçar via alias
alias cargo-build-sbf='RUSTC="$HOME/.rustup/toolchains/1.75.0-x86_64-unknown-linux-gnu/bin/rustc" cargo-build-sbf'

# Adicionar ao ~/.bashrc
echo 'alias cargo-build-sbf="RUSTC=\"$HOME/.rustup/toolchains/1.75.0-x86_64-unknown-linux-gnu/bin/rustc\" cargo-build-sbf"' >> ~/.bashrc
source ~/.bashrc
```

## Referências

- [INSTALAR-SOLANA-1.14.20.md](./INSTALAR-SOLANA-1.14.20.md)
- [CORRIGIR-INSTALACAO-SOLANA.md](./CORRIGIR-INSTALACAO-SOLANA.md)

