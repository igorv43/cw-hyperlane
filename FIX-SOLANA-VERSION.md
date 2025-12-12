# Fix: Versão do Solana Incompatível

Este documento explica como corrigir a versão do Solana para compilar programas Hyperlane sem alterar o código fonte.

## Problema

Você está usando:
- **Solana CLI**: `2.0.3` ❌ (muito nova, incompatível)
- **Hyperlane requer**: `1.14.20` ✅

O erro de stack overflow está ocorrendo porque a versão 2.0.3 do Solana tem mudanças que causam problemas de compilação com o código do Hyperlane.

## Solução: Instalar Solana 1.14.20

### Passo 1: Verificar Versão Atual

```bash
solana --version
# Saída atual: solana-cli 2.0.3
```

### Passo 2: Instalar Solana 1.14.20

O Hyperlane fornece um script de instalação. Use-o:

```bash
cd ~/hyperlane-monorepo/rust/sealevel

# Executar script de instalação do Solana 1.14.20
bash programs/install-solana-1.14.20.sh
```

**OU instalar manualmente:**

```bash
# Remover instalação atual (opcional, mas recomendado)
rm -rf ~/.local/share/solana

# Instalar Solana 1.14.20
sh -c "$(curl -sSfL https://release.anza.xyz/stable/install)"
solana-install init 1.14.20

# Verificar instalação
solana --version
# Deve mostrar: solana-cli 1.14.20
```

### Passo 3: Verificar cargo-build-sbf

```bash
# Verificar versão do cargo-build-sbf
cargo-build-sbf --version

# Deve mostrar algo como:
# solana-cargo-build-sbf 1.14.20
# platform-tools v1.XX
# rustc 1.75.0
```

### Passo 4: Atualizar PATH (Se Necessário)

```bash
# Adicionar ao ~/.bashrc ou ~/.zshrc
export PATH="$HOME/.local/share/solana/install/active_release/bin:$PATH"

# Recarregar
source ~/.bashrc  # ou source ~/.zshrc
```

### Passo 5: Limpar e Recompilar

```bash
cd ~/hyperlane-monorepo/rust/sealevel

# Limpar build anterior
cargo clean

# Tentar compilar novamente
cargo build-sbf --manifest-path programs/hyperlane-sealevel-token/Cargo.toml
```

## Verificação Completa

Após instalar, verifique todas as versões:

```bash
echo "=== Versões do Solana ==="
solana --version
cargo-build-sbf --version
solana-install --version

echo ""
echo "=== Versão do Rust (do Solana) ==="
~/.local/share/solana/install/active_release/bin/rustc --version

echo ""
echo "=== PATH ==="
which solana
which cargo-build-sbf
```

**Saída esperada:**
```
=== Versões do Solana ===
solana-cli 1.14.20
solana-cargo-build-sbf 1.14.20
platform-tools v1.XX
rustc 1.75.0

=== Versão do Rust (do Solana) ===
rustc 1.75.0

=== PATH ===
/home/lunc/.local/share/solana/install/active_release/bin/solana
/home/lunc/.local/share/solana/install/active_release/bin/cargo-build-sbf
```

## Se Ainda Falhar

### Opção 1: Usar Versão Específica do Rust

O Solana 1.14.20 vem com Rust 1.75.0. Certifique-se de usar essa versão:

```bash
# O cargo-build-sbf já usa o Rust do Solana automaticamente
# Mas você pode verificar:
~/.local/share/solana/install/active_release/bin/rustc --version
```

### Opção 2: Verificar Configurações do Cargo.toml

As configurações que adicionamos anteriormente devem estar corretas. Verifique:

```bash
cd ~/hyperlane-monorepo/rust/sealevel
grep -A 5 "\[profile.release\]" Cargo.toml
grep -A 3 "\[profile.release.package.solana-program\]" Cargo.toml
```

### Opção 3: Limpar Tudo e Reinstalar

```bash
# Remover instalação do Solana
rm -rf ~/.local/share/solana

# Remover cache do cargo
rm -rf ~/.cargo/registry/cache
rm -rf ~/hyperlane-monorepo/rust/sealevel/target

# Reinstalar Solana 1.14.20
sh -c "$(curl -sSfL https://release.anza.xyz/stable/install)"
solana-install init 1.14.20

# Verificar
solana --version
```

## Por Que 1.14.20?

O Hyperlane foi desenvolvido e testado com Solana 1.14.20. As versões mais novas (2.0.x) têm:
- Mudanças no compilador BPF
- Diferentes otimizações
- Possíveis bugs de compatibilidade

Usar a versão exata garante compatibilidade.

## Referências

- [Hyperlane Solana Documentation](https://docs.hyperlane.xyz/docs/guides/warp-routes/svm/svm-warp-route-guide)
- [Solana Release Archive](https://release.anza.xyz/)
- Script de instalação: `hyperlane-monorepo/rust/sealevel/programs/install-solana-1.14.20.sh`

