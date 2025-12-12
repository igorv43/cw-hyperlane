# Corrigir Instalação do Solana 1.14.20

Este guia corrige a instalação do Solana para garantir que o Rust correto seja usado.

## Problema Identificado

- **Rust do sistema**: 1.84.0 (incompatível)
- **Rust do Solana**: Não encontrado ❌
- **cargo-build-sbf usando**: Rust 1.84.1 (errado)
- **Requerido**: Rust 1.75.0 (do Solana 1.14.20)

## Solução: Reinstalar Solana 1.14.20 Corretamente

### Passo 1: Remover Instalação Atual

```bash
# Remover instalação atual do Solana
rm -rf ~/.local/share/solana

# Limpar PATH (remover referências antigas)
# Editar ~/.bashrc ou ~/.zshrc e remover linhas relacionadas ao Solana
```

### Passo 2: Instalar Solana 1.14.20

```bash
# Opção A: Usar script do Hyperlane
cd ~/hyperlane-monorepo/rust/sealevel
bash programs/install-solana-1.14.20.sh

# Opção B: Instalação manual
sh -c "$(curl -sSfL https://release.anza.xyz/stable/install)"
solana-install init 1.14.20
```

### Passo 3: Verificar Instalação Completa

```bash
# Verificar versão do Solana
solana --version
# Deve mostrar: solana-cli 1.14.20

# Verificar Rust do Solana
~/.local/share/solana/install/active_release/bin/rustc --version
# Deve mostrar: rustc 1.75.0

# Verificar cargo-build-sbf
cargo-build-sbf --version
# Deve mostrar: solana-cargo-build-sbf 1.14.20
# E: rustc 1.75.0 (não 1.84.x)
```

### Passo 4: Configurar PATH

```bash
# Adicionar ao ~/.bashrc ou ~/.zshrc
export PATH="$HOME/.local/share/solana/install/active_release/bin:$PATH"

# Recarregar
source ~/.bashrc  # ou source ~/.zshrc

# Verificar
which solana
which cargo-build-sbf
# Deve apontar para: ~/.local/share/solana/install/active_release/bin/
```

### Passo 5: Verificar que cargo-build-sbf Usa Rust Correto

```bash
# O cargo-build-sbf DEVE usar o Rust do Solana automaticamente
# Verificar:
cargo-build-sbf --version 2>&1 | grep rustc
# Deve mostrar: rustc 1.75.0 (não 1.84.x)
```

## Se cargo-build-sbf Ainda Usar Rust Errado

### Forçar Uso do Rust do Solana

```bash
# Definir variável de ambiente
export RUSTC="$HOME/.local/share/solana/install/active_release/bin/rustc"

# Ou criar alias
alias cargo-build-sbf='RUSTC="$HOME/.local/share/solana/install/active_release/bin/rustc" cargo-build-sbf'

# Adicionar ao ~/.bashrc
echo 'export RUSTC="$HOME/.local/share/solana/install/active_release/bin/rustc"' >> ~/.bashrc
source ~/.bashrc
```

### Verificar Configuração do Cargo

```bash
# Criar ou editar ~/.cargo/config.toml
mkdir -p ~/.cargo
cat > ~/.cargo/config.toml << EOF
[build]
rustc = "$HOME/.local/share/solana/install/active_release/bin/rustc"

[target.bpf-unknown-unknown]
rustc = "$HOME/.local/share/solana/install/active_release/bin/rustc"
EOF
```

## Limpar e Recompilar

Após corrigir a instalação:

```bash
cd ~/hyperlane-monorepo/rust/sealevel

# Limpar tudo
cargo clean
rm -rf target/

# Verificar versões antes de compilar
echo "=== Verificando Versões ==="
solana --version
cargo-build-sbf --version
~/.local/share/solana/install/active_release/bin/rustc --version

# Tentar compilar
cargo build-sbf --manifest-path programs/hyperlane-sealevel-token/Cargo.toml
```

## Troubleshooting

### Se Solana 1.14.20 Não Instalar

```bash
# Tentar download direto
cd /tmp
wget https://github.com/solana-labs/solana/releases/download/v1.14.20/solana-release-x86_64-unknown-linux-gnu.tar.bz2
tar -xjf solana-release-x86_64-unknown-linux-gnu.tar.bz2
cd solana-release
./install.sh
```

### Se Rust do Solana Não For Encontrado

```bash
# Verificar se foi instalado
ls -la ~/.local/share/solana/install/active_release/bin/rustc

# Se não existir, reinstalar
solana-install init 1.14.20 --force
```

### Verificar Estrutura de Instalação

```bash
# Ver estrutura completa
tree -L 3 ~/.local/share/solana/install/ 2>/dev/null || ls -laR ~/.local/share/solana/install/

# Verificar se active_release aponta para versão correta
ls -la ~/.local/share/solana/install/active_release
```

## Comandos de Verificação Completa

```bash
#!/bin/bash
echo "=== Verificação Completa da Instalação do Solana ==="
echo ""

echo "1. Versão do Solana CLI:"
solana --version
echo ""

echo "2. Versão do cargo-build-sbf:"
cargo-build-sbf --version
echo ""

echo "3. Rust do Solana:"
~/.local/share/solana/install/active_release/bin/rustc --version 2>/dev/null || echo "❌ Rust do Solana não encontrado"
echo ""

echo "4. Rust do sistema:"
rustc --version
echo ""

echo "5. PATH:"
which solana
which cargo-build-sbf
echo ""

echo "6. Verificar se cargo-build-sbf usa Rust correto:"
cargo-build-sbf --version 2>&1 | grep rustc
echo ""

echo "=== Verificação Completa ==="
```

## Resultado Esperado

Após instalação correta:

```
=== Verificação Completa da Instalação do Solana ===

1. Versão do Solana CLI:
solana-cli 1.14.20

2. Versão do cargo-build-sbf:
solana-cargo-build-sbf 1.14.20
platform-tools v1.XX
rustc 1.75.0  ✅ (não 1.84.x)

3. Rust do Solana:
rustc 1.75.0

4. Rust do sistema:
rustc 1.84.0 (não importa, cargo-build-sbf usa o do Solana)

5. PATH:
/home/lunc/.local/share/solana/install/active_release/bin/solana
/home/lunc/.local/share/solana/install/active_release/bin/cargo-build-sbf

6. Verificar se cargo-build-sbf usa Rust correto:
rustc 1.75.0  ✅
```

## Referências

- [INSTALAR-SOLANA-1.14.20.md](./INSTALAR-SOLANA-1.14.20.md)
- [FIX-SOLANA-VERSION.md](./FIX-SOLANA-VERSION.md)

